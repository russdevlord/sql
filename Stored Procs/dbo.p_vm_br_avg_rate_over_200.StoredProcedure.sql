/****** Object:  StoredProcedure [dbo].[p_vm_br_avg_rate_over_200]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_vm_br_avg_rate_over_200]
GO
/****** Object:  StoredProcedure [dbo].[p_vm_br_avg_rate_over_200]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_vm_br_avg_rate_over_200]       @start_date         datetime,
                                            @end_date           datetime,
                                            @regional_indicator char(1),
                                            @country_code       char(1),
                                            @amount             money
as 

declare		@error				int,
            @prev_start_date	datetime,
            @prev_end_date		datetime,
            @prev_6_start_date	datetime,
            @6_start_date		datetime

            
set nocount on

select @prev_start_date = dateadd(yy, -1, @start_date)
select @prev_end_date = dateadd(yy, -1, @end_date)

select @prev_6_start_date = dateadd(mm, -6, @start_date)
select @6_start_date = dateadd(mm, 6, @start_date)

create table #core_clients
(
client_mode             varchar(20), 
period                  varchar(50), 
client_name             varchar(50), 
revenue                 money, 
no_campaigns            int,
client_id               int
)

insert  into #core_clients
select  source,
        period, 
        client_name, 
        sum(revenue), 
        sum(no_campaigns), 
        client_id
from (  select      'Client' as source,
                    convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106)  as period,
                    client.client_name,
                    sum(cost) as  revenue,
                    count(distinct film_campaign.campaign_no) as no_campaigns,
                    film_campaign_reporting_client.client_id
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
        and         delta_date < '26-feb-2010'
        and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
        and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
        group by    client.client_name,
                    film_campaign_reporting_client.client_id
                    
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
        and         delta_date < '26-feb-2010'
        and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
        and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
        group by    client_group.client_group_desc,
                    client_group.client_group_id) as temp_table
group by    source,
            period, 
            client_name, 
            client_id                    
having      sum(revenue) >= @amount            
order by    client_id

            
create table #avg_rate_and_util
(
kpi_mode        varchar(30), --overview, top 50, industry/report product groups
kpi_type        varchar(50), --follow film, movie mix, total, top 50, industry
period          varchar(30), --last 12 months prior 12 months
spot_type       varchar(30), --paid, bonus
duration_type   varchar(30), --30 sec, 60 sec, other
avg_rate        money,
spot_count      int,
revenue         money
)            

/*
 F.i    FF prior period - paid
 F.ii   FF current period - paid
 F.iii  MM prior period - paid
 F.iv   MM current period - paid
 F.v    Total prior period - paid
 F.vi   Total current period - paid
 F.vii  FF prior period - bonus
 F.viii FF current period - bonus
 F.ix   MM prior period - bonus
 F.x    MM current period - bonus
 F.xi   Total prior period - bonus
 F.xii  Total current period - bonus
 */

/*
 * F.i
 */
 


/*
 * F.ii
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

 
insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id


insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

 
insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id


insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @6_start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            v_client_groups,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = 'A'
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'
and         v_client_groups.campaign_no = fc.campaign_no
and         v_client_groups.source_mode = #core_clients.client_mode
and         v_client_groups.source_id = #core_clients.client_id


select *, @regional_indicator from #avg_rate_and_util

return 0
GO
