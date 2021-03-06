/****** Object:  StoredProcedure [dbo].[p_monthly_film_figures]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_monthly_film_figures]
GO
/****** Object:  StoredProcedure [dbo].[p_monthly_film_figures]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_monthly_film_figures]  @report_period_end	datetime,
												@rep_id					integer
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare  @error          			integer,
         @rowcount					integer,
         @report_period_no			integer,
         @finyear_start				datetime,
         @report_period_status	char(1),
		   @prev_fin_year				datetime,
			@report_period				datetime,	
		   @first_name					varchar(30),
		   @last_name					varchar(30),
		   @film_target				money,
			@last_year_figures		money,
			@release_date				datetime,
			@slide_figures				money,
			@ytd_amount					money,
			@amount						money,
			@writebacks					money,
			@branch_code				char(2)


/*
 * Create Temporary Tables
 */

create table #monthly_figures
(
	film_target			money					null,
	last_year_figures	money					null,
	release_date		datetime				null,
	slide_figures		money					null,
	rep_id				integer				null,
	first_name			varchar(30)			null,
	last_name			varchar(30)			null,
	ytd_amount			money					null,
	amount				money					null,
	writebacks			money					null,
	branch_code			char(2)				null
)

/*
 *  Iniatialise values for reporting periods
 */
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
 * Declare Cursor to loop over sales_reps
 */ 
  declare sales_rep_csr cursor static for 
	select sr.rep_id,
		 sr.first_name,
		 sr.last_name,
		 ff.branch_code
     from sales_rep sr,
	 film_figures ff
	 where ff.rep_id = sr.rep_id and
	 ff.release_period <= @report_period_end and
	 ff.release_period >= @finyear_start
 group by sr.rep_id,
	 sr.first_name,
	 sr.last_name,
	 ff.branch_code
 order by ff.branch_code,
	 sr.rep_id

/*
 * Open cursor and fill get values
 */
open sales_rep_csr
fetch sales_rep_csr into @rep_id, @first_name, @last_name, @branch_code
while (@@fetch_status = 0)
begin
	/*
	 * Declare Cursor to loop over report_periods to date for the year
	 */ 
	  declare report_period_csr cursor static for 
	   select report_period_end 
	     from film_reporting_period 
	    where report_period_end <= @report_period_end and 
	          report_period_end >= @finyear_start
	order by report_period_end asc

	open report_period_csr
	fetch report_period_csr into @report_period
	while (@@fetch_status = 0)
	begin

		select @film_target = sum(target_amount)
		  from rep_film_targets
		 where rep_id = @rep_id and
				 report_period = @report_period and
				 branch_code = @branch_code

		select @amount = sum(nett_amount)
		  from film_figures
		 where rep_id = @rep_id and
				 figure_type <> 'W' and
				 release_period = @report_period and
				 branch_code = @branch_code

   	select @writebacks = sum(nett_amount)
		  from film_figures
		 where rep_id = @rep_id and
				 figure_type = 'W' and
				 release_period = @report_period and
				 branch_code = @branch_code
	
	  select @last_year_figures = sum(nett_amount)
		 from film_figures
		where rep_id = @rep_id and
				figure_type <> 'W' and
				release_period <= @finyear_start and
				release_period >= dateadd(mm, -12, @finyear_start) and
  			   branch_code = @branch_code

 	  select @slide_figures = sum(nett_amount)
	    from slide_figures
		where rep_id = @rep_id and
 			   release_period <= @report_period and
				release_period >= dateadd(mm, -1, @report_period) and
				 branch_code = @branch_code

	  select @ytd_amount = sum(nett_amount)
	    from film_figures
		where rep_id = @rep_id and
				release_period <= @report_period and
				release_period >= @finyear_start and
				 branch_code = @branch_code
	
			insert into #monthly_figures
			(film_target,
			last_year_figures,
			release_date,
			slide_figures,
			rep_id,
			first_name,
			last_name,
			ytd_amount,
			amount,
			writebacks,
			branch_code
			) values
			(isnull(@film_target,0),
			isnull(@last_year_figures,0),
			@report_period,
			isnull(@slide_figures,0),
			@rep_id,
			@first_name,
			@last_name,
			isnull(@ytd_amount,0),
			isnull(@amount,0),
			isnull(@writebacks,0),
			@branch_code
			)
 
		fetch report_period_csr into @report_period
	end
	close report_period_csr
	deallocate report_period_csr
 	fetch sales_rep_csr into @rep_id, @first_name, @last_name, @branch_code
end

close sales_rep_csr 
deallocate sales_rep_csr 

/*
 * Return
 */

select film_target,
		 last_year_figures,
		 release_date,
		 slide_figures,
		 rep_id,
		 first_name,
		 last_name,
		 ytd_amount,
		 amount,
		 writebacks,
		 branch_code
 from #monthly_figures
order by first_name,
			last_name,
			branch_code,
			release_date
			

return 0
GO
