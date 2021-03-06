/****** Object:  StoredProcedure [dbo].[p_pop_compare_playlist]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_pop_compare_playlist]
GO
/****** Object:  StoredProcedure [dbo].[p_pop_compare_playlist]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_pop_compare_playlist]
	@start_date datetime,
	@end_date datetime,
	@data_provider_id int
AS
BEGIN
	BEGIN TRY
		--exec p_pop_compare_playlist_1 '2018-01-24 00:00:00.000','2018-01-25 23:59:59.000',1

		-- we are checking below scenarios in this stored procedure :
		-- 1. Certificate item and playback match found and its in same order
		-- 2. Certificate item and playback match found but not in same order
		-- 3. Certificate item exist but playback match not found
		-- 4. Playback found but relevant certificate item does not exist

		--Log- start the process
		insert into dbo.pop_log([source],[Message])
		values('Stored Procedure : p_pop_compare_playlist',
  				'Start processing for data provider ' + cast(@data_provider_id as varchar(20)) + ' from ' + cast(@start_date as varchar(50)) + ' to ' + cast(@end_date as varchar(50)))
					
		--Get playback sessions based on certificate group summary,start and end dates,provider
		IF OBJECT_ID('tempdb..#PlayBackSessionsFromCertificateGroupSummaryStaging') IS NOT NULL
					DROP TABLE #PlayBackSessionsFromCertificateGroupSummaryStaging

		;with cte as
		(
			select distinct cgs.pop_playback_sessions_id from [dbo].[pop_certificate_group_summary] cgs inner join 
			pop_playback_sessions pps on cgs.pop_playback_sessions_id=pps.pop_playback_sessions_id
			and pps.pop_data_provider_id=@data_provider_id 
			and [playback_started] >= @start_date and [playback_started] <= @end_date
		)
		select IDENTITY(int) AS idcolForPlayBackSessions,* into #PlayBackSessionsFromCertificateGroupSummaryStaging from cte
		order by pop_playback_sessions_id
		--select * from #PlayBackSessionsFromCertificateGroupSummaryStaging

		--Check if any playback session exist for given duration
		declare @AnySessionExist int 
		select @AnySessionExist = count(1) from #PlayBackSessionsFromCertificateGroupSummaryStaging

		--if playback sessions are available
		if(@AnySessionExist >= 1)
			begin
				--Loop through playback sessions 
				declare @PopPlaybackSessionsCount int
				set @PopPlaybackSessionsCount = 1

				declare @PopPlaybackSessionsMaxCount int
				select @PopPlaybackSessionsMaxCount= Max(idcolForPlayBackSessions) from #PlayBackSessionsFromCertificateGroupSummaryStaging
			
				--Log entry
				insert into dbo.pop_log([source],[Message])
				values('Stored Procedure : p_pop_compare_playlist',
  					   'Looping through playback sessions( total : ' + cast(@AnySessionExist as varchar(20)) + ' ) for data provider ' 
					   + cast(@data_provider_id as varchar) + ' from ' + cast(@start_date as varchar(50)) + ' to ' + cast(@end_date as varchar(50)))

				while (@PopPlaybackSessionsCount <= @PopPlaybackSessionsMaxCount)
				begin
					BEGIN TRY  		

						--Get current/being processed playback session id
						declare @CurrentPopPlaybackSessionsId int 		
						select @CurrentPopPlaybackSessionsId = pop_playback_sessions_id from #PlayBackSessionsFromCertificateGroupSummaryStaging where 
															 idcolForPlayBackSessions=@PopPlaybackSessionsCount
			
						--Get certificate items for current playback session (using certificate groups)
						IF OBJECT_ID('tempdb..#CertificateItemsStaging') IS NOT NULL
									DROP TABLE #CertificateItemsStaging

						;with cte1 as
						(						
							select certificate_item_id,certificate_group,sequence_no,UPPER(uuid) uuid from certificate_item ci inner join 
							film_print_file_locations fl on ci.print_id=fl.print_id where certificate_group in 
							(select certificate_group_id from [dbo].[pop_certificate_group_summary] 
							where [pop_playback_sessions_id]=@CurrentPopPlaybackSessionsId) 							
							and fl.filename like '%_ADV_%' and fl.filename not like '%_PSA_%'
						)
						select IDENTITY(int) idcolForCertificateItems,* into #CertificateItemsStaging from cte1
						order by certificate_group,sequence_no
						-- select * from #CertificateItemsStaging

						--Get Playbacks for playback session
						IF OBJECT_ID('tempdb..#PlaybacksStaging') IS NOT NULL
									DROP TABLE #PlaybacksStaging

						;with cte2 as
						(
							select [pop_playback_id] * 1 as pop_playback_id,[playback_session_id],[uid],[title],[content_type],[playback_started],[playback_finished],
							CAST(0 AS bit) AS Processed from [dbo].[pop_playback] where content_type='AD' and 						
							[playback_session_id]=@CurrentPopPlaybackSessionsId

						)
						select IDENTITY(int) idcolForPlayback,* into #PlaybacksStaging from cte2 order by [playback_started] 			
						--select * from #PlaybacksStaging

						--Loop through certificate items
						declare @CertificationItemsCount int 
						set @CertificationItemsCount=1

						declare @MaxCertificationItemsCount int 
						select @MaxCertificationItemsCount=Max(idcolForCertificateItems) from #CertificateItemsStaging

						declare @CertificateItemId int 		
						declare @CertificateItemUuid varchar(50)
						declare @CertificateItemOrder int
						declare @PlaybackStatusId int 
						declare @PlaybackOrderStatusId int 
					
						while @CertificationItemsCount <= @MaxCertificationItemsCount
						begin
							BEGIN TRY								
								--Get current/being processed certificate Item details
								select @CertificateItemOrder=idcolForCertificateItems,
								@CertificateItemId = certificate_item_id, @CertificateItemUuid = uuid 
								from #CertificateItemsStaging where 
								idcolForCertificateItems=@CertificationItemsCount				
	
								declare @PlayBackId int	
								--just check first existence of certificate item uuid and not yet processed from #PlaybacksStaging table	
								if exists(select pop_playback_id from #PlaybacksStaging where [uid]=@CertificateItemUuid and Processed=0)
								begin		
									--As exist so playback status as 'Played'																																			
									select @PlaybackStatusId=pop_playback_status_id from pop_playback_status where pop_playback_status_desc = 'Played'
														
									---Scenarios 1: If exists with correct order then playback order status as 'Followed' (and playback status as 'Played')											
									if exists(select pop_playback_id from #PlaybacksStaging where [uid]=@CertificateItemUuid and idcolForPlayback=@CertificateItemOrder)
									begin																				
										select @PlayBackId = pop_playback_id  from #PlaybacksStaging 
										where [uid]=@CertificateItemUuid and idcolForPlayback=@CertificateItemOrder										

										select @PlaybackOrderStatusId =pop_playback_order_status_id from pop_playback_order_status 
										where pop_playback_order_status_desc = 'Followed'
									end
									else --Scenarios 2: If exists but not in correct order thn playback order status as 'Not Followed' (playback status as 'Played')
									begin										
										select top 1 @PlayBackId = pop_playback_id from #PlaybacksStaging 
										where [uid]=@CertificateItemUuid and Processed=0 order by [playback_started]	

										select @PlaybackOrderStatusId =pop_playback_order_status_id from pop_playback_order_status 
										where pop_playback_order_status_desc = 'Not Followed'		
									end
																										
									----Insert into pop_certificate_item_playback
									INSERT INTO [dbo].[pop_certificate_item_playback]([certificate_item_id],[pop_playback_id],[pop_playback_status_id],[pop_playback_order_status_id])
									VALUES(@certificateItemId,@PlayBackId,@PlaybackStatusId,@PlaybackOrderStatusId)

									--update playback as 'processed' in staging table so will not come in selection again(For multiple uuid in #PlaybacksStaging table or say ads played multiple times in the same playback list)
									Update #PlaybacksStaging set Processed=1 where pop_playback_id=@PlayBackId				
								end
								else
								begin		
									--Scenarios 3 : If not exists then 'Not Played' and 'Not Applicable' 									
									select @PlaybackStatusId=pop_playback_status_id from pop_playback_status where pop_playback_status_desc = 'Not Played'
									select @PlaybackOrderStatusId =pop_playback_order_status_id from pop_playback_order_status where pop_playback_order_status_desc = 'Not Applicable'					

									--Insert into pop_certificate_item_playback
									INSERT INTO [dbo].[pop_certificate_item_playback]([certificate_item_id],[pop_playback_id],[pop_playback_status_id],[pop_playback_order_status_id])
									VALUES (@certificateItemId,null,@PlaybackStatusId,@PlaybackOrderStatusId) 
								end

							END TRY
							BEGIN CATCH  	
								--Error generated while processing certificate item,log it and move to next certificate item
								insert into dbo.pop_log([source],[Message],error)values('Stored Procedure : pop_compare_playlist','Error while processing certificate item uuid : ' + @CertificateItemUuid + '.' + ERROR_MESSAGE(),1) 								
								--mark playback as processed if error generated while processing it so can easily process next one
								if(@PlayBackId <> '')
								begin
									Update #PlaybacksStaging set Processed=1 where pop_playback_id=@PlayBackId
								end
								
							END CATCH 

							set @CertificationItemsCount = @CertificationItemsCount + 1							
						end

						---Scenarios 4 : For all pop_playback in pop_certificate_group_summary where the pop_playback is not in pop_certificate_item_playback (all playbacks of current playback session being processed) 										
						INSERT INTO [dbo].[pop_certificate_item_playback]([certificate_item_id],[pop_playback_id],[pop_playback_status_id],[pop_playback_order_status_id])
						select null,pop_playback_id,
						(select pop_playback_status_id from pop_playback_status where pop_playback_status_desc = 'Not Scheduled'),
						(select pop_playback_order_status_id from pop_playback_order_status where pop_playback_order_status_desc = 'Not Applicable')  
						from #PlaybacksStaging 
						where pop_playback_id not in (select pop_playback_id from pop_certificate_item_playback where pop_playback_id is not null) 												

						END TRY
						BEGIN CATCH  	
							--if some error while processing this playback session Id,insert into log table and move to next playback session							
							insert into dbo.pop_log([source],[Message],error)
							values('Stored Procedure : pop_compare_playlist','Error while processing playback session Id : ' + cast(isnull(@CurrentPopPlaybackSessionsId,0) as varchar(10)) + '.' + ERROR_MESSAGE(),1)    							
						END CATCH 

					set @PopPlaybackSessionsCount = @PopPlaybackSessionsCount + 1
				end	
			
				--Log
				insert into dbo.pop_log([source],[Message])
				values('Stored Procedure : pop_compare_playlist',
					   'End looping through playback sessions for data provider ' + cast(@data_provider_id as varchar) + ' from ' + cast(@start_date as varchar(50)) + ' to ' + cast(@end_date as varchar(50)))
			end
		else
			begin 
				insert into dbo.pop_log([source],[Message])values
				('Stored Procedure : pop_compare_playlist','No playback sessions found to process for data provider ' + cast(@data_provider_id as varchar) + ' from ' + cast(@start_date as varchar(50)) + ' to ' + cast(@end_date as varchar(50)))			
			end
		
		--Log- End the process
		insert into dbo.pop_log([source],[Message])
		values('Stored Procedure : p_pop_compare_playlist',
  				'End processing for data provider ' + cast(@data_provider_id as varchar) + ' from ' + cast(@start_date as varchar(50)) + ' to ' + cast(@end_date as varchar(50)))

		--drop temp tables, check if exist (might not be created,based on condition) 
		IF OBJECT_ID('tempdb..#PlayBackSessionsFromCertificateGroupSummaryStaging') IS NOT NULL
			DROP TABLE #PlayBackSessionsFromCertificateGroupSummaryStaging

		IF OBJECT_ID('tempdb..#CertificateItemsStaging') IS NOT NULL
			DROP TABLE #CertificateItemsStaging

		IF OBJECT_ID('tempdb..#PlaybacksStaging') IS NOT NULL
			DROP TABLE #PlaybacksStaging

	END TRY
	BEGIN CATCH  	

		insert into dbo.pop_log([source],[Message],error)values('Stored Procedure : pop_compare_playlist',ERROR_MESSAGE(),1)    

		DECLARE @ErMessage NVARCHAR(2048),@ErSeverity INT,@ErState INT 
		SELECT @ErMessage = ERROR_MESSAGE(),@ErSeverity = ERROR_SEVERITY(),@ErState = ERROR_STATE()
 
		RAISERROR (@ErMessage,@ErSeverity,@ErState )

	END CATCH 
END
GO
