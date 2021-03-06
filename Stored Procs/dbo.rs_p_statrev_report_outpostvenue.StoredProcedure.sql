/****** Object:  StoredProcedure [dbo].[rs_p_statrev_report_outpostvenue]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[rs_p_statrev_report_outpostvenue]
GO
/****** Object:  StoredProcedure [dbo].[rs_p_statrev_report_outpostvenue]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE procedure [dbo].[rs_p_statrev_report_outpostvenue] 
									@report_date				datetime,
									@PERIOD_START				datetime,
									@PERIOD_END					datetime,
									@outpost_venue_group_id		INT
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
		outpost_venue_id		INT			NULL,
		outpost_venue_group_id	INT			NULL,
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
		outpost_panel_id		INT			NULL,
		outpost_venue_id		INT			NULL,
		outpost_venue_group_id	INT			NULL,
		outpost_venue_group_name	VARCHAR(50) NULL,
		revenue_group			INT			NULL,
		revenue_group_desc		VARCHAR(50) NULL,
		media_product_id		INT			NULL,
		media_product_desc		VARCHAR(30)	NULL,
		revenue_source			CHAR(1)		NULL,
		revenue_source_desc		VARCHAR(30)	NULL,
		inclusion_type			INT			NULL,
		inclusion_type_desc		VARCHAR(30) NULL,
		inclusion_category		VARCHAR(1)	NULL,
		inclusion_category_desc VARCHAR(30) NULL,
		liability_type			INT			NULL,
		liability_type_desc		VARCHAR(30)	NULL,
		liability_category_id	INT			NULL,
		liability_category_desc	VARCHAR(30)	NULL,
		business_unit_id		INT			NULL,
		branch_code				CHAR(2)		NULL,
		cost					money		NULL,
		units					INT			NULL,
		charge_rate				money		NULL,
		period_num				INT			NOT NULL,
		period_group			INT			NOT NULL
)

CREATE TABLE #branch(
		branch_code			char(2)		NOT NULL,
		branch_name			varchar(50) NOT NULL,
		sort_order			tinyint		NOT NULL
		)
INSERT	#branch(branch_code, branch_name, sort_order)
SELECT	branch_code, branch_name, sort_order
FROM	branch

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

INSERT INTO #work_data( row_no, row_desc, outpost_venue_id, outpost_venue_group_id,
			business_unit_id, branch_code, cost, units,
			period_num, period_group)
SELECT 		4, 'Retail/Oupost Spots', 
			outpost_panel.outpost_venue_id,
			outpost_venue_group.outpost_venue_group_id,
			film_campaign.business_unit_id,
			film_campaign.branch_code,		
			( no_days / 7) * SUM( CASE When outpost_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end Then CONVERT(MONEY, statrev_spot_rates.avg_rate) Else 0 End),
			SUM(CASE When outpost_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end Then 1 Else 0 End),
			p.period_num, p.period_group
FROM 		outpost_spot,
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			statrev_spot_rates,
			outpost_screening_date_xref,
			outpost_venue,
			outpost_venue_group,
			film_campaign,
			#PERIODS p
WHERE 		outpost_spot.campaign_no = film_campaign.campaign_no
AND 		outpost_spot.spot_status != 'P'
and 		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id
and 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id
and 		outpost_player.player_name = outpost_player_xref.player_name 
and			outpost_spot.screening_date = outpost_screening_date_xref.screening_date
and 		outpost_player.media_product_id = 9
and			statrev_spot_rates.campaign_no = outpost_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id)
--and			statrev_spot_rates.spot_id = outpost_spot.spot_id
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and			revenue_group = 50 
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
and			p.period_num <= 12
AND			outpost_panel.outpost_venue_id = outpost_venue.outpost_venue_id
AND			outpost_venue.outpost_venue_group_id = outpost_venue_group.outpost_venue_group_id
and			outpost_venue_group.outpost_venue_group_id = @outpost_venue_group_id
GROUP BY 	outpost_panel.outpost_venue_id,
			outpost_venue_group.outpost_venue_group_id,
			outpost_screening_date_xref.no_days,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			p.period_num, p.period_group
			
INSERT INTO #work_data( row_no, row_desc, outpost_venue_id, outpost_venue_group_id,
			business_unit_id, branch_code, cost, units,
			period_num, period_group)
SELECT 		5, 'Retail Wall Spots',
			inclusion_spot.outpost_venue_id,
			outpost_venue_group.outpost_venue_group_id,
			film_campaign.business_unit_id,
			film_campaign.branch_code,		
			( no_days / 7) * SUM( CASE When inclusion_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end Then CONVERT(MONEY, statrev_spot_rates.avg_rate) Else 0 End),
			SUM(CASE When inclusion_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end Then 1 Else 0 End),
			p.period_num, p.period_group
FROM 		inclusion_spot,
			inclusion,
            outpost_screening_date_xref,
			statrev_spot_rates,
			outpost_venue,
			outpost_venue_group,
			film_campaign,
			#PERIODS p
WHERE 		inclusion_spot.campaign_no = film_campaign.campaign_no
and         outpost_screening_date_xref.screening_date = inclusion_spot.op_screening_date
and         outpost_screening_date_xref.screening_date = inclusion_spot.screening_date
AND  		statrev_spot_rates.spot_id =  dbo.f_spot_inc_redirect_backwards(inclusion_spot.spot_id)
and			statrev_spot_rates.campaign_no = inclusion_spot.campaign_no
AND			inclusion_spot.spot_status != 'P'
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X','R'))
and			spot_type <> 'R' 
and 		spot_type <> 'W'
AND 		inclusion.inclusion_type = 18
and			revenue_group = 51		
and			inclusion.inclusion_id = inclusion_spot.inclusion_id
and			p.period_num <= 12
AND			inclusion_spot.outpost_venue_id = outpost_venue.outpost_venue_id
AND			outpost_venue.outpost_venue_group_id = outpost_venue_group.outpost_venue_group_id
and			outpost_venue_group.outpost_venue_group_id = @outpost_venue_group_id
GROUP BY 	inclusion_spot.outpost_venue_id,
			outpost_venue_group.outpost_venue_group_id,
			outpost_screening_date_xref.no_days,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			p.period_num, p.period_group
			
INSERT INTO #work_data( row_no, row_desc, outpost_venue_id, outpost_venue_group_id,
			business_unit_id, branch_code, cost, units,
			period_num, period_group)
SELECT 		10, 'Retail Billing Credits', 
			outpost_panel.outpost_venue_id,
			outpost_venue_group.outpost_venue_group_id,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			SUM( CASE When outpost_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end Then CONVERT(MONEY, outpost_spot_liability.spot_amount) Else 0 End),
			1,
			p.period_num, p.period_group
FROM 		outpost_spot,
			outpost_spot_liability,
			outpost_panel,
			--outpost_player_xref,
			--outpost_player,
			outpost_venue,
			outpost_venue_group,
			film_campaign,
			#PERIODS p
WHERE 		outpost_spot.campaign_no = film_campaign.campaign_no
AND 		outpost_spot.spot_status != 'P'
AND			outpost_spot.spot_id = outpost_spot_liability.spot_id
AND			outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id
--AND 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id
--AND 		outpost_player.player_name = outpost_player_xref.player_name
--AND		outpost_player.media_product_id = 9
and			p.period_num <= 12
AND			outpost_panel.outpost_venue_id = outpost_venue.outpost_venue_id
AND			outpost_venue.outpost_venue_group_id = outpost_venue_group.outpost_venue_group_id
and			outpost_venue_group.outpost_venue_group_id = @outpost_venue_group_id
GROUP BY 	outpost_panel.outpost_venue_id,
			outpost_venue_group.outpost_venue_group_id,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			p.period_num, p.period_group

INSERT INTO #work_data( row_no, row_desc, outpost_venue_id, outpost_venue_group_id,
			business_unit_id, branch_code, cost, units,
			period_num, period_group)
SELECT 		11, 'Retail Wall Billing Credits',
			outpost_panel.outpost_venue_id,
			outpost_venue_group.outpost_venue_group_id,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			SUM( CASE When outpost_spot.screening_date BETWEEN p.benchmark_start AND p.benchmark_end Then CONVERT(MONEY, outpost_spot_liability.spot_amount) Else 0 End),
			1,
			p.period_num, p.period_group
FROM 		outpost_spot,
			outpost_spot_liability,
			outpost_panel,
			outpost_venue,
			outpost_venue_group,
			film_campaign,
			#PERIODS p
WHERE 		outpost_spot.campaign_no = film_campaign.campaign_no
AND 		outpost_spot.spot_status != 'P'
AND			outpost_spot.spot_id = outpost_spot_liability.spot_id
AND			outpost_spot_liability.liability_type = 156
and			p.period_num <= 12
AND			outpost_panel.outpost_venue_id = outpost_venue.outpost_venue_id
AND			outpost_venue.outpost_venue_group_id = outpost_venue_group.outpost_venue_group_id
and			outpost_venue_group.outpost_venue_group_id = @outpost_venue_group_id
GROUP BY 	outpost_panel.outpost_venue_id,
			outpost_venue_group.outpost_venue_group_id,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			p.period_num, p.period_group

INSERT INTO #work_data( row_no, row_desc, outpost_venue_id, outpost_venue_group_id,
			business_unit_id, branch_code, cost, units,
			period_num, period_group)
SELECT 		12, 'Film, DMG, Showcaes, Cinelight Revenue Proxy Spots',
			inclusion_spot.outpost_venue_id,
			outpost_venue_group.outpost_venue_group_id,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			SUM( CASE When inclusion.revenue_period BETWEEN p.benchmark_start AND p.benchmark_end Then CONVERT(MONEY, inclusion_spot.charge_rate) Else 0 End),
			SUM( CASE When inclusion.revenue_period BETWEEN p.benchmark_start AND p.benchmark_end Then 1 Else 0 End),
			p.period_num, p.period_group
FROM 		inclusion_spot,
			inclusion,
			outpost_venue,
			outpost_venue_group,
			film_campaign,
			#PERIODS p
WHERE		inclusion.inclusion_id = inclusion_spot.inclusion_id
AND			inclusion_spot.spot_status != 'P'
AND 		inclusion.inclusion_type IN( 11, 12, 13, 14)
and			p.period_num <= 12
AND			inclusion_spot.outpost_venue_id = outpost_venue.outpost_venue_id
AND			outpost_venue.outpost_venue_group_id = outpost_venue_group.outpost_venue_group_id
and			outpost_venue_group.outpost_venue_group_id = @outpost_venue_group_id
GROUP BY 	inclusion_spot.outpost_venue_id,
			outpost_venue_group.outpost_venue_group_id,
			film_campaign.business_unit_id,
			film_campaign.branch_code,
			p.period_num, p.period_group

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
			#branch b
WHERE		#work_data.period_group = 1
AND			#work_data.branch_code = b.branch_code
GROUP BY	b.sort_order, b.branch_name,
			period_num, period_group


-- Result set
SET FMTONLY OFF
		
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
				
--DROP TABLE #PERIODS
--DROP TABLE #work_data
--DROP TABLE #work_total
--DROP TABLE #branch
GO
