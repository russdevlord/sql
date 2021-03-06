/****** Object:  StoredProcedure [dbo].[p_region_figure_warning_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_region_figure_warning_report]
GO
/****** Object:  StoredProcedure [dbo].[p_region_figure_warning_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_region_figure_warning_report]
as
set nocount on 
declare @error        		integer,
        @rowcount     		integer,
        @reps_csr_status      	integer,
        @errorode			integer,
        @rep_id			integer,
        @region_id		integer,
        @rep_warning		char(1)

create table #active_region_reps
(
   region_id				integer		null,
   rep_id				integer		null,
   region_rep_status	char(1)		null,
   rep_warning			char(1)		null
)

insert into #active_region_reps
select ar.region_id,
       ar.rep_id,
       ar.region_rep_status,
       'N'
  from sales_region sa,
       region_reps ar
 where sa.region_id = ar.region_id and
       sa.region_status = 'A'

 declare reps_csr cursor static for
  select aar.region_id,
         aar.rep_id
    from #active_region_reps aar
order by aar.region_id,
         aar.rep_id
     for read only

open reps_csr
fetch reps_csr into @region_id, @rep_id
select @reps_csr_status = @@fetch_status
while(@reps_csr_status = 0)
begin

   -- Set for Output Variable mode
   select @rep_warning = 'V'

   exec @errorode = p_slide_region_rep_check @region_id, @rep_id, @rep_warning Output
   if (@errorode !=0)
   begin
      return -1
   end

   update #active_region_reps
      set rep_warning = @rep_warning
    where region_id = @region_id and
          rep_id = @rep_id

   fetch reps_csr into @region_id, @rep_id
   select @reps_csr_status = @@fetch_status
end
close reps_csr
deallocate reps_csr

/*
 * Return Success
 */

select sa.region_id,
       sa.region_branch,
       tb.branch_name as region_branch_name,
       sa.region_code,
       sa.region_name,
       sa.region_status,
       sr.rep_id,
       sr.branch_code as rep_branch,
       srb.branch_name as rep_branch_name,
       sr.rep_code,
       sr.first_name,
       sr.last_name,
       sr.status as rep_status,
       aar.region_rep_status,
       aar.rep_warning
  from #active_region_reps aar,
       sales_region sa,
       sales_rep sr,
       branch tb,
       branch srb
 where aar.region_id = sa.region_id and
       aar.rep_id = sr.rep_id and
       sa.region_branch = tb.branch_code and
       sr.branch_code = srb.branch_code and
       aar.rep_warning = 'Y'

return 0
GO
