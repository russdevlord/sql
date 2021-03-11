/****** Object:  StoredProcedure [dbo].[p_proj_bill_ag_buying_branch_analysis]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_proj_bill_ag_buying_branch_analysis]
GO
/****** Object:  StoredProcedure [dbo].[p_proj_bill_ag_buying_branch_analysis]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * dbo.p_proj_bill_ag_buying_branch_analysis
 * ---------------------------------------
 * This procedure generated data for  Agency Buying Group Analysis report
 *
 * Args:    1. Billing Period FROM (Acct cut off date - Accounting Period End Date)
 *		    2. Billing Period TO
 *			3. Film Campaign Format = S (standart) ; D (motion graphics)
 *          4. Branch
 *
 * Created/Modified
 * GC, 13/4/2002, Created.
 *
 * ReUsed/Modified
 * VT,  22/08/2003
 */

CREATE  PROC [dbo].[p_proj_bill_ag_buying_branch_analysis]  @arg_billing_period_from    datetime,
                                            @arg_billing_period_to      datetime,
                                            @business_unit_id           int,
                                            @media_product_id           int,
                                            @mode                       char(1),
                                            @arg_branch_code           char(1)
with recompile
as

/*
 * Declare Variables
 */

declare     @error_num                          int,
            @prev_billing_period_from           datetime,
            @prev_billing_period_to             datetime,
            @period_number_from                 int,
            @period_number_to                   int,
            @this_period_year_from              datetime,
            @this_period_year_to                datetime,
            @prev_period_year_from              datetime,
            @prev_period_year_to                datetime,
            @agency_buying_group_id             int,
            @billing_amount                     money,
            @prev_billing_amount                money,
            @retcode                            int,
            @buying_group_name                  char(100),
            @variation_in_percents              numeric(15, 2),
            @tempp                              varchar(60),
            @report_header                      varchar(50),
            @agency_deal                        char(1),
            @group_desc                         varchar(60),
            @sort_add                           int

/*
 * Create Temporary Table
 */
create table #intra
(
    benchmark_end               datetime        null,
    branch_code                 char(2)         null,
    business_unit_id            int             null,
    media_product_id            int             null,
    agency_deal                 char(1)         null,
    amount                      money           null,
    finyear_end                 datetime        null,
    agency_group_id             int             null
)


CREATE TABLE   #result
(   agency_byuing_group_name    varchar(100)        Null,
    billing_period              datetime            Null,
    prev_billing_period         datetime            Null,
    period_no                   int                 Null,
    total_amount_this_period    money               Null,
    total_amount_prev_period    money               Null,
    variation_in_$              money               Null,
    variation_in_percents       numeric(9,2)        Null,
    sort            		    int                 null,
    group_desc      		    varchar(60)         null,
    billing_period_to           datetime            Null,
    prev_billing_period_to      datetime            Null,
    period_no_to                int                 Null
)

/* If TO billing period is not specified */
IF IsNull(@arg_billing_period_to, '1900-01-01') = '1900-01-01'
    select @arg_billing_period_to = @arg_billing_period_from

select  @this_period_year_from =  finyear_end,
        @period_number_from = period_no
from    accounting_period
where   end_date = @arg_billing_period_from

select  @this_period_year_to = finyear_end,
        @period_number_to = period_no
from    accounting_period
where   end_date = @arg_billing_period_to

/* salection criteria window validation routine should make sure that 'from-to' billing period <= 12 month */
SELECT  @prev_billing_period_from = benchmark_end
FROM    accounting_period
WHERE   period_no = @period_number_from and
        finyear_end = dateadd(yy, -1, @this_period_year_from)

SELECT  @prev_billing_period_to = benchmark_end
FROM    accounting_period
WHERE   period_no = @period_number_to and
        finyear_end = dateadd(yy, -1, @this_period_year_to)
   
select  @prev_period_year_from =  finyear_end
from    accounting_period
where   benchmark_end = @prev_billing_period_from

select  @prev_period_year_to =  finyear_end
from    accounting_period
where   benchmark_end = @prev_billing_period_to


select  @arg_billing_period_from = benchmark_end 
from    accounting_period 
where   end_date =  @arg_billing_period_from   

select  @arg_billing_period_to  = benchmark_end 
from    accounting_period 
where   end_date =  @arg_billing_period_to 

insert into #intra
(
benchmark_end,
branch_code,
business_unit_id,
media_product_id,
agency_deal,
amount,
finyear_end,
agency_group_id
) 
select      accounting_period, 
            branch_code,
            business_unit_id,
            media_product_id,
            agency_deal,
            billings,
            finyear,
            buying_group_id
from        v_projbill_bu_mp_ad_abg
where       finyear <= @this_period_year_to
and         finyear >= @prev_period_year_from

