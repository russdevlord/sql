/****** Object:  StoredProcedure [dbo].[p_figures_summary_by_rep_sel]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_figures_summary_by_rep_sel]
GO
/****** Object:  StoredProcedure [dbo].[p_figures_summary_by_rep_sel]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_figures_summary_by_rep_sel] @branch_code		char(2),
                                         @sales_period_end	datetime
as

/*
 * Declare Procedure Variables
 */

declare @error          	integer,
        @rowcount		integer,
        @sales_period_no	integer,
        @finyear_start		datetime,
        @sales_period_status	char(1)

/*
 * Create Temporary Tables
 */

create table #summary_by_rep
(
	rep_id			integer				null,
	business_group		integer				null,
	first_name		varchar(30)			null,
	last_name		varchar(30)			null,
	ytd_nett_amount	money					null,
	nett_amount		money				null,
	writebacks		money				null,
	new			integer				null,
	renewals		integer				null,
	extensions		integer				null,
	supercedes		integer				null
)

select @sales_period_no = sales_period.sales_period_no,
       @finyear_start = financial_year.finyear_start,
       @sales_period_status = sales_period.status
  from sales_period,
       financial_year
 where ( sales_period.finyear_end = financial_year.finyear_end ) and  
       ( ( sales_period.sales_period_end = @sales_period_end ) )

select @error = @@error
if ( @error !=0 )
begin
	return -1
end

/*
 * Select Financial Ytd Nett Amount
 */

insert into #summary_by_rep
	( rep_id, business_group, first_name, last_name, ytd_nett_amount, nett_amount, writebacks )
	select slide_figures.rep_id,   
			slide_figures.business_group,
			sales_rep.first_name,   
			sales_rep.last_name,   
			sum(slide_figures.nett_amount),
			0,
			0
	 from slide_figures,   
			slide_campaign,   
			sales_rep  
	where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
			( slide_figures.rep_id = sales_rep.rep_id ) and  
			( ( slide_figures.release_period >= @finyear_start ) and  
			( slide_figures.release_period < @sales_period_end ) and  
			( slide_figures.branch_code = @branch_code ) and
			( ( slide_figures.figure_status = 'R' and
			slide_campaign.campaign_release = 'Y' and
			slide_figures.figure_hold = 'N' ) or
			( slide_figures.figure_official = 'Y' ) ) )
	group by slide_figures.rep_id,   
				slide_figures.business_group,
				sales_rep.first_name,   
				sales_rep.last_name

/*
 * Select Nett Amount
 */

insert into #summary_by_rep
	( rep_id, business_group, first_name, last_name, ytd_nett_amount, nett_amount, writebacks )
	select slide_figures.rep_id,   
			slide_figures.business_group,
			sales_rep.first_name,   
			sales_rep.last_name,   
			0,
			sum(slide_figures.nett_amount),
			0
	 from slide_figures,   
			slide_campaign,   
			sales_rep  
	where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
			( slide_figures.rep_id = sales_rep.rep_id ) and  
			( ( slide_figures.release_period = @sales_period_end ) and  
			( slide_figures.branch_code = @branch_code ) and
			( slide_figures.figure_type <> 'W' ) and
			( ( slide_figures.figure_status = 'R' and
			slide_campaign.campaign_release = 'Y' and
			slide_figures.figure_hold = 'N' ) or
			( slide_figures.figure_official = 'Y' ) ) )
	group by slide_figures.rep_id,   
				slide_figures.business_group,
				sales_rep.first_name,   
				sales_rep.last_name

/*
 * Select Writebacks
 */

insert into #summary_by_rep
	( rep_id, business_group, first_name, last_name, ytd_nett_amount, nett_amount, writebacks )
	select slide_figures.rep_id,   
			slide_figures.business_group,
			sales_rep.first_name,   
			sales_rep.last_name,   
			0,
			0,
			sum(slide_figures.nett_amount)
	 from slide_figures,   
			slide_campaign,   
			sales_rep  
	where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
			( slide_figures.rep_id = sales_rep.rep_id ) and  
			( ( slide_figures.release_period = @sales_period_end ) and  
			( slide_figures.branch_code = @branch_code ) and
			( slide_figures.figure_type = 'W' ) )
	group by slide_figures.rep_id,   
				slide_figures.business_group,
				sales_rep.first_name,   
				sales_rep.last_name

/*
 * Select New Campaign Count
 */

