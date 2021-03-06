/****** Object:  StoredProcedure [dbo].[p_film_variance_to_target]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_variance_to_target]
GO
/****** Object:  StoredProcedure [dbo].[p_film_variance_to_target]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_film_variance_to_target]	@report_period_end	datetime,
												@country_code			char(1),
												@branch_code			char(2),
												@sortby					integer,
												@maxrows				integer,
												@term_reps				char(1),
												@group_level			char(1)
as

declare @error          		integer,
        @rowcount				integer,
        @rep_id					integer,
        @country_code_tmp		char(1),
        @country_name			char(30),
        @branch_code_tmp		char(2),
        @branch_name			char(50),
        @report_period_no		integer,
		@rep_periods			integer,
        @annual_target			money,
        @period_target			money,
        @prog_ytd_target		money,
        @prog_ytd_gross			money,
        @prog_ytd_nett			money

/*
 * Create Temporary Tables
 */
create table #summary (
		country_code		char(1)				null,
		branch_code			char(2)				null,
		rep_id				integer				null,
		first_name			varchar(30)			null,
		last_name			varchar(30)			null,
		status				char(1)				null,
		rep_type_desc		varchar(30)			null,
		start_date			datetime				null,
		branch_name			varchar(50)			null,
		annual_target		money					null,
		period_target		money					null,
		prog_ytd_target	money					null,
		prog_ytd_gross		money					null,
		prog_avg_gross		money					null,
		gross_target_var	money					null,
		prog_ytd_nett		money					null,
		prog_avg_nett		money					null,
		nett_target_var	money					null,
		area_id				integer				null,
		area_name			varchar(50)			null,
		team_id				integer				null,
		team_name			varchar(50)			null	
)

/*
 * Setup Country, Branch, Sales Peiod
 */
select @country_code_tmp = country_code
  from country
 where @country_code = country.country_code
select @country_code = @country_code_tmp

select @branch_code_tmp = branch_code
  from branch
 where @branch_code = branch.branch_code
select @branch_code = @branch_code_tmp

select @report_period_no = report_period_no
  from film_reporting_period
 where report_period_end = @report_period_end

/*
 * Initialise Temporary Table
 */
insert into #summary (
		country_code,
		branch_code,
		rep_id,
		first_name,
		last_name,
		status,
		rep_type_desc,
		start_date,
		branch_name,
		annual_target,
		period_target,
		prog_ytd_target,
		prog_ytd_gross,
		prog_avg_gross,
		gross_target_var,
		prog_ytd_nett,
		prog_avg_nett,
		nett_target_var,
		area_id,
		area_name,
		team_id,
		team_name )
select branch.country_code,
		branch.branch_code,
		sales_rep.rep_id,
		sales_rep.first_name,   
		sales_rep.last_name,   
		sales_rep.status,   
		rep_type.rep_type_desc,
		sales_rep.start_date,   
		branch.branch_name,
		0,
		0,
		0,
		0,
		0,
		-1,
		0,
		0,
		-1,
		rep_film_targets.area_id,
		film_sales_area.area_name,
		rep_film_targets.team_id,
		film_sales_team.team_name
FROM	sales_rep INNER JOIN
		film_rep_year ON sales_rep.rep_id = film_rep_year.rep_id INNER JOIN
		film_reporting_period ON film_rep_year.finyear_end = film_reporting_period.finyear_end INNER JOIN
		branch ON film_rep_year.branch_code = branch.branch_code INNER JOIN
		rep_film_targets LEFT OUTER JOIN
		film_sales_area ON rep_film_targets.area_id = film_sales_area.area_id LEFT OUTER JOIN
		film_sales_team ON rep_film_targets.team_id = film_sales_team.team_id ON film_rep_year.rep_id = rep_film_targets.rep_id AND 
		film_reporting_period.report_period_end = rep_film_targets.report_period AND branch.branch_code = rep_film_targets.branch_code CROSS JOIN
		rep_type
where	( film_reporting_period.report_period_end = @report_period_end ) and
		( sales_rep.status = 'A' or @term_reps = 'Y' ) and
		( branch.branch_code = @branch_code or @branch_code is null ) and
		( branch.country_code = @country_code or @country_code is null )
order by sales_rep.rep_id

/*
 * Declare Cursors
 */
 
 declare summary_csr cursor static for
  select rep_id
    from #summary
order by rep_id
     for read only

