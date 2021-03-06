/****** Object:  StoredProcedure [dbo].[p_accpac_create_liab_dist]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_accpac_create_liab_dist]
GO
/****** Object:  StoredProcedure [dbo].[p_accpac_create_liab_dist]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_accpac_create_liab_dist] 	  	@country_code			char(1),
											@accounting_period		datetime
									
as

set nocount on

declare		@error								int,
			--@error									int,
			@complex_id							int,
			@business_unit_id					int,
			@liab_amount						money,
	        @cinema_amount                   	money,
	        @cinema_agreement_id             	int,
	        @percentage_entitlement          	numeric(6,4),
	        @fixed_amount                    	money,
	        @rent_mode                       	char(1),          
	        @agreement_no                    	int,
	        @agreement_type                  	char(1),
	        @agreement_status                	char(1),
	        @agreement_desc                  	varchar(50),
	        @real_liability                  	money,
	        @revenue_source                  	char(1),
	        @media_product_id                	int,
			@gl_code							char(4),
            @proc_name                          varchar(50),
            @status_awaiting                    char(1),
            @status_failed                      char(1),
            @interface_status_new               char(1),
			@max_processing_date				datetime

       
select  @status_awaiting = 'A',
        @status_failed = 'F',
        @interface_status_new = 'N'

select  @proc_name = object_name(@@PROCID)


select @gl_code = '4500'
 
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
   and cl.liability_amount != 0
order by cl.complex_id

select @error = @@error
if @error != 0
begin
	raiserror ( 'Error: AccPac Liability - failed to init temp table.', 16, 1)
	goto error
end

/*
 * Declare Cursors
 */
 
 declare cinema_liability_csr cursor static for
  select #cinema_agreement_liability.complex_id,
         #cinema_agreement_liability.revenue_source,
         #cinema_agreement_liability.media_product_id
    from #cinema_agreement_liability
order by complex_id
     for read only
 
/*
 * Process Cursor and collect Cinema Agreement Information is any available
 */ 
 
open cinema_liability_csr
fetch cinema_liability_csr into @complex_id, @revenue_source, @media_product_id
while(@@fetch_status=0)
begin


	select @max_processing_date = max(processing_start_date) from cinema_agreement_policy where policy_status_code = 'A' and revenue_source = @revenue_source and complex_id = @complex_id 
    
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
	    or  cinema_agreement_policy.revenue_source = 'P')
	    and #cinema_agreement_liability.complex_id = @complex_id 
        and #cinema_agreement_liability.revenue_source = @revenue_source 
        and #cinema_agreement_liability.media_product_id = @media_product_id


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
	        and  cinema_agreement_policy.revenue_source = 'P'
	        and #cinema_agreement_liability.complex_id = @complex_id 
            and #cinema_agreement_liability.revenue_source = @revenue_source 
            and #cinema_agreement_liability.media_product_id = @media_product_id

		    select @error = @@error
		    if @error != 0
		    begin
			    deallocate cinema_liability_csr
			    raiserror ( 'Error: AccPac Liability - failed to update temp table.', 16, 1)
			    goto error
		    end
    end
		        
    fetch cinema_liability_csr into @complex_id, @revenue_source, @media_product_id
end

deallocate cinema_liability_csr

update #cinema_agreement_liability
set revenue_source = case when cinema_agreement.agreement_type in ('M', 'F') then 'P'  else #cinema_agreement_liability.revenue_source end
from cinema_agreement
where cinema_agreement.cinema_Agreement_id = #cinema_agreement_liability.cinema_Agreement_id

begin transaction

declare		liability_csr cursor forward_only static for
select 		complex_id,
			max(fixed_amount),
			revenue_source
from		#cinema_agreement_liability
where		accounting_period = @accounting_period
and			revenue_source = 'P'
and			cinema_agreement_id is not null
group by 	complex_id,
			revenue_source
union
select 		complex_id,
			sum(cinema_liability * percentage_entitlement),
			revenue_source
from		#cinema_agreement_liability
where		accounting_period = @accounting_period
and			revenue_source != 'P'
and			cinema_agreement_id is not null
group by 	complex_id,
			revenue_source
union
select 		complex_id,
			sum(cinema_liability * .5),
			case business_unit_id when 1 then 'S' when 2 then 'F' when 3 then 'D' else 'P' end
from		#cinema_agreement_liability
where		accounting_period = @accounting_period
and			cinema_agreement_id is null
group by 	complex_id,
            business_unit_id
order by 	complex_id

open liability_csr
fetch liability_csr into @complex_id, @real_liability, @revenue_source
while(@@fetch_status=0)
begin

    select @business_unit_id = case @revenue_source when 'P' then 4 when 'F' then 2 when 'D' then 3 when 'S' then 1 when 'W' then 5 else 0 end
    
    select @gl_code =  case @revenue_source when 'P' then '2450' when 'F' then '2150' when 'D' then '2250' when 'S' then '2350' when 'C' then '2550' when 'W' then '2660' else '2150' end
    
	insert into accpac_integration..liability_distribution
	(gl_account,
	 date,
	 amount,
	 status,
     country_code) values
	(dbo.f_gl_account(null, @gl_code,  @business_unit_id, @complex_id, default),
	 @accounting_period,
	 @real_liability,
	 'N',
     @country_code)

	select @error = @@error
	if @error != 0 
	begin
		raiserror ( 'Error inserting information into liability_distribution', 16, 1)
		deallocate liability_csr
		goto rollbackerror
	end

	fetch liability_csr into @complex_id, @real_liability, @revenue_source
end

deallocate liability_csr

commit transaction
return 0

rollbackerror:
	rollback transaction

error:
	exec @error = p_dw_exit_process @proc_name
	return -1
GO
