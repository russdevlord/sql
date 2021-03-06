/****** Object:  StoredProcedure [dbo].[p_vm_br_core_clients]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_vm_br_core_clients]
GO
/****** Object:  StoredProcedure [dbo].[p_vm_br_core_clients]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_vm_br_core_clients]        @start_date         datetime,
                                        @end_date           datetime,
                                        @country_code       char(1),
                                        @amount             money
as

declare     @prev_start_date        datetime,
            @prev_end_date          datetime,
            @source                 varchar(20),
            @source_id              int,
            @prev_6_month_start     datetime,
            @6_month_start     datetime

set nocount on

select @prev_start_date = dateadd(yy, -1, @start_date)
select @prev_end_date = dateadd(yy, -1, @end_date)
select @prev_6_month_start = dateadd(mm, -6, @start_date)
select @6_month_start = dateadd(mm, 6, @start_date)


create table #core_clients
(
source                  varchar(20), 
period                  varchar(50), 
client_name             varchar(50), 
revenue                 money, 
no_campaigns            int,
source_id               int,
period_sort             varchar(20)
)

insert  into #core_clients
select  source,
        period, 
        client_name, 
        sum(revenue), 
        sum(no_campaigns), 
        client_id,
        period_sort
from (  select      'Client' as source,
                    convert(varchar(20), @start_date, 6) + ' to ' + convert(varchar(20), @end_date, 6)  as period,
                    client.client_name,
                    sum(cost) as  revenue,
                    count(distinct film_campaign.campaign_no) as no_campaigns,
                    film_campaign_reporting_client.client_id,
                    'Rolling 12 Months' as period_sort
        from 		revision_transaction,
                    campaign_revision,
                    revision_transaction_type,
                    film_campaign,
                    client,
                    client_group,
                    agency,
                    agency_groups,
                    agency_buying_groups,
                    accounting_period,
                    product_report_groups,
                    product_report_group_client_xref,
                    film_campaign_reporting_client
        where 		revision_transaction.revision_id = campaign_revision.revision_id
        and			campaign_revision.campaign_no = film_campaign.campaign_no
        and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
        and         accounting_period.end_date = revision_transaction.revenue_period
        and         revision_transaction.revenue_period between @start_date and @end_date
        and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
        and         film_campaign_reporting_client.client_id = client.client_id
        and         client.client_group_id = client_group.client_group_id
        and         film_campaign.reporting_agency = agency.agency_id
        and         film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
        and         agency.agency_group_id = agency_groups.agency_group_id
        and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
        and         film_campaign.campaign_status <> 'P'
        and         client_group_desc = 'Other'
        and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
        and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
        group by    client.client_name,
                    film_campaign_reporting_client.client_id
                    
        union            
                    
        select 		'Client Group' as source,
                    convert(varchar(20), @start_date, 6) + ' to ' + convert(varchar(20), @end_date, 6)  as period,
                    client_group.client_group_desc,
                    sum(cost) as  revenue,
                    count(distinct film_campaign.campaign_no) as no_campaigns,
                    client_group.client_group_id,
                    'Rolling 12 Months' as period_sort
        from 		revision_transaction,
                    campaign_revision,
                    revision_transaction_type,
                    film_campaign,
                    client,
                    client_group,
                    agency,
                    agency_groups,
                    agency_buying_groups,
                    accounting_period,
                    product_report_groups,
                    product_report_group_client_xref,
                    film_campaign_reporting_client
        where 		revision_transaction.revision_id = campaign_revision.revision_id
        and			campaign_revision.campaign_no = film_campaign.campaign_no
        and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
        and         accounting_period.end_date = revision_transaction.revenue_period
        and         revision_transaction.revenue_period between @start_date and @end_date
        and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
        and         film_campaign_reporting_client.client_id = client.client_id
        and         film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
        and         client.client_group_id = client_group.client_group_id
        and         film_campaign.reporting_agency = agency.agency_id
        and         agency.agency_group_id = agency_groups.agency_group_id
        and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
        and         film_campaign.campaign_status <> 'P'
        and         client_group_desc != 'Other'
        and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
        and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
        group by    client_group.client_group_desc,
                    client_group.client_group_id) as temp_table
group by    source,
            period, 
            client_name, 
            client_id,
            period_sort                  
having      sum(revenue) > @amount            
order by    client_id


declare core_csr cursor forward_only for
select  source,
        source_id
from    #core_clients
order by source_id

open core_csr
fetch core_csr into @source, @source_id
while(@@fetch_status=0)
begin

insert into #core_clients
    select 		@source,
                convert(varchar(20), dateadd(yy, -1, @prev_start_date), 6) + ' to ' + convert(varchar(20), @prev_end_date, 6)  as period,
                client.client_name,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                film_campaign_reporting_client.client_id,
                'Rolling 24 Months' as period_sort
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_client_xref,
                film_campaign_reporting_client
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period between dateadd(yy, -1, @prev_start_date) and @prev_end_date
    and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
    and         film_campaign_reporting_client.client_id = client.client_id
    and         film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client'
    and         @source_id = client.client_id
    and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
    and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client.client_name,
                film_campaign_reporting_client.client_id
    union                
    select 		@source,
                convert(varchar(20), dateadd(yy, -1, @prev_start_date), 6) + ' to ' + convert(varchar(20), @prev_end_date, 6)  as period,
                client_group.client_group_desc,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                client_group.client_group_id,
                'Rolling 24 Months' as period_sort
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_client_xref,
                film_campaign_reporting_client
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period between dateadd(yy, -1, @prev_start_date) and @prev_end_date
    and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
    and         film_campaign_reporting_client.client_id = client.client_id
    and         film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client Group'
    and         @source_id = client_group.client_group_id
    and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
    and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client_group.client_group_desc,
                client_group.client_group_id

    insert into #core_clients
    select 		@source,
                convert(varchar(20), dateadd(yy, -1, @start_date), 6) + ' to ' + convert(varchar(20), @end_date, 6)  as period,
                client.client_name,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                film_campaign_reporting_client.client_id,
                'Rolling 24 Months' as period_sort
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_client_xref,
                film_campaign_reporting_client
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period between dateadd(yy, -1, @start_date) and @end_date
    and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
    and         film_campaign_reporting_client.client_id = client.client_id
    and         film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client'
    and         @source_id = client.client_id
    and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
    and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client.client_name,
                film_campaign_reporting_client.client_id
    union                
    select 		@source,
                convert(varchar(20), dateadd(yy, -1, @start_date), 6) + ' to ' + convert(varchar(20), @end_date, 6)  as period,
                client_group.client_group_desc,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                client_group.client_group_id,
                'Rolling 24 Months' as period_sort
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_client_xref,
                film_campaign_reporting_client
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period between dateadd(yy, -1, @start_date) and @end_date
    and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
    and         film_campaign_reporting_client.client_id = client.client_id
    and         film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client Group'
    and         @source_id = client_group.client_group_id
    and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
    and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client_group.client_group_desc,
                client_group.client_group_id
                
    insert into #core_clients
    select 		@source,
                convert(varchar(20), @prev_start_date, 6) + ' to ' + convert(varchar(20), @prev_end_date, 6)  as period,
                client.client_name,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                film_campaign_reporting_client.client_id,
                'Rolling 12 Months' as period_sort
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_client_xref,
                film_campaign_reporting_client
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period between @prev_start_date and @prev_end_date
    and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
    and         film_campaign_reporting_client.client_id = client.client_id
    and         film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client'
    and         @source_id = client.client_id
    and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
    and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client.client_name,
                film_campaign_reporting_client.client_id
    union                
    select 		@source,
                convert(varchar(20), @prev_start_date, 6) + ' to ' + convert(varchar(20), @prev_end_date, 6)  as period,
                client_group.client_group_desc,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                client_group.client_group_id,
                'Rolling 12 Months' as period_sort
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_client_xref,
                film_campaign_reporting_client
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period between @prev_start_date and @prev_end_date
    and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
    and         film_campaign_reporting_client.client_id = client.client_id
    and         film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client Group'
    and         @source_id = client_group.client_group_id
    and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
    and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client_group.client_group_desc,
                client_group.client_group_id

    insert into #core_clients
    select 		@source,
                convert(varchar(20), @6_month_start, 6) + ' to ' + convert(varchar(20), @end_date, 6)  as period,
                client.client_name,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                film_campaign_reporting_client.client_id,
                'Rolling 6 Months' as period_sort
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_client_xref,
                film_campaign_reporting_client
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period between @6_month_start and @end_date
    and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
    and         film_campaign_reporting_client.client_id = client.client_id
    and         film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client'
    and         @source_id = client.client_id
    and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
    and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client.client_name,
                film_campaign_reporting_client.client_id
    union                
    select 		@source,
                convert(varchar(20), @6_month_start, 6) + ' to ' + convert(varchar(20), @end_date, 6)  as period,
                client_group.client_group_desc,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                client_group.client_group_id,
                'Rolling 6 Months' as period_sort
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_client_xref,
                film_campaign_reporting_client
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period between @6_month_start and @end_date
    and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
    and         film_campaign_reporting_client.client_id = client.client_id
    and         film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client Group'
    and         @source_id = client_group.client_group_id
    and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
    and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client_group.client_group_desc,
                client_group.client_group_id

    insert into #core_clients
    select 		@source,
                convert(varchar(20), @prev_6_month_start, 6) + ' to ' + convert(varchar(20), @prev_end_date, 6)  as period,
                client.client_name,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                film_campaign_reporting_client.client_id,
                'Rolling 6 Months' as period_sort
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_client_xref,
                film_campaign_reporting_client
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period between @prev_6_month_start and @prev_end_date
    and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
    and         film_campaign_reporting_client.client_id = client.client_id
    and         film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client'
    and         @source_id = client.client_id
    and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
    and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client.client_name,
                film_campaign_reporting_client.client_id
    union                
    select 		@source,
                convert(varchar(20), @prev_6_month_start, 6) + ' to ' + convert(varchar(20), @prev_end_date, 6)  as period,
                client_group.client_group_desc,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                client_group.client_group_id,
                'Rolling 6 Months' as period_sort
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_client_xref,
                film_campaign_reporting_client
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period between @prev_6_month_start and @prev_end_date
    and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
    and         film_campaign_reporting_client.client_id = client.client_id
    and         film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client Group'
    and         @source_id = client_group.client_group_id
    and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
    and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client_group.client_group_desc,
                client_group.client_group_id
                
                
    insert into #core_clients
    select 		@source,
                'Forward Bookings'  as period,
                client.client_name,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                film_campaign_reporting_client.client_id,
                'Forward Bookings' as period_sort
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_client_xref,
                film_campaign_reporting_client
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period > @end_date
    and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
    and         film_campaign_reporting_client.client_id = client.client_id
    and         film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client'
    and         @source_id = client.client_id
    and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
    and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client.client_name,
                film_campaign_reporting_client.client_id
    union                
    select 		@source,
                'Forward Bookings'  as period,
                client_group.client_group_desc,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                client_group.client_group_id,
                'Forward Bookings' as period_sort
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_client_xref,
                film_campaign_reporting_client
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period > @end_date
    and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
    and         film_campaign_reporting_client.client_id = client.client_id
    and         film_campaign.branch_code in (select branch_code from branch where country_code = @country_code)
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client Group'
    and         @source_id = client_group.client_group_id
    and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
    and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client_group.client_group_desc,
                client_group.client_group_id

    fetch core_csr into @source, @source_id
end

select * from #core_clients
return 0
GO
