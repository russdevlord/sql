/****** Object:  StoredProcedure [dbo].[p_fixed_agreement_liability]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_fixed_agreement_liability]
GO
/****** Object:  StoredProcedure [dbo].[p_fixed_agreement_liability]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_fixed_agreement_liability] @accounting_period     datetime,
                                         @country_code          char(1)
as

set nocount on 

declare @error                           int,
        @cinema_amount                   money,
        @cinema_agreement_id             int,
        @percentage_entitlement          numeric(6,4),
        @fixed_amount                    money,
        @rent_mode                       char(1),          
        @agreement_no                    int,
        @agreement_type                  char(1),
        @agreement_status                char(1),
        @agreement_desc                  varchar(50),
        @real_liability                  money,
        @complex_id                      int,
        @revenue_source                  char(1),
        @media_product_id                int

/*
 * Create Temp Table
 */
 
create table #cinema_agreement_liability
(
    complex_id                      int                 null,
    accounting_period               datetime            null,
    complex_name                    varchar(50)         null,
    business_unit_id                int                 null,
    business_unit_desc              varchar(30)         null,
    media_product_id                int                 null,
    media_product_desc              varchar(30)         null,
    cinema_liability                money               null,
    cinema_agreement_id             int                 null,
    percentage_entitlement          numeric(6,4)        null,
    fixed_amount                    money               null,
    revenue_source                  char(1)             null,  
    rent_mode                       char(1)             null,          
    agreement_no                    char(6)             null,
    agreement_type                  char(1)             null,
    agreement_status                char(1)             null,
    agreement_desc                  varchar(50)         null,
    country_code                    char(1)             null,
    country_name                    varchar(30)         null
)

 
/*
 * Populate Temp Table
 */
 
insert into #cinema_agreement_liability  
(
    complex_id,
    accounting_period,
    complex_name,
    business_unit_id,
    business_unit_desc,
    media_product_id,
    media_product_desc,
    cinema_liability,
    country_code,
    country_name,
    revenue_source
)
select cl.complex_id,
       cl.accounting_period,
       c.complex_name,
       cl.business_unit_id,
       bu.business_unit_desc,
       cl.media_product_id,
       mp.media_product_desc,
       cl.liability_amount,
       country.country_code,
       country.country_name,
       cl.revenue_source
  from cinema_liability cl,
       complex c,
       business_unit bu,
       media_product mp,
       country,
       branch
 where cl.complex_id = c.complex_id
   and cl.business_unit_id = bu.business_unit_id
   and cl.accounting_period = @accounting_period
   and cl.media_product_id = mp.media_product_id
   and country.country_code = cl.country_code 
   and country.country_code = @country_code
   and branch.branch_code = c.branch_code
   and branch.country_code = @country_code
order by cl.complex_id


/*
 * Declare Cursors
 */
 
 declare cinema_liability_csr cursor static for
  select #cinema_agreement_liability.complex_id,
         #cinema_agreement_liability.revenue_source,
         #cinema_agreement_liability.media_product_id
    from #cinema_agreement_liability,
         media_product
   where media_product.media_product_id = #cinema_agreement_liability.media_product_id
order by complex_id
     for read only
/*
 * Process Cursor and collect Cinema Agreement Information is any available
 */ 
 
open cinema_liability_csr
fetch cinema_liability_csr into @complex_id, @revenue_source, @media_product_id
while(@@fetch_status=0)
begin

     update #cinema_agreement_liability
        set cinema_agreement_id = cinema_agreement.cinema_agreement_id,
            percentage_entitlement = cinema_agreement_policy.percentage_entitlement,
            fixed_amount = cinema_agreement_policy.fixed_amount,
            revenue_source = case when cinema_agreement.agreement_type = 'M' then 'P' when cinema_agreement.agreement_type = 'F' then 'P' else cinema_agreement_policy.revenue_source end, 
            rent_mode = cinema_agreement_policy.rent_mode,          
            agreement_no = cinema_agreement.agreement_no,
            agreement_type = cinema_agreement.agreement_type,
            agreement_status = cinema_agreement.agreement_status,
            agreement_desc = cinema_agreement.agreement_desc
       from cinema_agreement_policy,
	        cinema_agreement,
--            branch,
--            country,
            accounting_period
      where cinema_agreement_policy.cinema_agreement_id = cinema_agreement.cinema_agreement_id
	    and (cinema_agreement_policy.rent_inclusion_start <= @accounting_period
         or cinema_agreement_policy.rent_inclusion_start is null)
		and (cinema_agreement_policy.rent_inclusion_end > @accounting_period 
		 or cinema_agreement_policy.rent_inclusion_end is null)
        and cinema_agreement_policy.policy_status_code = 'A'
        and cinema_agreement_policy.complex_id = @complex_id
        and (cinema_agreement_policy.revenue_source = @revenue_source
          or cinema_agreement_policy.revenue_source = 'P')
        and #cinema_agreement_liability.complex_id = @complex_id 
        and #cinema_agreement_liability.media_product_id = @media_product_id
        
    fetch cinema_liability_csr into @complex_id, @revenue_source, @media_product_id
end
close cinema_liability_csr
deallocate cinema_liability_csr

select complex_id,
    accounting_period,
    complex_name,
    cinema_agreement_id,
    percentage_entitlement,
    avg(fixed_amount),
    revenue_source,
    agreement_no,
    agreement_type,
    agreement_status,
    agreement_desc,
    country_code,
    country_name
from #cinema_agreement_liability 
where revenue_source = 'P'
group by complex_id,
    accounting_period,
    complex_name,
    cinema_agreement_id,
    percentage_entitlement,
    revenue_source,
    agreement_no,
    agreement_type,
    agreement_status,
    agreement_desc,
    country_code,
    country_name
order by revenue_source,
		agreement_no,
		complex_name

return 0
GO
