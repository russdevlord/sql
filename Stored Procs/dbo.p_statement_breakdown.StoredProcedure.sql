/****** Object:  StoredProcedure [dbo].[p_statement_breakdown]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statement_breakdown]
GO
/****** Object:  StoredProcedure [dbo].[p_statement_breakdown]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_statement_breakdown] @statement_id			integer
as
set nocount on 
/*
 * Declare Variables
 */

declare @error     					integer,
        @rowcount       			integer,
        @accounting_period			datetime,
        @campaign_no					integer,
        @product_desc				varchar(100),
        @tran_id						integer,
        @spot_tran_id				integer,
        @spot_tran_desc				varchar(100),
        @tran_desc1					varchar(100),
        @tran_desc2					varchar(100),
        @tran_desc3					varchar(100),
        @tran_date					datetime,
        @spot_id 						integer,
        @desc_loop					tinyint


/*
 * Define Temporary Table
 */

create table #bill_trans
(
	accounting_period			datetime				null,
   campaign_no					integer				null,
	product_desc				varchar(100)		null,
	tran_id						integer				null,
	tran_desc1					varchar(100)		null,
	tran_desc2					varchar(100)		null,
	tran_desc3					varchar(100)		null,
   tran_date					datetime				null
)

/*
 * Loop Billing Transactions
 */
 declare bill_csr cursor static for
  select st.accounting_period,
         fc.campaign_no,
         fc.product_desc,
         ct.tran_id,
         ct.tran_date
    from statement st,
         film_campaign fc,
         campaign_transaction ct
   where st.statement_id = @statement_id and
         st.campaign_no = fc.campaign_no and
         st.statement_id = ct.statement_id and 
         ct.tran_type in (1,5,73,88,101) and
         ct.nett_amount >= 0
order by ct.tran_id
     for read only

open bill_csr
fetch bill_csr into @accounting_period, @campaign_no, @product_desc, @tran_id, @tran_date
while(@@fetch_status = 0)
begin

	select @spot_id = null

	/*
    * Get Spot Id
    */

	select @spot_id = max(spot_id)
     from campaign_spot
    where tran_id = @tran_id

	/*
    * Build Transaction Information
    */
	
	if(@spot_id is not null)
	begin

		/*
       * Reset Variables
       */

		select @desc_loop = 0

		declare spot_csr cursor static for
		 select ct.tran_id,
		        ct.tran_desc
		   from film_spot_xref fsx,
		        campaign_transaction ct
		  where fsx.spot_id = @spot_id and
		        fsx.tran_id = ct.tran_id
		/*
       * Loop Spot Transactions
       */
		open spot_csr
		fetch spot_csr into @spot_tran_id, @spot_tran_desc
		while(@@fetch_status = 0)
		begin
			
			select @desc_loop = @desc_loop + 1

			if(@desc_loop = 1)
			begin
				select @tran_desc1 = @spot_tran_desc + ' - Ref: ' + convert(varchar(10),@spot_tran_id)
			end

			if(@desc_loop = 2)
			begin
				select @tran_desc2 = @spot_tran_desc + ' - Ref: ' + convert(varchar(10),@spot_tran_id)
			end

			if(@desc_loop = 3)
			begin
				select @tran_desc3 = @spot_tran_desc + ' - Ref: ' + convert(varchar(10),@spot_tran_id)
			end

			/*
          * Fetch Next
          */

			fetch spot_csr into @spot_tran_id, @spot_tran_desc
			
		end
		close spot_csr
		deallocate spot_csr

		/*
       * Insert Transaction
       */

		insert into #bill_trans (
             accounting_period,
             campaign_no,
             product_desc,
             tran_id,
             tran_desc1,
             tran_desc2,
             tran_desc3,
             tran_date ) values (
             @accounting_period,
             @campaign_no,
             @product_desc,
             @tran_id,
             @tran_desc1,
             @tran_desc2,
             @tran_desc3,
             @tran_date )

	end
	
	/*
    * Fetch Next
    */

	fetch bill_csr into @accounting_period, @campaign_no, @product_desc, @tran_id, @tran_date

end
close bill_csr
deallocate bill_csr


/*
 * Return Dataset
 */

  select accounting_period,
         campaign_no,
         product_desc,
         tran_id,
         tran_desc1,
         tran_desc2,
         tran_desc3,
         tran_date
    from #bill_trans
order by tran_id

/*
 * Return Success
 */

return 0
GO
