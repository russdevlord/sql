/****** Object:  StoredProcedure [dbo].[p_create_spot_daily_segments]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_create_spot_daily_segments]
GO
/****** Object:  StoredProcedure [dbo].[p_create_spot_daily_segments]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
Create procedure [dbo].[p_create_spot_daily_segments]
As
declare     @spot            int,
	    @screeningdate   datetime,
            @startdate        datetime,
            @enddate        datetime,
	    @error	int,
	    @inc	int,
	    @err_msg            varchar(150)


/******************	 Retail   *************/

declare     spot_ds_csr cursor for 
select spot_id, screening_date  --Dateadd(day, 7, screening_date)
from outpost_spot s 
where not exists(select 1 from outpost_spot_daily_segment where spot_id = s.spot_id )   and screening_date is NOT NULL  --115404

begin transaction

open spot_ds_csr
fetch spot_ds_csr into @spot, @screeningdate 
while(@@fetch_status=0)
begin
	Set @inc = 0     
	while @inc < 7
	begin
	    set @startdate = Dateadd(day, @inc, DATEADD(hour,8,@screeningdate))     --Dateadd(day, @inc, @startdate)
	    set @enddate   = Dateadd(day, @inc, DATEADD( second, -1, DATEADD(hour,23,@screeningdate)) ) --Dateadd(day, @inc, @startdate)
		--Dateadd(day, 1, DATEADD(hour,8,@screeningdate))

	    insert into outpost_spot_daily_segment values (@spot,@startdate, @enddate )
	
	     select @error = @@error
	     if @error != 0 
	     begin
	        rollback transaction
	        raiserror ('Error: Failed to Insert Retail Spot daily segments', 16, 1)
	        return -1
	     end
	    Select @inc = @inc + 1
	end 

    fetch spot_ds_csr into  @spot, @screeningdate
end

deallocate spot_ds_csr
commit transaction

return  0
GO
