/****** Object:  StoredProcedure [dbo].[p_slide_team_resync]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_team_resync]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_team_resync]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_team_resync] @team_id	integer
with recompile as

/*
 * Declare Variables
 */

declare @error        				integer,
        @rowcount     				integer,
        @errorode							integer,
        @new_start					datetime,
        @new_end						datetime,
        @last_end						datetime,
        @team_branch					char(2),
        @team_rep_id					integer,
        @rep_id						integer,
        @loop							integer,
        @date_csr_open				tinyint,
        @team_csr_open				tinyint,
        @end_flag						tinyint

/*
 * Select Team Information
 */

select @team_branch = st.team_branch
  from sales_team st
 where st.team_id = @team_id

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error retrieving team information. Team Re-Sync Failed.', 16, 1)
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
       @team_csr_open = 0

/*
 * Update Targets for Reps Not in Team
 */

update rep_slide_targets
	set team_id = null
 where team_id = @team_id and
       rep_id not in (select rep_id from team_reps where team_id = @team_id)

select @error = @@error
if (@error !=0)
begin
	rollback transaction
	goto error
end	

 declare team_csr cursor static for
  select tr.team_rep_id,
         tr.rep_id
    from team_reps tr
   where tr.team_id = @team_id
order by tr.rep_id
     for read only

/*
 * Loop through reps in the Team
 */
open team_csr
select @team_csr_open = 1
fetch team_csr into @team_rep_id, @rep_id
while(@@fetch_status = 0)
begin

	/*
	 * Initialise Variables
	 */
	
	select @loop = 0,
			 @end_flag = 0
	
	 declare date_csr cursor static for
	  select start_period,
	         end_period
	    from team_rep_dates trd
	   where trd.team_rep_id = @team_rep_id
	order by trd.start_period
	     for read only
	
	/*
	 * Loop Team Rep Dates
	 */
	open date_csr
	select @date_csr_open = 1
	fetch date_csr into @new_start, @new_end
	while(@@fetch_status = 0)
	begin
	
		select @loop = @loop + 1,
				 @end_flag = 0
	
		/*
		 * Insert Figures Accredited to the Team Prior to this Start Date
		 */
	
		if(@loop = 1)
		begin
	
			update rep_slide_targets
				set team_id = null
			  from rep_slide_targets rst,
					 sales_period sp
			 where rst.rep_id = @rep_id and
					 rst.branch_code = @team_branch and
					 rst.team_id = @team_id and
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
				set team_id = null
			  from rep_slide_targets rst,
					 sales_period sp
			 where rst.rep_id = @rep_id and
					 rst.branch_code = @team_branch and
					 rst.team_id = @team_id and
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
		 * Insert Figures Not Accredited to the Team That falls between this period
		 */
	
		if(@new_end is null)
		begin
	
			update rep_slide_targets
				set team_id = @team_id
			  from rep_slide_targets rst,
					 sales_period sp
			 where rst.rep_id = @rep_id and
					 rst.branch_code = @team_branch and
              ( rst.team_id <> @team_id or
                rst.team_id is null ) and
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
				set team_id = @team_id
			  from rep_slide_targets rst,
					 sales_period sp
			 where rst.rep_id = @rep_id and
					 rst.branch_code = @team_branch and
              ( rst.team_id <> @team_id or
                rst.team_id is null ) and
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
	 * Insert Figures Accredited to the Team After the Last End Date
	 */
	
	if(@end_flag = 1)
	begin
	
		update rep_slide_targets
			set team_id = null
		  from rep_slide_targets rst,
				 sales_period sp
		 where rst.rep_id = @rep_id and
				 rst.branch_code = @team_branch and
				 rst.team_id = @team_id and
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
		 * If Rep has No Dates then Remove all Instances of the Team
		 */
	
		update rep_slide_targets
			set team_id = null
		 where rep_id = @rep_id and
				 team_id = @team_id
	
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

	fetch team_csr into @team_rep_id, @rep_id

end
close team_csr
deallocate team_csr
select @team_csr_open = 0

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	if (@team_csr_open = 1)
   begin
		close team_csr
		deallocate team_csr
	end

	if (@date_csr_open = 1)
   begin
		close date_csr
		deallocate date_csr
	end

	return -1
GO
