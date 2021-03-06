/****** Object:  StoredProcedure [dbo].[p_address_create_in_xref]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_address_create_in_xref]
GO
/****** Object:  StoredProcedure [dbo].[p_address_create_in_xref]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_address_create_in_xref]    @address_id int,
										@pk_int  int,
										@pk_char varchar(20),
                                        @address_type char(3),
                                        @address_category char(3)
                                        
as
/* Proc name:   p_address_create_in_xref
 * Author:      Victoria Tyshcehnko
 * Date:        12-oct-2004
 * Description: Creates entrance in address_xref_table
 *
*/ 

declare @error        				int,
        @err_msg                    varchar(150),
      --  @error                         int,
        @address_xref_id            int

execute @error = p_get_sequence_number 'address_xref', 5, @address_xref_id OUTPUT
if (@error !=0)
	return -1

begin transaction

    INSERT INTO dbo.address_xref 
              ( address_xref_id, 
                address_id, 
                version_no, 
                address_owner_pk_int, 
                address_owner_pk_char, 
                address_type_code, 
                address_category_code, 
                send_method, 
                last_updated, 
                employee_id) 
    VALUES (    @address_xref_id, 
                @address_id,
                1,
                @pk_int, 
                @pk_char, 
                @address_type, 
                @address_category, 
                'P', 
                getdate(), 
                1) 
    select @error = @@error
    if (@error !=0)
        goto rollbackerror

commit transaction

return 0

rollbackerror:
    rollback transaction
error:
    deallocate cinagree_csr
    if @error >= 50000
        raiserror (@err_msg, 16, 1)

    return -100
GO
