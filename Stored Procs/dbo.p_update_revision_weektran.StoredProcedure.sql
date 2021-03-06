/****** Object:  StoredProcedure [dbo].[p_update_revision_weektran]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_update_revision_weektran]
GO
/****** Object:  StoredProcedure [dbo].[p_update_revision_weektran]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   proc [dbo].[p_update_revision_weektran]		@arg_package_id int,
@arg_screening_date	datetime,@arg_revision_no int, @arg_revision_status_code char(1)

as
set nocount on 
declare  @error						integer

/*
 * Begin Transaction
 */

begin transaction

select @error = 0

if IsNull((select count(*) from campaign_package_ins_xref where package_id = @arg_package_id and screening_date = @arg_screening_date and revision_no = @arg_revision_no and revision_status_code = @arg_revision_status_code),0) = 0
begin
    delete	campaign_package_ins_xref
    where	package_id = @arg_package_id and
		screening_date = @arg_screening_date and 
		revision_no = @arg_revision_no

    insert into campaign_package_ins_xref
    (   package_id,
        screening_date,
        revision_no,
        revision_status_code)
    values
    (   @arg_package_id,
        @arg_screening_date,
        @arg_revision_no,
        @arg_revision_status_code)    
        
    select @error = @@error
end

if @error <> 0    
begin
    rollback transaction
    raiserror ('Error: Failed to update the weekly revision transaction table.', 16, 1)
    return -1
end

/*
 * Commit Transaction
 */

commit transaction
return 0
GO
