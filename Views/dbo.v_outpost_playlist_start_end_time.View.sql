/****** Object:  View [dbo].[v_outpost_playlist_start_end_time]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_outpost_playlist_start_end_time]
GO
/****** Object:  View [dbo].[v_outpost_playlist_start_end_time]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_outpost_playlist_start_end_time] (row_num, playlist_id, start_date, start_time, end_date, end_time)
AS
SELECT	V1.row_num, V1.playlist_id, V1.start_date, V1.start_time,-- V2.start_date, DATEADD(SECOND, -1, V2.start_time)
		V1.start_date, ISNULL(DATEADD(SECOND, -1, V2.start_time), CONVERT(TIME, '23:59:59.000'))
FROM	v_outpost_playlist_start_time AS V1
		INNER JOIN v_outpost_playlist_start_time AS V2 ON V1.start_date = V2.start_date
														AND	V1.playlist_id = V2.playlist_id
														AND V1.row_num + 1 = V2.row_num 
--WHERE	v1.playlist_id = @playlist_id OR @playlist_id IS NULL)
GO
