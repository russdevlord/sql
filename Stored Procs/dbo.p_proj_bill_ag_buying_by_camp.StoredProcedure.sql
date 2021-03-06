/****** Object:  StoredProcedure [dbo].[p_proj_bill_ag_buying_by_camp]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_proj_bill_ag_buying_by_camp]
GO
/****** Object:  StoredProcedure [dbo].[p_proj_bill_ag_buying_by_camp]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
 * dbo.p_proj_bill_ag_buying_by_camp
 * ---------------------------------------
 * This procedure generated data for  Agency Buying Group Analysis report, by campaign section
 *
 * Args:    1. Billing Period FROM (Acct cut off date - Accounting Period End Date)
 *		    2. Billing Period TO
 *			3. Film Campaign Format = S (standart) ; D (motion graphics)
 *
 * Created/Modified
 * GC, 13/4/2002, Created.
 *
 * ReUsed/Modified
 * VT,  22/08/2003
 */

CREATE PROC [dbo].[p_proj_bill_ag_buying_by_camp]   @billing_period_from            datetime,
                                            @billing_period_to              datetime,
                                            @business_unit_id               int,
                                            @media_product_id               int,
                                            @mode                           char(1),
                                            @country_code                   char(1)
with recompile
as

/*
 * Declare Variables
 */

declare     @error_num                      int,
            @current_billing_period         datetime,
            @prev_billing_period_from       datetime,
            @prev_billing_period_to         datetime,
            @period_number_from             int,
            @period_number_to               int,
            @this_period_year_from          int,
            @this_period_year_to            int,
            @prev_period_year               int,
            @agency_buying_group_id         int,
            @billing_amount                 money,
            @prev_billing_amount            money,
            @retcode                        int,
            @buying_group_name              char(100),
            @variation_in_percents          numeric(15, 2),
            @campaign_no                    int,
            @product_desc                   varchar(150),
            @client_name                    varchar(100),
            @agency_name                    varchar(100),
            @branch_code                    varchar(10),
            @sales_rep_Name                 varchar(100),
            @campaign_cost                  money,
            @reporting_agency_same          char(1),
            @date_from                      datetime,
            @date_to                        datetime,
            @tempp                          varchar(60),
            @is_prev_period                 int,
            @report_header                  varchar(50),
            @agency_deal                    char(1),
            @group_desc                     varchar(60),
            @sort_add                       int

CREATE TABLE   #result
(   agency_byuing_group_name    varchar(100)        Null,
    billing_period              datetime            Null,
    period_no                   int                 Null,
    total_amount_this_period    money               Null,
    campaign_no                 int                 NULL,
    product_desc                varchar(150)        null,
    client_name                 varchar(100)        null,
    agency_name                 varchar(100)        null,
    branch_code                 varchar(10)         null,
    sales_rep_Name              varchar(100)        null,
    campaign_cost               money               null,
    reporting_agency_same       char(1)             null,
    prev_period                 tinyint             null,
    group_desc                  varchar(60)         null,
    sort                        int                 null,
    billing_period_to           datetime            Null,
    period_no_to                int                 Null,
)

create table #dates
(   date_to                     datetime            null,
    date_from                   datetime            null,
    is_prev_period              int                 null
)

/* If TO billing period is not specified */
IF IsNull(@billing_period_to, '1900-01-01') = '1900-01-01'
    select @billing_period_to = @billing_period_from


 select @this_period_year_from =  DATEPART(year, finyear_end),
        @period_number_from = period_no
from accounting_period
where end_date = @billing_period_from

select @this_period_year_to =  DATEPART(year, finyear_end),
       @period_number_to = period_no
from accounting_period
where end_date = @billing_period_to

/* salection criteria window validation routine should make sure that 'from-to' billing period <= 12 month */
SELECT @prev_billing_period_from = benchmark_end
FROM   accounting_period
WHERE  period_no = @period_number_from and
       DATEPART(year, finyear_end) =  @this_period_year_from - 1

SELECT @prev_billing_period_to = benchmark_end
FROM   accounting_period
WHERE  period_no = @period_number_to and
       DATEPART(year, finyear_end) =  @this_period_year_to - 1

select  @billing_period_from = benchmark_end
from    accounting_period
where   end_date = @billing_period_from

select  @billing_period_to = benchmark_end
from    accounting_period
where   end_date = @billing_period_to

insert into #dates(date_to,date_from, is_prev_period) values (@billing_period_to,@billing_period_from, 1)
insert into #dates(date_to,date_from, is_prev_period) values (@prev_billing_period_to,@prev_billing_period_from,0)