open summary_csr
fetch summary_csr into @rep_id
while (@@fetch_status = 0)
begin

   select @rep_periods = 0,
          @annual_target = 0,
          @period_target = 0

   select @annual_target = annual_target
     from film_rep_year,
          film_reporting_period
    where film_rep_year.finyear_end = film_reporting_period.finyear_end and
          film_rep_year.rep_id = @rep_id and
          film_reporting_period.report_period_end = @report_period_end

   update #summary
      set annual_target = @annual_target
    where #summary.rep_id = @rep_id and
          @annual_target is not null

   select @period_target = target_amount
     from rep_film_targets
    where rep_film_targets.report_period = @report_period_end and
          rep_film_targets.rep_id = @rep_id

   update #summary
      set period_target = @period_target
    where #summary.rep_id = @rep_id and
          @period_target is not null

   select @rep_periods = count(rep_film_targets.rep_id)
     from rep_film_targets,
          film_reporting_period frp_a,
          film_reporting_period frp_b
    where frp_a.report_period_end = @report_period_end and
          frp_b.finyear_end = frp_a.finyear_end and
          rep_film_targets.report_period = frp_b.report_period_end and
          rep_film_targets.rep_id = @rep_id and
          frp_b.report_period_end <= @report_period_end

   select @prog_ytd_target = sum(rep_film_targets.target_amount)
     from film_reporting_period frp_a,
          film_reporting_period frp_b,
          rep_film_targets,
          film_rep_year
    where frp_a.finyear_end = frp_b.finyear_end and
          frp_b.report_period_end = rep_film_targets.report_period and
          rep_film_targets.rep_id = film_rep_year.rep_id and
          film_rep_year.finyear_end = frp_a.finyear_end and
          film_rep_year.setup_complete = 'Y' and
          rep_film_targets.rep_id = @rep_id and
          frp_a.report_period_end = @report_period_end and
          frp_b.report_period_end <= @report_period_end

   update #summary
      set prog_ytd_target = @prog_ytd_target
    where #summary.rep_id = @rep_id and
          @prog_ytd_target is not null

   select @prog_ytd_gross = sum(film_figures.gross_amount)
     from film_reporting_period frp_a,
          film_reporting_period frp_b,
          film_figures
    where frp_a.finyear_end = frp_b.finyear_end and
          frp_b.report_period_end = film_figures.release_period and
          film_figures.figure_official = 'Y' and
          film_figures.rep_id = @rep_id and
          frp_a.report_period_end = @report_period_end and
          frp_b.report_period_end <= @report_period_end

   update #summary
      set prog_ytd_gross = @prog_ytd_gross
    where #summary.rep_id = @rep_id and
          @prog_ytd_gross is not null

   update #summary
      set prog_avg_gross = @prog_ytd_gross / @rep_periods
    where @prog_ytd_gross is not null and
          @rep_periods is not null and
          @rep_periods > 0 and
          #summary.rep_id = @rep_id

   update #summary
      set gross_target_var = (@prog_ytd_gross - @prog_ytd_target) / @prog_ytd_target
    where @prog_ytd_gross is not null and
          @prog_ytd_target is not null and
          @prog_ytd_target > 0 and
          #summary.rep_id = @rep_id

   select @prog_ytd_nett = sum(film_figures.nett_amount)
     from film_reporting_period frp_a,
          film_reporting_period frp_b,
          film_figures
    where frp_a.finyear_end = frp_b.finyear_end and
          frp_b.report_period_end = film_figures.release_period and
          film_figures.figure_official = 'Y' and
          film_figures.rep_id = @rep_id and
          frp_a.report_period_end = @report_period_end and
          frp_b.report_period_end <= @report_period_end

   update #summary
      set prog_ytd_nett = @prog_ytd_nett
    where #summary.rep_id = @rep_id and
          @prog_ytd_nett is not null

   update #summary
      set prog_avg_nett = @prog_ytd_nett / @rep_periods
    where @prog_ytd_nett is not null and
          @rep_periods is not null and
          @rep_periods > 0 and
          #summary.rep_id = @rep_id

   update #summary
      set nett_target_var = (@prog_ytd_nett - @prog_ytd_target) / @prog_ytd_target
    where @prog_ytd_nett is not null and
          @prog_ytd_target is not null and
          @prog_ytd_target > 0 and
          #summary.rep_id = @rep_id

   fetch summary_csr into @rep_id
end
close summary_csr
deallocate summary_csr
/*
 * Return
 */

select @report_period_end as report_period_end,
		@report_period_no as report_period_no,
		@sortby as sortby,
		@maxrows as maxrows,
		@group_level as group_level,
		country_code,
		branch_code,
		rep_id,
		first_name,
		last_name,
		status,
		rep_type_desc,
		start_date,
		branch_name,
		annual_target,
		period_target,
		prog_ytd_target,
		prog_ytd_gross,
		prog_avg_gross,
		gross_target_var,
		prog_ytd_nett,
		prog_avg_nett,
		nett_target_var,
		area_id,
		area_name,
		team_id,
		team_name
from #summary
         
return 0
GO
