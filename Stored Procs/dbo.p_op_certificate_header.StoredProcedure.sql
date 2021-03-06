/****** Object:  StoredProcedure [dbo].[p_op_certificate_header]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_certificate_header]
GO
/****** Object:  StoredProcedure [dbo].[p_op_certificate_header]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[p_op_certificate_header] 	@playlist_id			int

as
SET NOCOUNT ON;

CREATE TABLE #temp_destination (
		row_num				INT				NOT NULL,
		D1					VARCHAR(11)		NULL,
		D2					VARCHAR(11)		NULL,
		D3					VARCHAR(11)		NULL,
		D4					VARCHAR(11)		NULL,
		D5					VARCHAR(11)		NULL,
		D6					VARCHAR(11)		NULL,
		D7					VARCHAR(11)		NULL
)

CREATE TABLE #temp_source (
		start_date			DATE			NULL,
		week_day			INT				NULL,
		D1					VARCHAR(11)		NULL,
		D2					VARCHAR(11)		NULL,
		D3					VARCHAR(11)		NULL,
		D4					VARCHAR(11)		NULL,
		D5					VARCHAR(11)		NULL,
		D6					VARCHAR(11)		NULL,
		D7					VARCHAR(11)		NULL,
		RANK1				INT				NULL,
		RANK2				INT				NULL
)

-- Create Header Row for WeekDays
INSERT INTO #temp_destination( row_num )
VALUES ( 0 )

-- Create Playlist segements container
INSERT INTO #temp_destination( row_num )
SELECT TOP 100 [Number]
  FROM Numbers
  
--INSERT INTO #temp_source( week_day, D1, D2, D3, D4, D5, D6, D7, RANK1, RANK2)  
--SELECT 0, 'SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA', 0 , 0
 
INSERT INTO #temp_source( start_date, week_day, D1, D2, D3, D4, D5, D6, D7, RANK1, RANK2) 
--INSERT INTO #temp_destination(row_num, D1, D2, D3, D4, D5, D6, D7) 
 SELECT DISTINCT CONVERT(DATE, start_date), --NULL,
		DATEPART( WEEKDAY, start_date),
		CASE WHEN DATEPART( WEEKDAY, start_date) = 1 Then UPPER(CONVERT(VARCHAR(15), DATENAME( WEEKDAY, start_date))) Else NULL End,
		CASE WHEN DATEPART( WEEKDAY, start_date) = 2 Then UPPER(CONVERT(VARCHAR(15), DATENAME( WEEKDAY, start_date))) Else NULL End,
		CASE WHEN DATEPART( WEEKDAY, start_date) = 3 Then UPPER(CONVERT(VARCHAR(15), DATENAME( WEEKDAY, start_date))) Else NULL End,
		CASE WHEN DATEPART( WEEKDAY, start_date) = 4 Then UPPER(CONVERT(VARCHAR(15), DATENAME( WEEKDAY, start_date))) Else NULL End,
		CASE WHEN DATEPART( WEEKDAY, start_date) = 5 Then UPPER(CONVERT(VARCHAR(15), DATENAME( WEEKDAY, start_date))) Else NULL End,
		CASE WHEN DATEPART( WEEKDAY, start_date) = 6 Then UPPER(CONVERT(VARCHAR(15), DATENAME( WEEKDAY, start_date))) Else NULL End,
		CASE WHEN DATEPART( WEEKDAY, start_date) = 7 Then UPPER(CONVERT(VARCHAR(15), DATENAME( WEEKDAY, start_date))) Else NULL End,
		0, 0
   FROM outpost_playlist_segment  
  WHERE playlist_id = @playlist_id
  
INSERT INTO #temp_source( start_date, week_day, D1, D2, D3, D4, D5, D6, D7, RANK1, RANK2)  
 SELECT DISTINCT OPS.start_date, --OPS.package_id,
	--dbo.f_outpost_certificate_package(outpost_certificate_item.certificate_item_id) package,
	DATEPART( DW, OPS.start_date),
	CASE WHEN DATEPART( WEEKDAY, OPS.start_date) = 1 Then CONVERT(varchar(5), CONVERT(TIME, OPS.start_date)) + '-' + CONVERT(varchar(5), CONVERT(TIME, end_date)) Else NULL End,
	CASE WHEN DATEPART( WEEKDAY, OPS.start_date) = 2 Then CONVERT(varchar(5), CONVERT(TIME, OPS.start_date)) + '-' + CONVERT(varchar(5), CONVERT(TIME, end_date)) Else NULL End,
	CASE WHEN DATEPART( WEEKDAY, OPS.start_date) = 3 Then CONVERT(varchar(5), CONVERT(TIME, OPS.start_date)) + '-' + CONVERT(varchar(5), CONVERT(TIME, end_date)) Else NULL End,
	CASE WHEN DATEPART( WEEKDAY, OPS.start_date) = 4 Then CONVERT(varchar(5), CONVERT(TIME, OPS.start_date)) + '-' + CONVERT(varchar(5), CONVERT(TIME, end_date)) Else NULL End,
	CASE WHEN DATEPART( WEEKDAY, OPS.start_date) = 5 Then CONVERT(varchar(5), CONVERT(TIME, OPS.start_date)) + '-' + CONVERT(varchar(5), CONVERT(TIME, end_date)) Else NULL End,
	CASE WHEN DATEPART( WEEKDAY, OPS.start_date) = 6 Then CONVERT(varchar(5), CONVERT(TIME, OPS.start_date)) + '-' + CONVERT(varchar(5), CONVERT(TIME, end_date)) Else NULL End,
	CASE WHEN DATEPART( WEEKDAY, OPS.start_date) = 7 Then CONVERT(varchar(5), CONVERT(TIME, OPS.start_date)) + '-' + CONVERT(varchar(5), CONVERT(TIME, end_date)) Else NULL End,
	Rank1 = DENSE_RANK() OVER( ORDER BY DATEPART( DAY, OPS.start_date)),
	Rank2 = DENSE_RANK() OVER( PARTITION BY DATEPART( DW, OPS.start_date)
			ORDER BY DATEPART( DW, OPS.start_date), DATEPART( HOUR, OPS.start_date),DATEPART( MINUTE, OPS.start_date)  ASC)
FROM outpost_playlist_segment AS OPS
	INNER JOIN outpost_certificate_item ON outpost_certificate_item.playlist_id = OPS.playlist_id
	inner join  outpost_print on outpost_certificate_item.print_id = outpost_print.print_id
	--INNER join outpost_package on outpost_package.package_id = dbo.f_outpost_certificate_package(outpost_certificate_item.certificate_item_id)
WHERE	outpost_certificate_item.playlist_id = @playlist_id
--AND		OPS.package_id = dbo.f_outpost_certificate_package(outpost_certificate_item.certificate_item_id) 
--AND		outpost_certificate_item.player_name = :as_player_name
--AND		outpost_certificate_item.screening_date = @screening_date 


-- Update Segments
UPDATE	#temp_destination
SET		D1 = CASE WHEN #temp_source.D1 IS NOT NULL Then #temp_source.D1 Else NULL End,
		D2 = CASE WHEN #temp_source.D2 IS NOT NULL Then #temp_source.D2 Else NULL End,
		D3 = CASE WHEN #temp_source.D3 IS NOT NULL Then #temp_source.D3 Else NULL End,
		D4 = CASE WHEN #temp_source.D4 IS NOT NULL Then #temp_source.D4 Else NULL End,
		D5 = CASE WHEN #temp_source.D5 IS NOT NULL Then #temp_source.D5 Else NULL End,
		D6 = CASE WHEN #temp_source.D6 IS NOT NULL Then #temp_source.D6 Else NULL End,
		D7 = CASE WHEN #temp_source.D7 IS NOT NULL Then #temp_source.D7 Else NULL End
FROM	#temp_destination
	INNER JOIN #temp_source
	ON #temp_source.RANK2 = #temp_destination.row_num

DROP TABLE #temp_source

---- DELETE unused rows
DELETE FROM	#temp_destination
WHERE D1 IS NULL AND D2 IS NULL AND D3 IS NULL AND D4 IS NULL AND D5 IS NULL AND D6 IS NULL AND D7 IS NULL

UPDATE #temp_destination SET D1 = 'X' WHERE D1 IS NULL and row_num > 0
UPDATE #temp_destination SET D2 = 'X' WHERE D2 IS NULL and row_num > 0
UPDATE #temp_destination SET D3 = 'X' WHERE D3 IS NULL and row_num > 0
UPDATE #temp_destination SET D4 = 'X' WHERE D4 IS NULL and row_num > 0
UPDATE #temp_destination SET D5 = 'X' WHERE D5 IS NULL and row_num > 0
UPDATE #temp_destination SET D6 = 'X' WHERE D6 IS NULL and row_num > 0
UPDATE #temp_destination SET D7 = 'X' WHERE D7 IS NULL and row_num > 0

SELECT row_num, --'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7'
	CAST ( d1 AS CHAR(15)) AS D1,
	CAST ( d2 AS CHAR(15)) AS D2,
	CAST ( d3 AS CHAR(15)) AS D3,
	CAST ( d4 AS CHAR(15)) AS D4,
	CAST ( d5 AS CHAR(15)) AS D5,
	CAST ( d6 AS CHAR(15)) AS D6,
	CAST ( d7 AS CHAR(15)) AS D7
FROM	#temp_destination
order by row_num

--DROP TABLE #temp_destination

--return 0
GO