if @mode = '1' -- Business Unit Header Report     
begin
    declare     report_csr cursor static for
    select      bu.business_unit_id,
                mp.media_product_id,
                convert(char(1),null),
                mp.media_product_desc,
                case when  mp.media_product_id = bu.primary_media_product then 0 else 100 end 
    from        business_unit bu,
                media_product mp
    where       mp.system_use_only = 'N'  
    and         bu.system_use_only = 'N'
	and			mp.media = 'Y'
    and         bu.business_unit_id = @business_unit_id
    order by    bu.business_unit_id,
                mp.media_product_id
    for         read only
    
    select      @report_header = business_unit_desc
    from        business_unit
    where       business_unit_id = @business_unit_id
    
end
else if @mode = '2' -- Media Product Header Report
begin
    declare     report_csr cursor static for
    select      null,
                mp.media_product_id,
                ad.agency_deal,
                ad.agency_deal_desc,
                case when  ad.agency_deal = 'Y' then 0 else 100 end 
    from        agency_deal ad,
                media_product mp
    where       mp.system_use_only = 'N'  
    and         mp.media_product_id = @media_product_id
   	and			mp.media = 'Y'
	order by    mp.media_product_id,
                ad.agency_deal
    for         read only

    select      @report_header = media_product_desc
    from        media_product
    where       media_product_id = @media_product_id
end
else
begin
    raiserror ('Error: Unsupported Mode', 16, 1)
    return -1
end


/*
 * Begin Processing
 */
 
open report_csr
fetch report_csr into @business_unit_id, @media_product_id, @agency_deal, @group_desc, @sort_add
while(@@fetch_status=0)
begin   

	/* cursor static for Agency Buying Group */
	declare     ag_buying_groups cursor static for
	select      buying_group_id,
	            buying_group_desc
	from        agency_buying_groups
	for         read only 

    open ag_buying_groups
    fetch ag_buying_groups INTO @agency_buying_group_id, @buying_group_name
    WHILE @@fetch_status = 0  /* BUYING GROUPS */
    begin

            select  @billing_amount   = isnull(sum(amount),0)
            from    #intra
    		where   (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id
			 or 	@media_product_id is null)
            and     benchmark_end >= @arg_billing_period_from
            and     benchmark_end <= @arg_billing_period_to
            and     agency_group_id = @agency_buying_group_id
			and     branch_code = @arg_branch_code
            
            
            select  @prev_billing_amount   = isnull(sum(amount),0)
            from    #intra
            where   (business_unit_id = @business_unit_id
             or     @business_unit_id is null)
            and     (agency_deal = @agency_deal
             or     @agency_deal is null)
            and     (media_product_id = @media_product_id or @media_product_id is null)
            and     benchmark_end >= @prev_billing_period_from
            and     benchmark_end <= @prev_billing_period_to
            and     agency_group_id = @agency_buying_group_id
			and     branch_code = @arg_branch_code

        IF @prev_billing_amount = 0
            select @variation_in_percents = 100
        ELSE
            select @variation_in_percents = ( @billing_amount - @prev_billing_amount )  / @prev_billing_amount


          INSERT INTO #result
                (   agency_byuing_group_name    ,
                    billing_period              ,
                    prev_billing_period         ,
                    period_no                   ,
                    total_amount_this_period    ,
                    total_amount_prev_period    ,
                    variation_in_$              ,
                    variation_in_percents       ,
                    group_desc                   ,
                    sort                        ,
                    billing_period_to           ,
                    prev_billing_period_to      ,
                    period_no_to
                    )
            VALUES ( @buying_group_name,
                     @arg_billing_period_from,
                     @prev_billing_period_from,
                     @period_number_from,
                     @billing_amount,
                     @prev_billing_amount,
                     @billing_amount - @prev_billing_amount,
                     @variation_in_percents,
     @group_desc,
                     @sort_add,
                     @arg_billing_period_to,
                     @prev_billing_period_to,
                     @period_number_to
                     )

        fetch ag_buying_groups INTO @agency_buying_group_id, @buying_group_name

    end  /* BUYING GROUPS */
    close   ag_buying_groups
	deallocate ag_buying_groups
    fetch report_csr into @business_unit_id, @media_product_id, @agency_deal, @group_desc, @sort_add
end

deallocate report_csr


select #result.agency_byuing_group_name, #result.billing_period, #result.prev_billing_period, #result.period_no, #result.total_amount_this_period, #result.total_amount_prev_period, #result.variation_in_$, #result.variation_in_percents, #result.group_desc, #result.sort, #result.billing_period_to, #result.prev_billing_period_to, #result.period_no_to, @report_header, @arg_branch_code from #result

return 0
GO
