/****** Object:  StoredProcedure [dbo].[rs_p_booking_vs_target]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[rs_p_booking_vs_target]
GO
/****** Object:  StoredProcedure [dbo].[rs_p_booking_vs_target]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE proc  [dbo].[rs_p_booking_vs_target]
	@PERIOD_START		datetime,
	@PERIOD_END			datetime,
	@team_id			INT,
	@rep_id				INT,
	@branch_code		varchar(1),
	@country_code		varchar(1),
	@business_unit_id	int,
	@revision_group		int,
	@report_type		varchar(1) -- 'C' - cinema, 'O' - outpost/retail, '' - All
AS

CREATE TABLE #PERIODS (
		period_num			int			IDENTITY,
		period_no			int			NOT NULL,
		period_group		INT			NOT NULL,
		group_desc			varchar(30)	null,
		benchmark_start		datetime	null,
		benchmark_end		datetime	null,
)

-- Important to have the earlist first and the latest last
INSERT	#PERIODS(period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	period_no, 1, 'Current', period_start, sales_period
FROM	film_sales_period
WHERE	sales_period BETWEEN @PERIOD_START AND @PERIOD_END
ORDER BY period_start, sales_period

---- Important to have it ON to allow explicit identity to be inserted #PERIODS table
SET IDENTITY_INSERT #PERIODS ON

-- Insert prior year start/end dates (periods are different to current year)
INSERT	#PERIODS(period_num, period_no, period_group, group_desc, benchmark_start, benchmark_end)
SELECT	#PERIODS.period_num, sp.period_no, 2, 'Prior', sp.period_start, sp.sales_period
FROM	#PERIODS, film_sales_period sp
WHERE	#PERIODS.period_no = sp.period_no AND
	DATEPART ( yy , #PERIODS.benchmark_start)- 1 = DATEPART ( yy , sp.sales_period)

SELECT	p.period_num,
		period_month = DATEPART(MONTH, p.benchmark_end),
		prior_booking = TEMP1.prior_booking,
		current_booking = TEMP1.current_booking,
		current_target = TEMP2.current_target
FROM	#PERIODS p,
		(	SELECT	period_num = p.period_num,
					prior_booking = SUM(CASE WHEN booking_figures.booking_period BETWEEN p.benchmark_start AND p.benchmark_end AND p.period_group = 2 Then nett_amount ELSE 0 END ),
					current_booking = SUM(CASE WHEN booking_figures.booking_period BETWEEN p.benchmark_start AND p.benchmark_end AND p.period_group = 1 Then nett_amount ELSE 0 END )
			FROM	booking_figures,
					film_campaign,
					branch,
					#PERIODS p
			WHERE	( booking_figures.branch_code = @branch_code OR @branch_code = '')
			AND		( branch.country_code = @country_code OR @country_code = '')
			AND		( film_campaign.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
			AND		( booking_figures.revision_group = @revision_group OR @revision_group = 0 )
			AND		( booking_figures.rep_id = @rep_id OR @rep_id = 0 )
			AND		( @team_id = 0 OR EXISTS ( SELECT * FROM booking_figure_team_xref bx
												WHERE	bx.figure_id = booking_figures.figure_id
												AND		bx.team_id = @team_id))
			AND		booking_figures.campaign_no = film_campaign.campaign_no
			and		booking_figures.branch_code = branch.branch_code
			and		booking_figures.figure_type <> 'A'
			AND		( booking_figures.revision_group >= ( CASE @report_type When 'O' Then 50 Else 0 End )
			AND		  booking_figures.revision_group < ( CASE @report_type When 'C' Then 50 Else 1000 End ))
			and		(	booking_figures.booking_period  = p.benchmark_end )
			GROUP BY p.period_num
			) AS TEMP1,
		(	SELECT	period_num = p.period_num,
					prior_target = NULL, --SUM(CASE WHEN booking_target.sales_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_group = 2 Then target ELSE 0 END ),
					current_target = SUM(CASE WHEN booking_target.sales_period BETWEEN p.benchmark_start AND p.benchmark_end and p.period_group = 1 Then target ELSE 0 END )
			FROM	booking_target,
					branch,
					#PERIODS p
			WHERE		 booking_target.branch_code = branch.branch_code
			AND		( branch.country_code = @country_code OR @country_code = '')
			AND		( booking_target.business_unit_id = @business_unit_id OR @business_unit_id = 0 ) 
			AND		( ISNULL(booking_target.rep_id, 0) = @rep_id OR @rep_id = 0 )
			AND		( ISNULL(booking_target.team_id, 0) = @team_id OR @team_id = 0)
			AND		( ISNULL(booking_target.branch_code, '') = @branch_code OR @branch_code = '')
			AND		(( booking_target.revision_group = @revision_group) 
			OR		( booking_target.revision_group >= ( CASE @report_type When 'O' Then 50 Else 0 End )
			AND		  booking_target.revision_group < ( CASE @report_type When 'C' Then 50 Else 1000 End )))
			and		( booking_target.sales_period = p.benchmark_end )
			GROUP BY p.period_num
			) AS TEMP2
WHERE		p.period_num = TEMP1.period_num
AND			p.period_num = TEMP2.period_num
AND			p.period_group= 1
ORDER BY p.period_num

DROP TABLE #PERIODS
GO
