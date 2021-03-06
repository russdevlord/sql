/****** Object:  StoredProcedure [dbo].[p_production_output_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_production_output_report]
GO
/****** Object:  StoredProcedure [dbo].[p_production_output_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_production_output_report]  @date_from   datetime,
													 @date_to	  datetime	
as
set nocount on 
declare  @branch_code			char(2),
			@output_code			char(1),
			@branch_sched_sum		integer,
			@branch_actual_sum	integer,
			@prod_sched_sum		integer,
			@prod_actual_sum		integer,
			@ho_sched_sum			integer,
			@ho_actual_sum			integer

/*
 * Create Temporary Table
 */

create table #report_items
(
	country_code		char(1)				null,
	branch_code			char(2)				null,
	output_code			char(1)				null,
	branch 				varchar(50)			null,
	output_cat			varchar(30)			null,
	branch_sched		integer				null,
	branch_actual		integer				null,
	prod_sched			integer				null,
	prod_actual			integer				null,
	ho_sched				integer				null,
	ho_actual			integer				null
)

/*
 * Fill the table with a cartesian product of branches and output_categories
 */

insert into #report_items (
       country_code,
	    branch_code,
	    output_code,
	    branch,
	    output_cat,
	    branch_sched,
	    branch_actual,
	    prod_sched,
	    prod_actual,
	    ho_sched,
	    ho_actual )
select country_code,
       branch_code,
		 output_category_code,	
		 branch_name,
		 output_category_desc,
		 0,
 		 0,
		 0,
		 0,
		 0,
		 0
  from branch,
		 output_category 
 where output_category_code <> 'N'

/*
 * Declare Cursor
 */
 declare item_csr cursor static for
  select branch_code,
         output_code
    from #report_items
order by branch_code,output_code
     for read only

open item_csr
fetch item_csr into @branch_code, @output_code
while(@@fetch_status = 0)
begin
	-- Update Branch values.
	select @branch_sched_sum = isnull(sum(scheduled_qty + spare_qty),0),
			 @branch_actual_sum = isnull(sum(production_qty),0)
	  from production_output,
			 npu_request n
	 where n.branch_code = @branch_code and
			 n.request_no = production_output.request_no and
			 n.request_source = 'B' and
			 output_category = @output_code and 
			 production_date >= @date_from and
			 production_date <= @date_to

	-- Update Production values.
	select @prod_sched_sum = isnull(sum(scheduled_qty + spare_qty),0),
			 @prod_actual_sum = isnull(sum(production_qty),0)
	  from production_output,
			 npu_request n
	 where n.branch_code = @branch_code and
			 n.request_no = production_output.request_no and
			 n.request_source = 'P' and
			 output_category = @output_code and 
			 production_date >= @date_from and
			 production_date <= @date_to

	-- Update Head Office values.
	select @ho_sched_sum = isnull(sum(scheduled_qty + spare_qty),0),
			 @ho_actual_sum = isnull(sum(production_qty),0)
	  from production_output,
			 npu_request n
	 where n.branch_code = @branch_code and
			 n.request_no = production_output.request_no and
			 n.request_source = 'H' and
			 output_category = @output_code and 
			 production_date >= @date_from and
			 production_date <= @date_to

	update #report_items 
		set branch_sched = @branch_sched_sum,
			 branch_actual = @branch_actual_sum,
			 prod_sched = @prod_sched_sum,
			 prod_actual = @prod_actual_sum,
			 ho_sched = @ho_sched_sum,
			 ho_actual = @ho_actual_sum
	 where #report_items.branch_code = @branch_code and
			 #report_items.output_code = @output_code

	fetch item_csr into @branch_code, @output_code
end

close item_csr
deallocate item_csr

/*
 * Return Dataset
 */

  select country_code,
         branch_code,
         branch,
 	      output_cat,
	      branch_sched,
 	      branch_actual,
	      prod_sched,
	      prod_actual,
	      ho_sched,
	      ho_actual
    from #report_items
order by output_cat,
         country_code,
         branch_code

return 0
GO
