/****** Object:  StoredProcedure [dbo].[p_op_date_activation]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_date_activation]
GO
/****** Object:  StoredProcedure [dbo].[p_op_date_activation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_date_activation] @outpost_panel_id		int
as

/*
 * Declare Variables
 */

declare @error        						int,
        @rowcount     						int,
        @errorode								int,
        @errno								int,
        @screening_date						datetime,
        @screening_date_csr_open			tinyint,
		@max_ads							int,
		@max_time							int



/*
 * Begin Transaction
 */

begin transaction

/*
 * Declare Cursor
 */

 declare screening_date_csr cursor static for
  select fsd.screening_date
    from outpost_screening_dates fsd
order by fsd.screening_date
     for read only
 
/*
 * Loop Through Screening Dates
 */

open screening_date_csr
select @screening_date_csr_open = 1
fetch screening_date_csr into @screening_date
while(@@fetch_status = 0)
begin

	/*
     * Check outpost_venue Date Does Not Already Exist
     */

	select 	@rowcount = count(outpost_panel_id)
     from 	outpost_panel_date
    where 	outpost_panel_id = @outpost_panel_id and
          	screening_date = @screening_date

	if(@rowcount = 0)
	begin

      /*
       * Insert outpost_panel Date
       */

		insert into outpost_panel_date ( 
					outpost_panel_id,   
					screening_date,   
					generation_status,
					outpost_panel_locked,
					outpost_panel_revision) values (
					@outpost_panel_id,
					@screening_date,
					'N',
					'N',
					-1)
	
		select @errno = @@error
		if (@errno != 0)
			goto error

	end

	/*
    * Fetch Next Spot
    */

	fetch screening_date_csr into @screening_date

end
close screening_date_csr
select @screening_date_csr_open = 0
deallocate screening_date_csr

/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:

	 rollback transaction
	 if(@screening_date_csr_open = 1)
    begin
		 close screening_date_csr
		 deallocate screening_date_csr
	 end

	 return -1
GO
