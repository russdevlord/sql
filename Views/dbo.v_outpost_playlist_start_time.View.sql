/****** Object:  View [dbo].[v_outpost_playlist_start_time]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_outpost_playlist_start_time]
GO
/****** Object:  View [dbo].[v_outpost_playlist_start_time]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_outpost_playlist_start_time] (row_num, playlist_id, start_date, start_time, start_datetime)
AS
SELECT DISTINCT ROW_NUMBER() OVER( PARTITION BY playlist_id, CONVERT(DATE, Start_Time.start_date) ORDER BY Start_Time.start_datetime),
		playlist_id,
		start_Time.start_date, Start_Time.start_time, 
		Start_Time.start_datetime as start_datetime
FROM (
		SELECT DISTINCT playlist_id,
				CONVERT(DATE, start_date) AS start_date,
				CONVERT(TIME, start_date) AS start_time,
				start_date AS start_datetime
		FROM outpost_playlist_segment
		UNION
		SELECT DISTINCT TT1.playlist_id,
						CONVERT(DATE, end_date) AS start_date,						
						CONVERT(TIME, DATEADD(SECOND, 1, end_date)) AS start_time,
						CONVERT(DATETIME, DATEADD(SECOND, 1, end_date)) AS start_datetime
		FROM outpost_playlist_segment AS TT1,
			( SELECT DISTINCT playlist_id AS playlist_id,
						CONVERT(DATE, start_date) AS start_date,
						CONVERT(TIME, start_date) as start_time,
						start_date AS start_datetime					
				FROM	outpost_playlist_segment) AS TT2
				WHERE	TT1.playlist_id = TT2.playlist_id
				and		CONVERT(TIME,  DATEADD(SECOND, 1, TT1.end_date)) <> CONVERT(TIME, TT2.start_time)
				AND		CONVERT(DATE, TT1.end_date) = CONVERT(DATE, TT2.start_date)
			) AS Start_Time
--WHERE	( playlist_id = @playlist_id OR @playlist_id IS NULL )
GO
