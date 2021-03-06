/****** Object:  StoredProcedure [dbo].[p_slide_area_resync]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_area_resync]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_area_resync]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_slide_area_resync] @area_id	integer
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
        @area_branch					char(2),
        @area_rep_id					integer,
        @rep_id						integer,
        @loop							integer,
        @date_csr_open				tinyint,
        @area_csr_open				tinyint,
        @end_flag						tinyint


/*
 * Select Sales Manager ( Area ) Information
 */

select @area_branch = sa.area_branch
  from sales_area sa
 where sa.area_id = @area_id

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error retrieving Sales Manager information. Sales Manager Team Re-Sync Failed.', 16, 1)
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
       @area_csr_open = 0

/*
 * Update Targets for Reps Not in Area
 */

update rep_slide_targets
	set area_id = null
 where area_id = @area_id and
       rep_id not in (select rep_id from area_reps where area_id = @area_id)

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	goto error
end	

/*
 * Loop through reps in the Area
 */

 declare area_csr cursor static for
  select ar.area_rep_id,
         ar.rep_id
    from area_reps ar
   where ar.area_id = @area_id
order by ar.rep_id
     for read only

open area_csr
select @area_csr_open = 1
fetch area_csr into @area_rep_id, @rep_id
while(@@fetch_status = 0)
begin

	/*
	 * Initialise Variables
	 */
	
	select @loop = 0,
			 @end_flag = 0
	
	/*
	 * Loop Area Rep Dates
	 */
	
	declare date_csr cursor static for
	  select start_period,
	         end_period
	    from area_rep_dates ard
	   where ard.area_rep_id = @area_rep_id
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
		 * Insert Figures Accredited to the Area Prior to this Start Date
		 */
	
		if(@loop = 1)
		begin
	
			update rep_slide_targets
				set area_id = null
			  from rep_slide_targets rst,
					 sales_period sp
			 where rst.rep_id = @rep_id and
					 rst.branch_code = @area_branch and
					 rst.area_id = @area_id and
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
				set area_id = null
			  from rep_slide_targets rst,
					 sales_period sp
			 where rst.rep_id = @rep_id and
					 rst.branch_code = @area_branch and
					 rst.area_id = @area_id and
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
		 * Insert Figures Not Accredited to the Area That falls between this period
		 */
	
		if(@new_end is null)
		begin
	
			update rep_slide_targets
				set area_id = @area_id
			  from rep_slide_targets rst,
					 sales_period sp
			 where rst.rep_id = @rep_id and
					 rst.branch_code = @area_branch and
              ( rst.area_id <> @area_id or
                rst.area_id is null ) and
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
				set area_id = @area_id
			  from rep_slide_targets rst,
					 sales_period sp
			 where rst.rep_id = @rep_id and
					 rst.branch_code = @area_branch and
              ( rst.area_id <> @area_id or
                rst.area_id is null ) and
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
	 * Insert Figures Accredited to the Area After the Last End Date
	 */
	
	if(@end_flag = 1)
	begin
	
		update rep_slide_targets
			set area_id = null
		  from rep_slide_targets rst,
				 sales_period sp
		 where rst.rep_id = @rep_id and
				 rst.branch_code = @area_branch and
				 rst.area_id = @area_id and
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
		 * If Rep has No Dates then Remove all Instances of the Area
		 */
	
		update rep_slide_targets
			set area_id = null
		 where rep_id = @rep_id and
				 area_id = @area_id
	
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

	fetch area_csr into @area_rep_id, @rep_id

end
close area_csr
deallocate area_csr
select @area_csr_open = 0

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	if (@area_csr_open = 1)
   begin
		close area_csr
		deallocate area_csr
	end

	if (@date_csr_open = 1)
   begin
		close date_csr
		deallocate date_csr
	end

	return -1
GO
