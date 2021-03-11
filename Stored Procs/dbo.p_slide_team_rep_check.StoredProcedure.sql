/****** Object:  StoredProcedure [dbo].[p_slide_team_rep_check]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_team_rep_check]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_team_rep_check]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_team_rep_check] @team_id	integer,
                                   @rep_id   integer,
                                   @mode		char(1) Output
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
	figure_scope	tinyint		null
)

/*
 * Select Team Rep Id and Branch
 */

select @team_rep_id = tr.team_rep_id,
       @team_branch = st.team_branch
  from team_reps tr,
       sales_team st
 where tr.team_id = @team_id and
       tr.rep_id = @rep_id and
       tr.team_id = st.team_id

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error retrieving team rep information. Team Rep Check Failed.', 16, 1)
	return -1
end

/*
 * Initialise Variables
 */

select @loop = 0,
       @date_csr_open = 0


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

		insert into #figures
		select sf.figure_id,
             1
        from slide_figures sf,
             slide_campaign sc,
             slide_proposal sp
		 where sf.campaign_no = sc.campaign_no and
				 sc.campaign_no = sp.campaign_no and
				 sf.rep_id = @rep_id and
				 sf.team_id = @team_id and
				 sf.branch_code = @team_branch and
				 sp.creation_period < @new_start

		select @rowcount = @@rowcount
		if(@rowcount > 0 and @mode = 'C')
		begin
			close date_csr
			deallocate date_csr
			select 'Y'
			return 0
		end

		if(@rowcount > 0 and @mode = 'V')
		begin
			close date_csr
			deallocate date_csr
			select @mode = 'Y'
			return 0
		end
		
	end
	else
	begin

		insert into #figures
		select sf.figure_id,
             1
        from slide_figures sf,
             slide_campaign sc,
             slide_proposal sp
		 where sf.campaign_no = sc.campaign_no and
				 sc.campaign_no = sp.campaign_no and
				 sf.rep_id = @rep_id and
				 sf.team_id = @team_id and
				 sf.branch_code = @team_branch and
				 sp.creation_period > @last_end and
             sp.creation_period < @new_start

		select @rowcount = @@rowcount
		if(@rowcount > 0 and @mode = 'C')
		begin
			close date_csr
			deallocate date_csr
			select 'Y'
			return 0
		end

		if(@rowcount > 0 and @mode = 'V')
		begin
			close date_csr
			deallocate date_csr
			select @mode = 'Y'
			return 0
		end

	end

	/*
    * Insert Figures Not Accredited to the Team That falls between this period
    */

	if(@new_end is null)
	begin

		insert into #figures
		select sf.figure_id,
             0
        from slide_figures sf,
             slide_campaign sc,
             slide_proposal sp
		 where sf.campaign_no = sc.campaign_no and
				 sc.campaign_no = sp.campaign_no and
		       sf.rep_id = @rep_id and
             ( sf.team_id <> @team_id or sf.team_id is null ) and
				 sf.branch_code = @team_branch and
				 sp.creation_period >= @new_start

		select @rowcount = @@rowcount
		if(@rowcount > 0 and @mode = 'C')
		begin
			close date_csr
			deallocate date_csr
			select 'Y'
			return 0
		end

		if(@rowcount > 0 and @mode = 'V')
		begin
			close date_csr
			deallocate date_csr
			select @mode = 'Y'
			return 0
		end
		
	end
	else
	begin

		select @end_flag = 1

		insert into #figures
		select sf.figure_id,
             0
        from slide_figures sf,
             slide_campaign sc,
             slide_proposal sp
		 where sf.campaign_no = sc.campaign_no and
				 sc.campaign_no = sp.campaign_no and
		       sf.rep_id = @rep_id and
             ( sf.team_id <> @team_id or sf.team_id is null ) and
				 sf.branch_code = @team_branch and
				 sp.creation_period >= @new_start and
             sp.creation_period <= @new_end

		select @rowcount = @@rowcount
		if(@rowcount > 0 and @mode = 'C')
		begin
			close date_csr
			deallocate date_csr
			select 'Y'
			return 0
		end

		if(@rowcount > 0 and @mode = 'V')
		begin
			close date_csr
			deallocate date_csr
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
deallocate date_csr
select @date_csr_open = 0

/*
 * Insert Figures Accredited to the Team After the Last End Date
 */

if(@end_flag = 1)
begin

	insert into #figures
	select sf.figure_id,
			 1
     from slide_figures sf,
          slide_campaign sc,
          slide_proposal sp
    where sf.campaign_no = sc.campaign_no and
			 sc.campaign_no = sp.campaign_no and
	       sf.rep_id = @rep_id and
			 sf.team_id = @team_id and
			 sf.branch_code = @team_branch and
			 sp.creation_period > @last_end

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
	select sf.figure_id,   
			 sf.campaign_no,   
			 @rep_id,
          sf.business_group,   
			 sf.team_id,   
			 sf.area_id,
			 sf.region_id,
			 sf.origin_period,   
			 sf.creation_period,   
			 sf.release_period,   
			 sf.figure_type,   
			 sf.figure_status,   
			 sf.figure_category,   
			 sf.gross_amount,   
			 sf.nett_amount,   
			 sf.comm_amount,   
			 sf.release_value,   
			 sf.re_coupe_value,   
			 sf.branch_hold,   
			 sf.ho_hold,   
			 sf.figure_hold,   
			 sf.figure_reason,   
			 sf.figure_official,   
			 sp.creation_period,   
			 sc.name_on_slide,   
          sc.branch_release,   
          sc.npu_release,   
          sc.ho_release,   
          sc.campaign_release,   
          sc.nett_contract_value,   
			 rep.first_name,   
			 rep.last_name  
	  from slide_figures sf,   
			 slide_campaign sc,
          slide_proposal sp,   
			 sales_rep rep,
			 #figures  
	 where #figures.figure_id = sf.figure_id and
			 sf.campaign_no = sc.campaign_no and  
			 sc.campaign_no = sp.campaign_no and
			 sf.rep_id = rep.rep_id and
        ((@mode = 'O' and #figures.figure_scope = 0) or
         (@mode = 'I' and #figures.figure_scope = 1))

/*
 * Return Success
 */

return 0
GO
