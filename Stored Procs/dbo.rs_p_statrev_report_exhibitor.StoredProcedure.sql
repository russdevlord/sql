/****** Object:  StoredProcedure [dbo].[rs_p_statrev_report_exhibitor]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[rs_p_statrev_report_exhibitor]
GO
/****** Object:  StoredProcedure [dbo].[rs_p_statrev_report_exhibitor]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[rs_p_statrev_report_exhibitor] 
									@report_date		datetime,
									@PERIOD_START		datetime,
									@PERIOD_END			datetime,
									@exhibitor_id		INT
AS

CREATE TABLE #PERIODS (
		period_num			int			IDENTITY,
		period_no			int			not null,
		period_group		INT			NOT NULL,
		group_desc			varchar(30)	null,
		benchmark_start		datetime	null,
		benchmark_end		datetime	null,
)

CREATE TABLE #work_data (
		row_no					INT			NOT NULL,
		row_desc				VARCHAR(50) NULL,
		exhibitor_id			INT			NULL,
		complex_id				INT			NULL,
		inclusion_type			INT			NULL,
		liability_type			INT			NULL,
		business_unit_id		INT			NULL,
		branch_code				CHAR(2)		NULL,
		cost					money		NULL,
		units					INT			NULL,
		charge_rate				money		NULL,
		period_num				INT			NOT NULL,
		period_group			INT			NOT NULL
)
			
CREATE TABLE #work_total (
		group_no				INT			NOT NULL,
		group_desc				VARCHAR(50) NULL,
		row_no					INT			NOT NULL,
		row_desc				VARCHAR(50) NULL,
		complex_id				INT			NULL,
		complex_name			VARCHAR(50) NULL,
		exhibitor_id			INT			NULL,
		exhibitor_name			VARCHAR(50) NULL,
		inclusion_type			INT			NULL,
		inclusion_type_desc		VARCHAR(30) NULL,
		liability_type			INT			NULL,
		liability_type_desc		VARCHAR(30)	NULL,
		business_unit_id		INT			NULL,
		branch_code				CHAR(2)		NULL,
		cost					money		NULL,
		units					INT			NULL,
		period_num				INT			NOT NULL,
		period_group			INT			NOT NULL
)

-- Important to have the earlist first and the latest last
INSERT #PERIODS(period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT period_no, 1, 'Current', benchmark_start, benchmark_end
FROM	accounting_period
WHERE	( benchmark_start <= @PERIOD_START AND benchmark_end >= @PERIOD_START) OR
	( benchmark_start >  @PERIOD_START AND benchmark_end <= @PERIOD_END)
ORDER BY 4,5;

---- Important to have it ON to allow explicit identity to be inserted #PERIODS table
SET IDENTITY_INSERT #PERIODS ON

-- Insert prior year start/end dates (periods are different to current year)
INSERT #PERIODS(period_num, period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT #PERIODS.period_num, ap.period_no, 2, 'Prior', ap.benchmark_start, ap.benchmark_end
FROM	#PERIODS, accounting_period ap
WHERE	#PERIODS.period_no = ap.period_no AND
	DATEPART ( yy , #PERIODS.benchmark_start)- 1 = DATEPART ( yy , ap.benchmark_start)
	
--INSERT INTO #PERIODS(period_num, period_no, period_group, group_desc, benchmark_start, benchmark_end)
--SELECT	100, 100, 1, 'Current', MIN(benchmark_start), MAX(benchmark_end)
--FROM	#PERIODS
--WHERE	period_group = 1

--INSERT INTO #PERIODS(period_num, period_no, period_group, group_desc, benchmark_start, benchmark_end)
--SELECT	100, 100, 2, 'Prior', MIN(benchmark_start), MAX(benchmark_end)
--FROM	#PERIODS
--WHERE	period_group = 2

--SELECT @MIN_CURRENT = MIN(benchmark_start) FROM #PERIODS WHERE period_group = 1
--SELECT @MAX_CURRENT = MAX(benchmark_end) FROM #PERIODS WHERE period_group = 1
--SELECT @MIN_PRIOR = MIN(benchmark_start) FROM #PERIODS WHERE period_group = 2
--SELECT @MAX_PRIOR = MAX(benchmark_end) FROM #PERIODS WHERE period_group = 2

INSERT INTO #work_data( row_no, row_desc, exhibitor_id,
			business_unit_id, branch_code, cost, units,
			period_num, period_group)
SELECT 		1, 'Campaign Spots',
			complex.exhibitor_id,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			SUM( CASE When campaign_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end Then CONVERT(MONEY,statrev_spot_rates.avg_rate) Else 0 End),
			SUM( CASE When campaign_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end Then 1 Else 0 End),
			p.period_num, p.period_group
FROM 		campaign_spot,
			statrev_spot_rates,
			film_campaign,
			complex,
			#PERIODS p
WHERE 		campaign_spot.campaign_no = film_campaign.campaign_no
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
AND			campaign_spot.complex_id = complex.complex_id
and			complex.exhibitor_id = @exhibitor_id
AND			campaign_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end
AND			p.period_num <= 12
GROUP BY 	complex.exhibitor_id,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			p.period_num, p.period_group
			
INSERT INTO #work_data( row_no, row_desc, exhibitor_id,
			business_unit_id, branch_code, cost, units,
			p.period_num, p.period_group)
SELECT 		2, 'Cinelight Spots',
			complex.exhibitor_id,
			film_campaign.business_unit_id,
			film_campaign.branch_code,		
			SUM( CASE When cinelight_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end Then CONVERT(MONEY,statrev_spot_rates.avg_rate) Else 0 End),
			SUM(CASE When cinelight_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end Then 1 Else 0 End),
			p.period_num, p.period_group
FROM 		cinelight_spot,
			statrev_spot_rates,
			film_campaign,
			complex,
			#PERIODS p,
			cinelight
WHERE 		cinelight_spot.campaign_no = film_campaign.campaign_no
AND			cinelight.complex_id = complex.complex_id
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and			statrev_spot_rates.campaign_no = dbo.f_spot_cl_redirect_backwards(cinelight_spot.campaign_no)
and			statrev_spot_rates.spot_id = cinelight_spot.spot_id
and			cinelight_spot.cinelight_id = cinelight.cinelight_id
AND			cinelight_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end
AND			p.period_num <= 12
and			complex.exhibitor_id = @exhibitor_id
GROUP BY 	complex.exhibitor_id,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			p.period_num, p.period_group

INSERT INTO #work_data( row_no, row_desc, exhibitor_id,
			inclusion_type,
			business_unit_id, branch_code, cost, units,
			p.period_num, p.period_group)
SELECT 		3, 'Cinemarketing Spots', 
			complex.exhibitor_id,
			inclusion.inclusion_type,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			SUM( CASE When inclusion_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end Then CONVERT(MONEY,statrev_spot_rates.avg_rate) Else 0 End),
			SUM(CASE When inclusion_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end Then 1 Else 0 End),
			p.period_num, p.period_group
FROM 		inclusion_spot,
			statrev_spot_rates,
			film_campaign,
			complex,
			#PERIODS p,
			inclusion
WHERE		inclusion.campaign_no = film_campaign.campaign_no
AND			inclusion.inclusion_id = inclusion_spot.inclusion_id
AND			inclusion_spot.complex_id = complex.complex_id
AND			inclusion_spot.spot_status != 'P'
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
and			spot_type <> 'R' 
and 		spot_type <> 'W'
AND 		inclusion.inclusion_type = 5
and			statrev_spot_rates.campaign_no = inclusion_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_inc_redirect_backwards(inclusion_spot.spot_id)
AND			inclusion_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end
AND			p.period_num <= 12
and			complex.exhibitor_id = @exhibitor_id
GROUP BY 	complex.exhibitor_id,
			inclusion.inclusion_type,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			p.period_num, p.period_group
			
INSERT INTO #work_data( row_no, row_desc, exhibitor_id,
			inclusion_type,
			business_unit_id, branch_code, cost, units,
			p.period_num, p.period_group)
SELECT 		6, 'TakeOuts',
			complex.exhibitor_id,
			inclusion.inclusion_type,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			SUM( CASE When inclusion_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end Then CONVERT(MONEY, inclusion_spot.takeout_rate * - 1) Else 0 End),
			SUM(CASE When inclusion_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end Then 1 Else 0 End),
			p.period_num, p.period_group
FROM 		inclusion_spot,
			inclusion,
			complex,
			#PERIODS p,
			film_campaign
WHERE		inclusion.campaign_no = film_campaign.campaign_no
AND  		inclusion.inclusion_id = inclusion_spot.inclusion_id
AND			inclusion_spot.complex_id = complex.complex_id
AND  		inclusion.include_revenue = 'Y' 
AND			inclusion_spot.spot_status != 'P'
AND 		inclusion.inclusion_category in ('F','D')
AND			inclusion_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end
and			p.period_num <= 12
and			complex.exhibitor_id = @exhibitor_id
GROUP BY 	complex.exhibitor_id,
			inclusion.inclusion_type,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			p.period_num, p.period_group

INSERT INTO #work_data( row_no, row_desc, exhibitor_id,
			liability_type,
			business_unit_id, branch_code, cost, units,
			p.period_num, p.period_group)
SELECT 		7, 'Film, DMG, Showcase Billing Credits', 
			complex.exhibitor_id,
			spot_liability.liability_type,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			SUM( CASE When spot_liability.creation_period BETWEEN p.benchmark_start AND p.benchmark_end Then CONVERT(MONEY, spot_liability.spot_amount) Else 0 End),
			1,
			p.period_num, p.period_group
FROM 		campaign_spot,
			spot_liability,
			complex,
			#PERIODS p,
			film_campaign 
WHERE		campaign_spot.campaign_no = film_campaign.campaign_no
AND			campaign_spot.complex_id = complex.complex_id
AND 		campaign_spot.spot_status != 'P'
AND 		spot_liability.liability_type in (7,8)
AND 		campaign_spot.spot_id = spot_liability.spot_id
AND			campaign_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end
and			p.period_num <= 12
and			complex.exhibitor_id = @exhibitor_id
GROUP BY	complex.exhibitor_id,
			spot_liability.liability_type,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			p.period_num, p.period_group

INSERT INTO #work_data( row_no, row_desc, exhibitor_id,
			liability_type,
			business_unit_id, branch_code, cost, units,
			p.period_num, p.period_group)
SELECT 		8, 'Cinelight Billing Credits', 
			complex.exhibitor_id,
			cinelight_spot_liability.liability_type,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			SUM( CASE When cinelight_spot_liability.creation_period BETWEEN p.benchmark_start AND p.benchmark_end Then CONVERT(MONEY, cinelight_spot_liability.spot_amount) Else 0 End),
			1,
			p.period_num, p.period_group
FROM 		cinelight_spot,
			cinelight_spot_liability,
			complex,
			#PERIODS p,
			film_campaign,
			cinelight
WHERE		cinelight_spot.campaign_no = film_campaign.campaign_no
AND			cinelight.complex_id = complex.complex_id
AND 		cinelight_spot.spot_status != 'P'
AND 		cinelight_spot_liability.liability_type in (13)
AND 		cinelight_spot.spot_id  = cinelight_spot_liability.spot_id
AND			cinelight_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end
and			p.period_num <= 12
and			cinelight_spot.cinelight_id = cinelight.cinelight_id
and			complex.exhibitor_id = @exhibitor_id
GROUP BY	complex.exhibitor_id,
			cinelight_spot_liability.liability_type,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			p.period_num, p.period_group

INSERT INTO #work_data( row_no, row_desc, exhibitor_id,
			liability_type,
			business_unit_id, branch_code, cost, units,
			p.period_num, p.period_group)
SELECT		9, 'Cinemarketing Billing Credits', 
			complex.exhibitor_id,
			inclusion_spot_liability.liability_type,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			SUM( CASE When inclusion_spot_liability.creation_period BETWEEN p.benchmark_start AND p.benchmark_end Then CONVERT(MONEY, inclusion_spot_liability.spot_amount) Else 0 End),
			1,
			p.period_num, p.period_group
FROM 		inclusion_spot,
			inclusion_spot_liability,
			complex,
			#PERIODS p,
			film_campaign 
WHERE		inclusion_spot.campaign_no = film_campaign.campaign_no
AND			inclusion_spot.complex_id = complex.complex_id
AND 		inclusion_spot.spot_status != 'P'
AND 		inclusion_spot_liability.liability_type in (152,161)
AND 		inclusion_spot.spot_id  = inclusion_spot_liability.spot_id
AND			inclusion_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end
and			p.period_num <= 12
and			complex.exhibitor_id = @exhibitor_id
GROUP BY	complex.exhibitor_id,
			inclusion_spot_liability.liability_type,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			p.period_num, p.period_group

--SELECT * FROM #work_data
--ORDER BY period_num, period_group

INSERT INTO #work_total ( group_no, group_desc, row_no, row_desc,
			cost,
			units,
			period_num, period_group )
SELECT		10, 'Revenue', 10, 'Actual',
			SUM(cost),
			SUM(units),
			period_num, period_group
FROM		#work_data
WHERE		#work_data.period_group = 1
GROUP BY	period_num, period_group

INSERT INTO #work_total ( group_no, group_desc, row_no, row_desc,
			cost,
			units,
			period_num, period_group )
SELECT		20, 'Prior', 10, 'Actual',
			SUM(cost),
			SUM(units),
			period_num, period_group
FROM		#work_data
WHERE		#work_data.period_group = 2
GROUP BY	period_num, period_group

INSERT INTO #work_total ( group_no, group_desc, row_no, row_desc,
			cost,
			units,
			period_num, period_group )
SELECT		20, 'Prior', 11, '(+/-)',
			SUM(W1.cost - W2.cost),
			SUM(W1.units - W2.units),
			W2.period_num, W2.period_group
FROM		#work_total w1, #work_total w2
WHERE		w1.group_no = 10 AND w2.group_no = 20
AND			W1.period_num = W2.period_num
GROUP BY	W2.period_num, W2.period_group

INSERT INTO #work_total ( group_no, group_desc, row_no, row_desc,
			cost,
			units,
			period_num, period_group )
SELECT		20, 'Prior', 12, '(+/-) %',
			SUM(W1.cost - W2.cost)/SUM(W1.cost),
			SUM(W1.units - W2.units)/SUM(W1.units),
			W2.period_num, W2.period_group
FROM		#work_total w1, #work_total w2
WHERE		w1.group_no = 10 AND w2.group_no = 20 AND w2.row_no = 10
AND			W1.period_num = W2.period_num
and			w1.row_no = w2.row_no
GROUP BY	W2.period_num, W2.period_group

INSERT INTO #work_total ( group_no, group_desc, row_no, row_desc,
			cost,
			units,
			period_num, period_group )
SELECT		30, 'Business Unit',
			#work_data.business_unit_id, b.business_unit_desc,
			SUM(cost),
			SUM(units),
			period_num, period_group
FROM		#work_data,
			business_unit b
WHERE		#work_data.period_group = 1
AND			#work_data.business_unit_id = b.business_unit_id
GROUP BY	#work_data.business_unit_id, b.business_unit_desc,
			period_num, period_group
			
INSERT INTO #work_total ( group_no, group_desc, row_no, row_desc,
			cost,
			units,
			period_num, period_group )
SELECT		40, 'State',
			b.sort_order, b.branch_name,
			SUM(cost),
			SUM(units),
			period_num, period_group
FROM		#work_data,
			branch b
WHERE		#work_data.period_group = 1
AND			#work_data.branch_code = b.branch_code
GROUP BY	b.sort_order, b.branch_name,
			period_num, period_group

-- Result set
SET FMTONLY OFF

--SELECT * FROM #work_total
		
SELECT		#work_total.group_no, 
			#work_total.group_desc,
			#work_total.row_no,
			#work_total.row_desc,
			revenue1 = SUM(CASE WHEN p.period_num = 1 Then COST ELSE 0 END),
			revenue2 = SUM(CASE WHEN p.period_num = 2 Then COST ELSE 0 END),
			revenue3 = SUM(CASE WHEN p.period_num = 3 Then COST ELSE 0 END),
			revenue4 = SUM(CASE WHEN p.period_num = 4 Then COST ELSE 0 END),
			revenue5 = SUM(CASE WHEN p.period_num = 5 Then COST ELSE 0 END),
			revenue6 = SUM(CASE WHEN p.period_num = 6 Then COST ELSE 0 END),
			revenue7 = SUM(CASE WHEN p.period_num = 7 Then COST ELSE 0 END),
			revenue8 = SUM(CASE WHEN p.period_num = 8 Then COST ELSE 0 END),
			revenue9 = SUM(CASE WHEN p.period_num = 9 Then COST ELSE 0 END),
			revenue10 = SUM(CASE WHEN p.period_num = 10 Then COST ELSE 0 END),
			revenue11 = SUM(CASE WHEN p.period_num = 11 Then COST ELSE 0 END),
			revenue12 = SUM(CASE WHEN p.period_num = 12 Then COST ELSE 0 END),
			period1 = MIN(CASE WHEN p.period_num = 1 Then P.benchmark_end ELSE NULL End),
			period2 = MIN(CASE WHEN p.period_num = 2 Then P.benchmark_end ELSE NULL End),
			period3 = MIN(CASE WHEN p.period_num = 3 Then P.benchmark_end ELSE NULL End),
			period4 = MIN(CASE WHEN p.period_num = 4 Then P.benchmark_end ELSE NULL End),
			period5 = MIN(CASE WHEN p.period_num = 5 Then P.benchmark_end ELSE NULL End),
			period6 = MIN(CASE WHEN p.period_num = 6 Then P.benchmark_end ELSE NULL End),
			period7 = MIN(CASE WHEN p.period_num = 7 Then P.benchmark_end ELSE NULL End),
			period8 = MIN(CASE WHEN p.period_num = 8 Then P.benchmark_end ELSE NULL End),
			period9 = MIN(CASE WHEN p.period_num = 9 Then P.benchmark_end ELSE NULL End),
			period10 = MIN(CASE WHEN p.period_num = 10 Then P.benchmark_end ELSE NULL End),
			period11 = MIN(CASE WHEN p.period_num = 11 Then P.benchmark_end ELSE NULL End),
			period12 = MIN(CASE WHEN p.period_num = 12 Then P.benchmark_end ELSE NULL End)
FROM		#work_total,
			#PERIODS P
WHERE		#work_total.period_num = P.period_num
AND			#work_total.period_group = P.period_group
GROUP BY	#work_total.group_no, 
			#work_total.group_desc,
			#work_total.row_no,
			#work_total.row_desc
				
DROP TABLE #PERIODS
DROP TABLE #work_data
DROP TABLE #work_total
GO
