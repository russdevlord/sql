/****** Object:  StoredProcedure [dbo].[p_area_figure_warning_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_area_figure_warning_report]
GO
/****** Object:  StoredProcedure [dbo].[p_area_figure_warning_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_area_figure_warning_report]
as

declare @error        				integer,
        @rowcount     				integer,
        @reps_csr_status      	integer,
        @errorode							integer,
        @rep_id						integer,
        @area_id						integer,
        @rep_warning					char(1)

create table #active_area_reps
(
   area_id				integer		null,
   rep_id				integer		null,
   area_rep_status	char(1)		null,
   rep_warning			char(1)		null
)

insert into #active_area_reps
select ar.area_id,
       ar.rep_id,
       ar.area_rep_status,
       'N'
  from sales_area sa,
       area_reps ar
 where sa.area_id = ar.area_id and
       sa.area_status = 'A'

 declare reps_csr cursor static for
  select aar.area_id,
         aar.rep_id
    from #active_area_reps aar
order by aar.area_id,
         aar.rep_id
     for read only

open reps_csr
fetch reps_csr into @area_id, @rep_id
select @reps_csr_status = @@fetch_status
while(@reps_csr_status = 0)
begin

   -- Set for Output Variable mode
   select @rep_warning = 'V'

   exec @errorode = p_slide_area_rep_check @area_id, @rep_id, @rep_warning Output
   if (@errorode !=0)
   begin
      return -1
   end

   update #active_area_reps
      set rep_warning = @rep_warning
    where area_id = @area_id and
          rep_id = @rep_id

   fetch reps_csr into @area_id, @rep_id
   select @reps_csr_status = @@fetch_status
end
close reps_csr
deallocate reps_csr

/*
 * Return Success
 */

select sa.area_id,
       sa.area_branch,
       tb.branch_name as area_branch_name,
       sa.area_code,
       sa.area_name,
       sa.area_status,
       sr.rep_id,
       sr.branch_code as rep_branch,
       srb.branch_name as rep_branch_name,
       sr.rep_code,
       sr.first_name,
       sr.last_name,
       sr.status as rep_status,
       aar.area_rep_status,
       aar.rep_warning
  from #active_area_reps aar,
       sales_area sa,
       sales_rep sr,
       branch tb,
       branch srb
 where aar.area_id = sa.area_id and
       aar.rep_id = sr.rep_id and
       sa.area_branch = tb.branch_code and
       sr.branch_code = srb.branch_code and
       aar.rep_warning = 'Y'

return 0
GO
