/****** Object:  StoredProcedure [dbo].[p_update_ctrl_pod_user]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_update_ctrl_pod_user]
GO
/****** Object:  StoredProcedure [dbo].[p_update_ctrl_pod_user]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_update_ctrl_pod_user]		@control_group		int,
										@login_id			varchar(30),
										@pod_order			int,
										@mode				int

as

declare		@error		int

set nocount on

/*
 * Begin transaction
 */

begin transaction

/*
 * Mode 1 Insert new row
 */

if @mode = 1
begin
	insert into control_pod_user
	(control_group,
	login_id,
	pod_order) values
	(@control_group,
	@login_id,
	@pod_order)

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error adding pod', 16, 1)
		rollback transaction 
		return -1
	end
end

/*
 * Mode 2 Update existing row
 */

if @mode = 2
begin

	update 	control_pod_user
	set		pod_order = @pod_order
	where	control_group = @control_group
	and		login_id = @login_id

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error changing pod', 16, 1)
		rollback transaction 
		return -1
	end
end

/*
 * Mode 3 Delete current row
 */

if @mode = 3 
begin

	delete 	control_pod_user
	where	control_group = @control_group
	and		login_id = @login_id

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error removing pod', 16, 1)
		rollback transaction 
		return -1
	end

end

commit transaction
return 0
GO
