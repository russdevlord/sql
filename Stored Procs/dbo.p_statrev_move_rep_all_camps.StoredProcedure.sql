/****** Object:  StoredProcedure [dbo].[p_statrev_move_rep_all_camps]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_move_rep_all_camps]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_move_rep_all_camps]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_statrev_move_rep_all_camps]		@new_rep_id						int,
														@old_rep_id						int,
														@revenue_period					datetime,
														@change_date					datetime
														
																							
as

declare			@error								int,
						@campaign_no			int
						
set nocount on

declare		campaign_csr cursor for
select		distinct campaign_no 
from			statrev_revision_rep_xref, 
					v_statrev 
where		statrev_revision_rep_xref.revision_id = v_statrev.revision_id 
and				rep_id = @old_rep_id 
and				revenue_period >= @revenue_period
group by	campaign_no
having		sum(cost) > 0
order by	campaign_no
for				read only

begin transaction

open campaign_csr
fetch campaign_csr into @campaign_no
while(@@fetch_status = 0)
begin
	
	print	@campaign_no

	exec	@error = p_statrev_move_sales_rep @campaign_no, @revenue_period, @old_rep_id, @new_rep_id, @change_date

	if @error <> 0
	begin
		raiserror ('Error moving rep revenue', 16, 1)
		rollback transaction
		return -1
	end
	
	fetch campaign_csr into @campaign_no
end

commit transaction
return 0
GO
