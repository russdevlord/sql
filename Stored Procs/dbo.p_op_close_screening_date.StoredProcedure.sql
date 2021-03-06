/****** Object:  StoredProcedure [dbo].[p_op_close_screening_date]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_close_screening_date]
GO
/****** Object:  StoredProcedure [dbo].[p_op_close_screening_date]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  PROC [dbo].[p_op_close_screening_date] @closing_date		datetime,
                                   @opening_date		datetime                         
as

/*
 * Declare Variables
 */

declare @error								int,
				@errorode							int,
				@spot_id							int,
				@rowcount						int,
				@complex_id				    int,
				@cert_groups				int,
				@spot_csr_open		    tinyint,
				@film_plan_id   				int

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Closing Screening Date
 */
 
update		outpost_screening_dates
set				screening_date_status = 'X'
where		screening_date = @closing_date

select @error = @@error
if(@error !=0)
	goto error

/*
 * Update Opening Screening Date
 */
 
update	outpost_screening_dates
set			screening_date_status = 'C'
where	screening_date = @opening_date

select @error = @@error
if(@error !=0)
	goto error

/*
 * Update Cinelight Status and Spot Instruction
 */

update		outpost_spot
set				spot_status = 'X',
					certificate_score = 0,
					spot_instruction = 'Allocation from closure of screening_date'
where		spot_status = 'A' 
and				screening_date = @closing_date

select @error = @@error
if(@error !=0)
	goto error

/*
 * Update Inclusions - Set Cinemarketing Spots to allocated where appropriate.
 */

update 		inclusion_spot
set				spot_status = 'X'
where 		screening_date = @closing_date
and				spot_status = 'A'

select @error = @@error
if(@error !=0)
	goto error

/*
 * Declare Cursors
 */
 
declare			complex_date_csr cursor static for
select			outpost_venue_id 
from				outpost_venue_date 
where			screening_date = @closing_date
order by		outpost_venue_id 
for					read only

/*
 * Update Complex Date - Set Movies Confirmed if No certifcate generated
 */


open complex_date_csr
fetch complex_date_csr into @complex_id
while(@@fetch_status = 0)
begin

	/*
    * Check For Certificate
    */

/*	select @cert_groups = 0

	select @cert_groups = isnull(count(certificate_group_id),0)
      from certificate_group
     where complex_id = @complex_id and
           screening_date = @closing_date

	select @cert_groups = isnull(@cert_groups,0) 

	if(@cert_groups = 0)
	begin */

	  /*
       * Update Complex Date
       */
	
		update outpost_venue_date --complex_date
           set certificate_confirmation = 'N'--,
               --no_movies = 1
         where outpost_venue_id = @complex_id and --complex_id 
               screening_date = @closing_date

		select @error = @@error
		if(@error !=0)
		begin
			close complex_date_csr
			goto error
		end
	
	/*
     * Fetch Next
     */


	fetch complex_date_csr into @complex_id

end
close complex_date_csr
deallocate complex_date_csr

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
	return -1
GO
