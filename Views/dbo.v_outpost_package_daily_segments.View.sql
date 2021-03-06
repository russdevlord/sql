/****** Object:  View [dbo].[v_outpost_package_daily_segments]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_outpost_package_daily_segments]
GO
/****** Object:  View [dbo].[v_outpost_package_daily_segments]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_outpost_package_daily_segments] ( package_id, start_date, end_date, patt_day)
AS 
SELECT	pack.package_id ,
		--CONVERT(DATETIME, DATEADD(DAY, Numbers.number - 1, pack.start_date)) AS pack_start_date,   
		--CONVERT(DATETIME, DATEADD(DAY, Numbers.number - 1, pack.start_date) + CONVERT(TIME, DATEADD(SECOND, -1, pack.start_date))) AS pack_end_date,
		CONVERT(DATETIME, ( DATEADD(DAY, Numbers.number - 1, pack.start_date)) + CONVERT(TIME, PIP.start_date)) AS start_date,
		CONVERT(DATETIME, ( DATEADD(DAY, Numbers.number - 1, pack.start_date)) + CONVERT(TIME, PIP.end_date)) AS end_date,
		PIP.patt_day AS patt_day 
FROM	outpost_package as pack 
			INNER JOIN outpost_package_burst AS PB ON pack.package_id = PB.package_id  
			INNER JOIN outpost_package_intra_pattern AS PIP ON pack.package_id = PIP.package_id,
		Numbers  
WHERE	( Numbers.number <= DATEDIFF(DAY, pack.start_date, pack.used_by_date ))
AND		( CONVERT(DATETIME, DATEADD(DAY, Numbers.number - 1, pack.start_date)) >= DATEADD(DAY, 0, pack.start_date) )
AND		( CONVERT(DATETIME, DATEADD(DAY, Numbers.number, pack.start_date) + CONVERT(TIME, DATEADD(SECOND, -1, pack.start_date))) < DATEADD(DAY, 1, pack.used_by_date))
AND		( CONVERT(DATETIME, DATEADD(DAY, Numbers.number - 1, pack.start_date)) >= PB.start_date )
AND		( CONVERT(DATETIME, DATEADD(DAY, Numbers.number - 1, pack.start_date) + CONVERT(TIME, DATEADD(SECOND, -1, pack.start_date))) <= DATEADD(DAY, 1, PB.end_date ))
AND		( PIP.patt_day = DATEPART(WEEKDAY, DATEADD(DAY,Numbers.number - 1, PB.start_date)) )
--AND		( pack.package_id = @package_id )
--AND		PACK.package_id IN ( SELECT package_id FROM outpost_package WHERE campaign_no = @campaign_no ) 
--ORDER BY 1, 2 ASC, 3 ASC
GO
