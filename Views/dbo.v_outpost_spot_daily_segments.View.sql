/****** Object:  View [dbo].[v_outpost_spot_daily_segments]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_outpost_spot_daily_segments]
GO
/****** Object:  View [dbo].[v_outpost_spot_daily_segments]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_outpost_spot_daily_segments] ( spot_id, screening_date, package_id, start_date, end_date, patt_day)
AS 
SELECT	SPOT.spot_id,
		SPOT.screening_date,
		pack.package_id ,
		--CONVERT(DATETIME, DATEADD(DAY, Numbers.number - 1, pack.start_date)) AS pack_start_date,   
		--CONVERT(DATETIME, DATEADD(DAY, Numbers.number - 1, pack.start_date) + CONVERT(TIME, DATEADD(SECOND, -1, pack.start_date))) AS pack_end_date,
		--CONVERT(DATETIME, ( DATEADD(DAY, N1.number - 1, pack.start_date)) + CONVERT(TIME, PIP.start_date)) AS start_date,
		--CONVERT(DATETIME, ( DATEADD(DAY, N1.number - 1, pack.start_date)) + CONVERT(TIME, PIP.end_date)) AS end_date,
		CONVERT(DATETIME, dateadd(DAY, N2.number - 1, SPOT.screening_date)+ CONVERT(TIME, PIP.start_date)) AS start_date,
		CONVERT(DATETIME, dateadd(DAY, N2.number - 1, SPOT.screening_date)+ CONVERT(TIME, PIP.END_date)) AS end_date,
		PIP.patt_day AS patt_day 
FROM	outpost_package as pack 
			INNER JOIN outpost_package_burst AS PB ON pack.package_id = PB.package_id  
			INNER JOIN outpost_package_intra_pattern AS PIP ON pack.package_id = PIP.package_id
			INNER JOIN outpost_spot AS SPOT ON pack.package_id = SPOT.package_id,
		--Numbers AS N1,
		Numbers AS N2
WHERE	N2.number BETWEEN 1 AND 7
AND		( PB.start_date >= DATEADD(DAY, 0, SPOT.screening_date) AND CONVERT(DATETIME, PB.end_date + CONVERT(TIME, '23:59:59.000')) < DATEADD(DAY, 7, SPOT.screening_date) 
OR		PB.start_date < DATEADD(DAY, 7, SPOT.screening_date) AND CONVERT(DATETIME, PB.end_date + CONVERT(TIME, '23:59:59.000')) >= DATEADD(DAY, 7, SPOT.screening_date )
OR		PB.start_date < DATEADD(DAY, 0, SPOT.screening_date) AND CONVERT(DATETIME, PB.end_date + CONVERT(TIME, '23:59:59.000')) >= DATEADD(DAY, 0, SPOT.screening_date))
and		PIP.patt_day =  N2.number
AND CONVERT(DATETIME, ( DATEADD(DAY, N2.number - 1, SPOT.screening_date)) + CONVERT(TIME, PIP.start_date)) >= DATEADD(DAY, 0, SPOT.screening_date)
AND CONVERT(DATETIME, ( DATEADD(DAY, N2.number - 1, SPOT.screening_date)) + CONVERT(TIME, PIP.end_date)) < DATEADD(DAY, 7, SPOT.screening_date) 
--AND		( pack.package_id = @package_id )
--AND		PACK.package_id IN ( SELECT package_id FROM outpost_package WHERE campaign_no = @campaign_no ) 
--ORDER BY 1, 2 ASC, 3 ASC
GO
