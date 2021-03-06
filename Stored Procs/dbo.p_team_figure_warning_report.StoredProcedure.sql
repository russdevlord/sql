/****** Object:  StoredProcedure [dbo].[p_team_figure_warning_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_team_figure_warning_report]
GO
/****** Object:  StoredProcedure [dbo].[p_team_figure_warning_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_team_figure_warning_report]
as
set nocount on 
declare @error        				integer,
        @rowcount     				integer,
        @reps_csr_status      	integer,
        @errorode							integer,
        @rep_id						integer,
        @team_id						integer,
        @rep_warning					char(1)

create table #active_teams_reps
(
   team_id				integer		null,
   rep_id				integer		null,
   team_rep_status	char(1)		null,
   rep_warning			char(1)		null
)

insert into #active_teams_reps
select tr.team_id,
       tr.rep_id,
       tr.team_rep_status,
       'N'
  from sales_team st,
       team_reps tr
 where st.team_id = tr.team_id and
       st.team_status = 'A'

 declare reps_csr cursor static for
  select atr.team_id,
         atr.rep_id
    from #active_teams_reps atr
order by atr.team_id,
         atr.rep_id
     for read only

open reps_csr
fetch reps_csr into @team_id, @rep_id
select @reps_csr_status = @@fetch_status
while(@reps_csr_status = 0)
begin

   -- Set for Output Variable mode
   select @rep_warning = 'V'

   exec @errorode = p_slide_team_rep_check @team_id, @rep_id, @rep_warning Output
   if (@errorode !=0)
   begin
      return -1
   end

   update #active_teams_reps
      set rep_warning = @rep_warning
    where team_id = @team_id and
          rep_id = @rep_id

   fetch reps_csr into @team_id, @rep_id
   select @reps_csr_status = @@fetch_status
end
deallocate  reps_csr

/*
 * Return Success
 */

select st.team_id,
       st.team_branch,
       tb.branch_name as team_branch_name,
       st.team_code,
       st.team_name,
       st.team_status,
       sr.rep_id,
       sr.branch_code as rep_branch,
       srb.branch_name as rep_branch_name,
       sr.rep_code,
       sr.first_name,
       sr.last_name,
       sr.status as rep_status,
       atr.team_rep_status,
       atr.rep_warning
  from #active_teams_reps atr,
       sales_team st,
       sales_rep sr,
       branch tb,
       branch srb
 where atr.team_id = st.team_id and
       atr.rep_id = sr.rep_id and
       st.team_branch = tb.branch_code and
       sr.branch_code = srb.branch_code and
       atr.rep_warning = 'Y'

return 0
GO