insert into #summary_by_rep
	( rep_id, business_group, first_name, last_name, new, renewals, extensions, supercedes )
	select slide_figures.rep_id,   
			slide_figures.business_group,
			sales_rep.first_name,   
			sales_rep.last_name,   
			count(slide_figures.figure_id),
			0,
			0,
			0
	 from slide_figures,   
			slide_campaign,   
			sales_rep  
	where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
			( slide_figures.rep_id = sales_rep.rep_id ) and  
			( ( slide_figures.release_period = @sales_period_end ) and  
			( slide_figures.branch_code = @branch_code ) and
			( slide_campaign.campaign_type = 'N' ) and
			( ( slide_figures.figure_status = 'R' and
			slide_campaign.campaign_release = 'Y' and
			slide_figures.figure_hold = 'N' ) or
			( slide_figures.figure_official = 'Y' ) ) )
	group by slide_figures.rep_id,   
				slide_figures.business_group,
				sales_rep.first_name,   
				sales_rep.last_name

/*
 * Select Renewal Campaign Count
 */

insert into #summary_by_rep
	( rep_id, business_group, first_name, last_name, new, renewals, extensions, supercedes )
	select slide_figures.rep_id,   
			slide_figures.business_group,
			sales_rep.first_name,   
			sales_rep.last_name,   
			0,
			count(slide_figures.figure_id),
			0,
			0
	 from slide_figures,   
			slide_campaign,   
			sales_rep  
	where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
			( slide_figures.rep_id = sales_rep.rep_id ) and  
			( ( slide_figures.release_period = @sales_period_end ) and  
			( slide_figures.branch_code = @branch_code ) and
			( slide_campaign.campaign_type = 'R' ) and
			( ( slide_figures.figure_status = 'R' and
			slide_campaign.campaign_release = 'Y' and
			slide_figures.figure_hold = 'N' ) or
			( slide_figures.figure_official = 'Y' ) ) )
	group by slide_figures.rep_id,   
				slide_figures.business_group,
				sales_rep.first_name,   
				sales_rep.last_name

/*
 * Select Extension Campaign Count
 */

insert into #summary_by_rep
	( rep_id, business_group, first_name, last_name, new, renewals, extensions, supercedes )
	select slide_figures.rep_id,   
			slide_figures.business_group,
			sales_rep.first_name,   
			sales_rep.last_name,   
			0,
			0,
			count(slide_figures.figure_id),
			0
	 from slide_figures,   
			slide_campaign,   
			sales_rep  
	where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
			( slide_figures.rep_id = sales_rep.rep_id ) and  
			( ( slide_figures.release_period = @sales_period_end ) and  
			( slide_figures.branch_code = @branch_code ) and
			( slide_campaign.campaign_type = 'E' ) and
			( ( slide_figures.figure_status = 'R' and
			slide_campaign.campaign_release = 'Y' and
			slide_figures.figure_hold = 'N' ) or
			( slide_figures.figure_official = 'Y' ) ) )
	group by slide_figures.rep_id,   
				slide_figures.business_group,
				sales_rep.first_name,   
				sales_rep.last_name

/*
 * Select Supercede Campaign Count
 */

insert into #summary_by_rep
	( rep_id, business_group, first_name, last_name, new, renewals, extensions, supercedes )
	select slide_figures.rep_id,   
			slide_figures.business_group,
			sales_rep.first_name,   
			sales_rep.last_name,   
			0,
			0,
			0,
			count(slide_figures.figure_id)
	 from slide_figures,   
			slide_campaign,   
			sales_rep  
	where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
			( slide_figures.rep_id = sales_rep.rep_id ) and  
			( ( slide_figures.release_period = @sales_period_end ) and  
			( slide_figures.branch_code = @branch_code ) and
			( slide_campaign.campaign_type = 'S' ) and
			( ( slide_figures.figure_status = 'R' and
			slide_campaign.campaign_release = 'Y' and
			slide_figures.figure_hold = 'N' ) or
			( slide_figures.figure_official = 'Y' ) ) )
	group by slide_figures.rep_id,   
				slide_figures.business_group,
				sales_rep.first_name,   
				sales_rep.last_name

/*
 * Return
 */

select @branch_code, 
		@sales_period_no,
		@sales_period_end,
		@sales_period_status,
		rep_id,
		business_group,
		first_name,
		last_name,
		sum(ytd_nett_amount),
		sum(nett_amount),
		sum(writebacks),
		sum(nett_amount) + sum(writebacks),
		sum(ytd_nett_amount) + (sum(nett_amount) + sum(writebacks)),
		sum(new),
		sum(renewals),
		sum(extensions),
		sum(supercedes)
 from #summary_by_rep
group by rep_id,
	business_group,
	first_name,
	last_name
GO
