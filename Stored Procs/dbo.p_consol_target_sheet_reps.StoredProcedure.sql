/****** Object:  StoredProcedure [dbo].[p_consol_target_sheet_reps]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_consol_target_sheet_reps]
GO
/****** Object:  StoredProcedure [dbo].[p_consol_target_sheet_reps]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_consol_target_sheet_reps] @finyear_end		datetime
as

/*
 * Declare Procedure Variables
 */

declare @errorode						integer,
        @error          		integer,
        @rowcount					integer

/*
 * Create Temporary Tables
 */

create table #reps
(
   rep_id				integer			null,
   branch_code			char(2)			null,
   first_name			varchar(30)		null,
   last_name			varchar(30)		null,
   status				char(1)			null
)

/*
 * Select reps with target records
 */

insert into #reps
  select sales_rep.rep_id,
         sales_rep.branch_code,
         sales_rep.first_name,
         sales_rep.last_name,
         sales_rep.status
    from sales_rep,
         rep_year
   where sales_rep.rep_id = rep_year.rep_id and
         rep_year.finyear_end = @finyear_end

/*
 * Select reps who have written business
 */

/*insert into #reps
 select
distinct sales_rep.rep_id,
         sales_rep.branch_code,
         sales_rep.first_name,
         sales_rep.last_name,
         sales_rep.status
    from sales_rep,
         slide_figures,
         slide_campaign,
         sales_period
   where sales_rep.rep_id = slide_figures.rep_id and
         slide_figures.campaign_no = slide_campaign.campaign_no and
         slide_figures.release_period = sales_period.sales_period_end and
         slide_figures.figure_official = 'Y' and
         sales_period.finyear_end = @finyear_end*/
-- michael added following 1/6/01 to make select faster
insert into #reps
 select
distinct slide_figures.rep_id,
         sales_rep.branch_code,
         sales_rep.first_name,
         sales_rep.last_name,
         sales_rep.status
    from slide_figures,
			sales_rep,
         sales_period
   where slide_figures.rep_id = sales_rep.rep_id and
         slide_figures.release_period = sales_period.sales_period_end and
         slide_figures.figure_official = 'Y' and
         sales_period.finyear_end = @finyear_end

/*
 * Return Result Set
 */

  select
distinct rep_id,
         branch_code,
         first_name,
         last_name,
         status
    from #reps

return 0
GO