if @mode = '1' -- Business Unit Header Report     
begin
    select      @report_header = business_unit_desc
    from        business_unit
    where       business_unit_id = @business_unit_id

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
end
else if @mode = '2' -- Media Product Header Report
begin

    select      @report_header = media_product_desc
    from        media_product
    where       media_product_id = @media_product_id

    declare     report_csr cursor static for
    select      null,
                mp.media_product_id,
                ad.agency_deal,
                ad.agency_deal_desc,
                case when  ad.agency_deal = 'Y' then 0 else 100 end 
    from        agency_deal ad,
                media_product mp
    where       mp.system_use_only = 'N'  
	and			mp.media = 'Y'
    and         mp.media_product_id = @media_product_id
    order by    mp.media_product_id,
                ad.agency_deal
    for         read only


end
else
begin
    raiserror ('Error: Unsupported Mode', 16, 1)
    return -1
end

open report_csr
fetch report_csr into @business_unit_id, @media_product_id, @agency_deal, @group_desc, @sort_add
while(@@fetch_status=0)
begin

	/*
	 * Declare Cursors
	 */
	 
	declare     date_csr cursor static for
	select      date_from,
	            date_to,
                is_prev_period
	from        #dates            
	order by    date_from DESC
	for         read only    

    
    open date_csr
    fetch date_csr into @date_from, @date_to, @is_prev_period
    while(@@fetch_status=0)
    begin

		if @mode = '1' -- Business Unit Header Report     
		begin
		    declare     campaign_agency_buying_gr cursor static for
		    select      film_campaign.campaign_no,
		                product_desc,
		                client_name,
		                agency_name,
		                film_campaign.branch_code,
		                RTRIM(sales_rep.First_Name) + ' ' + sales_rep.Last_name,
		                min(campaign_cost),
		                isnull(sum(campaign_spot.charge_rate * (convert(numeric(6,4),x.no_days)/7.0)),0),
		                ( CASE WHEN billing_agency = reporting_agency THEN 'Y' ELSE 'N' END ) as reporting_agency_same,
		                agency_buying_groups.buying_group_id,
		                buying_group_desc
		    from        film_campaign,
		                client,
		                agency,
		                agency_groups,
		                agency_buying_groups,
		                sales_rep,
		                branch,
		                campaign_spot,
		                campaign_package,
		                film_screening_date_xref x
		    where       film_campaign.branch_code = branch.branch_code
		    and         branch.country_code = @country_code
		    and         film_campaign.client_id = client.client_id
		    and         film_campaign.rep_id = sales_rep.rep_id
		    and         film_campaign.reporting_agency = agency.agency_id
		    and         agency.agency_group_id = agency_groups.agency_group_id
		    and         film_campaign.business_unit_id = @business_unit_id
		    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
		    and         campaign_status != 'P'
		    and         billing_date = x.screening_date
		    and         benchmark_end >= @date_from
		    and         benchmark_end <= @date_to
		    and         campaign_spot.campaign_no = film_campaign.campaign_no
		    and         campaign_package.campaign_no = film_campaign.campaign_no
		    and         campaign_spot.package_id = campaign_package.package_id
		    and         campaign_spot.campaign_no = campaign_package.campaign_no
		    and         campaign_package.media_product_id = @media_product_id
		    group by    film_campaign.campaign_no,
		                product_desc,
		                client_name,
		                agency_name,
		                film_campaign.branch_code,
		                RTRIM(sales_rep.First_Name) + ' ' + sales_rep.Last_name,
		                ( CASE WHEN billing_agency = reporting_agency THEN 'Y' ELSE 'N' END ),
		                agency_buying_groups.buying_group_id,
		                buying_group_desc
			union
		    select      film_campaign.campaign_no,
		                product_desc,
		                client_name,
		                agency_name,
		                film_campaign.branch_code,
		                RTRIM(sales_rep.First_Name) + ' ' + sales_rep.Last_name,
		                min(campaign_cost),
		                isnull(sum(cinelight_spot.charge_rate * (convert(numeric(6,4),x.no_days)/7.0)),0),
		                ( CASE WHEN billing_agency = reporting_agency THEN 'Y' ELSE 'N' END ) as reporting_agency_same,
		                agency_buying_groups.buying_group_id,
		                buying_group_desc
		    from        film_campaign,
		                client,
		                agency,
		                agency_groups,
		                agency_buying_groups,
		                sales_rep,
		                branch,
		                cinelight_spot,
		                cinelight_package,
		                film_screening_date_xref x
		    where       film_campaign.branch_code = branch.branch_code
		    and         branch.country_code = @country_code
		    and         film_campaign.client_id = client.client_id
		    and         film_campaign.rep_id = sales_rep.rep_id
		    and         film_campaign.reporting_agency = agency.agency_id
		    and         agency.agency_group_id = agency_groups.agency_group_id
		    and         film_campaign.business_unit_id = @business_unit_id
		    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
		    and         campaign_status != 'P'
		    and         billing_date = x.screening_date
		    and         benchmark_end >= @date_from
		    and         benchmark_end <= @date_to
		    and         cinelight_spot.campaign_no = film_campaign.campaign_no
		    and         cinelight_package.campaign_no = film_campaign.campaign_no
		    and         cinelight_spot.package_id = cinelight_package.package_id
		    and         cinelight_spot.campaign_no = cinelight_package.campaign_no
		    and         cinelight_package.media_product_id = @media_product_id
		    group by    film_campaign.campaign_no,
		                product_desc,
		                client_name,
		                agency_name,
		                film_campaign.branch_code,
		                RTRIM(sales_rep.First_Name) + ' ' + sales_rep.Last_name,
		                ( CASE WHEN billing_agency = reporting_agency THEN 'Y' ELSE 'N' END ),
		                agency_buying_groups.buying_group_id,
		                buying_group_desc
		    ORDER BY    film_campaign.campaign_no
		    for         read only
		    
		end
		else if @mode = '2' -- Media Product Header Report
		begin
		    declare     campaign_agency_buying_gr cursor static for
		    select      film_campaign.campaign_no,
		                product_desc,
		                client_name,
		                agency_name,
		                film_campaign.branch_code,
		                RTRIM(sales_rep.First_Name) + ' ' + sales_rep.Last_name,
		                min(campaign_cost),
		                isnull(sum(campaign_spot.charge_rate * (convert(numeric(6,4),x.no_days)/7.0)),0),
		                ( CASE WHEN billing_agency = reporting_agency THEN 'Y' ELSE 'N' END ) as reporting_agency_same,
		                agency_buying_groups.buying_group_id,
		                buying_group_desc
		    from        film_campaign,
		                client,
		                agency,
		                agency_groups,
		                agency_buying_groups,
		                sales_rep,
		                branch,
		                campaign_spot,
		                campaign_package,
		                film_screening_date_xref x
		    where       film_campaign.branch_code = branch.branch_code
		    and         branch.country_code = @country_code
		    and         film_campaign.client_id = client.client_id
		    and         film_campaign.rep_id = sales_rep.rep_id
		    and         film_campaign.reporting_agency = agency.agency_id
		    and         agency.agency_group_id = agency_groups.agency_group_id
		    and         film_campaign.agency_deal = @agency_deal
		    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
		    and         campaign_status != 'P'
		    and         billing_date = x.screening_date
		    and         benchmark_end >= @date_from
		    and         benchmark_end <= @date_to
		    and         campaign_spot.campaign_no = film_campaign.campaign_no
		    and         campaign_package.campaign_no = film_campaign.campaign_no
		    and         campaign_spot.package_id = campaign_package.package_id
		    and         campaign_spot.campaign_no = campaign_package.campaign_no
		    and         campaign_package.media_product_id = @media_product_id
		    group by    film_campaign.campaign_no,
		                product_desc,
		                client_name,
		                agency_name,
		                film_campaign.branch_code,
		                RTRIM(sales_rep.First_Name) + ' ' + sales_rep.Last_name,
		                ( CASE WHEN billing_agency = reporting_agency THEN 'Y' ELSE 'N' END ),
		                agency_buying_groups.buying_group_id,
		                buying_group_desc
