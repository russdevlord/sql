/****** Object:  StoredProcedure [dbo].[p_team_target_sheet_reps]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_team_target_sheet_reps]
GO
/****** Object:  StoredProcedure [dbo].[p_team_target_sheet_reps]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_team_target_sheet_reps] @finyear_end			datetime,
                                     @sales_period_end	datetime,
                                     @team_id				integer,
												 @include_term_reps	char(1)
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @errorode						integer,
        @error          		integer,
        @rowcount					integer,
        @finyear_start_period	datetime,
        @finyear_end_period	datetime

create table #reps
(
   rep_id				integer	null,
   first_name			varchar(30)		null,
   last_name			varchar(30)		null,
   status				char(1)			null
)

select @finyear_start_period = min(sales_period.sales_period_end),
       @finyear_end_period = max(sales_period.sales_period_end)
  from sales_period
 where sales_period.finyear_end = @finyear_end

-- Select team reps that belong to Team for selected Sales Period
-- Include Reps that have belonged to team for Financial Year to include in 'Cost to Sell'
insert into #reps
  select sales_rep.rep_id,
         sales_rep.first_name,
         sales_rep.last_name,
         sales_rep.status
    from sales_rep,
         team_reps,
         team_rep_dates
   where sales_rep.rep_id = team_reps.rep_id and
         team_reps.team_rep_id = team_rep_dates.team_rep_id and
         team_reps.team_id = @team_id and
         ((team_rep_dates.start_period >= @finyear_start_period and team_rep_dates.start_period <= @finyear_end_period) or
          (team_rep_dates.end_period >= @finyear_start_period and team_rep_dates.end_period <= @finyear_end_period and team_rep_dates.end_period is not null) or
          (team_rep_dates.start_period <= @finyear_end_period and team_rep_dates.end_period is null))  and
			((sales_rep.status <> 'X' and @include_term_reps = 'N') or @include_term_reps = 'Y')

-- Select reps who have written business for branch
insert into #reps
 select
distinct sales_rep.rep_id,
         sales_rep.first_name,
         sales_rep.last_name,
         sales_rep.status
    from sales_rep,
         slide_figures,
         sales_period
   where sales_rep.rep_id = slide_figures.rep_id and
         slide_figures.release_period = sales_period.sales_period_end and
         slide_figures.figure_official = 'Y' and
         sales_period.finyear_end = @finyear_end and
         slide_figures.team_id = @team_id and
			((sales_rep.status <> 'X' and @include_term_reps = 'N') or @include_term_reps = 'Y')
/*
 * Return
 */

  select
distinct rep_id,
         first_name,
         last_name,
         status
    from #reps

return 0
GO
