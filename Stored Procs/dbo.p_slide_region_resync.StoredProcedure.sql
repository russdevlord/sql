/****** Object:  StoredProcedure [dbo].[p_slide_region_resync]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_region_resync]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_region_resync]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_region_resync] @region_id	integer
with recompile as
set nocount on 
/*
 * Declare Variables
 */

declare @error        				integer,
        @rowcount     				integer,
        @errorode							integer,
        @new_start					datetime,
        @new_end						datetime,
        @last_end						datetime,
        @region_branch				char(2),
        @region_rep_id				integer,
        @rep_id						integer,
        @loop							integer,
        @date_csr_open				tinyint,
        @region_csr_open			tinyint,
        @end_flag						tinyint


/*
 * Select Sales Manager ( region ) Information
 */

select @region_branch = sa.region_branch
  from sales_region sa
 where sa.region_id = @region_id

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error retrieving Sales Region information. Sales Region Re-Sync Failed.', 16, 1)
	goto error
end

/*
 * Begin Transaction
 */

begin transaction

/*
 * Initalise Variables
 */

select @date_csr_open = 0,
       @region_csr_open = 0

/*
 * Update Targets for Reps Not in region
 */

update rep_slide_targets
	set region_id = null
 where region_id = @region_id and
       rep_id not in (select rep_id from region_reps where region_id = @region_id)

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	goto error
end	


 declare region_csr cursor static for
  select ar.region_rep_id,
         ar.rep_id
    from region_reps ar
   where ar.region_id = @region_id
order by ar.rep_id
     for read only

/*
 * Loop through reps in the region
 */
open region_csr
select @region_csr_open = 1
fetch region_csr into @region_rep_id, @rep_id
while(@@fetch_status = 0)
begin

	/*
	 * Initialise Variables
	 */
	
	select @loop = 0,
			 @end_flag = 0
	
	/*
	 * Loop region Rep Dates
	 */
	
	 declare date_csr cursor static for
	  select start_period,
	         end_period
	    from region_rep_dates ard
	   where ard.region_rep_id = @region_rep_id
	order by ard.start_period
	     for read only

	open date_csr
	select @date_csr_open = 1
	fetch date_csr into @new_start, @new_end
	while(@@fetch_status = 0)
	begin
	
		select @loop = @loop + 1,
				 @end_flag = 0
	
		/*
		 * Insert Figures Accredited to the region Prior to this Start Date
		 */
	
		if(@loop = 1)
		begin
	
			update rep_slide_targets
				set region_id = null
			  from rep_slide_targets rst,
					 sales_period sp
			 where rst.rep_id = @rep_id and
					 rst.branch_code = @region_branch and
					 rst.region_id = @region_id and
					 rst.sales_period = sp.sales_period_end and
					 sp.status in ('F','O') and
					 sp.sales_period_end < @new_start
	
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	
	
		end
		else
		begin
	
			update rep_slide_targets
				set region_id = null
			  from rep_slide_targets rst,
					 sales_period sp
			 where rst.rep_id = @rep_id and
					 rst.branch_code = @region_branch and
					 rst.region_id = @region_id and
					 rst.sales_period = sp.sales_period_end and
					 sp.status in ('F','O') and
					 sp.sales_period_end > @last_end and
					 sp.sales_period_end < @new_start
	
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	
	
		end
	
		/*
		 * Insert Figures Not Accredited to the region That falls between this period
		 */
	
		if(@new_end is null)
		begin
	
			update rep_slide_targets
				set region_id = @region_id
			  from rep_slide_targets rst,
					 sales_period sp
			 where rst.rep_id = @rep_id and
					 rst.branch_code = @region_branch and
              ( rst.region_id <> @region_id or
                rst.region_id is null ) and
					 rst.sales_period = sp.sales_period_end and
					 sp.status in ('F','O') and
					 sp.sales_period_end >= @new_start
	
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	
		
		end
		else
		begin
	
			select @end_flag = 1
	
			update rep_slide_targets
				set region_id = @region_id
			  from rep_slide_targets rst,
					 sales_period sp
			 where rst.rep_id = @rep_id and
					 rst.branch_code = @region_branch and
              ( rst.region_id <> @region_id or
                rst.region_id is null ) and
					 rst.sales_period = sp.sales_period_end and
					 sp.status in ('F','O') and
					 sp.sales_period_end >= @new_start and
					 sp.sales_period_end <= @new_end
	
			select @error = @@error
			if (@error !=0)
			begin
				rollback transaction
				goto error
			end	
	
		end
	
		/*
		 * Fetch Next
		 */
	
		select @last_end = @new_end
		fetch date_csr into @new_start, @new_end
	
	end
	close date_csr
	deallocate date_csr
	select @date_csr_open = 0
	
	/*
	 * Insert Figures Accredited to the region After the Last End Date
	 */
	
	if(@end_flag = 1)
	begin
	
		update rep_slide_targets
			set region_id = null
		  from rep_slide_targets rst,
				 sales_period sp
		 where rst.rep_id = @rep_id and
				 rst.branch_code = @region_branch and
				 rst.region_id = @region_id and
				 rst.sales_period = sp.sales_period_end and
				 sp.status in ('F','O') and
				 sp.sales_period_end > @last_end
	
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	
	
	end
	
	if(@loop = 0)
	begin
	
		/*
		 * If Rep has No Dates then Remove all Instances of the region
		 */
	
		update rep_slide_targets
			set region_id = null
		 where rep_id = @rep_id and
				 region_id = @region_id
	
		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	
	
	end

	/*
    * Fetch Next
    */

	fetch region_csr into @region_rep_id, @rep_id

end
close region_csr
deallocate region_csr
select @region_csr_open = 0

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	if (@region_csr_open = 1)
   begin
		close region_csr
		deallocate region_csr
	end

	if (@date_csr_open = 1)
   begin
		close date_csr
		deallocate date_csr
	end

	return -1
GO
