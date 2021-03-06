/****** Object:  StoredProcedure [dbo].[p_slide_camp_suspension_detls]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_camp_suspension_detls]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_camp_suspension_detls]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_slide_camp_suspension_detls] 	@pass_campaign_no	char(7)


AS
set nocount on 
/*
 *  Declare Procedure Variables
 */

declare 	@store_start_date		datetime,
		  	@store_end_date		datetime,
			@spot_no					integer,
			@group_no				integer,
			@campaign_no			char(7),
			@spot_status			char(1),
			@billing_status		char(1),
			@screening_date		datetime,
			@gross_rate				money,
			@sequence_no			integer,
			@errorode					integer,
			@susp_amount			money

create table #suspension
(
	sequence_no			integer	null,
	start_date			datetime null,
	end_date				datetime null,
	susp_amount 		money
)


/*
 * initialise variables
 */
select @store_start_date = null
select @store_end_date = null
select @sequence_no = 0
select @susp_amount = 0

/*
 * declare the slide_campaign_spot cursor
 */

declare spot_csr cursor static for
	select spot_no,
			 group_no,
			 campaign_no,
			 spot_status,
			 billing_status,
			 screening_date,
			 gross_rate
	from	 slide_campaign_spot
	where	 campaign_no = @pass_campaign_no
	order by campaign_no, spot_no
	for read only

/*
 * open spot cursor
 */
open 	spot_csr


/*
 * get the first spot row
 */
fetch spot_csr
into 	@spot_no,
		@group_no,
		@campaign_no,
		@spot_status,
		@billing_status,
		@screening_date,
		@gross_rate

while (@@fetch_status = 0)
begin
	
	/*
	 * check the spot status and process
	 */	
	
	if	@spot_status = 'S'
		begin
			if	@store_start_date = null 
				begin
					select @store_start_date = @screening_date
					select @store_end_date = @screening_date
				end
			else
				begin		
					select @store_end_date = @screening_date
				end
			select @susp_amount = @susp_amount + @gross_rate
		end
	else
		begin
			if @store_start_date <> null 
				begin

					/*
					 * finalise end date for the suspension period incurred
					 */
					select @store_end_date = dateadd(dd,6,@store_end_date)	

					/*
					 * write the suspension row
					 */
					select @sequence_no = @sequence_no + 1
					insert into #suspension (
								sequence_no,
                        start_date, 
                        end_date,
								susp_amount ) values (
								@sequence_no,
								@store_start_date,
								@store_end_date,
								@susp_amount )
					/*
 					 * initialise for next suspension range
					 */
					select @store_start_date = null
					select @susp_amount = 0
					
				end 
	end 

	
	/*
	 * get the next spot row
	 */
	fetch spot_csr
	into 	@spot_no,
			@group_no,
			@campaign_no,
			@spot_status,
			@billing_status,
			@screening_date,
			@gross_rate
/*
 * end while loop
 */
end

/*
 * after final fetch - if final spot happens to be a suspension then need to write the last suspension row.
 */

if	@spot_status = 'S' and 
	@store_start_date <> null 
		begin

			/*
			 * finalise end date for the suspension period incurred
			 */
			select @store_end_date = dateadd(dd,6,@store_end_date)
			select @susp_amount = @susp_amount + @gross_rate	

			/*
			 * write the suspension row
			 */
			select @sequence_no = @sequence_no + 1
			insert into #suspension (
						sequence_no,
						start_date, 
						end_date,
						susp_amount ) values (
						@sequence_no,
						@store_start_date,
						@store_end_date,
						@susp_amount )
			end 

/*
 * close the cursor
 */

close spot_csr
deallocate spot_csr

/*
 * return the result set
 */

select sequence_no,
		 start_date,
		 end_date,
		 susp_amount
from	 #suspension


return 0

/*
 * Error Handler
 */

error:

	close spot_csr

	return -1
GO
