/****** Object:  StoredProcedure [dbo].[p_figures_group_summary_sel]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_figures_group_summary_sel]
GO
/****** Object:  StoredProcedure [dbo].[p_figures_group_summary_sel]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_figures_group_summary_sel] @country_code			char(1),
					 @branch_code			char(2),
					 @sales_period_end	datetime,
					 @business_group		integer
as

/*
 * Declare Procedure Variables
 */

declare @error          			integer,
        @rowcount						integer,

        @sales_period_no			integer,
        @sales_period_status		char(1),
        @finyear_start				datetime,
        @country_name				varchar(30),
        @branch_code_tmp			char(2),
        @branch_name					varchar(50),
        @business_group_tmp		integer,
        @business_group_desc		varchar(30),
        @proposal_canc				money,
        @proposal_canc_cnt			integer,
        @proposal_wip				money,
        @proposal_wip_cnt			integer,
        @new_business_rel			money,
        @new_business_rel_cnt		integer,
        @new_business_canc			money,
        @new_business_canc_cnt	integer,
        @new_business_hold			money,
        @new_business_hold_cnt	integer,
        @new_business_wip			money,
        @new_business_wip_cnt		integer,
        @ren_business_rel			money,
        @ren_business_rel_cnt		integer,
        @ren_business_canc			money,
        @ren_business_canc_cnt	integer,
        @ren_business_hold			money,
        @ren_business_hold_cnt	integer,
        @ren_business_wip			money,
        @ren_business_wip_cnt		integer,
        @sup_business_rel			money,
        @sup_business_rel_cnt		integer,
        @sup_business_canc			money,
        @sup_business_canc_cnt	integer,
        @sup_business_hold			money,
        @sup_business_hold_cnt	integer,
        @sup_business_wip			money,
        @sup_business_wip_cnt		integer,
        @ext_business_rel			money,
        @ext_business_rel_cnt		integer,
        @ext_business_canc			money,
        @ext_business_canc_cnt	integer,
        @ext_business_hold			money,
        @ext_business_hold_cnt	integer,
        @ext_business_wip			money,
        @ext_business_wip_cnt		integer,
        @rel_pending_rel			money,
        @rel_pending_rel_cnt		integer,
        @rel_pending_canc			money,
        @rel_pending_canc_cnt		integer,
        @rel_pending_hold			money,
        @rel_pending_hold_cnt		integer,
        @rel_pending_wip			money,
        @rel_pending_wip_cnt		integer,
        @writebacks_rel				money,
        @writebacks_rel_cnt		integer,
        @writebacks_canc			money,
        @writebacks_canc_cnt		integer,
        @writebacks_hold			money,
        @writebacks_hold_cnt		integer,
        @writebacks_wip				money,
        @writebacks_wip_cnt		integer

/*
 * Create Temporary Tables
 */

create table #summary
(
	country_code		char(2)				null,
	country_name		varchar(30)			null,
	branch_code		char(2)				null,
	branch_name		varchar(50)			null,
	business_group		integer				null,
	business_group_desc	varchar(30)			null,
	proposal_canc		money				null,
	proposal_canc_cnt	integer				null,
	proposal_wip		money				null,
	proposal_wip_cnt	integer				null,
	new_business_rel	money				null,
	new_business_rel_cnt	integer				null,
	new_business_canc	money					null,
	new_business_canc_cnt	integer				null,
	new_business_hold	money					null,
	new_business_hold_cnt	integer				null,
	new_business_wip	money					null,
	new_business_wip_cnt	integer				null,
	ren_business_rel	money					null,
	ren_business_rel_cnt	integer				null,
	ren_business_canc	money					null,
	ren_business_canc_cnt	integer				null,
	ren_business_hold	money					null,
	ren_business_hold_cnt	integer				null,
	ren_business_wip	money					null,
	ren_business_wip_cnt	integer				null,
	sup_business_rel	money					null,
	sup_business_rel_cnt	integer				null,
	sup_business_canc	money					null,
	sup_business_canc_cnt	integer				null,
	sup_business_hold	money					null,
	sup_business_hold_cnt	integer				null,
	sup_business_wip	money					null,
	sup_business_wip_cnt	integer				null,
	ext_business_rel	money					null,
	ext_business_rel_cnt	integer				null,
	ext_business_canc	money					null,
	ext_business_canc_cnt	integer				null,
	ext_business_hold	money					null,
	ext_business_hold_cnt	integer				null,
	ext_business_wip	money					null,
	ext_business_wip_cnt	integer				null,
	rel_pending_rel		money					null,
	rel_pending_rel_cnt	integer				null,
	rel_pending_canc	money					null,
	rel_pending_canc_cnt	integer				null,
	rel_pending_hold	money					null,
	rel_pending_hold_cnt	integer				null,
	rel_pending_wip		money					null,
	rel_pending_wip_cnt	integer				null,
	writebacks_rel		money					null,
	writebacks_rel_cnt	integer				null,
	writebacks_canc		money					null,
	writebacks_canc_cnt	integer				null,
	writebacks_hold		money					null,
	writebacks_hold_cnt	integer				null,
	writebacks_wip		money					null,
	writebacks_wip_cnt	integer				null
)
select @country_name = country_name
  from country
 where country.country_code = @country_code

