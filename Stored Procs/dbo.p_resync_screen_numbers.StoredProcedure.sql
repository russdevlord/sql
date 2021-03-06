/****** Object:  StoredProcedure [dbo].[p_resync_screen_numbers]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_resync_screen_numbers]
GO
/****** Object:  StoredProcedure [dbo].[p_resync_screen_numbers]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_resync_screen_numbers] 	@campaign_no		char(7)
as
set nocount on 
/*
 * Declare Valiables
 */ 

declare @error						integer,
        @sqlstatus					integer,
        @errorode						integer,
        @num_csr_open				tinyint,
        @new_number					integer,
        @old_number					integer

create table #numbers (
	old_number	integer	null,
	new_number	integer	null
)

/*
 * Initialise Variables
 */

select @new_number = 1

/*
 * Begin Transaction
 */

begin transaction


declare setup_csr cursor static for
 select distinct scs.screen_no
   from slide_campaign_screening scs,
        slide_campaign_spot scp
  where scs.spot_id = scp.spot_id and
        scp.campaign_no = @campaign_no
 order by scs.screen_no
for read only

open setup_csr
fetch setup_csr into @old_number
while (@@fetch_status = 0)
begin
	insert into #numbers (
 		old_number,
      new_number
      ) values (
      @old_number,
      @new_number
      )
	
	select @new_number = @new_number + 1

	fetch setup_csr into @old_number
end
close setup_csr
deallocate setup_csr


declare num_csr cursor static for
  select old_number,
         new_number
    from #numbers
order by old_number
	for read only

open num_csr
select @num_csr_open = 1
fetch num_csr into @old_number, @new_number
while (@@fetch_status = 0)
begin

	if @new_number <> @old_number
	begin
		update slide_campaign_screening
			set screen_no = @new_number
		  from slide_campaign_spot
		 where screen_no = @old_number
			and slide_campaign_screening.spot_id = slide_campaign_spot.spot_id and
             slide_campaign_spot.campaign_no = @campaign_no

		select @error = @@error
		if (@error !=0)
		begin
			rollback transaction
			goto error
		end	
	end

	fetch num_csr into @old_number, @new_number
end
close num_csr
deallocate num_csr
select @num_csr_open = 0

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	if (@num_csr_open = 1)
   begin
		close num_csr
		deallocate num_csr
	end

	return -1
GO
