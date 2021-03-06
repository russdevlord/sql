/****** Object:  StoredProcedure [dbo].[rs_p_kpi_rates]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[rs_p_kpi_rates]
GO
/****** Object:  StoredProcedure [dbo].[rs_p_kpi_rates]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

-- Generic proc for KPI Rates
CREATE proc  [dbo].[rs_p_kpi_rates]
	@PERIOD_START		datetime,
	@PERIOD_END			datetime,
	@country_code		varchar(1)
AS

CREATE TABLE #PERIODS (
	period_num			int			IDENTITY,
	period_no			int			NOT NULL,
	period_group		INT			NOT NULL,
	group_desc			varchar(30)	null,
	benchmark_start		datetime	null,
	benchmark_end		datetime	null,
)
CREATE INDEX benchmark_start_ind ON #PERIODS (benchmark_start)
CREATE INDEX benchmark_end_ind ON #PERIODS (benchmark_end)

CREATE TABLE #OUTPUT (
	group_no			int			not null,
	group_desc			varchar(30)	null,
	row_no	 			int			not null,
	row_desc			varchar(60)	null,
	charge_rate1		money		null DEFAULT 0.0,
	charge_rate2		money		null DEFAULT 0.0,
	charge_rate3		money		null DEFAULT 0.0,
	charge_rate4		money		null DEFAULT 0.0,
	charge_rate5		money		null DEFAULT 0.0,
	charge_rate6		money		null DEFAULT 0.0,
	charge_rate7		money		null DEFAULT 0.0,
	charge_rate8		money		null DEFAULT 0.0,
	charge_rate9		money		null DEFAULT 0.0,
	charge_rate10		money		null DEFAULT 0.0,
	charge_rate11		money		null DEFAULT 0.0,
	charge_rate12		money		null DEFAULT 0.0,
	spot_count1			INT			null DEFAULT 0,
	spot_count2			INT			null DEFAULT 0,
	spot_count3			INT			null DEFAULT 0,
	spot_count4			INT			null DEFAULT 0,
	spot_count5			INT			null DEFAULT 0,
	spot_count6			INT			null DEFAULT 0,
	spot_count7			INT			null DEFAULT 0,
	spot_count8			INT			null DEFAULT 0,
	spot_count9			INT			null DEFAULT 0,
	spot_count10		INT			null DEFAULT 0,
	spot_count11		INT			null DEFAULT 0,
	spot_count12		INT			null DEFAULT 0,
 	total_rate			money		null DEFAULT 0.0,--AS (charge_rate1 + charge_rate2 + charge_rate3 + charge_rate4 + charge_rate5 + charge_rate6 + charge_rate7 + charge_rate8 + charge_rate9 + charge_rate10 + charge_rate11 + charge_rate12),
 	total_spot			INT			null DEFAULT 0,--AS spot_count1 + spot_count2 + spot_count3 + spot_count4 + spot_count5 + spot_count6 + spot_count7 + spot_count8 + spot_count9 + spot_count10 + spot_count11 + spot_count12,
	avg_rate1			AS CASE When spot_count1 = 0 Then 0 Else charge_rate1/spot_count1 End,
	avg_rate2			AS CASE When spot_count2 = 0 Then 0 Else charge_rate2/spot_count2 End,
	avg_rate3			AS CASE When spot_count3 = 0 Then 0 Else charge_rate3/spot_count3 End,
	avg_rate4			AS CASE When spot_count4 = 0 Then 0 Else charge_rate4/spot_count4 End,
	avg_rate5			AS CASE When spot_count5 = 0 Then 0 Else charge_rate5/spot_count5 End, 
	avg_rate6			AS CASE When spot_count6 = 0 Then 0 Else charge_rate6/spot_count6 End, 
	avg_rate7			AS CASE When spot_count7 = 0 Then 0 Else charge_rate7/spot_count7 End, 
	avg_rate8			AS CASE When spot_count8 = 0 Then 0 Else charge_rate8/spot_count8 End, 
	avg_rate9			AS CASE When spot_count9 = 0 Then 0 Else charge_rate9/spot_count9 End, 
	avg_rate10			AS CASE When spot_count10 = 0 Then 0 Else charge_rate10/spot_count10 End, 
	avg_rate11			AS CASE When spot_count11 = 0 Then 0 Else charge_rate11/spot_count11 End, 
	avg_rate12			AS CASE When spot_count12 = 0 Then 0 Else charge_rate12/spot_count12 End, 
 	avg_rate			AS CASE total_spot When 0 Then 0 Else total_rate / total_spot End,
 	period01_end		datetime 	null,
	period02_end		datetime 	null,
	period03_end		datetime 	null,
	period04_end		datetime 	null,
	period05_end		datetime 	null,
	period06_end		datetime 	null,
	period07_end		datetime 	null,
	period08_end		datetime 	null,
	period09_end		datetime 	null,
	period10_end		datetime 	null,
	period11_end		datetime 	null,
	period12_end		datetime 	null,
	row_country_code	varchar(1)	null,
)

-- Important to have the earlist first and the latest last
INSERT	#PERIODS(period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	period_no, 1, 'Current', benchmark_start, benchmark_end
FROM	accounting_period
WHERE	benchmark_end BETWEEN @PERIOD_START AND @PERIOD_END
ORDER BY benchmark_start, benchmark_end

---- Important to have it ON to allow explicit identity to be inserted #PERIODS table
SET IDENTITY_INSERT #PERIODS ON

-- Insert prior year start/end dates (periods are different to current year)
INSERT	#PERIODS(period_num, period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	#PERIODS.period_num, ap.period_no, 2, 'Prior', ap.benchmark_start, ap.benchmark_end
FROM	#PERIODS, accounting_period ap
WHERE	#PERIODS.period_no = ap.period_no AND
	DATEPART ( yy , #PERIODS.benchmark_start)- 1 = DATEPART ( yy , ap.benchmark_start)
--SELECT * FROM 	#PERIODS

INSERT into #OUTPUT(group_no, row_no, row_desc,
		total_rate, total_spot,
		charge_rate1, charge_rate2, charge_rate3, charge_rate4, charge_rate5, charge_rate6, charge_rate7, charge_rate8, charge_rate9, charge_rate10, charge_rate11, charge_rate12,
		spot_count1, spot_count2, spot_count3, spot_count4, spot_count5, spot_count6, spot_count7, spot_count8, spot_count9, spot_count10, spot_count11, spot_count12,
		period01_end,period02_end,period03_end,period04_end,period05_end,period06_end,period07_end,period08_end,period09_end,period10_end,period11_end,period12_end,
		row_country_code)
SELECT	p.period_group *10, 10, CASE b.country_code When 'A' Then 'AU ' Else 'NZ ' End + CASE When complex_region_class.regional_indicator = 'Y' Then 'Regional' Else 'Metro' End + ' Paid Only',
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num >= 1 AND p.period_num <= 12 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num >= 1 AND p.period_num <= 12 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 1 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 2 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 3 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 4 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 5 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 6 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 7 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 8 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 9 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 10 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 11 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 12 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 1 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 2 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 3 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 4 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 5 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 6 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 7 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 8 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 9 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 10 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 11 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 12 Then 1 ELSE 0 END ),
		MIN(CASE WHEN p.period_num = 1 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 2 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 3 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 4 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 5 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 6 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 7 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 8 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 9 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 10 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 11 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 12 Then p.benchmark_end Else NULL END),
		b.country_code
from	campaign_spot cs,
		film_campaign fc,
		branch b,
		complex,
		complex_region_class,
		#PERIODS p
where	cs.campaign_no = fc.campaign_no
and		fc.branch_code = b.branch_code
and		( b.country_code = @country_code OR @country_code = '')
and		( cs.billing_date BETWEEN p.benchmark_start and p.benchmark_end )
and		cs.complex_id = complex.complex_id
and		complex_region_class.complex_region_class = complex.complex_region_class
and 	cs.spot_status != 'P'
and 	cs.spot_type = 'S'
and		p.period_group IN (1, 2)
GROUP BY P.period_group,
		b.country_code,
		complex_region_class.regional_indicator
		
INSERT into #OUTPUT(group_no, row_no, row_desc,
		total_rate, total_spot,
		charge_rate1, charge_rate2, charge_rate3, charge_rate4, charge_rate5, charge_rate6, charge_rate7, charge_rate8, charge_rate9, charge_rate10, charge_rate11, charge_rate12,
		spot_count1, spot_count2, spot_count3, spot_count4, spot_count5, spot_count6, spot_count7, spot_count8, spot_count9, spot_count10, spot_count11, spot_count12,
		period01_end,period02_end,period03_end,period04_end,period05_end,period06_end,period07_end,period08_end,period09_end,period10_end,period11_end,period12_end,
		row_country_code)
SELECT	p.period_group *10, 20, CASE b.country_code When 'A' Then 'AU ' Else 'NZ ' End + CASE When complex_region_class.regional_indicator = 'Y' Then 'Regional' Else 'Metro' End + ' All Spots',
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num >= 1 AND p.period_num <= 12 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num >= 1 AND p.period_num <= 12 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 1 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 2 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 3 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 4 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 5 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 6 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 7 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 8 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 9 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 10 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 11 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 12 Then cs.charge_rate ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 1 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 2 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 3 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 4 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 5 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 6 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 7 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 8 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 9 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 10 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 11 Then 1 ELSE 0 END ),
		SUM(CASE WHEN billing_date BETWEEN p.benchmark_start and p.benchmark_end and p.period_num = 12 Then 1 ELSE 0 END ),
		MIN(CASE WHEN p.period_num = 1 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 2 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 3 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 4 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 5 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 6 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 7 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 8 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 9 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 10 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 11 Then p.benchmark_end Else NULL END),
		MIN(CASE WHEN p.period_num = 12 Then p.benchmark_end Else NULL END),
		b.country_code
from	campaign_spot cs,
		film_campaign fc,
		branch b,
		complex,
		complex_region_class,
		#PERIODS p
where	cs.campaign_no = fc.campaign_no
and		fc.branch_code = b.branch_code
and		( b.country_code = @country_code OR @country_code = '')
and		( cs.billing_date BETWEEN p.benchmark_start and p.benchmark_end )
and		cs.complex_id = complex.complex_id
and		complex_region_class.complex_region_class = complex.complex_region_class
and 	cs.spot_status != 'P'
and 	cs.spot_type IN ('S','B','C','N')
and		p.period_group IN (1, 2)
GROUP BY P.period_group,
		b.country_code,
		complex_region_class.regional_indicator

SET FMTONLY OFF

-- Output Data
SELECT	group_no, 
		group_desc = CASE When group_no = 10 Then 'Current' Else 'Previous' End,
		row_no, 
		row_desc, 
 		avg_rate,
 		total_spot,
		avg_rate1,avg_rate2,avg_rate3,avg_rate4,avg_rate5,avg_rate6,avg_rate7,avg_rate8,avg_rate9,avg_rate10,avg_rate11,avg_rate12,
		spot_count1, spot_count2, spot_count3, spot_count4, spot_count5, spot_count6, spot_count7, spot_count8, spot_count9, spot_count10, spot_count11, spot_count12,
		period01_end, period02_end,period03_end,period04_end,period05_end,period06_end,period07_end,period08_end,period09_end,period10_end,period11_end,period12_end,
		row_country_code
FROM	#OUTPUT o
ORDER BY row_country_code, group_no, row_desc DESC, row_no

--DROP TABLE #OUTPUT
--DROP TABLE #PERIODS
GO
