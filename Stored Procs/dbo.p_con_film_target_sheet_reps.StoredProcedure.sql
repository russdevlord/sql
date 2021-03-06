/****** Object:  StoredProcedure [dbo].[p_con_film_target_sheet_reps]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_con_film_target_sheet_reps]
GO
/****** Object:  StoredProcedure [dbo].[p_con_film_target_sheet_reps]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_con_film_target_sheet_reps] @finyear_end		datetime
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
         film_rep_year
   where sales_rep.rep_id = film_rep_year.rep_id and
         film_rep_year.finyear_end = @finyear_end

/*
 * Select reps who have written business
 */

insert into #reps
SELECT DISTINCT sales_rep.rep_id,   
         sales_rep.branch_code,   
         sales_rep.first_name,   
         sales_rep.last_name,   
         sales_rep.status  
    FROM film_campaign,   
         film_figures,   
         film_reporting_period,   
         sales_rep  
   WHERE ( film_campaign.campaign_no = film_figures.campaign_no ) and  
         ( film_figures.release_period = film_reporting_period.report_period_end ) and  
         ( sales_rep.rep_id = film_figures.rep_id ) and  
         ( ( film_figures.figure_official = 'Y' ) AND  
         ( film_reporting_period.finyear_end =  @finyear_end ) )

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
