/****** Object:  StoredProcedure [dbo].[p_vm_br_avg_rate_util]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_vm_br_avg_rate_util]
GO
/****** Object:  StoredProcedure [dbo].[p_vm_br_avg_rate_util]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_vm_br_avg_rate_util]	    @start_date         datetime,
                                        @end_date           datetime,
                                        @country_code       char(1),
                                        @amount             money
as 

declare		@error				int,
            @prev_start_date	datetime,
            @prev_end_date		datetime,
            @avail_time         int

            
set nocount on

select @prev_start_date = dateadd(yy, -1, @start_date)
select @prev_end_date = dateadd(yy, -1, @end_date)

select @avail_time = 0

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
avail_time                      int,
spot_count                      int,
used_time                       int,
duration_type                   varchar(30)
)            


/*
 I.i    Top 50 Follow Film clients current period - paid
 I.ii   Top 50 Follow Film  clients current period - bonus
 I.iii  Top 50 Movie Mix clients current period - paid
 I.iv   Top 50 Movie Mix clients current period - bonus
 I.v    Top 50 Follow Film clients prior period - paid
 I.vi   Top 50 Follow Film  clients prior period - bonus
 I.vii  Top 50 Movie Mix clients prior period - paid
 I.viii Top 50 Movie Mix clients prior period - bonus
 */


/*
 * I.i
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @end_date
and		complex_date.screening_date  >=  @start_date
and		movie_history.screening_date <= @end_date
and		movie_history.screening_date  >=  @start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	  distinct cs.complex_id
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
                        and			fc.campaign_no = film_campaign_reporting_client.campaign_no
                        and         fc.client_id = client.client_id
                        and         client.client_group_id = client_group.client_group_id
                        and         client_group_desc = 'Other'
                        and         fc.client_product_id = product_report_group_client_xref.client_product_id
                        and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
                        and         #core_clients.client_id = client.client_id
                        and         #core_clients.client_mode = 'C'
                        and         band_id = 3
                        group by    cs.complex_id
                        union
                        select 	    distinct cs.complex_id
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
                        and 	    cs.spot_status = 'X'
                        and			fc.campaign_no = film_campaign_reporting_client.campaign_no
                        and         fc.client_id = client.client_id
                        and         client.client_group_id = client_group.client_group_id
                        and         client_group_desc != 'Other'
                        and         fc.client_product_id = product_report_group_client_xref.client_product_id
                        and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
                        and         #core_clients.client_id = client_group.client_group_id
                        and         #core_clients.client_mode = 'G'
                        and         band_id = 3
                        group by    	   cs.complex_id
)

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.ii
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @end_date
and		complex_date.screening_date  >=  @start_date
and		movie_history.screening_date <= @end_date
and		movie_history.screening_date  >=  @start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    cs.complex_id
union
select 	    distinct cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    cs.complex_id
)

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.iii
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @end_date
and		complex_date.screening_date  >=  @start_date
and		movie_history.screening_date <= @end_date
and		movie_history.screening_date  >=  @start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.iv
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @end_date
and		complex_date.screening_date  >=  @start_date
and		movie_history.screening_date <= @end_date
and		movie_history.screening_date  >=  @start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.i
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @end_date
and		complex_date.screening_date  >=  @start_date
and		movie_history.screening_date <= @end_date
and		movie_history.screening_date  >=  @start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.ii
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @end_date
and		complex_date.screening_date  >=  @start_date
and		movie_history.screening_date <= @end_date
and		movie_history.screening_date  >=  @start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    cs.complex_id
union
select 	   cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    cs.complex_id
)

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.iii
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @end_date
and		complex_date.screening_date  >=  @start_date
and		movie_history.screening_date <= @end_date
and		movie_history.screening_date  >=  @start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.iv
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @end_date
and		complex_date.screening_date  >=  @start_date
and		movie_history.screening_date <= @end_date
and		movie_history.screening_date  >=  @start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.i
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @end_date
and		complex_date.screening_date  >=  @start_date
and		movie_history.screening_date <= @end_date
and		movie_history.screening_date  >=  @start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.ii
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @end_date
and		complex_date.screening_date  >=  @start_date
and		movie_history.screening_date <= @end_date
and		movie_history.screening_date  >=  @start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.iii
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @end_date
and		complex_date.screening_date  >=  @start_date
and		movie_history.screening_date <= @end_date
and		movie_history.screening_date  >=  @start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'Paid',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.iv
 */


