/****** Object:  StoredProcedure [dbo].[p_bcc_xml_data_feed]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_bcc_xml_data_feed]
GO
/****** Object:  StoredProcedure [dbo].[p_bcc_xml_data_feed]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[p_bcc_xml_data_feed] 
									@campaign_no		INT,
									@mode				INT,
									@billing_period		DATETIME
AS

-- Modes
-- 1 - National
-- 2 - Market
-- 3 - Complex

DECLARE	@BILLING_START		datetime
DECLARE	@BILLING_END		datetime
SELECT	@BILLING_START	= '2010-01-01'
SELECT	@BILLING_END	= '2015-01-01'


if (@billing_period = '1900-01-01')
	begin
		SET @billing_period = NULL
	end


CREATE TABLE #work_data (
		mode								int							not null,
		row_no							INT							NOT NULL,
		row_desc						VARCHAR(50)		NULL,
		campaign_no				INT							NOT NULL,
		campaign_desc			VARCHAR(100)	NOT NULL,
		location_name				VARCHAR(255)	NULL,
		film_market_no			INT							NULL,
--		inclusion_type				INT							NULL,
--		liability_type					INT							NULL,
		inclusion_category		CHAR(1)				NULL,
		package_id					INT							NULL,
		duration							INT							NULL,
		prints								INT							NULL,
		spot_type						CHAR(1)				NULL,
		cost									money					NULL,
		units								INT							NULL,
		charge_rate					money					NULL,
		screening_date			DATETIME			NULL,
		billing_date					DATETIME			NULL
)
			
INSERT INTO #work_data( mode, row_no, row_desc, campaign_no, package_id, campaign_desc, location_name, film_market_no, spot_type, cost, units, screening_date, billing_date)
SELECT 		@mode, 1, 'Onscreen - Single Creative',
			campaign_spot.campaign_no,
			campaign_spot.package_id,
			film_campaign.product_desc,
			complex.complex_name,
			complex.film_market_no,
			campaign_spot.spot_type,
			SUM( CONVERT(MONEY,campaign_spot.charge_rate)),
			COUNT ( campaign_spot.spot_id),
			campaign_spot.screening_date,
			campaign_spot.billing_date
FROM 		campaign_spot,
			film_campaign,
			complex
WHERE 		campaign_spot.campaign_no = film_campaign.campaign_no
--and			((spot_status = 'A'
and			( spot_type <> 'M'
and			spot_type <> 'V')
--or			spot_status in ('X', 'R'))
--and			spot_type <> 'R' 
--and 		spot_type <> 'W'
--and			campaign_spot.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id )
--and			spot_status NOT IN ( 'U' , 'N')
AND			campaign_spot.complex_id = complex.complex_id
AND			campaign_spot.billing_date BETWEEN @BILLING_START AND @BILLING_END
and			( campaign_spot.campaign_no = @campaign_no OR @campaign_no = 0 )
and         campaign_spot.package_id in (select package_id from print_package group by package_id having count(print_id) = 1)
GROUP BY 	campaign_spot.campaign_no,
			campaign_spot.package_id,
			film_campaign.product_desc,
			complex.complex_name,
			complex.film_market_no,
			campaign_spot.spot_type,
			campaign_spot.screening_date,
			campaign_spot.billing_date
			order by complex.film_market_no, complex.complex_name,	campaign_spot.spot_type,		campaign_spot.billing_date
            
INSERT INTO #work_data( mode, row_no, row_desc, campaign_no, package_id, campaign_desc, location_name, film_market_no, spot_type, cost, units, screening_date, billing_date)
SELECT 		@mode, 1, 'Onscreen - Multiple Creative',
			campaign_spot.campaign_no,
			campaign_spot.package_id,
			film_campaign.product_desc,
			complex.complex_name,
			complex.film_market_no,
			campaign_spot.spot_type,
			SUM( CONVERT(MONEY,campaign_spot.charge_rate)),
			COUNT ( campaign_spot.spot_id),
			campaign_spot.screening_date,
			campaign_spot.billing_date
FROM 		campaign_spot,
			film_campaign,
			complex
WHERE 		campaign_spot.campaign_no = film_campaign.campaign_no
--and			((spot_status = 'A'
and			( spot_type <> 'M'
and			spot_type <> 'V')
--or			spot_status in ('X', 'R'))
--and			spot_type <> 'R' 
--and 		spot_type <> 'W'
--and			campaign_spot.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id )
--and			spot_status NOT IN ( 'U' , 'N')
AND			campaign_spot.complex_id = complex.complex_id
AND			campaign_spot.billing_date BETWEEN @BILLING_START AND @BILLING_END
and			( campaign_spot.campaign_no = @campaign_no OR @campaign_no = 0 )
and         campaign_spot.package_id in (select package_id from print_package group by package_id having count(print_id) > 1)
GROUP BY 	campaign_spot.campaign_no,
			campaign_spot.package_id,
			film_campaign.product_desc,
			complex.complex_name,
			complex.film_market_no,
			campaign_spot.spot_type,
			campaign_spot.screening_date,
			campaign_spot.billing_date          
order by complex.film_market_no, complex.complex_name,	campaign_spot.spot_type,		campaign_spot.billing_date
			  
			
INSERT INTO #work_data( mode, row_no, row_desc, campaign_no, package_id, campaign_desc, location_name, film_market_no, spot_type, cost, units, screening_date, billing_date)
SELECT 		@mode, 2, 'Digilite',
			cinelight_spot.campaign_no,
			cinelight_spot.package_id, 
			film_campaign.product_desc,
			complex.complex_name,
			complex.film_market_no,
			cinelight_spot.spot_type,
			SUM( CONVERT(MONEY,cinelight_spot.charge_rate)),
			COUNT( cinelight_spot.spot_id),
			cinelight_spot.screening_date,
			cinelight_spot.billing_date
FROM 		cinelight_spot,
			film_campaign,
			complex,
			cinelight
WHERE 		cinelight_spot.campaign_no = film_campaign.campaign_no
AND			cinelight.complex_id = complex.complex_id
--and			((spot_status = 'A'
and			( spot_type <> 'M'
and			spot_type <> 'V')
--or			spot_status in ('X', 'R'))
--and			spot_type <> 'R' 
--and 		spot_type <> 'W'
--and			cinelight_spot.campaign_no = dbo.f_spot_cl_redirect_backwards(cinelight_spot.campaign_no)
--and			spot_status NOT IN ( 'U' , 'N')
and			cinelight_spot.cinelight_id = cinelight.cinelight_id
AND			cinelight_spot.billing_date BETWEEN @BILLING_START AND @BILLING_END
and			( cinelight_spot.campaign_no = @campaign_no OR @campaign_no = 0 )
GROUP BY 	cinelight_spot.campaign_no,
			cinelight_spot.package_id,
			film_campaign.product_desc,
			complex.complex_name,
			complex.film_market_no,
			cinelight_spot.spot_type,
			cinelight_spot.screening_date,
			cinelight_spot.billing_date
order by complex.film_market_no, complex.complex_name,	cinelight_spot.spot_type,		cinelight_spot.billing_date

INSERT INTO #work_data(mode,  row_no, row_desc, campaign_no, campaign_desc, location_name, film_market_no, spot_type, cost, units, screening_date, billing_date)
SELECT 		@mode, 3, 'CineMarketing', 
			inclusion_spot.campaign_no,
			film_campaign.product_desc,
			complex.complex_name,
			complex.film_market_no,
			inclusion_spot.spot_type,
			SUM( CONVERT(MONEY, inclusion_spot.charge_rate)),
			COUNT( inclusion_spot.spot_id ),
			inclusion_spot.screening_date,
			inclusion_spot.billing_date
FROM 		inclusion_spot,
			film_campaign,
			complex,
			inclusion
WHERE		inclusion.campaign_no = film_campaign.campaign_no
AND			inclusion.inclusion_id = inclusion_spot.inclusion_id
AND			inclusion_spot.complex_id = complex.complex_id
AND			inclusion_spot.spot_status != 'P'
--and			((spot_status = 'A'
and			( spot_type <> 'M'
and			spot_type <> 'V')
--or			spot_status in ('X', 'R'))
--and			spot_type <> 'R' 
--and 		spot_type <> 'W'
--and			inclusion_spot.spot_id = dbo.f_spot_inc_redirect_backwards(inclusion_spot.spot_id)
--and			spot_status NOT IN ( 'U' , 'N')
AND 		inclusion.inclusion_type = 5
AND			inclusion_spot.billing_date BETWEEN @BILLING_START AND @BILLING_END
and			( inclusion_spot.campaign_no = @campaign_no OR @campaign_no = 0 )
GROUP BY 	inclusion_spot.campaign_no,
			film_campaign.product_desc,
			complex.complex_name,
			complex.film_market_no,
			inclusion_spot.spot_type,
			inclusion_spot.screening_date,
			inclusion_spot.billing_date
order by complex.film_market_no, complex.complex_name,	inclusion_spot.spot_type,		inclusion_spot.billing_date
			
			
INSERT INTO #work_data(mode, row_no, row_desc, campaign_no, package_id, campaign_desc, location_name, film_market_no, spot_type, cost, units, screening_date, billing_date)
SELECT 		@mode, 4, 'Retail', 
			outpost_spot.campaign_no,
			outpost_spot.package_id, 
			film_campaign.product_desc,
			outpost_venue.outpost_venue_name,
			outpost_venue.market_no,
			outpost_spot.spot_type,
			SUM( CONVERT(MONEY, outpost_spot.charge_rate)),
			COUNT( outpost_spot.spot_id ),
			outpost_spot.screening_date,
			outpost_spot.billing_date
FROM 		outpost_spot,
			film_campaign,
			outpost_panel,
			outpost_venue
WHERE		outpost_spot.campaign_no = film_campaign.campaign_no
and			outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id
AND			outpost_panel.outpost_venue_id = outpost_venue.outpost_venue_id
--AND			outpost_spot.spot_status != 'P'
--and			((spot_status = 'A'
and			( spot_type <> 'M'
and			spot_type <> 'V')
--or			spot_status in ('X', 'R'))
--and			spot_type <> 'R' 
--and 		spot_type <> 'W'
--and			outpost_spot.spot_id = dbo.f_spot_inc_redirect_backwards(outpost_spot.spot_id)
--and			spot_status NOT IN ( 'U' , 'N')
AND			outpost_spot.billing_date BETWEEN @BILLING_START AND @BILLING_END
and			( outpost_spot.campaign_no = @campaign_no OR @campaign_no = 0 )
GROUP BY 	outpost_spot.campaign_no,
			outpost_spot.package_id, 
			film_campaign.product_desc,
			outpost_venue.outpost_venue_name,
			outpost_venue.market_no,
			outpost_spot.spot_type,
			outpost_spot.screening_date,
			outpost_spot.billing_date
order by outpost_venue.market_no, outpost_venue.outpost_venue_name,	outpost_spot.spot_type,		outpost_spot.billing_date
			
			
INSERT INTO #work_data( mode, row_no, row_desc, campaign_no, campaign_desc,  spot_type, cost, units, screening_date, billing_date, film_market_no, location_name)			
SELECT		99, 5, 'Production', 
			inclusion.campaign_no,
			film_campaign.product_desc,
			'P', --inclusion_spot.spot_type,
--			inclusion_type.inclusion_type,
--			inclusion_type.inclusion_type_DESC,
--			inclusion_type_group.inclusion_type_group,
--			inclusion_type_group.inclusion_type_group_DESC,
--			inclusion_category.inclusion_category,
--			inclusion_category.inclusion_category_DESC,
			--SUM( CONVERT(MONEY, CASE inclusion_type_group.inclusion_type_group When 'C' Then inclusion_spot.charge_rate Else inclusion_spot.takeout_rate End)),
			SUM(inclusion.inclusion_qty * inclusion.inclusion_charge),
			1, --COUNT( inclusion_spot.spot_id ),
			CONVERT(DATETIME, NULL), --inclusion_spot.screening_date,
--			inclusion_spot.billing_date,
			inclusion.billing_period, 0, inclusion.inclusion_desc
FROM 		inclusion
				LEFT OUTER JOIN inclusion_spot ON inclusion.inclusion_id = inclusion_spot.inclusion_id,
			inclusion_type,
			inclusion_type_group,
			inclusion_category,
			film_campaign
WHERE		inclusion.campaign_no = film_campaign.campaign_no
--AND  		inclusion.include_revenue = 'Y' 
AND			inclusion_type.inclusion_type_group = 'P'
AND 		inclusion.inclusion_category = 'S'
--AND			inclusion_spot.spot_status != 'P'
--AND 		inclusion.inclusion_category in ( 'F', -- Main Block Takeout
--											  'D') -- Lead Block Takeout
AND			( inclusion.campaign_no = @campaign_no OR @campaign_no = 0 )
AND			inclusion.inclusion_type = inclusion_type.inclusion_type
AND			inclusion_type.inclusion_type_group = inclusion_type_group.inclusion_type_group
AND			inclusion.inclusion_category = inclusion_category.inclusion_category
GROUP BY 	inclusion.campaign_no,inclusion.inclusion_desc,		inclusion.billing_period, film_campaign.product_desc
			

INSERT INTO #work_data( mode, row_no, row_desc, campaign_no, campaign_desc,  spot_type, cost, units, screening_date, billing_date, film_market_no, location_name)			
SELECT		100, 6, 'Miscellaneous', 
			inclusion.campaign_no,
			film_campaign.product_desc,
			'P', --inclusion_spot.spot_type,
--			inclusion_type.inclusion_type,
--			inclusion_type.inclusion_type_DESC,
--			inclusion_type_group.inclusion_type_group,
--			inclusion_type_group.inclusion_type_group_DESC,
--			inclusion_category.inclusion_category,
--			inclusion_category.inclusion_category_DESC,
			--SUM( CONVERT(MONEY, CASE inclusion_type_group.inclusion_type_group When 'C' Then inclusion_spot.charge_rate Else inclusion_spot.takeout_rate End)),
			SUM(inclusion.inclusion_qty * inclusion.inclusion_charge),
			1, --COUNT( inclusion_spot.spot_id ),
			CONVERT(DATETIME, NULL), --inclusion_spot.screening_date,
--			inclusion_spot.billing_date,
			inclusion.billing_period, 
			0, 
			inclusion.inclusion_desc
FROM 		inclusion
				LEFT OUTER JOIN inclusion_spot ON inclusion.inclusion_id = inclusion_spot.inclusion_id,
			inclusion_type,
			inclusion_type_group,
			inclusion_category,
			film_campaign
WHERE		inclusion.campaign_no = film_campaign.campaign_no
AND			inclusion_type.inclusion_type_group in ('G', 'T', 'D')
AND 		inclusion.inclusion_category = 'S'
--AND  		inclusion.include_revenue = 'Y' 
--AND		inclusion_spot.spot_status != 'P'
--AND 		inclusion.inclusion_category in ( 'F', -- Main Block Takeout
--											  'D') -- Lead Block Takeout
AND			( inclusion.campaign_no = @campaign_no OR @campaign_no = 0 )
AND			inclusion.inclusion_type = inclusion_type.inclusion_type
AND			inclusion_type.inclusion_type_group = inclusion_type_group.inclusion_type_group
AND			inclusion.inclusion_category = inclusion_category.inclusion_category
GROUP BY 	inclusion.campaign_no,inclusion.inclusion_desc,		
			inclusion.billing_period, 
			film_campaign.product_desc

-- Update with prints and duration			
UPDATE	#work_data
SET			#work_data.prints = TEMPACK.prints,
			#work_data.duration = TEMPACK.duration	
FROM		campaign_package AS TEMPACK
WHERE		#work_data.row_no = 1 -- Onscreen
AND			#work_data.campaign_no = TEMPACK.campaign_no
AND			#work_data.package_id = TEMPACK.package_id

UPDATE	#work_data
SET			#work_data.prints = TEMPACK.prints,
			#work_data.duration = TEMPACK.duration	
FROM		cinelight_package AS TEMPACK
WHERE		#work_data.row_no = 2 -- Cinelight
AND			#work_data.campaign_no = TEMPACK.campaign_no
AND			#work_data.package_id = TEMPACK.package_id

UPDATE	#work_data
SET			#work_data.prints = TEMPACK.prints,
			#work_data.duration = TEMPACK.duration	
FROM		outpost_package AS TEMPACK
WHERE		#work_data.row_no = 4 -- Outpost
AND			#work_data.campaign_no = TEMPACK.campaign_no
AND			#work_data.package_id = TEMPACK.package_id

----DEBUG
/*
SELECT *
FROM #work_data
*/