select @branch_code_tmp = branch_code,
       @branch_name = branch_name
  from branch
 where branch.branch_code = @branch_code

select @branch_code = @branch_code_tmp

select @business_group_tmp = business_group_no,
       @business_group_desc = business_group_desc
  from business_group
 where business_group.business_group_no = @business_group

select @business_group = @business_group_tmp

select @sales_period_no = sales_period.sales_period_no,
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
 * Initialise the #summary table
 */

insert into #summary
	(  country_code, country_name, branch_code, branch_name, business_group, business_group_desc,
		proposal_canc, proposal_canc_cnt, proposal_wip, proposal_wip_cnt,
		new_business_rel, new_business_rel_cnt, new_business_canc, new_business_canc_cnt, new_business_hold, new_business_hold_cnt, new_business_wip, new_business_wip_cnt,
		ren_business_rel, ren_business_rel_cnt, ren_business_canc, ren_business_canc_cnt, ren_business_hold, ren_business_hold_cnt, ren_business_wip, ren_business_wip_cnt,
		sup_business_rel, sup_business_rel_cnt, sup_business_canc, sup_business_canc_cnt, sup_business_hold, sup_business_hold_cnt, sup_business_wip, sup_business_wip_cnt,
		ext_business_rel, ext_business_rel_cnt, ext_business_canc, ext_business_canc_cnt, ext_business_hold, ext_business_hold_cnt, ext_business_wip, ext_business_wip_cnt,
		rel_pending_rel, rel_pending_rel_cnt, rel_pending_canc, rel_pending_canc_cnt, rel_pending_hold, rel_pending_hold_cnt, rel_pending_wip, rel_pending_wip_cnt,
		writebacks_rel, writebacks_rel_cnt, writebacks_canc, writebacks_canc_cnt, writebacks_hold, writebacks_hold_cnt, writebacks_wip, writebacks_wip_cnt )
values
	(  @country_code, @country_name, @branch_code, @branch_name, @business_group, @business_group_desc,
		0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0 )

/*
 * Select Proposals Work In Progress
 */

select @proposal_wip = sum(slide_proposal.comm_period_value),
		 @proposal_wip_cnt = count(slide_proposal.comm_period_value)
  from slide_proposal
 where ( ( slide_proposal.business_group = @business_group ) or ( @business_group is null) ) and
       ( ( slide_proposal.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_proposal.campaign_no is null and
           slide_proposal.proposal_lost <> 'Y' and
           slide_proposal.campaign_period = @sales_period_end ) or
         ( slide_proposal.creation_period <= @sales_period_end and
           slide_proposal.campaign_period > @sales_period_end ) )

update #summary
	set proposal_wip = @proposal_wip,
		 proposal_wip_cnt = @proposal_wip_cnt
 where @proposal_wip is not null

/*
 * Select Proposals Cancelled
 */

