/****** Object:  StoredProcedure [dbo].[p_brch_film_target_sheet_reps]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_brch_film_target_sheet_reps]
GO
/****** Object:  StoredProcedure [dbo].[p_brch_film_target_sheet_reps]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_brch_film_target_sheet_reps] @finyear_end		datetime,
                                       	@branch_code		char(1)
as

/*
 * Declare Procedure Variables
 */

declare @errorode						integer,
        @error          		integer,
        @rowcount					integer

create table #reps
(
   rep_id				integer			null,
   first_name			varchar(30)		null,
   last_name			varchar(30)		null,
   status				char(1)			null
)

/*
 * Select home branch reps with target records
 */

insert into #reps
  select sales_rep.rep_id,
         sales_rep.first_name,
         sales_rep.last_name,
         sales_rep.status
    from sales_rep,
         film_rep_year
   where sales_rep.rep_id = film_rep_year.rep_id and
         film_rep_year.finyear_end = @finyear_end and
         film_rep_year.branch_code = @branch_code 

/*
 * Select reps who have written business for branch
 */

insert into #reps
 select
distinct sales_rep.rep_id,
         sales_rep.first_name,
         sales_rep.last_name,
         sales_rep.status
    from sales_rep,
         film_figures,
         film_campaign,
         film_reporting_period
   where sales_rep.rep_id = film_figures.rep_id and
         film_figures.campaign_no = film_campaign.campaign_no and
         film_figures.release_period = film_reporting_period.report_period_end and
         film_figures.figure_official = 'Y' and
         film_reporting_period.finyear_end = @finyear_end and
         film_figures.branch_code = @branch_code 

/*
 * Return Result Set
 */

  select
distinct rep_id,
         first_name,
         last_name,
         status
    from #reps

return 0
GO
