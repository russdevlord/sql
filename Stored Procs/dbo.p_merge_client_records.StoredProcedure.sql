/****** Object:  StoredProcedure [dbo].[p_merge_client_records]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_merge_client_records]
GO
/****** Object:  StoredProcedure [dbo].[p_merge_client_records]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  proc [dbo].[p_merge_client_records]		@master_client_id	int,
										@child_client_id	int

as

declare		@error			int

set nocount on

begin transaction

/*
 * Update Film Campaigns
 */

update 	film_campaign
set		client_id = @master_client_id
where	client_id = @child_client_id

select @error = @@error
if @error != 0 
begin
	raiserror ('Error: Failed to update Film Campaign', 16, 1)
	rollback transaction
	return -1
end 

update 	film_campaign
set		reporting_client = @master_client_id
where	reporting_client = @child_client_id

select @error = @@error
if @error != 0 
begin
	raiserror ('Error: Failed to update Film Campaign', 16, 1)
	rollback transaction
	return -1
end 

update 	film_campaign_reporting_client
set		client_id = @master_client_id
where	client_id = @child_client_id

select @error = @@error
if @error != 0 
begin
	raiserror ('Error: Failed to update Film Campaign', 16, 1)
	rollback transaction
	return -1
end 

/*
 * Update Client Products
 */

update 	client_product
set		client_id = @master_client_id
where	client_id = @child_client_id

select @error = @@error
if @error != 0 
begin
	raiserror ('Error: Failed to update Client Product', 16, 1)
	rollback transaction
	return -1
end 

/*
 * Update account
 */

update 	account
set		client_id = @master_client_id
where	client_id = @child_client_id

select @error = @@error
if @error != 0 
begin
	raiserror ('Error: Failed to update Account', 16, 1)
	rollback transaction
	return -1
end 

update 	client_notes
set		client_id = @master_client_id
where	client_id = @child_client_id

select @error = @@error
if @error != 0 
begin
	raiserror ('Error: Failed to update Client Product', 16, 1)
	rollback transaction
	return -1
end   
  
update 	adex_revenue
set		client_id = @master_client_id
where	client_id = @child_client_id

select @error = @@error
if @error != 0 
begin
	raiserror ('Error: Failed to update Client Product', 16, 1)
	rollback transaction
	return -1
end 
  
update 	client_prospect
set		client_id = @master_client_id
where	client_id = @child_client_id

select @error = @@error
if @error != 0 
begin
	raiserror ('Error: Failed to update Client Product', 16, 1)
	rollback transaction
	return -1
end 
  
/*
 * Update Client
 */

delete	client
where	client_id = @child_client_id

select @error = @@error
if @error != 0 
begin
	raiserror ('Error: Failed to deelte Client', 16, 1)
	rollback transaction
	return -1
end 



commit transaction
return 0
GO