select @proposal_canc = sum(slide_proposal.comm_period_value),
		 @proposal_canc_cnt = count(slide_proposal.comm_period_value)
  from slide_proposal
 where slide_proposal.campaign_no is null and
       slide_proposal.proposal_lost = 'Y' and
       ( ( slide_proposal.business_group = @business_group ) or ( @business_group is null) ) and
       ( ( slide_proposal.branch_code = @branch_code ) or ( @branch_code is null) ) and
       slide_proposal.campaign_period = @sales_period_end

update #summary
	set proposal_canc = @proposal_canc,
		 proposal_canc_cnt = @proposal_canc_cnt
 where @proposal_canc is not null

/*
 * Select New Business Released
 */

select @new_business_rel = sum(slide_figures.nett_amount),
       @new_business_rel_cnt = count(slide_figures.nett_amount)
  from slide_figures,
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'N' ) and
       ( ( slide_figures.figure_official = 'Y' ) or
         ( slide_figures.figure_status <> 'X' and
           slide_campaign.campaign_release = 'Y' and
           slide_figures.figure_hold <> 'Y' ) ) )

update #summary
	set new_business_rel = @new_business_rel,
		 new_business_rel_cnt = @new_business_rel_cnt
 where @new_business_rel is not null

/*
 * Select New Business Cancelled
 */

select @new_business_canc = sum(slide_figures.nett_amount),
		 @new_business_canc_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'N' ) and
       ( slide_figures.figure_official <> 'Y' and
         slide_figures.figure_status = 'X' ) )

update #summary
	set new_business_canc = @new_business_canc,
		 new_business_canc_cnt = @new_business_canc_cnt
 where @new_business_canc is not null

/*
 * Select New Business Hold
 */

select @new_business_hold = sum(slide_figures.nett_amount),
		 @new_business_hold_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'N' ) and
       ( ( slide_figures.release_period = @sales_period_end and  
           slide_figures.figure_official <> 'Y' and
           slide_figures.figure_status <> 'X' and
           slide_campaign.campaign_release = 'Y' and
           slide_figures.figure_hold = 'Y' ) or
         ( slide_figures.creation_period <= @sales_period_end and
           slide_figures.release_period > @sales_period_end ) ) )

update #summary
	set new_business_hold = @new_business_hold,
		 new_business_hold_cnt = @new_business_hold_cnt
 where @new_business_hold is not null

/*
 * Select New Business Work In Progress
 */

select @new_business_wip = sum(slide_figures.nett_amount),
		 @new_business_wip_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'N' ) and
       ( slide_figures.figure_official <> 'Y' and
         slide_figures.figure_status <> 'X' and
         slide_campaign.campaign_release <> 'Y' ) )

update #summary
	set new_business_wip = @new_business_wip,
		 new_business_wip_cnt = @new_business_wip_cnt
 where @new_business_wip is not null

/*
 * Select Renewed Business Released
 */

select @ren_business_rel = sum(slide_figures.nett_amount),
		 @ren_business_rel_cnt = count(slide_figures.nett_amount)
  from slide_figures,
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'R' ) and
       ( ( slide_figures.figure_official = 'Y' ) or
         ( slide_figures.figure_status <> 'X' and
           slide_campaign.campaign_release = 'Y' and
           slide_figures.figure_hold <> 'Y' ) ) )

update #summary
	set ren_business_rel = @ren_business_rel,
		 ren_business_rel_cnt = @ren_business_rel_cnt
 where @ren_business_rel is not null

/*
 * Select Renewed Business Cancelled
 */

select @ren_business_canc = sum(slide_figures.nett_amount),
		 @ren_business_canc_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'R' ) and
       ( slide_figures.figure_official <> 'Y' and
         slide_figures.figure_status = 'X' ) )

update #summary
	set ren_business_canc = @ren_business_canc,
		 ren_business_canc_cnt = @ren_business_canc_cnt
 where @ren_business_canc is not null

/*
 * Select Renewed Business Hold
 */

select @ren_business_hold = sum(slide_figures.nett_amount),
		 @ren_business_hold_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'R' ) and
       ( ( slide_figures.release_period = @sales_period_end and
           slide_figures.figure_official <> 'Y' and
           slide_figures.figure_status <> 'X' and
           slide_campaign.campaign_release = 'Y' and
           slide_figures.figure_hold = 'Y' ) or
         ( slide_figures.creation_period <= @sales_period_end and
           slide_figures.release_period > @sales_period_end ) ) )

