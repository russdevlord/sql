/****** Object:  StoredProcedure [dbo].[p_pop_match_playlist]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_pop_match_playlist]
GO
/****** Object:  StoredProcedure [dbo].[p_pop_match_playlist]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_pop_match_playlist]
	@start_date datetime,
	@end_date datetime,
	@data_provider_id int
AS
BEGIN
	BEGIN TRY
	--exec [p_pop_match_playlist] '2018-01-24 00:00:00.000','2018-01-25 23:59:59.000',1

	--Check if any playback sessions exist (in other words, Log file executed/uploaded successfully in step 1) for given duration and data provider
	declare @AnySessionExist int 
	select @AnySessionExist = count(1) from pop_playback_sessions where [playback_started] >= @start_date and [playback_started] <= @end_date 
							  and pop_data_provider_id =@data_provider_id
	if(@AnySessionExist < 1)
	BEGIN
		insert into dbo.pop_log([source],[Message],[error])
		values('Stored Procedure : p_pop_match_playlist',
			  'No playlist sessions found for data provider ' + cast(@data_provider_id as varchar) + ' from ' + cast(@start_date as varchar(50)) + ' to ' + cast(@end_date as varchar(50))
			  ,1)
	END
	else
	BEGIN
		--Log
		insert into dbo.pop_log([source],[Message])
		values('Stored Procedure : p_pop_match_playlist',
			  'Start matching playlists for data provider ' + cast(@data_provider_id as varchar) + ' from ' + cast(@start_date as varchar(50)) + ' to ' + cast(@end_date as varchar(50)))
		
		--Get screening date based on end date parameter - get last screening date of end date 
		declare @ScreeningDate datetime				
		set @ScreeningDate = DATEADD(dd, 0, DATEDIFF(dd, 0, CONVERT(date, [dbo].f_get_screening_date(@end_date))))		
		print @ScreeningDate

		declare @CinemaTypeMovieId int
		set @CinemaTypeMovieId = 102

		--Fetch all certificate groups for last thrusday of date range's end date
		IF OBJECT_ID('tempdb..#CertificateGroupsStagingAll') IS NOT NULL
			DROP TABLE #CertificateGroupsStagingAll

		IF OBJECT_ID('tempdb..#CertificateGroupsStaging') IS NOT NULL
			DROP TABLE #CertificateGroupsStaging

		;WITH allcertificategroups AS
		(
		select distinct cg.certificate_group_id,cg.complex_id,cg.screening_date,mh.movie_id,dp.data_provider_id,(select min(sequence_no)
					from          (select              sequence_no,
																	sum(no_grps) as groups,
																	sum(number_of_dupes) as dupes
										from                 (select                     certificate_group_id, 
																										sequence_no,
																										print_id,
																										count(*) as no_grps,
																										count(*) over (partition by sequence_no, print_id) as number_of_dupes
																	from                        certificate_group 
																	inner join           movie_history on certificate_group.certificate_group_id = movie_history.certificate_group
																	inner join           certificate_item on certificate_item.certificate_group = certificate_group.certificate_group_id
																	where                certificate_group.complex_id = cg.complex_id
																	and                         certificate_group.screening_date =cg.screening_date
																	and                         movie_id = mh.movie_id
																	and                         certificate_group.print_medium = cg.print_medium
																	and                         certificate_group.three_d_type = cg.three_d_type
																	and                         certificate_group.premium_cinema = cg.premium_cinema   
																	group by             certificate_group_id, 
																										sequence_no, 
																										print_id) as temp_table
										group by      sequence_no) as temp_table_2
					where  groups = dupes) as search_to_row 
		from certificate_group cg 
		join complex c on c.complex_id=cg.complex_id
		join data_provider dp on c.exhibitor_id=dp.exhibitor_id
		inner join movie_history mh on mh.certificate_group = cg.certificate_group_id
		and mh.movie_id <> @CinemaTypeMovieId and dp.data_provider_id=@data_provider_id
		and cg.is_movie='Y'
		and cg.screening_date=@ScreeningDate
	--	and cg.complex_id=1079 --For testing
		--and cp.screening_date = [dbo].f_get_screening_date(playback_started) 
		--and movie_id=10861 and cg.complex_id=1079 --For testing
		--and movie_id in (10489,10861) and cg.complex_id=1079 --For testing	
		--and movie_id <> 10861 and cg.complex_id=1079 --For testing	
		)	
		select * into #CertificateGroupsStagingAll from allcertificategroups 	

		--When Search-to-row is null(certificate groups items are identical) then take first one
		;with cte
		as
		(
			select certificate_group_id,complex_id,screening_date,movie_id,data_provider_id,search_to_row
			from  #CertificateGroupsStagingAll where search_to_row is not null 
			union all 
			select certificate_group_id,complex_id,screening_date,movie_id,data_provider_id,search_to_row from 
			(
				select certificate_group_id,complex_id,screening_date,movie_id,data_provider_id,search_to_row,
				ROW_NUMBER() OVER(PARTITION BY complex_id,screening_date,movie_id order by certificate_group_id) Number 
				from #CertificateGroupsStagingAll where search_to_row is null 
			) as t where Number =1		
		)
		select IDENTITY(int) AS idcol,* into #CertificateGroupsStaging from cte 	

		DECLARE @CertificateGroupsStagingCount int
		set @CertificateGroupsStagingCount = 1 

		DECLARE @MaxCertificateGroupsStagingCount int
		select @MaxCertificateGroupsStagingCount = MAX(idcol) FROM #CertificateGroupsStaging

		--Loop through certificate groups
		WHILE @CertificateGroupsStagingCount <= @MaxCertificateGroupsStagingCount
		BEGIN	
			BEGIN TRY  		
				declare @currentCertificateGroupId int
				declare @ComplexId int		
				declare @MovieCode varchar(30)
				declare @MovieId int
				declare @ComplexCode varchar(30)
				declare @SearchToRow int		

			   --get current/being processed certificate group data
				select @currentCertificateGroupId=s.certificate_group_id, @ComplexId=s.complex_id,
				@MovieCode = tm.movie_code, @ComplexCode=tc.complex_code,@MovieId=s.movie_id,
				@SearchToRow=s.search_to_row
				from #CertificateGroupsStaging s 
				join data_translate_movie tm on tm.movie_id=s.movie_id and tm.data_provider_id=s.data_provider_id
				join data_translate_complex tc on tc.complex_id=s.complex_id and tc.data_provider_id=s.data_provider_id
				where idcol=@CertificateGroupsStagingCount 

				--get certificate groups count/playlist count for complex,movie and screening date
				declare @PlaybackListCount int 
				if (@SearchToRow is null)
				begin				
					set @PlaybackListCount = 1
				end
				else
				begin				
					select @PlaybackListCount = count(cg.certificate_group_id) from certificate_group cg 
					join movie_history mh on  cg.certificate_group_id=mh.certificate_group
					join complex c on c.complex_id=cg.complex_id
					where  cg.complex_id=@ComplexId and mh.movie_id=@MovieId and cg.screening_date=@ScreeningDate
					group by cg.complex_id,movie_id,cg.screening_date
				end
					
				----Fetch all playback sessions for movie,complex and between date range parameters
				IF OBJECT_ID('tempdb..#PopPlayBackSessionsStaging') IS NOT NULL
							DROP TABLE #PopPlayBackSessionsStaging

				;with cte1 as
				(select [pop_playback_sessions_id] * 1 as pop_playback_sessions_id,feature_title,movie_code,complex_code,
				 complex_name,screen,playback_started,pop_data_provider_id
				 from pop_playback_sessions where movie_code=@MovieCode and complex_code=@ComplexCode  
				 and [playback_started] >= @start_date and [playback_started] <= @end_date) --put the date range here from parameters				 
				select IDENTITY(int) AS idcolForPlayBackSessions,* into #PopPlayBackSessionsStaging from cte1

				DECLARE @PopPlayBackSessionsCount int
				set @PopPlayBackSessionsCount= 1 

				DECLARE @MaxPopPlayBackSessionsCount int
				select @MaxPopPlayBackSessionsCount=MAX(idcolForPlayBackSessions) FROM #PopPlayBackSessionsStaging

				----Loop through playback sessions
				WHILE @PopPlayBackSessionsCount <= @MaxPopPlayBackSessionsCount
				BEGIN		
						declare @CinemaNo varchar(20)
						declare @currentPlaybackSessionsId int

						--get current playback session and cinema number for that
						select @CinemaNo = LTRIM(RTRIM(screen)),
						@currentPlaybackSessionsId=pop_playback_sessions_id 
						from #PopPlayBackSessionsStaging where idcolForPlayBackSessions=@PopPlayBackSessionsCount
						set @CinemaNo = SUBSTRING(@CinemaNo, CHARINDEX(' ', @CinemaNo) + 1, LEN(@CinemaNo))
				
						--get current playback's Cinema Certificate group id for complex and screening date
						declare @CinemaCertificateGroupId int
						select @CinemaCertificateGroupId = certificate_group from movie_history where movie_id=@CinemaTypeMovieId 
						and complex_id=@ComplexId and screening_date=@ScreeningDate
						and occurence=@CinemaNo
			
						--Get all playbacks from from pop playback table(of XML log) (to be checked against certificate groups) and assign number to it	
						IF OBJECT_ID('tempdb..#PlaybackStaging') IS NOT NULL
								DROP TABLE #PlaybackStaging		
			
						select uid,ROW_NUMBER() OVER(ORDER BY pop_Playback_id) Number into #PlaybackStaging 
						from [dbo].[pop_playback] where [playback_session_Id]=@currentPlaybackSessionsId and [content_type]='AD'
						order by pop_Playback_id				

						--if multiple playlist(from certificate groups) then restrict MOVIE(not cinema) playlist comparison upto searchrow sequence
						if (@PlaybackListCount > 1)
						begin							
								IF OBJECT_ID('tempdb..#CertificateItemsStaging') IS NOT NULL
										DROP TABLE #CertificateItemsStaging

								IF OBJECT_ID('tempdb..#NotMatchedPlayback') IS NOT NULL
										DROP TABLE #NotMatchedPlayback

								create table #CertificateItemsStaging
								(
									Number int,
									uuid varchar(50)
								)		

								create table #NotMatchedPlayback
								(
									uuid varchar(50),
									playback_order int
								)		

								--Get all certificate Items(based on cinema + movie certificate group ids) and assign number to against it
								Insert into #CertificateItemsStaging(uuid,Number)
								select  upper(uuid) uid,ROW_NUMBER() OVER(ORDER BY  certificate_group,sequence_no) Number 
								from 
								(
								select uuid,sequence_no,certificate_item_id,certificate_group,ci.print_id from certificate_item ci 
										join film_print fp on ci.print_id=fp.print_id
										join film_print_file_locations fl on fp.print_id=fl.print_id  
										where certificate_group in (@CinemaCertificateGroupId) and fl.uuid is not null 
										and fl.filename like '%_ADV_%' and fl.filename not like '%_PSA_%' -- NEED TO REMOVE THIS CONDITION ONCE GOES WITH REAL TIME DATA
								UNION all
								select uuid,sequence_no,certificate_item_id,certificate_group,ci.print_id from certificate_item ci 
										join film_print fp on ci.print_id=fp.print_id
										join film_print_file_locations fl on fp.print_id=fl.print_id  
										where certificate_group in (@currentCertificateGroupId) and fl.uuid is not null 
										and fl.filename like '%_ADV_%' and fl.filename not like '%_PSA_%' -- NEED TO REMOVE THIS CONDITION ONCE GOES WITH REAL TIME DATA
										and ci.sequence_no <= @SearchToRow	--restrict MOVIE(not cinema) playlist comparison upto searchrow sequence			
								)
								CertificateItems Order by  certificate_group,sequence_no

								declare @CurrentItem int
								set @CurrentItem =1

								declare @MaxItem int
								select @MaxItem = Max(Number) from #CertificateItemsStaging		

								---Loop Through Certificate items for 2 certificate groups(cinema and movie) and compare playlist with current playback list
								While @CurrentItem <= @MaxItem
								begin 
									--get current certificate uuid from number
									 declare @uuid varchar(50)	 
									 select @uuid=uuid from #CertificateItemsStaging where Number=@CurrentItem

									 --check in playback that same uuid exist in same number, if not playback not matching
									 declare @MatchFound int
									 select  @MatchFound = count(1) from #PlaybackStaging where uid=@uuid and Number=@CurrentItem

									 --if not matching then add to temp table
									 if(@MatchFound <= 0)
									 begin 
										 insert into #NotMatchedPlayback(uuid,playback_order)values(@uuid,@CurrentItem)
									 end

									 set @CurrentItem=@CurrentItem + 1
								end

								--check playlist is same, if temp table is empty then playlist are same
								declare @PlayListAreSame int 
								select @PlayListAreSame =(CASE WHEN count(*) <= 0 THEN 1 ELSE 0 END) from #NotMatchedPlayback

								if (@PlayListAreSame=1)
								begin			
									--Insert matched playlist to pop_certificate_group_summary table
									 insert into [dbo].[pop_certificate_group_summary]([certificate_group_id],[pop_playback_sessions_id])
									 VALUES(@CinemaCertificateGroupId,@currentPlaybackSessionsId)

									insert into [dbo].[pop_certificate_group_summary]([certificate_group_id],[pop_playback_sessions_id])
									VALUES(@currentCertificateGroupId,@currentPlaybackSessionsId)
								end
						end
						else
						begin										
							 --Insert to pop_certificate_group_summary table if only one playlist/certificate group found
							 insert into [dbo].[pop_certificate_group_summary]([certificate_group_id],[pop_playback_sessions_id])
							 values(@CinemaCertificateGroupId,@currentPlaybackSessionsId)

							 insert into[dbo].[pop_certificate_group_summary]([certificate_group_id],[pop_playback_sessions_id])
							 values (@currentCertificateGroupId,@currentPlaybackSessionsId)
						end
		
						SET @PopPlayBackSessionsCount = @PopPlayBackSessionsCount + 1
				End			
		END TRY
		BEGIN CATCH  	
			--if some error while processing this Certificate group,insert into log table and move to next certificate group
			insert into dbo.pop_log([source],[Message],error)values('Stored Procedure : p_pop_match_playlist',ERROR_MESSAGE(),1)    
		END CATCH 

			SET @CertificateGroupsStagingCount = @CertificateGroupsStagingCount + 1
		End

		--Log
		insert into dbo.pop_log([source],[Message])
		values('Stored Procedure : p_pop_match_playlist',
			   'End matching playlists for data provider ' + cast(@data_provider_id as varchar) + ' from ' + cast(@start_date as varchar(50)) + ' to ' + cast(@end_date as varchar(50)))

		--drop temp tables, check if exist (might not be created,based on condition) 
		IF OBJECT_ID('tempdb..#CertificateGroupsStaging') IS NOT NULL
			DROP TABLE #CertificateGroupsStaging

		IF OBJECT_ID('tempdb..#PopPlayBackSessionsStaging') IS NOT NULL
			DROP TABLE #PopPlayBackSessionsStaging

		IF OBJECT_ID('tempdb..#CertificateItemsStaging') IS NOT NULL
			DROP TABLE #CertificateItemsStaging

		IF OBJECT_ID('tempdb..#PlaybackStaging') IS NOT NULL
			DROP TABLE #PlaybackStaging		

		IF OBJECT_ID('tempdb..#NotMatchedPlayback') IS NOT NULL
			DROP TABLE #NotMatchedPlayback	
	END

	END TRY
	BEGIN CATCH  	

		insert into dbo.pop_log([source],[Message],error)values('Stored Procedure : p_pop_match_playlist',ERROR_MESSAGE(),1)    

		DECLARE @ErMessage NVARCHAR(2048),@ErSeverity INT,@ErState INT 
		SELECT @ErMessage = ERROR_MESSAGE(),@ErSeverity = ERROR_SEVERITY(),@ErState = ERROR_STATE()
 
		RAISERROR (@ErMessage,@ErSeverity,@ErState )

	END CATCH 
END
GO
