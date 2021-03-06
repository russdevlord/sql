/****** Object:  StoredProcedure [dbo].[p_film_team_rep_check]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_team_rep_check]
GO
/****** Object:  StoredProcedure [dbo].[p_film_team_rep_check]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_film_team_rep_check]  @team_id	integer,
                                   @rep_id   integer,
                                   @mode		char(1) Output
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
        @loop							integer,
        @date_csr_open				tinyint,
        @end_flag						tinyint

/*
 * Declare Temporary Table
 */

create table #figures
(
	figure_id		integer		null,
	figure_fcope	tinyint		null
)



/*
 * Select Sales Manager Rep Id and Branch
 */

select @team_rep_id = ar.team_rep_id,
       @team_branch = sa.team_branch
  from film_team_reps ar,
       film_sales_team sa
 where ar.team_id = @team_id and
       ar.rep_id = @rep_id and
       ar.team_id = sa.team_id

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error retrieving Sales Manager rep information. Area Rep Check Failed.', 16, 1)
	return -1
end

/*
 * Initialise Variables
 */

select @loop = 0,
       @date_csr_open = 0

/*
 * Declare Cursor
 */ 
 
 declare date_csr cursor static for
  select start_period,
         end_period
    from film_team_rep_dates ard
   where ard.team_rep_id = @team_rep_id
order by ard.start_period
     for read only

/*
 * Loop Sales Manager Rep Dates
 */

open date_csr
select @date_csr_open = 1
fetch date_csr into @new_start, @new_end
while(@@fetch_status = 0)
begin

	select @loop = @loop + 1,
          @end_flag = 0

	/*
    * Insert Figures Accredited to the Sales Manager Prior to this Start Date
    */

	if(@loop = 1)
	begin

		insert into #figures
		select ff.figure_id,
             1
        from film_figures ff,
             film_campaign fc
		 where ff.campaign_no = fc.campaign_no and
				 ff.rep_id = @rep_id and
				 ff.team_id = @team_id and
				 ff.branch_code = @team_branch and
				 fc.start_date < @new_start

		select @rowcount = @@rowcount
		if(@rowcount > 0 and @mode = 'C')
		begin
			close date_csr
			select 'Y'
			return 0
		end

		if(@rowcount > 0 and @mode = 'V')
		begin
			close date_csr
			select @mode = 'Y'
			return 0
		end
		
	end
	else
	begin

		insert into #figures
		select ff.figure_id,
             1
        from film_figures ff,
             film_campaign fc
		 where ff.campaign_no = fc.campaign_no and
				 ff.rep_id = @rep_id and
				 ff.team_id = @team_id and
				 ff.branch_code = @team_branch and
				 fc.start_date > @last_end and
             fc.start_date < @new_start

		select @rowcount = @@rowcount
		if(@rowcount > 0 and @mode = 'C')
		begin
			close date_csr
			select 'Y'
			return 0
		end

		if(@rowcount > 0 and @mode = 'V')
		begin
			close date_csr
			select @mode = 'Y'
			return 0
		end

	end

	/*
    * Insert Figures Not Accredited to the Sales Manager that falls between this period
    */

	if(@new_end is null)
	begin

		insert into #figures
		select ff.figure_id,
             0
        from film_figures ff,
             film_campaign fc
		 where ff.campaign_no = fc.campaign_no and
		       ff.rep_id = @rep_id and
             ( ff.team_id <> @team_id or ff.team_id is null ) and
				 ff.branch_code = @team_branch and
				 fc.start_date >= @new_start

		select @rowcount = @@rowcount
		if(@rowcount > 0 and @mode = 'C')
		begin
			close date_csr
			select 'Y'
			return 0
		end

		if(@rowcount > 0 and @mode = 'V')
		begin
			close date_csr
			select @mode = 'Y'
			return 0
		end
		
	end
	else
	begin

		select @end_flag = 1

		insert into #figures
		select ff.figure_id,
             0
        from film_figures ff,
             film_campaign fc
		 where ff.campaign_no = fc.campaign_no and
		       ff.rep_id = @rep_id and
             ( ff.team_id <> @team_id or ff.team_id is null ) and
				 ff.branch_code = @team_branch and
				 fc.start_date >= @new_start and
             fc.start_date <= @new_end

		select @rowcount = @@rowcount
		if(@rowcount > 0 and @mode = 'C')
		begin
			close date_csr
			select 'Y'
			return 0
		end

		if(@rowcount > 0 and @mode = 'V')
		begin
			close date_csr
			select @mode = 'Y'
			return 0
		end

	end

	/*
    * Fetch Next
    */

	select @last_end = @new_end
	fetch date_csr into @new_start, @new_end

end
close date_csr
select @date_csr_open = 0

/*
 * Insert Figures Accredited to the Team After the Last End Date
 */

if(@end_flag = 1)
begin

	insert into #figures
	select ff.figure_id,
			 1
     from film_figures ff,
          film_campaign fc
    where ff.campaign_no = fc.campaign_no and
	       ff.rep_id = @rep_id and
			 ff.team_id = @team_id and
			 ff.branch_code = @team_branch and
			 fc.start_date > @last_end

	select @rowcount = @@rowcount
	if(@rowcount > 0 and @mode = 'C')
	begin
		select 'Y'
		return 0
	end

	if(@rowcount > 0 and @mode = 'V')
	begin
		close date_csr
		select @mode = 'Y'
		return 0
	end

end

/*
 * Return Dataset
 */

if(@mode = 'C')
	select 'N'
else if(@mode = 'V')
	select @mode = 'N'
else	
	select ff.figure_id,   
			 ff.campaign_no,   
			 @rep_id,
			 ff.team_id,   
			 ff.origin_period,   
			 ff.creation_period,   
			 ff.release_period,   
			 ff.figure_type,   
			 ff.figure_status,   
			 ff.figure_category,   
			 ff.gross_amount,   
			 ff.nett_amount,   
			 ff.comm_amount,   
			 ff.figure_reason,   
			 ff.figure_official,   
			 fc.start_date,   
			 fc.product_desc,   
          fc.confirmed_cost,   
			 rep.first_name,   
			 rep.last_name,
			 ff.team_id  
	  from film_figures ff,   
			 film_campaign fc,
			 sales_rep rep,
			 #figures  
	 where #figures.figure_id = ff.figure_id and
			 ff.campaign_no = fc.campaign_no and  
			 ff.rep_id = rep.rep_id and
        ((@mode = 'O' and #figures.figure_fcope = 0) or
         (@mode = 'I' and #figures.figure_fcope = 1))

/*
 * Return Success
 */

return 0
GO
