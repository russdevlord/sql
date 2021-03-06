/****** Object:  StoredProcedure [dbo].[p_vm_br_avg_rate]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_vm_br_avg_rate]
GO
/****** Object:  StoredProcedure [dbo].[p_vm_br_avg_rate]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_vm_br_avg_rate]	            @start_date         datetime,
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
 
insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

/*
 * F.iii
 */
 
insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'


/*
 * F.iv
 */
 
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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

/*
 * F.v
 */
 
insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'Paid',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'

/*
 * F.vi
 */
 
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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('S')
and 	    cs.spot_status != 'P'

/*
 * F.vii
 */
 
insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Follow Film',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

/*
 * F.viii
 */
 
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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'Y'
and 	    cs.spot_status != 'P'

/*
 * F.ix
 */
 
insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Movie Mix',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'


/*
 * F.x
 */
 
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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and         cp.follow_film = 'N'
and 	    cs.spot_status != 'P'

/*
 * F.xi
 */
 
insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            '30 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            '60 sec',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @prev_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'

insert into #avg_rate_and_util
select 	    'Overview',
            'Total',
            convert(varchar(20), @prev_6_start_date, 106) + ' to ' + convert(varchar(20), @prev_end_date, 106),
            'All',
            'Other',
            isnull(avg(cs.charge_rate),0),
            isnull(count(cs.charge_rate),0),
            isnull(sum(cs.charge_rate),0)
from	    campaign_spot cs,
            film_campaign fc,
            campaign_package cp,
            branch b,
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @prev_end_date
and		    cs.billing_date >=  @prev_6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'

/*
 * F.xii
 */
 
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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 3
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id = 5
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'

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
            complex
where	    cs.campaign_no = fc.campaign_no
and		    cs.package_id = cp.package_id
and		    fc.branch_code = b.branch_code
and		    b.country_code = @country_code
and		    cs.billing_date <= @end_date
and		    cs.billing_date >=  @6_start_date
and		    cs.complex_id = complex.complex_id and complex.complex_region_class in (select complex_region_class from complex_region_class where regional_indicator = @regional_indicator)
and         cp.band_id not in (3,5)
and		    cs.spot_type in ('B','C','N','S')
and 	    cs.spot_status != 'P'


select *, @regional_indicator from #avg_rate_and_util

return 0
GO
