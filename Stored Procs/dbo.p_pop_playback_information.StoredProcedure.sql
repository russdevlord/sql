/****** Object:  StoredProcedure [dbo].[p_pop_playback_information]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_pop_playback_information]
GO
/****** Object:  StoredProcedure [dbo].[p_pop_playback_information]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_pop_playback_information]
	@xml XML,
	@data_provider_id int
AS
BEGIN	
	BEGIN TRY  

			--Log
			insert into dbo.pop_log([source],[Message])
			values(cast(@xml as nvarchar(max)),'Start Processing xml for data provider ' + cast(@data_provider_id as varchar))
		
			--Log
			insert into dbo.pop_log([Message])values('Create temp tables while reading xml and insert data into temp tables')

			--Create temp tables while reading xml and insert data into temp tables
			IF OBJECT_ID('tempdb..#PopStagingTable') IS NOT NULL 
					DROP TABLE #PopStagingTable

			;WITH Parents AS
			(
				SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS ParentID
					  ,prnt.value(N'(FtrTitle)[1]','nvarchar(max)') AS FtrTitle
					  ,prnt.value(N'(FtrCode)[1]','nvarchar(max)') AS FtrCode
					  ,prnt.value(N'(ComplexName)[1]','nvarchar(max)') AS ComplexName
					  ,prnt.value(N'(ComplexCode)[1]','nvarchar(max)') AS ComplexCode
					  ,prnt.value(N'(Screen)[1]','nvarchar(max)') AS Screen
					  ,prnt.value(N'(PlaybackStarted)[1]','nvarchar(max)') AS PlaybackStarted
					  ,prnt.query(N'PreShow/*') AS ChildrenXML
				FROM @xml.nodes(N'/PlayBack/*') AS Lvl1(prnt)
			)
			SELECT   Parents.ParentID
					,Parents.FtrTitle
					,Parents.FtrCode
					,Parents.ComplexName
					,Parents.ComplexCode
					,Parents.Screen
					,Parents.PlaybackStarted
					,ROW_NUMBER() OVER(PARTITION BY ParentID ORDER BY (SELECT NULL)) AS ChildID
					,chld.value(N'(Title)[1]','nvarchar(max)') AS PlaybackTitle
					,chld.value(N'(UUID)[1]','nvarchar(max)') AS PlaybackUUId
					,chld.value(N'(ContentType)[1]','nvarchar(max)') AS PlaybackContentType
					,chld.value(N'(PlaybackStarted)[1]','nvarchar(max)') AS PlaybackPlaybackStarted
					,chld.value(N'(PlaybackFinished)[1]','nvarchar(max)') AS PlaybackPlaybackFinished
			INTO #PopStagingTable
			FROM Parents
			OUTER APPLY ChildrenXML.nodes(N'*') AS Lvl2(chld);

			--Log
			insert into dbo.pop_log([Message])values('Loop through sessions and playbacks in temp table and insert records of sessions and playbacks')

			DECLARE @Id int
			set @Id = 1 

			DECLARE @theMax int
			select distinct @theMax=  MAX(parentId) FROM #PopStagingTable
			print @theMax

			--Loop through playback sessions 
			WHILE @Id <= @theMax
			BEGIN	
				BEGIN TRY  				

					INSERT INTO [dbo].[pop_playback_sessions]
					(feature_title,movie_code,complex_code,complex_name,screen,playback_started,pop_data_provider_id)
					select top 1 FtrTitle,FtrCode,ComplexCode,ComplexName,Screen,PlaybackStarted,@data_provider_id 
					from #PopStagingTable where ParentID=@Id

					declare @GeneratedPlayBackSessionId int
					SET @GeneratedPlayBackSessionId = SCOPE_IDENTITY();
	
					BEGIN TRY  
						DECLARE @ChildId int
						set @ChildId= 1 

						DECLARE @MaxChildId int
						select distinct @MaxChildId=MAX(ChildID) FROM #PopStagingTable where ParentID=@Id			

						--Loop through playbacks
						WHILE @ChildId <= @MaxChildId
						BEGIN
			
							insert into dbo.pop_playback(playback_session_Id,[uid],title,content_type,playback_started,playback_finished)
							select @GeneratedPlayBackSessionId,PlaybackUUId,PlaybackTitle,PlaybackContentType,PlaybackPlaybackStarted,PlaybackPlaybackFinished 
							from #PopStagingTable
							where ChildID=@ChildId and ParentID=@Id  --and PlaybackContentType = 'AD'

							SET @ChildId = @ChildId + 1
						End
					END TRY
					BEGIN CATCH  	
						--if playback is repeated/fails unique constraint then it will log error here and keep moving to next playback
						insert into dbo.pop_log([source],[Message],error)values(cast(@xml as nvarchar(max)),ERROR_MESSAGE(),1)    
					END CATCH 

				END TRY
				BEGIN CATCH  	
					--if playback session is repeated/fails unique constraint then it will log error here and keep moving to next session
					insert into dbo.pop_log([source],[Message],error)values(cast(@xml as nvarchar(max)),ERROR_MESSAGE(),1)    
				END CATCH 

				SET @Id = @Id + 1
			END

			--Log
			insert into dbo.pop_log([Message])values('End of processing xml for data provider ' + cast(@data_provider_id as varchar))
			DROP TABLE #PopStagingTable

	END TRY
	BEGIN CATCH  	

		insert into dbo.pop_log([source],[Message],error)values(cast(@xml as nvarchar(max)),ERROR_MESSAGE(),1)    
	
		DECLARE @ErMessage NVARCHAR(2048),@ErSeverity INT,@ErState INT 
		SELECT @ErMessage = ERROR_MESSAGE(),@ErSeverity = ERROR_SEVERITY(),@ErState = ERROR_STATE()
 
		RAISERROR (@ErMessage,@ErSeverity,@ErState )

	END CATCH 
END
GO