SELECT	#work_data.row_no,
		version = '16.0',
		srcSys = 'VALMOR',
		dstSys = 'BMD',
		timeStamp = CONVERT(VARCHAR(19), GetDate(), 120),
		medcode =	CASE #work_data.mode 
									When 1 Then  'National' 
									When 2 Then 'VAL' + film_market.film_market_code
									When 3 then location_name
									When 99 then 'National Production'
									When 100 then location_name --'Miscellaneous'
									Else 'Unknown -Error'
								End,
		schCode = #work_data.campaign_desc,
		cliCode = CONVERT(VARCHAR(6), #work_data.campaign_no),
		ccyCode = 'AUD',
		dayFlags = '0000100',
-- 		spotTypeCode = CASE @mode When 3 Then (CASE When #work_data.spot_type IN ( 'B','C','N','W') Then 'B' Else #work_data.spot_type End) ELSE '' End,
 		spotTypeCode = CASE When #work_data.spot_type IN ( 'B','C','N','W') Then 'B' Else null End,
 		bunCode = #work_data.row_desc,
 		calcBookingFlag = CASE @mode When 3 Then 'SPOT' Else 'PACKGE' End,
		wcDate = CONVERT(VARCHAR(19), DATEADD(dd, -1 * datepart(dw,#work_data.billing_date) + 1, #work_data.billing_date), 112),
--		Placement = CASE @mode When 1 Then '' When 2 Then ISNULL('VAL' + film_market.film_market_code, 'Production Cost')		
--		Else ISNULL(ISNULL( complex.complex_name, outpost_venue.outpost_venue_name), 'Production Cost') End,
		Placement = CONVERT(VARCHAR(50), NULL),
		rate = CONVERT(DECIMAL(10,2), CASE @mode When 3 Then SUM(#work_data.cost)/SUM(#work_data.units) ELSE SUM(#work_data.cost) End),
		spots = CASE @mode When 3 Then SUM(#work_data.units) Else 1 End,
		xid = 159 - 1 + ROW_NUMBER() OVER (ORDER BY #work_data.campaign_no),
		CalcLoadingFlag = CASE @mode When 3 Then 'SPOT' Else 'PACKGE' End,
		LoadingAmount = CONVERT(MONEY, SUM(#work_data.cost)),
		lineComment = CASE #work_data.mode
										When 99 Then max(location_name)
										When 100 Then max(location_name)
										When 1 Then dbo.Concatenate( DISTINCT film_market.film_market_desc + ' ' +	 convert(varchar(3), Temp.units) + ' screening week(s) @ ' + convert(varchar(8), CONVERT(DECIMAL(6,2), ( Temp.cost / Temp.units))) + ' = ' + convert(varchar(8), CONVERT(INT, Temp.cost)))
										When 2 Then dbo.Concatenate( DISTINCT film_market.film_market_desc + ' ' +	 convert(varchar(3), Temp.units) + ' screening week(s) @ ' + convert(varchar(8), CONVERT(DECIMAL(6,2), ( Temp.cost / Temp.units))) + ' = ' + convert(varchar(8), CONVERT(INT, Temp.cost)))
										When 3 Then MAX(film_market.film_market_desc) Else '' End,
		size1 = CONVERT(DECIMAL(6,3), MIN(#work_data.duration)),
		size2 = 1.0--,#work_data.mode
FROM	#work_data
		LEFT OUTER JOIN film_market ON #work_data.film_market_no = film_market.film_market_no,
		( SELECT	row_no AS row_no,
					campaign_no AS campaign_no,
					film_market_no AS film_market_no,
					spot_type AS spot_type,
					billing_date AS billing_date,
					SUM(cost) AS cost,
					sum(units) AS units
			FROM	#work_data  WD
			GROUP BY row_no,
					campaign_no,
					spot_type,
					film_market_no,
					billing_date) AS Temp
WHERE	#work_data.row_no = Temp.row_no
AND		#work_data.campaign_no = Temp.campaign_no
AND		#work_data.film_market_no = Temp.film_market_no
AND		#work_data.spot_type = Temp.spot_type
AND		#work_data.billing_date = Temp.billing_date
AND		( #work_data.campaign_no = @campaign_no OR @campaign_no = 0)
AND		( #work_data.billing_date = @billing_period OR #work_data.billing_date = DATEADD (dd, 3, @billing_period ) OR @billing_period IS NULL )
GROUP BY #work_data.row_no,
	#work_data.row_desc,
	#work_data.campaign_no,
	#work_data.campaign_desc,
	#work_data.mode,
	film_market.film_market_no,
	film_market.film_market_code,
	CASE #work_data.mode 
		When 1 Then  'National' 
		When 2 Then 'VAL' + film_market.film_market_code
		When 3 then #work_data.location_name
		When 99 then 'National Production'
		When 100 then #work_data.location_name
		Else 'Unknown -Error'
	End,
	CASE @mode 
		When 1 Then '' 
		When 2 Then ISNULL('VAL' + film_market.film_market_code, 'Production Cost')		
		Else ISNULL(#work_data.location_name, 'Production Cost') End,
	CASE @mode 
		When 1 Then 'National' 
		When 2 Then ISNULL( 'VAL' + film_market.film_market_code, 'Production Cost')		
		Else ISNULL(ISNULL( 'VAL' + film_market.film_market_code, #work_data.location_name), 'Production Cost') End,
	CASE @mode 
		When 1 Then 0
		Else ISNULL(film_market.film_market_no, 1000) End,	
	CASE @mode 
		When 1 Then ''
		When 2 then ''
		Else ISNULL(#work_data.location_name, '') 
		End,	
	CASE @mode 
		When 3 Then (CASE When #work_data.spot_type IN ( 'B','C','N','W') Then 'B' 
		Else #work_data.spot_type End) ELSE '' End,
	#work_data.billing_date,
	CASE 
		When #work_data.spot_type IN ( 'B','C','N','W') Then 'B' 
		Else null End
ORDER BY 	
	CASE @mode 
		When 1 Then (CASE When #work_data.row_no = 5 Then 1000 When #work_data.row_no = 6 Then 1001 Else 0 End)
		When 2 then (CASE When #work_data.row_no = 5 Then 1000 When #work_data.row_no = 6 Then 1001 Else 0 End)
		When 3 Then ISNULL(film_market.film_market_no, 1000) End,
	CASE @mode 
		When 1 Then film_market.film_market_no
		When 2 Then film_market.film_market_no
		Else '' End,
	CASE #work_data.mode 
		When 1 Then 'National' 
		When 2 Then 'VAL' + film_market.film_market_code
		--When 3 then #work_data.location_name
		When 99 then 'National Production'
		When 100 then  film_market.film_market_code --'Miscellaneous'
		Else 'Unknown -Error' End,
		#work_data.billing_date,
		#work_data.row_no
		
DROP TABLE #work_data
GO
