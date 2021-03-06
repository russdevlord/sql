/****** Object:  StoredProcedure [dbo].[p_area_target_sheet_reps]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_area_target_sheet_reps]
GO
/****** Object:  StoredProcedure [dbo].[p_area_target_sheet_reps]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_area_target_sheet_reps] @finyear_end			datetime,
                                     @sales_period_end	datetime,
                                     @area_id				integer,
					@include_term_reps	char(1)
as

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

-- Select area reps that belong to area for selected Sales Period
-- Include Reps that have belonged to area for Financial Year to include in 'Cost to Sell'
insert into #reps
  select sales_rep.rep_id,
         sales_rep.first_name,
         sales_rep.last_name,
         sales_rep.status
    from sales_rep,
         area_reps,
         area_rep_dates
   where sales_rep.rep_id = area_reps.rep_id and
         area_reps.area_rep_id = area_rep_dates.area_rep_id and
         area_reps.area_id = @area_id and
         ((area_rep_dates.start_period >= @finyear_start_period and area_rep_dates.start_period <= @finyear_end_period) or
          (area_rep_dates.end_period >= @finyear_start_period and area_rep_dates.end_period <= @finyear_end_period and area_rep_dates.end_period is not null) or
          (area_rep_dates.start_period <= @finyear_end_period and area_rep_dates.end_period is null)) and
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
         slide_figures.area_id = @area_id  and
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
