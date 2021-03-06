/****** Object:  StoredProcedure [dbo].[rs_p_proj_bill_ag_buying_analysis]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[rs_p_proj_bill_ag_buying_analysis]
GO
/****** Object:  StoredProcedure [dbo].[rs_p_proj_bill_ag_buying_analysis]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[rs_p_proj_bill_ag_buying_analysis]		@PERIOD_START			datetime,
                                            				@PERIOD_END				datetime,
															@business_unit_id		int,
															@branch_code			VARCHAR(1),
															@country_code           VARCHAR(1)
AS

CREATE TABLE #PERIODS (
		period_num			int			IDENTITY,
		period_no			int			not null,
		period_group		INT			NOT NULL,
		group_desc			varchar(30)	null,
		benchmark_start		datetime	null,
		benchmark_end		datetime	null,
)

CREATE TABLE #OUTPUT (
		ID					int			IDENTITY,
		finyear_end			DATETIME	NULL,
		benchmark_end		DATETIME	NULL,
		country_code		VARCHAR(1)	NOT NULL,
		branch_code			VARCHAR(1)	NOT NULL,
		branch_name			VARCHAR(50)	NULL,
		business_unit_id	INT			NOT NULL,
		business_unit_desc	VARCHAR(50)	NULL,
		media_product_id	INT			NOT NULL,
		media_product_desc	VARCHAR(50)	NULL,
		agency_deal			VARCHAR(1)	NULL,
		agency_id			INT			NULL,
		agency_name			VARCHAR(50)	NULL,
		agency_group_id		INT			NULL,
		agency_group_name	VARCHAR(50)	NULL,
		client_id			INT			NULL,
		client_name			VARCHAR(50)	NULL,
		client_group_id		INT			NULL,
		client_group_desc	VARCHAR(50)	NULL,
		buying_group_id		INT			NULL,
		buying_group_desc	VARCHAR(50)	NULL,
		BILLING				MONEY		NULL			DEFAULT 0.0,
		--PRIOR_YEAR			MONEY		NULL			DEFAULT 0.0,
		--CURRENT_YEAR		MONEY		NULL			DEFAULT 0.0,
		--VARIANCE_NUM		AS CURRENT_YEAR - PRIOR_YEAR,
		--VARIANCE_PCN		AS CASE PRIOR_YEAR When 0 Then 0 Else ( CURRENT_YEAR - PRIOR_YEAR ) / PRIOR_YEAR END
		)

-- Important to have the earlist first and the latest last
INSERT	#PERIODS(period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	period_no, 1, 'Current', benchmark_start, benchmark_end
FROM	accounting_period
WHERE	benchmark_end BETWEEN @PERIOD_START AND @PERIOD_END
--		( benchmark_start <= @PERIOD_START AND benchmark_end >= @PERIOD_END) OR
--		( benchmark_start > @PERIOD_START AND benchmark_end <= @PERIOD_END)
ORDER BY 4,5;

---- Important to have it ON to allow explicit identity to be inserted #PERIODS table
SET IDENTITY_INSERT #PERIODS ON

-- Insert prior year start/end dates (periods are different to current year)
INSERT	#PERIODS(period_num, period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	#PERIODS.period_num, ap.period_no, 2, 'Prior', ap.benchmark_start, ap.benchmark_end
FROM	#PERIODS, accounting_period ap
WHERE	#PERIODS.period_no = ap.period_no AND
	DATEPART ( yy , #PERIODS.benchmark_start)- 1 = DATEPART ( yy , ap.benchmark_start)
	
--INSERT	#PERIODS(period_num, period_no, period_group, group_desc, benchmark_start, benchmark_end)
--SELECT	100, 100, period_group, group_desc, MIN(benchmark_end), MAX(benchmark_end)
--FROM	#PERIODS
--GROUP BY period_group, group_desc

--INSERT	#PERIODS(period_num, period_no, period_group, group_desc, benchmark_start, benchmark_end)
--SELECT	1000, 1000, 1000, 'Total', MIN(benchmark_start), MAX(benchmark_end)
--FROM	#PERIODS
--WHERE	period_num = 100
--GROUP BY period_group

--SELECT * FROM #PERIODS

INSERT INTO #OUTPUT (
		benchmark_end,
		country_code,
		branch_code,
		branch_name,
		business_unit_id,
		business_unit_desc,
		media_product_id,
		media_product_desc,
		agency_deal,
		agency_id,
		agency_name,
		agency_group_id,
		agency_group_name,
		client_id,
		client_name,
		client_group_id,
		client_group_desc,
		buying_group_id,
		buying_group_desc,
		billing)
SELECT	x.benchmark_end,
		branch.country_code,
		CONVERT(VARCHAR(1),fc.branch_code),
		branch.branch_name,
		fc.business_unit_id,
		bu.business_unit_desc,
		cp.media_product_id,
		mp.media_product_desc,
		fc.agency_deal,
		fc.agency_id,
		agency.agency_name,
		ag.agency_group_id,
		ag.agency_group_name,
		fc.client_id,
		client.client_name,
		client.client_group_id,
		cg.client_group_desc,
		abg.buying_group_id,
		abg.buying_group_desc,
		CONVERT(MONEY,SUM(ISNULL(cs.charge_rate,0) * (convert(numeric(6,4),x.no_days)/7.0)))
FROM	campaign_spot cs,
		film_screening_date_xref x,
		campaign_package cp,
		film_campaign fc,
		agency,
		agency_groups ag,
		agency_buying_groups abg,
		client,
		client_group cg,
		business_unit bu,
		media_product mp,
		branch,
		#PERIODS p
WHERE	cs.billing_date = x.screening_date
and		cs.package_id = cp.package_id
and		cp.campaign_no = fc.campaign_no
and		fc.reporting_agency = agency.agency_id
and     agency.agency_group_id = ag.agency_group_id
and		ag.buying_group_id = abg.buying_group_id
AND		fc.client_id = client.client_id
AND		client.client_group_id = cg.client_group_id
AND		cp.media_product_id = mp.media_product_id
and		mp.system_use_only = 'N'
and		mp.media = 'Y'
AND		fc.business_unit_id = bu.business_unit_id
AND		fc.branch_code = branch.branch_code
and		bu.system_use_only = 'N'
AND		cs.spot_status != 'P'
AND		cs.billing_period = p.benchmark_end
AND		p.period_group IN (1,2)
AND		( fc.business_unit_id = @business_unit_id OR @business_unit_id = 0 )
AND		( fc.branch_code = @branch_code or @branch_code = '' ) 
AND		( branch.country_code = @country_code or @country_code = '' )
GROUP BY   x.benchmark_end,
		p.benchmark_end,
		fc.business_unit_id,
		cp.media_product_id,
		fc.agency_id,
		fc.client_id,
		client.client_group_id,
		ag.agency_group_id,
		abg.buying_group_id,
		mp.media_product_desc,
		bu.business_unit_desc,
		agency.agency_name,
		client.client_name,
		fc.agency_deal,
		ag.agency_group_name,
		cg.client_group_desc,
		abg.buying_group_desc,
		branch.country_code,
		fc.branch_code,
		branch.branch_name
		
SELECT	--o.benchmark_end,
		country_code,
		branch_code = CONVERT(VARCHAR(1),NULL),
		branch_name = CONVERT(VARCHAR(30),NULL),
		business_unit_id,
		business_unit_desc,
		media_product_id,
		media_product_desc,
		--agency_deal,
		--agency_id,
		--agency_name,
		--agency_group_id,
		--agency_group_name,
		--client_id,
		--client_name,
		--client_group_id,
		--client_group_desc,
		buying_group_id,
		buying_group_desc,
		PRIOR_YEAR = SUM(CASE WHEN o.benchmark_end BETWEEN p.benchmark_start and p.benchmark_end and p.period_group = 2 Then o.billing ELSE 0 END ),
		CURRENT_YEAR = SUM(CASE WHEN o.benchmark_end BETWEEN p.benchmark_start and p.benchmark_end and p.period_group = 1 Then o.billing ELSE 0 END)
FROM	#OUTPUT o,
		#PERIODS p
WHERE	o.benchmark_end = p.benchmark_end
GROUP BY --o.benchmark_end,
		country_code,
		--branch_code,
		--branch_name,
		business_unit_id,
		business_unit_desc,
		media_product_id,
		media_product_desc,
		--agency_deal,
		--agency_id,
		--agency_name,
		--agency_group_id,
		--agency_group_name,
		--client_id,
		--client_name,
		--client_group_id,
		--client_group_desc,
		buying_group_id,
		buying_group_desc
		
DROP TABLE #PERIODS
DROP TABLE #OUTPUT
GO