select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @end_date
and		complex_date.screening_date  >=  @start_date
and		movie_history.screening_date <= @end_date
and		movie_history.screening_date  >=  @start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @start_date, 106) + ' to ' + convert(varchar(20), @end_date, 106),
            'All',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.v
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @prev_end_date
and		complex_date.screening_date  >=  @prev_start_date
and		movie_history.screening_date <= @prev_end_date
and		movie_history.screening_date  >=  @prev_start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.vi
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @prev_end_date
and		complex_date.screening_date  >=  @prev_start_date
and		movie_history.screening_date <= @prev_end_date
and		movie_history.screening_date  >=  @prev_start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	   cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.vii
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @prev_end_date
and		complex_date.screening_date  >=  @prev_start_date
and		movie_history.screening_date <= @prev_end_date
and		movie_history.screening_date  >=  @prev_start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.viii
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @prev_end_date
and		complex_date.screening_date  >=  @prev_start_date
and		movie_history.screening_date <= @prev_end_date
and		movie_history.screening_date  >=  @prev_start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 3
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 3
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.v
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @prev_end_date
and		complex_date.screening_date  >=  @prev_start_date
and		movie_history.screening_date <= @prev_end_date
and		movie_history.screening_date  >=  @prev_start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    cs.complex_id
)

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.vi
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @prev_end_date
and		complex_date.screening_date  >=  @prev_start_date
and		movie_history.screening_date <= @prev_end_date
and		movie_history.screening_date  >=  @prev_start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    cs.complex_id
union
select 	   cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.vii
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @prev_end_date
and		complex_date.screening_date  >=  @prev_start_date
and		movie_history.screening_date <= @prev_end_date
and		movie_history.screening_date  >=  @prev_start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.viii
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @prev_end_date
and		complex_date.screening_date  >=  @prev_start_date
and		movie_history.screening_date <= @prev_end_date
and		movie_history.screening_date  >=  @prev_start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id = 5
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id = 5
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.v
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @prev_end_date
and		complex_date.screening_date  >=  @prev_start_date
and		movie_history.screening_date <= @prev_end_date
and		movie_history.screening_date  >=  @prev_start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.vi
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @prev_end_date
and		complex_date.screening_date  >=  @prev_start_date
and		movie_history.screening_date <= @prev_end_date
and		movie_history.screening_date  >=  @prev_start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.vii
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @prev_end_date
and		complex_date.screening_date  >=  @prev_start_date
and		movie_history.screening_date <= @prev_end_date
and		movie_history.screening_date  >=  @prev_start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
 * I.viii
 */

select 	@avail_time = isnull(sum(complex_date.max_time),0) + isnull(sum(complex_date.mg_max_time),0)
from	complex_date,
        movie_history,
        (select distinct complex.complex_id
        from	complex,
                complex_region_class,
                branch
        where	complex.branch_code = branch.branch_code
        and		branch.country_code = @country_code
        and		complex_region_class.complex_region_class = complex.complex_region_class
        )	as temp_complex_table
where	complex_date.screening_date <= @prev_end_date
and		complex_date.screening_date  >=  @prev_start_date
and		movie_history.screening_date <= @prev_end_date
and		movie_history.screening_date  >=  @prev_start_date
and		complex_date.complex_id = movie_history.complex_id
and		complex_date.complex_id = temp_complex_table.complex_id
and		movie_history.complex_id = temp_complex_table.complex_id
and		complex_date.screening_date = movie_history.screening_date
and		movie_history.advertising_open = 'Y'
and     movie_history.complex_id in (select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc = 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client.client_id
and         #core_clients.client_mode = 'C'
and         band_id not in (5, 3)
group by    cs.complex_id
union
select 	    cs.complex_id
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
and 	    cs.spot_status = 'X'
and			fc.campaign_no = film_campaign_reporting_client.campaign_no
and         fc.client_id = client.client_id
and         client.client_group_id = client_group.client_group_id
and         client_group_desc != 'Other'
and         fc.client_product_id = product_report_group_client_xref.client_product_id
and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
and         #core_clients.client_id = client_group.client_group_id
and         #core_clients.client_mode = 'G'
and         band_id not in (5, 3)
group by    cs.complex_id)

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            product_report_group_desc,
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
            @avail_time,
            isnull(count(cs.charge_rate),0),
            isnull(sum(cp.duration),0),
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
and 	    cs.spot_status = 'X'
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