update #summary
	set ren_business_hold = @ren_business_hold,
		 ren_business_hold_cnt = @ren_business_hold_cnt
 where @ren_business_hold is not null

/*
 * Select Renewed Business Work In Progress
 */

select @ren_business_wip = sum(slide_figures.nett_amount),
		 @ren_business_wip_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'R' ) and
       ( slide_figures.figure_official <> 'Y' and
         slide_figures.figure_status <> 'X' and
         slide_campaign.campaign_release <> 'Y' ) )

update #summary
	set ren_business_wip = @ren_business_wip,
		 ren_business_wip_cnt = @ren_business_wip_cnt
 where @ren_business_wip is not null

/*
 * Select Supercede Business Released
 */

select @sup_business_rel = sum(slide_figures.nett_amount),
		 @sup_business_rel_cnt = count(slide_figures.nett_amount)
  from slide_figures,
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'S' ) and
       ( ( slide_figures.figure_official = 'Y' ) or
         ( slide_figures.figure_status <> 'X' and
           slide_campaign.campaign_release = 'Y' and
           slide_figures.figure_hold <> 'Y' ) ) )

update #summary
	set sup_business_rel = @sup_business_rel,
		 sup_business_rel_cnt = @sup_business_rel_cnt
 where @sup_business_rel is not null

/*
 * Select Supercede Business Cancelled
 */

select @sup_business_canc = sum(slide_figures.nett_amount),
		 @sup_business_canc_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'S' ) and
       ( slide_figures.figure_official <> 'Y' and
         slide_figures.figure_status = 'X' ) )

update #summary
	set sup_business_canc = @sup_business_canc,
		 sup_business_canc_cnt = @sup_business_canc_cnt
 where @sup_business_canc is not null

/*
 * Select Supercede Business Hold
 */

select @sup_business_hold = sum(slide_figures.nett_amount),
		 @sup_business_hold_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'S' ) and
       ( ( slide_figures.release_period = @sales_period_end and
           slide_figures.figure_official <> 'Y' and
           slide_figures.figure_status <> 'X' and
           slide_campaign.campaign_release = 'Y' and
           slide_figures.figure_hold = 'Y' ) or
         ( slide_figures.creation_period <= @sales_period_end and
           slide_figures.release_period > @sales_period_end ) ) )

update #summary
	set sup_business_hold = @sup_business_hold,
		 sup_business_hold_cnt = @sup_business_hold_cnt
 where @sup_business_hold is not null

/*
 * Select Supercede Business Work In Progress
 */

select @sup_business_wip = sum(slide_figures.nett_amount),
		 @sup_business_wip_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'S' ) and
       ( slide_figures.figure_official <> 'Y' and
         slide_figures.figure_status <> 'X' and
         slide_campaign.campaign_release <> 'Y' ) )

update #summary
	set sup_business_wip = @sup_business_wip,
		 sup_business_wip_cnt = @sup_business_wip_cnt
 where @sup_business_wip is not null

/*
 * Select Extended Business Released
 */

select @ext_business_rel = sum(slide_figures.nett_amount),
		 @ext_business_rel_cnt = count(slide_figures.nett_amount)
  from slide_figures,
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'E' ) and
       ( ( slide_figures.figure_official = 'Y' ) or
         ( slide_figures.figure_status <> 'X' and
           slide_campaign.campaign_release = 'Y' and
           slide_figures.figure_hold <> 'Y' ) ) )

update #summary
	set ext_business_rel = @ext_business_rel,
		 ext_business_rel_cnt = @ext_business_rel_cnt
 where @ext_business_rel is not null

/*
 * Select Extended Business Cancelled
 */

select @ext_business_canc = sum(slide_figures.nett_amount),
		 @ext_business_canc_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'E' ) and
       ( slide_figures.figure_official <> 'Y' and
         slide_figures.figure_status = 'X' ) )

update #summary
	set ext_business_canc = @ext_business_canc,
		 ext_business_canc_cnt = @ext_business_canc_cnt
 where @ext_business_canc is not null

