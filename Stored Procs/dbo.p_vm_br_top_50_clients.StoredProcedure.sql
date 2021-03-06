/****** Object:  StoredProcedure [dbo].[p_vm_br_top_50_clients]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_vm_br_top_50_clients]
GO
/****** Object:  StoredProcedure [dbo].[p_vm_br_top_50_clients]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_vm_br_top_50_clients]          @start_date         datetime,
                                            @end_date           datetime
as

declare     @prev_start_date        datetime,
            @prev_end_date          datetime,
            @source                 varchar(20),
            @source_id              int

set nocount on

select @prev_start_date = dateadd(yy, -1, @start_date)
select @prev_end_date = dateadd(yy, -1, @end_date)

create table #top_50_clients
(
source                  varchar(20), 
period                  varchar(50), 
client_name             varchar(50), 
revenue                 money, 
no_campaigns            int,
source_id               int
)

insert  into #top_50_clients
select  top 50 source,
        period, 
        client_name, 
        revenue, 
        no_campaigns, 
        client_id
from (  select      'Client' as source,
                    convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106)  as period,
                    client.client_name,
                    sum(cost) as  revenue,
                    count(distinct film_campaign.campaign_no) as no_campaigns,
                    client.client_id
        from 		revision_transaction,
                    campaign_revision,
                    revision_transaction_type,
                    film_campaign,
                    v_campaign_product vcpc,
                    product_category,
                    client,
                    client_group,
                    agency,
                    agency_groups,
                    agency_buying_groups,
                    accounting_period,
                    product_report_groups,
                    product_report_group_xref
        where 		revision_transaction.revision_id = campaign_revision.revision_id
        and			campaign_revision.campaign_no = film_campaign.campaign_no
        and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
        and         vcpc.campaign_no = film_campaign.campaign_no
        and         vcpc.product_category_id = product_category.product_category_id
        and         accounting_period.end_date = revision_transaction.revenue_period
        and         revision_transaction.revenue_period between @start_date and @end_date
        and         film_campaign.client_id = client.client_id
        and         client.client_group_id = client_group.client_group_id
        and         film_campaign.reporting_agency = agency.agency_id
        and         film_campaign.branch_code <> 'Z'
        and         agency.agency_group_id = agency_groups.agency_group_id
        and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
        and         film_campaign.campaign_status <> 'P'
        and         client_group_desc = 'Other'
        and         vcpc.product_category_id = product_report_group_xref.product_category_id
        and         product_report_group_xref.product_report_group_id = product_report_groups.product_report_group_id
        group by    client.client_name,
                    client.client_id
                    
        union            
                    
        select 		'Client Group' as source,
                    convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106)  as period,
                    client_group.client_group_desc,
                    sum(cost) as  revenue,
                    count(distinct film_campaign.campaign_no) as no_campaigns,
                    client_group.client_group_id
        from 		revision_transaction,
                    campaign_revision,
                    revision_transaction_type,
                    film_campaign,
                    v_campaign_product vcpc,
                    product_category,
                    client,
                    client_group,
                    agency,
                    agency_groups,
                    agency_buying_groups,
                    accounting_period,
                    product_report_groups,
                    product_report_group_xref
        where 		revision_transaction.revision_id = campaign_revision.revision_id
        and			campaign_revision.campaign_no = film_campaign.campaign_no
        and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
        and         vcpc.campaign_no = film_campaign.campaign_no
        and         vcpc.product_category_id = product_category.product_category_id
        and         accounting_period.end_date = revision_transaction.revenue_period
        and         revision_transaction.revenue_period between @start_date and @end_date
        and         film_campaign.client_id = client.client_id
        and         film_campaign.branch_code <> 'Z'
        and         client.client_group_id = client_group.client_group_id
        and         film_campaign.reporting_agency = agency.agency_id
        and         agency.agency_group_id = agency_groups.agency_group_id
        and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
        and         film_campaign.campaign_status <> 'P'
        and         client_group_desc != 'Other'
        and         vcpc.product_category_id = product_report_group_xref.product_category_id
        and         product_report_group_xref.product_report_group_id = product_report_groups.product_report_group_id
        group by    client_group.client_group_desc,
                    client_group.client_group_id) as temp_table
order by  revenue DESC


declare top_50_csr cursor forward_only for
select  source,
        source_id
from    #top_50_clients
order by source_id

open top_50_csr
fetch top_50_csr into @source, @source_id
while(@@fetch_status=0)
begin

    insert into #top_50_clients
    select 		@source,
                convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106)  as period,
                client.client_name,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                client.client_id
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                v_campaign_product vcpc,
                product_category,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_xref
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         vcpc.campaign_no = film_campaign.campaign_no
    and         vcpc.product_category_id = product_category.product_category_id
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period between @prev_start_date and @prev_end_date
    and         film_campaign.client_id = client.client_id
    and         film_campaign.branch_code <> 'Z'
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client'
    and         @source_id = client.client_id
    and         vcpc.product_category_id = product_report_group_xref.product_category_id
    and         product_report_group_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client.client_name,
                client.client_id
    union                
    select 		@source,
                convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106)  as period,
                client_group.client_group_desc,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                client_group.client_group_id
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                v_campaign_product vcpc,
                product_category,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_xref
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         vcpc.campaign_no = film_campaign.campaign_no
    and         vcpc.product_category_id = product_category.product_category_id
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period between @prev_start_date and @prev_end_date
    and         film_campaign.client_id = client.client_id
    and         film_campaign.branch_code <> 'Z'
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client Group'
    and         @source_id = client_group.client_group_id
    and         vcpc.product_category_id = product_report_group_xref.product_category_id
    and         product_report_group_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client_group.client_group_desc,
                client_group.client_group_id

    insert into #top_50_clients
    select 		@source,
                'Forward Bookings'  as period,
                client.client_name,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                client.client_id
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                v_campaign_product vcpc,
                product_category,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_xref
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         vcpc.campaign_no = film_campaign.campaign_no
    and         vcpc.product_category_id = product_category.product_category_id
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period > @end_date
    and         film_campaign.client_id = client.client_id
    and         film_campaign.branch_code <> 'Z'
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client'
    and         @source_id = client.client_id
    and         vcpc.product_category_id = product_report_group_xref.product_category_id
    and         product_report_group_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client.client_name,
                client.client_id
    union                
    select 		@source,
                'Forward Bookings'  as period,
                client_group.client_group_desc,
                sum(cost) as  revenue,
                count(distinct film_campaign.campaign_no) as no_campaigns,
                client_group.client_group_id
    from 		revision_transaction,
                campaign_revision,
                revision_transaction_type,
                film_campaign,
                v_campaign_product vcpc,
                product_category,
                client,
                client_group,
                agency,
                agency_groups,
                agency_buying_groups,
                accounting_period,
                product_report_groups,
                product_report_group_xref
    where 		revision_transaction.revision_id = campaign_revision.revision_id
    and			campaign_revision.campaign_no = film_campaign.campaign_no
    and			revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type
    and         vcpc.campaign_no = film_campaign.campaign_no
    and         vcpc.product_category_id = product_category.product_category_id
    and         accounting_period.end_date = revision_transaction.revenue_period
    and         revision_transaction.revenue_period > @end_date
    and         film_campaign.client_id = client.client_id
    and         film_campaign.branch_code <> 'Z'
    and         client.client_group_id = client_group.client_group_id
    and         film_campaign.reporting_agency = agency.agency_id
    and         agency.agency_group_id = agency_groups.agency_group_id
    and         agency_groups.buying_group_id = agency_buying_groups.buying_group_id
    and         film_campaign.campaign_status <> 'P'
    and         @source = 'Client Group'
    and         @source_id = client_group.client_group_id
    and         vcpc.product_category_id = product_report_group_xref.product_category_id
    and         product_report_group_xref.product_report_group_id = product_report_groups.product_report_group_id
    group by    client_group.client_group_desc,
                client_group.client_group_id

    fetch top_50_csr into @source, @source_id
end

select * from #top_50_clients
return 0
GO
