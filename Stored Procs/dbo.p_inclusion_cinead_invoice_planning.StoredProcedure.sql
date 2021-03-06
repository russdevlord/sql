/****** Object:  StoredProcedure [dbo].[p_inclusion_cinead_invoice_planning]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_cinead_invoice_planning]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_cinead_invoice_planning]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: 6/11/2014
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_inclusion_cinead_invoice_planning]
	@accounting_period datetime
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  --  drop table #missing_inclusions

	 create table #missing_inclusions(
	  campaign_no           int,
	  product_desc          varchar(100),
	  branch_code           char(1),
	  rep_id                int,
	  campaign_status       CHAR(1),
	  start_date            datetime,
	  end_date              datetime,
	  inclusion_status      CHAR(1),
	  inclusion_campaign_no int,
	  inclusion_type		int,
    inclusion_id    int,
	  number_of_plans int,
    billing_month_match int
	)

	  insert into #missing_inclusions
	  SELECT
		fc.campaign_no,
		fc.product_desc,
		fc.branch_code,
		fc.rep_id,
		fc.campaign_status,
		fc.start_date,
		fc.end_date,
		fc.inclusion_status,
		i.campaign_no as inclusion_campaign_no,
		i.inclusion_type,
    i.inclusion_id,
    (case when i.inclusion_type is not null and i.inclusion_type = 28 then 1 else 0 end) as number_of_plans,
    CASE when MONTH(MIN(iis.billing_period)) = MONTH(MIN(cs.billing_period)) THEN 1 ELSE 0 END AS billing_month_match
	--	count(inclusion_type) as number_of_plans
	  FROM film_campaign AS fc
	  LEFT JOIN inclusion AS i ON fc.campaign_no = i.campaign_no
    LEFT JOIN inclusion_spot iis on fc.campaign_no = iis.campaign_no AND i.inclusion_id = iis.inclusion_id
	  LEFT JOIN campaign_spot as cs on fc.campaign_no = cs.campaign_no
	  WHERE business_unit_id = 9
	  and fc.campaign_status <> 'X'
--	  and inclusion_type = 28
	  and (i.inclusion_type is null or i.inclusion_type = 28)
	  group by fc.campaign_no,
		fc.product_desc,
		fc.branch_code,
		fc.rep_id,
		fc.campaign_status,
		fc.start_date,
		fc.end_date,
		fc.inclusion_status,
		i.inclusion_type,
    i.inclusion_id,
		i.campaign_no

	select distinct a.campaign_no, a.product_desc, a.branch_code, a.rep_id, a.campaign_status, a.start_date, a.end_date,
	 a.message
	  
	from (SELECT distinct
		  mi.*,
		  iss.spot_id,
		  iss.spot_type,
		  iss.campaign_no AS spot_inclusion_campaign_no,
		  cs.screening_date,
		  fcsi.inclusion_id as payment_plan_inclusion_id,
		  fcsi.campaign_no as payment_plan_campaign_no,
		  fsdx.benchmark_end,
		  CASE WHEN mi.inclusion_campaign_no IS NULL THEN 'Missing Invoice Plan'     -- no inclusion
			   WHEN mi.number_of_plans > 1 THEN 'Campaign Has Multiple Invoice Plans'
			   WHEN mi.inclusion_campaign_no IS NOT NULL AND fcsi.campaign_no IS NOT NULL
														 AND iss.campaign_no IS NULL
														 AND fsdx.benchmark_end = @accounting_period THEN 'Missing Invoice Plan Spot' --inclusion + payment plan no spot for selected accounting period
			   WHEN mi.inclusion_campaign_no IS NOT NULL AND fcsi.campaign_no IS NULL
														 AND iss.campaign_no IS NULL
														 AND fsdx.benchmark_end = @accounting_period THEN 'Missing Invoice Plan Spot and Invoice Plan Details' -- inclusion no spot or payment plan
			   WHEN mi.inclusion_campaign_no IS NOT NULL AND fcsi.campaign_no IS NULL
														 AND iss.campaign_no IS NOT NULL
														 AND iss.spot_type = 'C'
														 AND fsdx.benchmark_end = @accounting_period
														 THEN 'Missing Invoice Plan Details and there is an Contra Spot'
			   WHEN mi.inclusion_campaign_no IS NOT NULL AND fcsi.campaign_no IS NOT NULL
														 AND iss.campaign_no IS NOT NULL
														 AND iss.spot_type = 'C'
														 AND fsdx.benchmark_end = @accounting_period
														 THEN 'Invoice Plan has a Contra Spot'
			   WHEN mi.inclusion_campaign_no IS NOT NULL AND fcsi.campaign_no IS NULL THEN 'Missing Invoice Plan Details' --inclusion + inclusion spot but no payment plan
			   WHEN mi.billing_month_match = 0 then 'Invoice Plan & Campaign Schedule Starting Billing Months Don''''t Match'
         ELSE ''
		  END as message
		  FROM #missing_inclusions AS mi
		  LEFT JOIN inclusion_spot AS iss ON mi.inclusion_campaign_no = iss.campaign_no and iss.inclusion_id = mi.inclusion_id
		  LEFT JOIN film_campaign_standalone_invoice  as fcsi on mi.campaign_no = fcsi.campaign_no
		  INNER JOIN campaign_spot as cs on mi.campaign_no = cs.campaign_no
		  INNER JOIN film_screening_date_xref as fsdx on cs.screening_date = fsdx.screening_date
		  ) as a
	where a.message <> ''
	and a.benchmark_end = @accounting_period

END
GO