/*
 * Select Extended Business Hold
 */

select @ext_business_hold = sum(slide_figures.nett_amount),
		 @ext_business_hold_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'E' ) and
       ( ( slide_figures.release_period = @sales_period_end and
           slide_figures.figure_official <> 'Y' and
           slide_figures.figure_status <> 'X' and
           slide_campaign.campaign_release = 'Y' and
           slide_figures.figure_hold = 'Y' ) or
         ( slide_figures.creation_period <= @sales_period_end and
           slide_figures.release_period > @sales_period_end ) ) )

update #summary
	set ext_business_hold = @ext_business_hold,
		 ext_business_hold_cnt = @ext_business_hold_cnt
 where @ext_business_hold is not null

/*
 * Select Extended Business Work In Progress
 */

select @ext_business_wip = sum(slide_figures.nett_amount),
		 @ext_business_wip_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value = 0 ) and
       ( slide_campaign.campaign_type = 'E' ) and
       ( slide_figures.figure_official <> 'Y' and
         slide_figures.figure_status <> 'X' and
         slide_campaign.campaign_release <> 'Y' ) )

update #summary
	set ext_business_wip = @ext_business_wip,
		 ext_business_wip_cnt = @ext_business_wip_cnt
 where @ext_business_wip is not null

/*
 * Select Released Pending Released
 */

select @rel_pending_rel = sum(slide_figures.nett_amount),
		 @rel_pending_rel_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value > 0 ) and
       ( ( slide_figures.figure_official = 'Y' ) or
         ( slide_figures.figure_status <> 'X' and
           slide_campaign.campaign_release = 'Y' and
           slide_figures.figure_hold <> 'Y' ) ) )

update #summary
	set rel_pending_rel = @rel_pending_rel,
		 rel_pending_rel_cnt = @rel_pending_rel_cnt
 where @rel_pending_rel is not null

/*
 * Select Released Pending Cancelled
 */

select @rel_pending_canc = sum(slide_figures.nett_amount),
		 @rel_pending_canc_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value > 0 ) and
       ( slide_figures.figure_official <> 'Y' and
         slide_figures.figure_status = 'X' ) )

update #summary
	set rel_pending_canc = @rel_pending_canc,
		 rel_pending_canc_cnt = @rel_pending_canc_cnt
 where @rel_pending_canc is not null

/*
 * Select Released Pending Hold
 */

select @rel_pending_hold = sum(slide_figures.nett_amount),
		 @rel_pending_hold_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value > 0 ) and
       ( ( slide_figures.release_period = @sales_period_end and
           slide_figures.figure_official <> 'Y' and
           slide_figures.figure_status <> 'X' and
           slide_campaign.campaign_release = 'Y' and
           slide_figures.figure_hold = 'Y' ) or
         ( slide_figures.creation_period <= @sales_period_end and
           slide_figures.release_period > @sales_period_end ) ) )

update #summary
	set rel_pending_hold = @rel_pending_hold,
		 rel_pending_hold_cnt = @rel_pending_hold_cnt
 where @rel_pending_hold is not null

/*
 * Select Released Pending Work In Progress
 */

select @rel_pending_wip = sum(slide_figures.nett_amount),
		 @rel_pending_wip_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type <> 'W' and
         slide_figures.figure_status <> 'P' and
         slide_figures.release_value > 0 ) and
       ( slide_figures.figure_official <> 'Y' and
         slide_figures.figure_status <> 'X' and
         slide_campaign.campaign_release <> 'Y' ) )

update #summary
	set rel_pending_wip = @rel_pending_wip,
		 rel_pending_wip_cnt = @rel_pending_wip_cnt
 where @rel_pending_wip is not null

/*
 * Select Writebacks Released
 */

select @writebacks_rel = sum(slide_figures.nett_amount),
		 @writebacks_rel_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type = 'W' ) and
       ( ( slide_figures.figure_official = 'Y' ) or
         ( slide_figures.figure_status <> 'X' and
           slide_campaign.campaign_release = 'Y' and
           slide_figures.figure_hold <> 'Y' ) ) )

