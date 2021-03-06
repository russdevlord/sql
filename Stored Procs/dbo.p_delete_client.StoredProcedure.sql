/****** Object:  StoredProcedure [dbo].[p_delete_client]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_delete_client]
GO
/****** Object:  StoredProcedure [dbo].[p_delete_client]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_delete_client]		@client_id		integer

as

declare @error          int,
        @rowcount			int

if exists (select 1
             from film_campaign
            where client_id = @client_id)
begin
	raiserror ('Client is assigned to a film campaign and cannot be deleted.', 16, 1)
	return -1
end

/*
 * Begin Transaction
 */

begin transaction


/*
 * Delete  product_report_group_client_xref
 */

delete product_report_group_client_xref
from client_product
 where client_id = @client_id
and product_report_group_client_xref.client_product_id = client_product.client_product_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete client product.
 */

delete client_product
 where client_id = @client_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	


/*
 * Delete account
 */

delete account
 where client_id = @client_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Delete client
 */

delete client
 where client_id = @client_id
select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return -1
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
