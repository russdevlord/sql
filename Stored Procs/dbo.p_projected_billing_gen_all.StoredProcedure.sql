/****** Object:  StoredProcedure [dbo].[p_projected_billing_gen_all]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_projected_billing_gen_all]
GO
/****** Object:  StoredProcedure [dbo].[p_projected_billing_gen_all]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
 * p_projected_billing_gen_all
 * --------------------------
 * This procedure calls p_projected_billing_data_gen for all branches and forecast dates
 *
 * Args:    1. Billing period (Acct cut off date)
 *		    3. Country code
 *			4. Product Type (ie: Film, Slide)
 *
 * Created/Modified
 * GC, 14/4/2002, Created.
 * GC, 6/5/2003, modified to data-warehouse type function
 * VT, 8/3/2004, period_no has been added to the billing_period cursor
 */

CREATE PROC [dbo].[p_projected_billing_gen_all] @billing_period	datetime,
                                   @report_date  datetime
with recompile                                   
as

/* Declare Variables */
declare     @error_num              int,
            @error                     int,
            @cur_billing_period     datetime,
            @cur_branch_code        char(1),
            @finyear_end            datetime,
            @cur_period_no          tinyint,
            @business_unit_id       int,
            @media_product_id       int,
            @last_billing_period    datetime,
            @agency_deal            char(1)

SET NOCOUNT ON 

select  @finyear_end = finyear_end from accounting_period where benchmark_end = @billing_period

select  @last_billing_period = max(benchmark_end)
from    accounting_period
where   benchmark_end >= @billing_period
and     finyear_end = @finyear_end

create table #intra
(
    benchmark_end               datetime        null,
    branch_code                 char(2)         null,
    business_unit_id            int             null,
    media_product_id            int             null,
    agency_deal                 char(1)         null,
    amount                      money           null,
    finyear_end                 datetime        null
)

   insert into #intra
    (
    benchmark_end,
    branch_code,
    business_unit_id,
    media_product_id,
    agency_deal,
    amount,
    finyear_end
    ) 
    select      accounting_period, 
                branch_code,
                business_unit_id,
                media_product_id,
                agency_deal,
                billings,
                finyear
    from        v_projbill_bu_mp_ad
    where       finyear >= @finyear_end

declare     business_unit_csr cursor static for
select      business_unit_id
from        business_unit
where       system_use_only = 'N'
order by    business_unit_id
for         read only

open business_unit_csr
fetch business_unit_csr into @business_unit_id
while(@@fetch_status=0)
begin

	declare     media_product_csr cursor static for
	select      media_product_id
	from        media_product
	where       system_use_only = 'N'
	order by    media_product_id
	for         read only

    open media_product_csr
    fetch media_product_csr into @media_product_id
    while(@@fetch_status=0)
    begin

		declare     agency_deal_csr cursor static for
		select      agency_deal
		from        agency_deal
		order by    agency_deal
		for         read only

        open agency_deal_csr
        fetch agency_deal_csr into @agency_deal
        while(@@fetch_status=0)
        begin

			declare     branch_cur cursor static forward_only for
			select      branch_code
			from        branch
			order by    branch_code
			for         read only

            open branch_cur
            fetch branch_cur into @cur_branch_code
            while(@@fetch_status=0)
            begin
 
                exec @error = p_projected_billing_data_gen @report_date, @business_unit_id, @media_product_id, @agency_deal, @cur_branch_code, @finyear_end
                exec @error = p_projected_billing_future_gen @report_date, @business_unit_id, @media_product_id, @agency_deal, @cur_branch_code, @finyear_end, @last_billing_period

                fetch branch_cur into @cur_branch_code
            end /* branch_cur */

			deallocate branch_cur

            fetch agency_deal_csr into @agency_deal
        end            

		deallocate agency_deal_csr

        fetch media_product_csr into @media_product_id        
    end

	deallocate media_product_csr

    fetch business_unit_csr into @business_unit_id
end
deallocate business_unit_csr

SET NOCOUNT OFF

return @error
GO