update #summary
	set writebacks_rel = @writebacks_rel,
		 writebacks_rel_cnt = @writebacks_rel_cnt
 where @writebacks_rel is not null

/*
 * Select Writebacks Cancelled
 */

select @writebacks_canc = sum(slide_figures.nett_amount),
		 @writebacks_canc_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type = 'W' ) and
       ( slide_figures.figure_official <> 'Y' and
         slide_figures.figure_status = 'X' ) )

update #summary
	set writebacks_canc = @writebacks_canc,
		 writebacks_canc_cnt = @writebacks_canc_cnt
 where @writebacks_canc is not null

/*
 * Select Writebacks Hold
 */

select @writebacks_hold = sum(slide_figures.nett_amount),
		 @writebacks_hold_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type = 'W' ) and
       ( ( slide_figures.release_period = @sales_period_end and
           slide_figures.figure_official <> 'Y' and
           slide_figures.figure_status <> 'X' and
           slide_campaign.campaign_release = 'Y' and
           slide_figures.figure_hold = 'Y' ) or
         ( slide_figures.creation_period <= @sales_period_end and
           slide_figures.release_period > @sales_period_end ) ) )

update #summary
	set writebacks_hold = @writebacks_hold,
		 writebacks_hold_cnt = @writebacks_hold_cnt
 where @writebacks_hold is not null

/*
 * Select Writebacks Work In Progress
 */

select @writebacks_wip = sum(slide_figures.nett_amount),
		 @writebacks_wip_cnt = count(slide_figures.nett_amount)
  from slide_figures,   
       slide_campaign,
       branch
 where ( slide_figures.campaign_no = slide_campaign.campaign_no ) and  
       ( slide_figures.branch_code = branch.branch_code ) and
       ( ( branch.country_code = @country_code ) and
       ( slide_figures.release_period = @sales_period_end ) and  
       ( ( slide_figures.branch_code = @branch_code ) or ( @branch_code is null) ) and
       ( ( slide_figures.business_group = @business_group ) or ( @business_group is null ) ) and 
       ( slide_figures.figure_type = 'W' ) and
       ( slide_figures.figure_official <> 'Y' and
         slide_figures.figure_status <> 'X' and
         slide_campaign.campaign_release <> 'Y' ) )

update #summary
	set writebacks_wip = @writebacks_wip,
		 writebacks_wip_cnt = @writebacks_wip_cnt
 where @writebacks_wip is not null

/*
 * Return
 */

select @sales_period_no,
       @sales_period_end,
      @sales_period_status,

      country_code,
      country_name,

      branch_code,
      branch_name,

       business_group,
      business_group_desc,

      proposal_canc,
      proposal_canc_cnt,
      proposal_wip,
      proposal_wip_cnt,

       new_business_rel,
       new_business_rel_cnt,
       new_business_canc,
       new_business_canc_cnt,
       new_business_hold,
       new_business_hold_cnt,
       new_business_wip,
       new_business_wip_cnt,

       ren_business_rel,
       ren_business_rel_cnt,
       ren_business_canc,
       ren_business_canc_cnt,
       ren_business_hold,
       ren_business_hold_cnt,
       ren_business_wip,
       ren_business_wip_cnt,

       sup_business_rel,
       sup_business_rel_cnt,
       sup_business_canc,
       sup_business_canc_cnt,
       sup_business_hold,
       sup_business_hold_cnt,
       sup_business_wip,
       sup_business_wip_cnt,

       ext_business_rel,
       ext_business_rel_cnt,
       ext_business_canc,
       ext_business_canc_cnt,
       ext_business_hold,
       ext_business_hold_cnt,
       ext_business_wip,
       ext_business_wip_cnt,

       rel_pending_rel,
       rel_pending_rel_cnt,
       rel_pending_canc,
       rel_pending_canc_cnt,
       rel_pending_hold,
       rel_pending_hold_cnt,
       rel_pending_wip,
       rel_pending_wip_cnt,

       writebacks_rel,
       writebacks_rel_cnt,
       writebacks_canc,
       writebacks_canc_cnt,
       writebacks_hold,
       writebacks_hold_cnt,
       writebacks_wip,
       writebacks_wip_cnt

 from #summary

return 0
GO
