/****** Object:  StoredProcedure [dbo].[p_ffin_cl_allocate_makeup]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_cl_allocate_makeup]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_cl_allocate_makeup]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_ffin_cl_allocate_makeup]	@source_spot_id		    int,
                                    @destination_spot_id    int

as

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
            @source_cinema_rate             money,
@source_complex	int,
@errorode int


begin transaction                                     

if IsNull(@source_spot_id, 0)= 0 or IsNull(@destination_spot_id, 0) = 0
begin
    raiserror ('p_ffin_cl_allocate_makeup.Source/Dest spot id is NULL', 16, 1)
    goto ERROR
end 

/* 
 * Source spot must be Unallocated or No Show
 */

select @source_spot_status = spot_status,
       @source_spot_type = spot_type,
       @source_cinema_rate = cinema_rate,
		@source_complex = c.complex_id
  from cinelight_spot as cp
    inner join cinelight as c on c.cinelight_id = cp.cinelight_id
 where spot_id = @source_spot_id

if @@error != 0 and @@rowcount != 1
    goto ERROR

if @source_spot_status != 'U' and  @source_spot_status != 'N'
begin
    raiserror ('p_ffin_cl_allocate_makeup.Source spot must be Unallocated or No Show', 16, 1)
    goto ERROR
end 

/*
 *   Create spot_redirect on the Source Campaign Spot
 */

update cinelight_spot
   set spot_redirect = @destination_spot_id
 where spot_id = @source_spot_id

if @@error != 0 or @@rowcount != 1
begin
    raiserror ('p_ffin_cl_allocate_makeup.DB error <update campaign_spot>', 16, 1)
    goto ERROR
end


/*
 *   Change Cinema Rate to be old cinema rate
 */

update cinelight_spot
   set cinema_rate = @source_cinema_rate
 where spot_id =  @destination_spot_id

if @@error != 0 or @@rowcount != 1
begin
    raiserror ('p_ffin_cl_allocate_makeup.DB error <update campaign_spot>', 16, 1)
    goto ERROR
end


/*
 * Check if Source Spot has liability records 
 */

select @cnt = 0

select @cnt = count(spot_id) 
  from cinelight_spot_liability
 where spot_id = @source_spot_id

if @@error != 0 
begin       
    raiserror ('p_ffin_cl_allocate_makeup.DB error <select @cnt = count>', 16, 1)
    goto ERROR
end

if IsNull(@cnt, 0) = 0
begin
    commit transaction
    return 0
end 

/*
 *  Update all Spot Liability Records with the Destination Spot ID
 */

if @source_spot_status = 'N' 
    select @dest_complex_id = c.complex_id
      from cinelight_spot as cp
        inner join cinelight as c on c.cinelight_id = cp.cinelight_id
     where spot_id = @source_spot_id
else
    select @dest_complex_id = c.complex_id
      from cinelight_spot as cp
        inner join cinelight as c on c.cinelight_id = cp.cinelight_id
     where spot_id = @destination_spot_id
 
if @@error != 0
begin
    raiserror ('p_ffin_cl_allocate_makeup.DB error <select @dest_complex_id >'            , 16, 1)
    goto ERROR
end

execute @errorode = p_ffin_move_spot_liability	@source_spot_id, @destination_spot_id, @source_complex, @dest_complex_id
if(@@error != 0)
    goto error

commit transaction

if(@@error!= 0)
begin
    raiserror ('p_ffin_cl_allocate_makeup,DB error <commit >', 16, 1)
    goto ERROR
end


return 0

ERROR:
    if @cur_src_spot_libility_open = 'y'
        close cur_src_spot_libility  
		deallocate cur_src_spot_libility
    rollback transaction
    return -100
GO
