/****** Object:  StoredProcedure [dbo].[p_vm_br_avg_rate_products]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_vm_br_avg_rate_products]
GO
/****** Object:  StoredProcedure [dbo].[p_vm_br_avg_rate_products]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_vm_br_avg_rate_products]	    @start_date         datetime,
                                            @end_date           datetime,
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
client_id           int,
client_mode         char(1)
)


insert  into #core_clients
select  client_id,
        source
from (  select      'C' as source,
                    sum(cost) as  revenue,
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
        and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
        and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
        group by    film_campaign_reporting_client.client_id
                    
        union            
                    
        select 		'G' as source,
                    sum(cost) as  revenue,
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
        and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
        and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
        group by    client_group.client_group_id) as temp_table
group by    source,
            client_id                    
having      sum(revenue) >= @amount            
order by    client_id


            
create table #avg_rate_and_util
(
kpi_mode                        varchar(30), --overview, top 50, industry/report product groups
kpi_type                        varchar(50), --follow film, movie mix, total, top 50, industry
product_report_group_desc       varchar(50), --product_report_group_desc
period                          varchar(30), --last 12 months prior 12 months
spot_type                       varchar(30), --paid, bonus
avg_rate                        money,
spot_count                      int,
revenue                         money,
duration_type                   varchar(30)
)            


/*
 H.i    Top 50 Follow Film clients current period - paid
 H.ii   Top 50 Follow Film  clients current period - bonus
 H.iii  Top 50 Movie Mix clients current period - paid
 H.iv   Top 50 Movie Mix clients current period - bonus
 H.v    Top 50 Follow Film clients prior period - paid
 H.vi   Top 50 Follow Film  clients prior period - bonus
 H.vii  Top 50 Movie Mix clients prior period - paid
 H.viii Top 50 Movie Mix clients prior period - bonus
 */

/*
 * H.i
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    product_report_group_desc
union
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    product_report_group_desc

/*
 * H.ii
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    product_report_group_desc
union
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    product_report_group_desc

/*
 * H.iii
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    product_report_group_desc
union
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    product_report_group_desc

/*
 * H.iv
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    product_report_group_desc
union
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    product_report_group_desc


/*
 * H.i
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    product_report_group_desc
union
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    product_report_group_desc

/*
 * H.ii
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    product_report_group_desc
union
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    product_report_group_desc

/*
 * H.iii
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    product_report_group_desc
union
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    product_report_group_desc

/*
 * H.iv
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    product_report_group_desc
union
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    product_report_group_desc


/*
 * H.i
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    product_report_group_desc
union
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    product_report_group_desc

/*
 * H.ii
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    product_report_group_desc
union
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    product_report_group_desc

/*
 * H.iii
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    product_report_group_desc
union
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    product_report_group_desc

/*
 * H.iv
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    product_report_group_desc
union
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    product_report_group_desc

delete #core_clients


insert  into #core_clients
select  client_id,
        source
from (  select      'C' as source,
                    sum(cost) as  revenue,
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
        and         revision_transaction.revenue_period between @prev_start_date and @prev_end_date
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
        group by    film_campaign_reporting_client.client_id
                    
        union            
                    
        select 		'G' as source,
                    sum(cost) as  revenue,
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
        and         revision_transaction.revenue_period between @prev_start_date and @prev_end_date
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
        group by    client_group.client_group_id) as temp_table
group by    source,
            client_id                    
having      sum(revenue) >= @amount            
order by    client_id

/*
 * H.v
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    product_report_group_desc
union
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    product_report_group_desc

/*
 * H.vi
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    product_report_group_desc
union
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    product_report_group_desc

/*
 * H.vii
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    product_report_group_desc
union
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    product_report_group_desc

/*
 * H.viii
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    product_report_group_desc
union
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '30 Sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    product_report_group_desc


/*
 * H.v
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    product_report_group_desc
union
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    product_report_group_desc

/*
 * H.vi
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    product_report_group_desc
union
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    product_report_group_desc

/*
 * H.vii
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    product_report_group_desc
union
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    product_report_group_desc

/*
 * H.viii
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    product_report_group_desc
union
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            '60 sec'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    product_report_group_desc

/*
 * H.v
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    product_report_group_desc
union
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    product_report_group_desc

/*
 * H.vi
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    product_report_group_desc
union
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    product_report_group_desc

/*
 * H.vii
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    product_report_group_desc
union
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    product_report_group_desc

/*
 * H.viii
 */

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    product_report_group_desc
union
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0),
            'Other'
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex,
            client,
            client_group,
            film_campaign_reporting_client,
            product_report_groups,
            product_report_group_client_xref,
            #core_clients
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id
and		    cs.spot_type in ('S','C','B','N')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    product_report_group_desc


select * from #avg_rate_and_util

return 0
GO
