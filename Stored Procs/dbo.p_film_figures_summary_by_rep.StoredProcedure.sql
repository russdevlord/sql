/****** Object:  StoredProcedure [dbo].[p_film_figures_summary_by_rep]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_figures_summary_by_rep]
GO
/****** Object:  StoredProcedure [dbo].[p_film_figures_summary_by_rep]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_film_figures_summary_by_rep] @branch_code		   char(2),
                                          @report_period_end	datetime
as

/*
 * Declare Procedure Variables
 */

declare @error          		integer,
        @rowcount					integer,
        @report_period_no		integer,
        @finyear_start			datetime,
        @report_period_status	char(1)

/*
 * Create Temporary Tables
 */

create table #summary_by_rep
(
	rep_id				integer				null,
	first_name			varchar(30)			null,
	last_name			varchar(30)			null,
	ytd_nett_amount			money				null,
	nett_amount			money				null,
	writebacks			money				null,
	new				integer				null
)

select @report_period_no = film_reporting_period.report_period_no,
       @finyear_start = financial_year.finyear_start,
       @report_period_status = film_reporting_period.status
  from film_reporting_period,
       financial_year
 where ( film_reporting_period.finyear_end = financial_year.finyear_end ) and  
       ( ( film_reporting_period.report_period_end = @report_period_end ) )

select @error = @@error
if ( @error !=0 )
begin
	return -1
end

/*
 * Select Financial Ytd Nett Amount
 */

insert into #summary_by_rep
	( rep_id, first_name, last_name, ytd_nett_amount, nett_amount, writebacks )
	select film_figures.rep_id,   
			sales_rep.first_name,   
			sales_rep.last_name,   
			sum(film_figures.nett_amount),
			0,
			0
	 from film_figures,   
			film_campaign,   
			sales_rep  
	where ( film_figures.campaign_no = film_campaign.campaign_no ) and  
			( film_figures.rep_id = sales_rep.rep_id ) and  
			( ( film_figures.release_period >= @finyear_start ) and  
			( film_figures.release_period < @report_period_end ) and  
			( film_figures.branch_code = @branch_code ) and
			( ( film_figures.figure_status = 'R' and
			film_campaign.campaign_status <> 'P' ) or
			( film_figures.figure_official = 'Y' ) ) )
	group by film_figures.rep_id,   
				sales_rep.first_name,   
				sales_rep.last_name

/*
 * Select Nett Amount
 */

insert into #summary_by_rep
	( rep_id, first_name, last_name, ytd_nett_amount, nett_amount, writebacks )
	select film_figures.rep_id,   
			sales_rep.first_name,   
			sales_rep.last_name,   
			0,
			sum(film_figures.nett_amount),
			0
	 from film_figures,   
			film_campaign,   
			sales_rep  
	where ( film_figures.campaign_no = film_campaign.campaign_no ) and  
			( film_figures.rep_id = sales_rep.rep_id ) and  
			( ( film_figures.release_period = @report_period_end ) and  
			( film_figures.branch_code = @branch_code ) and
			( film_figures.figure_type <> 'W' ) and
			( ( film_figures.figure_status = 'R' and
			film_campaign.campaign_status <> 'P' ) or
			( film_figures.figure_official = 'Y' ) ) )
	group by film_figures.rep_id,   
				sales_rep.first_name,   
				sales_rep.last_name

/*
 * Select Writebacks
 */

insert into #summary_by_rep
	( rep_id, first_name, last_name, ytd_nett_amount, nett_amount, writebacks )
	select film_figures.rep_id,   
			sales_rep.first_name,   
			sales_rep.last_name,   
			0,
			0,
			sum(film_figures.nett_amount)
	 from film_figures,   
			film_campaign,   
			sales_rep  
	where ( film_figures.campaign_no = film_campaign.campaign_no ) and  
			( film_figures.rep_id = sales_rep.rep_id ) and  
			( ( film_figures.release_period = @report_period_end ) and  
			( film_figures.branch_code = @branch_code ) and
			( film_figures.figure_type = 'W' ) )
	group by film_figures.rep_id,   
				sales_rep.first_name,   
				sales_rep.last_name

/*
 * Select Campaign Count
 */

insert into #summary_by_rep
	( rep_id, first_name, last_name, new)
	select film_figures.rep_id,   
			sales_rep.first_name,   
			sales_rep.last_name,   
			count(film_figures.figure_id)
	 from film_figures,   
			film_campaign,   
			sales_rep  
	where ( film_figures.campaign_no = film_campaign.campaign_no ) and  
			( film_figures.rep_id = sales_rep.rep_id ) and  
			( ( film_figures.release_period = @report_period_end ) and  
			( film_figures.branch_code = @branch_code ) and
			( film_campaign.campaign_type = 'N' ) and
			( ( film_figures.figure_status = 'R' and
			film_campaign.campaign_status <> 'P' ) or
			( film_figures.figure_official = 'Y' ) ) )
	group by film_figures.rep_id,   
				sales_rep.first_name,   
				sales_rep.last_name

/*
 * Return
 */

select @branch_code, 
		@report_period_no,
		@report_period_end,
		@report_period_status,
		rep_id,
		first_name,
		last_name,
		sum(ytd_nett_amount),
		sum(nett_amount),
		sum(writebacks),
		sum(nett_amount) + sum(writebacks),
		sum(ytd_nett_amount) + (sum(nett_amount) + sum(writebacks)),
		sum(new)
 from #summary_by_rep
group by rep_id,
			first_name,
			last_name

return 0
GO