union
		    select      film_campaign.campaign_no,
		                product_desc,
		                client_name,
		                agency_name,
		                film_campaign.branch_code,
		                RTRIM(sales_rep.First_Name) + ' ' + sales_rep.Last_name,
		                min(campaign_cost),
		                isnull(sum(cinelight_spot.charge_rate * (convert(numeric(6,4),x.no_days)/7.0)),0),
		                ( CASE WHEN billing_agency = reporting_agency THEN 'Y' ELSE 'N' END ) as reporting_agency_same,
		                agency_buying_groups.buying_group_id,
		                buying_group_desc
		    from        film_campaign,
		                client,
		                agency,
		                agency_groups,
		                agency_buying_groups,
		                sales_rep,
		                branch,
		                cinelight_spot,
		                cinelight_package,
		                film_screening_date_xref x
		    where       film_campaign.branch_code = branch.branch_code
		    and         branch.country_code = @country_code
		    and         film_campaign.client_id = client.client_id
		    and         film_campaign.rep_id = sales_rep.rep_id
		    and         film_campaign.reporting_agency = agency.agency_id
		    and         agency.agency_group_id = agency_groups.agency_group_id
		    and         film_campaign.agency_deal = @agency_deal
		    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
		    and         campaign_status != 'P'
		    and         billing_date = x.screening_date
		    and         benchmark_end >= @date_from
		    and         benchmark_end <= @date_to
		    and         cinelight_spot.campaign_no = film_campaign.campaign_no
		    and         cinelight_package.campaign_no = film_campaign.campaign_no
		    and         cinelight_spot.package_id = cinelight_package.package_id
		    and         cinelight_spot.campaign_no = cinelight_package.campaign_no
		    and         cinelight_package.media_product_id = @media_product_id
		    group by    film_campaign.campaign_no,
		                product_desc,
		                client_name,
		                agency_name,
		                film_campaign.branch_code,
		                RTRIM(sales_rep.First_Name) + ' ' + sales_rep.Last_name,
		                ( CASE WHEN billing_agency = reporting_agency THEN 'Y' ELSE 'N' END ),
		                agency_buying_groups.buying_group_id,
		                buying_group_desc
		    ORDER BY    film_campaign.campaign_no
		    for         read only
		    
		end
		else
		begin
		    raiserror ('Error: Unsupported Mode', 16, 1)
		    return -1
		end

        open campaign_agency_buying_gr
        fetch campaign_agency_buying_gr INTO @campaign_no, @product_desc, @client_name, @agency_name, @branch_code, @sales_rep_name, @campaign_cost, @billing_amount, @reporting_agency_same, @agency_buying_group_id, @buying_group_name
        WHILE @@fetch_status = 0  /* CAMPAIGNS - BUYING GROUPS */
        begin
            IF IsNull(@date_from, '1900-01-01') <> '1900-01-01'
          /*  begin
                EXECUTE @retcode = p_proj_bill_period_ag_buying  @date_from, @date_to, @agency_buying_group_id, @campaign_no, @business_unit_id, @media_product_id, @agency_deal, @country_code, @billing_amount OUTPUT
                if (@retcode != 0)
                    return -1*/
                
            IF @billing_amount != 0                
                INSERT INTO  #result
                (agency_byuing_group_name,
                billing_period,
                period_no,
                total_amount_this_period,
                campaign_no,
                product_desc,
                client_name,
                agency_name,
                branch_code,
                sales_rep_Name,
                campaign_cost,
                reporting_agency_same,
                prev_period,
                group_desc,
                sort,
                billing_period_to,
                period_no_to
                )  VALUES
                (   @buying_group_name,
                @date_from,
                @period_number_from,
                @billing_amount,
                @campaign_no,
                @product_desc,
                @client_name,
                @agency_name,
                @branch_code,
                @sales_rep_name,
                @campaign_cost,
                @reporting_agency_same,
                @is_prev_period,
                @group_desc,
                @sort_add,
                @date_to,
                @period_number_to
                )
/*            end*/
    
            fetch campaign_agency_buying_gr INTO @campaign_no, @product_desc, @client_name, @agency_name, @branch_code, @sales_rep_name, @campaign_cost, @billing_amount, @reporting_agency_same, @agency_buying_group_id, @buying_group_name
        end  /* CAMPAIGNS - BUYING GROUPS */

        close campaign_agency_buying_gr
		deallocate campaign_agency_buying_gr
        fetch date_csr into @date_from, @date_to, @is_prev_period
    end        
    close date_csr
	deallocate date_csr
    fetch report_csr into @business_unit_id, @media_product_id, @agency_deal, @group_desc, @sort_add
end
deallocate report_csr


select #result.agency_byuing_group_name, #result.billing_period, #result.period_no, #result.total_amount_this_period, #result.campaign_no, #result.product_desc, #result.client_name, #result.agency_name, #result.branch_code, #result.sales_rep_Name, #result.campaign_cost, #result.reporting_agency_same, #result.prev_period, #result.group_desc, #result.sort, #result.billing_period_to, #result.period_no_to, @report_header, @country_code from #result
return 0
GO
