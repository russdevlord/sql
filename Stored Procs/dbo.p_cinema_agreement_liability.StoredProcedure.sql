/****** Object:  StoredProcedure [dbo].[p_cinema_agreement_liability]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinema_agreement_liability]
GO
/****** Object:  StoredProcedure [dbo].[p_cinema_agreement_liability]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cinema_agreement_liability] @accounting_period     datetime,
                                         @country_code          char(1)
as


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
        @media_product_id                int,
		@max_processing_date			 datetime,
		@origin_period					 datetime,
		@rowcount						 int

set nocount on

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
    country_name                    varchar(30)         null,
	origin_period					datetime			null
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
    revenue_source,
	origin_period
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
       cl.revenue_source,
		cl.origin_period
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
   and cl.liability_amount != 0 
  --and bu.business_unit_id <> 9  
order by cl.complex_id

/*
 * Declare Cursors
 */
 
declare 	cinema_liability_csr cursor static for
select 		#cinema_agreement_liability.complex_id,
			#cinema_agreement_liability.revenue_source,
			#cinema_agreement_liability.media_product_id,
			#cinema_agreement_liability.origin_period
from 		#cinema_agreement_liability
order by 	complex_id
for 		read only
 
/*
 * Process Cursor and collect Cinema Agreement Information is any available
 */ 
 
open cinema_liability_csr
fetch cinema_liability_csr into @complex_id, @revenue_source, @media_product_id, @origin_period
while(@@fetch_status=0)
begin

	select 	@max_processing_date = max(processing_start_date)
	from 	cinema_agreement_policy 
	where 	policy_status_code = 'A' 
	and 	revenue_source = @revenue_source 
	and 	complex_id = @complex_id 
	and     isnull(cinema_agreement_policy.rent_inclusion_start,'1-jan-1900') <= @origin_period
	and     isnull(cinema_agreement_policy.rent_inclusion_end,'1-jan-2050') >= @origin_period
	
    
	 update #cinema_agreement_liability
        set cinema_agreement_id = cinema_agreement.cinema_agreement_id,
            percentage_entitlement = cinema_agreement_policy.percentage_entitlement,
            fixed_amount = cinema_agreement_policy.fixed_amount,
            rent_mode = cinema_agreement_policy.rent_mode,          
            agreement_no = cinema_agreement.agreement_no,
            agreement_type = cinema_agreement.agreement_type,
            agreement_status = cinema_agreement.agreement_status,
            agreement_desc = cinema_agreement.agreement_desc
       from cinema_agreement_policy,
	        cinema_agreement
      where cinema_agreement_policy.cinema_agreement_id = cinema_agreement.cinema_agreement_id
        and cinema_agreement_policy.policy_status_code = 'A'
        and cinema_agreement_policy.complex_id = @complex_id
        and ((cinema_agreement_policy.revenue_source = @revenue_source
		and processing_start_date = @max_processing_date) 
	    or cinema_agreement_policy.revenue_source = 'P')
		and #cinema_agreement_liability.origin_period = @origin_period
	    and #cinema_agreement_liability.complex_id = @complex_id 
        and #cinema_agreement_liability.revenue_source = @revenue_source 
        and #cinema_agreement_liability.media_product_id = @media_product_id
		and isnull(cinema_agreement_policy.rent_inclusion_start,'1-jan-1900') <= @origin_period
		and isnull(cinema_agreement_policy.rent_inclusion_end,'1-jan-2050') >= @origin_period
		
		select @rowcount = @@rowcount
		
		if @rowcount = 0 and @revenue_source <> 'L' and @revenue_source <> 'I'
			select @rowcount = 0

	select @max_processing_date = max(processing_start_date) from cinema_agreement_policy where policy_status_code = 'A' and revenue_source = 'P' and complex_id = @complex_id 

    if @max_processing_date  is not null
    begin

	     update #cinema_agreement_liability
            set cinema_agreement_id = cinema_agreement.cinema_agreement_id,
                percentage_entitlement = cinema_agreement_policy.percentage_entitlement,
                fixed_amount = cinema_agreement_policy.fixed_amount,
                rent_mode = cinema_agreement_policy.rent_mode,          
                agreement_no = cinema_agreement.agreement_no,
                agreement_type = cinema_agreement.agreement_type,
                agreement_status = cinema_agreement.agreement_status,
                agreement_desc = cinema_agreement.agreement_desc
           from cinema_agreement_policy,
	            cinema_agreement
          where cinema_agreement_policy.cinema_agreement_id = cinema_agreement.cinema_agreement_id
            and cinema_agreement_policy.policy_status_code = 'A'
            and cinema_agreement_policy.complex_id = @complex_id
	        and cinema_agreement_policy.revenue_source = 'P'
	        and #cinema_agreement_liability.complex_id = @complex_id 
            and #cinema_agreement_liability.revenue_source = @revenue_source 
            and #cinema_agreement_liability.media_product_id = @media_product_id
            and #cinema_agreement_liability.origin_period = @origin_period
			and isnull(cinema_agreement_policy.rent_inclusion_start,'1-jan-1900') <= @origin_period
			and isnull(cinema_agreement_policy.rent_inclusion_end,'1-jan-2050') >= @origin_period

    end

    fetch cinema_liability_csr into @complex_id, @revenue_source, @media_product_id, @origin_period
end

deallocate cinema_liability_csr

update #cinema_agreement_liability
set revenue_source = case when cinema_agreement.agreement_type in ('M', 'F') then 'P'  else #cinema_agreement_liability.revenue_source end
from cinema_agreement
where cinema_agreement.cinema_Agreement_id = #cinema_agreement_liability.cinema_Agreement_id

set nocount off

select 	complex_id,
	    accounting_period,
	    complex_name,
	    business_unit_id,
	    business_unit_desc,
	    media_product_id,
	    media_product_desc,
	    cinema_liability,
	    cinema_agreement_id,
	    percentage_entitlement,
	    fixed_amount,
	    revenue_source,
	    rent_mode,
	    agreement_no,
	    agreement_type,
	    agreement_status,
	    agreement_desc,
	    country_code,
	    country_name,
		origin_period,
	    case when revenue_source = 'P' then 0.0 when revenue_source = null then 0 else percentage_entitlement * cinema_liability end
from 	#cinema_agreement_liability 
order by revenue_source,
		agreement_no,
		complex_name,
		origin_period,
		media_product_desc



return 0
GO
