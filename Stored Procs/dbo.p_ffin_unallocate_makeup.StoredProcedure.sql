/****** Object:  StoredProcedure [dbo].[p_ffin_unallocate_makeup]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_unallocate_makeup]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_unallocate_makeup]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_ffin_unallocate_makeup] @makeup_spot_id		int
                                      
as
set nocount on 
declare @error                          int,
        @source_spot_type               char(1),
        @source_spot_status             char(1),
        @spot_liability_id              int,
        @complex_id                     int,
        @liability_type                 tinyint,
        @allocation_id                  int,
        @creation_period                datetime,
        @release_period                 datetime,
        @spot_amount                    money,
        @cinema_amount                  money,
        @cancelled                      tinyint,
        @cnt                            int,
        @dest_complex_id                int,
        @dest_liability_type            tinyint,
        @cur_src_spot_libility_open     char(1),
        @unalloc_spot_id                int,
        @spot_redirect                  int ,
		@errorode							int,
		@spot_type						char(1)	

/*
 * Begin Transaction
 */
 
begin transaction

select 	@spot_redirect = spot_redirect,
		@complex_id = complex_id,
		@spot_type = spot_type
from 	campaign_spot
where 	spot_id = @makeup_spot_id
 
if @@error != 0 
begin
    raiserror ('p_ffin_allocate_makeup.Cannot determine if makeup spot has been made up', 16, 1)
    goto ERROR
end

if @spot_redirect is not null
begin
    raiserror ('p_ffin_allocate_makeup.Makeup spot has already been redirected to another spot', 16, 1)
    goto ERROR
end
 
select @unalloc_spot_id = spot_id,
       @dest_complex_id = complex_id 
  from campaign_spot
 where spot_redirect = @makeup_spot_id
 
if @@error != 0 
begin
    raiserror ('p_ffin_allocate_makeup.Unallocated spot id not found', 16, 1)
    goto ERROR
end

if @makeup_spot_id is null or @unalloc_spot_id is null
begin
    raiserror ('p_ffin_allocate_makeup.Makeup\Unallocated spot id is NULL', 16, 1)
    goto ERROR
end

/*
 * Remove Spot Redirect
 */
 
update campaign_spot 
   set spot_redirect = null
 where spot_redirect = @makeup_spot_id

select @error = @@error
if @error != 0
    goto error

/*
 * Source spot must(?????) have liability records
 */
 
select @cnt = count(spot_id)
  from spot_liability 
 where spot_id = @makeup_spot_id

select @error = @@error
if @error != 0
    goto ERROR

if IsNull(@cnt, 0) = 0
begin
    commit transaction
    return 0
end

select 	@cnt = count(spot_id)
from 	spot_liability 
where 	spot_id = @makeup_spot_id
and		release_period is not null

select @error = @@error
if @error != 0
    goto ERROR

if not isnull(@cnt ,0) = 0
begin
    raiserror ('Error : Cannot delete a makeup whose spot liability has been released.', 16, 1)
	goto error
end

execute @errorode = p_ffin_move_spot_liability	@makeup_spot_id, @unalloc_spot_id, @complex_id, @dest_complex_id
if(@@error != 0)
	goto error

if @spot_type = 'M' or @spot_type = 'Y' or @spot_type = 'V'
begin

	delete spot_liability where spot_id = @makeup_spot_id

	select @error = @@error
	if @error != 0
	    goto ERROR

end

commit transaction
return 0


ERROR:
    if @cur_src_spot_libility_open = 'y'
        close cur_src_spot_libility
    raiserror ('Error : Failed to unallocate makeup spot.', 16, 1)
    rollback transaction
    return -1
GO
