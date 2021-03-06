/****** Object:  StoredProcedure [dbo].[p_wgt_film_billing_sum_rpt]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_wgt_film_billing_sum_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_wgt_film_billing_sum_rpt]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_wgt_film_billing_sum_rpt]	@accounting_period_from		datetime,
										@accounting_period_to	datetime,
										@country_code			char(1)
as
set nocount on 

declare @error				    int,
        @finyear			    datetime,
        @complex_id			    int,
        @cplx_csr_open		    tinyint,
        @bill_tot			    money,
        @comm_tot			    money,
        @bd_tot				    money,
        @d_bill_tot			    money,
        @d_comm_tot			    money,
        @d_bd_tot			    money,
		@media_product_id       int,
        @business_unit_id       int,
		@accounting_period		datetime


if @accounting_period_to is null
	select @accounting_period_to = @accounting_period_from

/*
 * Create Temporary Table
 */

create table #billing_summary
(
        accountig_period        datetime        null,
        complex_id				int			    null,
        media_product_id		int			    null,
        media_product_desc		varchar(30)     null,
        business_unit_id		int			    null,
        business_unit_desc		varchar(30)	    null,
        complex_name			varchar(50)		null,
        country_code			char(1)			null,
        country_name			varchar(30)		null,
        branch_code				varchar(2)		null,
        branch_name				varchar(30)		null,
        bill_ytd				money			null,
        comm_ytd				money			null,
        bd_ytd					money			null,
        bill_mtd				money			null,
        comm_mtd				money			null,
        bd_mtd					money			null
)

/*
 * Initialise Cursor Flags
 */
select @cplx_csr_open = 0

declare	acc_prd_crs cursor for
	select	end_date, finyear_end
	from	accounting_period
	where	end_date >= @accounting_period_from
	and 	end_date <= @accounting_period_to
order by end_date
     for read only

open acc_prd_crs
fetch acc_prd_crs into @accounting_period, @finyear
while(@@fetch_status = 0)
begin


/*
 * Determine Financial Year
 */

-- select @finyear = finyear_end
--   from accounting_period
--  where end_date = @accounting_period

/*
 * Insert Summary Billing Totals Year to Date
 */

	  insert into #billing_summary
	  select @accounting_period,
	         cplx.complex_id,
	         mp.media_product_id,
	         mp.media_product_desc,
	         bu.business_unit_id,
	         bu.business_unit_desc,
	         cplx.complex_name,
	         c.country_code,
	         c.country_name,
	         b.branch_code,
	         b.branch_name,
	         sum(fss.weighted_billings),
	         sum(fss.weighted_commission),
	         sum(fss.weighted_bad_debt),
	         0.0,
	         0.0,
	         0.0
	    from accounting_period ap,
	         film_spot_summary fss,
	         complex cplx,
	         branch b,
			 country c,
	         business_unit bu,
	         media_product mp
	   where ap.finyear_end = @finyear and
	         ap.end_date <= @accounting_period and
	         ap.end_date = fss.accounting_period and
	         fss.country_code = @country_code and
	         fss.country_code = c.country_code and
	         fss.complex_id = cplx.complex_id and
	         cplx.branch_code = b.branch_code and
	         fss.business_unit_id = bu.business_unit_id and
	         fss.media_product_id = mp.media_product_id 
	          and bu.business_unit_id <> 9   
		group by cplx.complex_id,
	         mp.media_product_id,
	         mp.media_product_desc,
	         bu.business_unit_id,
	         bu.business_unit_desc,
	         cplx.complex_name,
	         c.country_code,
	         c.country_name,
	         b.branch_code,
	         b.branch_name

		/*
		 * Declare MTD Cursor
		 */
		
		 declare complex_csr cursor for
		  select complex_id,
		         business_unit_id,
		         media_product_id
		    from #billing_summary
		order by complex_id
		     for read only
		
		/*
		 * Update Month to Date Totals
		 */
		open complex_csr
		select @cplx_csr_open = 1
		fetch complex_csr into @complex_id, @business_unit_id, @media_product_id
		while(@@fetch_status = 0)
		begin
		
			select @bill_tot = 0.0,
		           @comm_tot = 0.0,
		           @bd_tot = 0.0
		
			/*
		    * Calculate MTD Totals - Standard Campaign Format
		    */
		
			select @bill_tot = isnull(sum(weighted_billings),0),
		           @comm_tot = isnull(sum(weighted_commission),0),
		           @bd_tot = isnull(sum(weighted_bad_debt),0)
		      from film_spot_summary
		     where complex_id = @complex_id and
		           country_code = @country_code and
		           accounting_period = @accounting_period and
		           business_unit_id = @business_unit_id and
		           media_product_id = @media_product_id
		           
			if(@bill_tot <> 0.0 or @comm_tot <> 0.0 or @bd_tot <> 0.0)
			begin
		
				update #billing_summary
		 		   set bill_mtd = @bill_tot,
					   comm_mtd = @comm_tot,
				 	   bd_mtd = @bd_tot
				 where complex_id = @complex_id and
		               business_unit_id = @business_unit_id and
		               media_product_id = @media_product_id and
					   accountig_period = @accounting_period
			
			end
		
			/*
		    * Fetch Next
		    */
		
			fetch complex_csr into @complex_id, @business_unit_id, @media_product_id
		
		end
		close complex_csr
		select @cplx_csr_open = 0
		deallocate complex_csr

		fetch acc_prd_crs into @accounting_period, @finyear

end 
close acc_prd_crs
deallocate acc_prd_crs

/*
 * Return Dataset
 */

select * 
  from #billing_summary

/*
 * Return
 */

return 0
GO
