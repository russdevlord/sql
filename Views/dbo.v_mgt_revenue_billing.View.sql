/****** Object:  View [dbo].[v_mgt_revenue_billing]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_mgt_revenue_billing]
GO
/****** Object:  View [dbo].[v_mgt_revenue_billing]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_mgt_revenue_billing]
as
    select      fc.campaign_no 'campaign_no',
                x.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                cp.media_product_id 'media_product_id',
                sum(isnull(cs.charge_rate,0)) 'billings',
                'Standard' as type,
                 x.screening_date,
                 fc.start_date
    from        v_spots_non_proposed cs,
                film_screening_date_xref x,
                campaign_package cp,
                film_campaign fc
    where       cs.billing_date = x.screening_date
    and         cs.package_id = cp.package_id
    and         cp.campaign_no = fc.campaign_no
    group by    fc.campaign_no,
                x.finyear_end,
                x.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                cp.media_product_id,
                 x.screening_date,
                 fc.start_date
	union all
    select      fc.campaign_no 'campaign_no',
                x.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                cp.media_product_id 'media_product_id',
                sum(isnull(cs.charge_rate,0)) 'billings',
                'Standard',
                 x.screening_date,
                 fc.start_date
    from        v_cinelight_spots_non_proposed cs,
                film_screening_date_xref x,
                cinelight_package cp,
                film_campaign fc
    where       cs.billing_date = x.screening_date
    and         cs.package_id = cp.package_id
    and         cp.campaign_no = fc.campaign_no
    group by    fc.campaign_no,
                x.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                cp.media_product_id,
                 x.screening_date,
                 fc.start_date
union all
    select      fc.campaign_no 'campaign_no',
                x.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                6 as 'media_product_id',
                sum(isnull(cs.charge_rate,0)) 'billings',
                'Standard',
                 x.screening_date,
                 fc.start_date
    from        v_cinemarketing_spots_non_proposed cs,
                film_screening_date_xref x,
                inclusion inc,
                film_campaign fc
    where       cs.billing_date = x.screening_date
    and         cs.inclusion_id = inc.inclusion_id
    and         inc.campaign_no = fc.campaign_no
    group by    fc.campaign_no,
                x.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                 x.screening_date,
                 fc.start_date
union all        
    select      fc.campaign_no 'campaign_no',
                cs.revenue_period 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                (case inc.inclusion_category when 'C' then 3 when 'D' then 2 when 'F' then 1 when 'I' then 6 end)  as 'media_product_id',
                sum(isnull(cs.takeout_rate,0) * -1) 'billings',
                'Takeouts',
                null,
                 fc.start_date
    from        inclusion_spot cs,
                inclusion inc,
                film_campaign fc
    where       cs.inclusion_id = inc.inclusion_id
    and         inc.campaign_no = fc.campaign_no
    and         inclusion_category <> 'S'
    and         spot_status <> 'P'
    and         inclusion_type <> 21
    group by    fc.campaign_no,
                cs.revenue_period,
                fc.branch_code,
                fc.business_unit_id,
                inc.inclusion_category ,
                 fc.start_date
union all
    select      fc.campaign_no 'campaign_no',
                x.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                6 as 'media_product_id',
                sum(isnull(cs.charge_rate,0)) 'billings',
                'Proxies ' + convert(char(2), inclusion_type),
                 x.screening_date,
                 fc.start_date
    from        inclusion_spot cs,
                film_screening_date_xref x,
                inclusion inc,
                film_campaign fc
    where       cs.billing_date = x.screening_date
    and         cs.inclusion_id = inc.inclusion_id
    and         inc.campaign_no = fc.campaign_no
    and         spot_status <> 'P'
    and         inclusion_type in (select inclusion_type from inclusion_type where inclusion_type_group = 'M')
    group by    fc.campaign_no,
                x.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                inclusion_type,
                 x.screening_date,
                 fc.start_date
union all
    SELECT 	    fc.campaign_no 'campaign_no',
                sl.creation_period  'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                1 as 'media_product_id',
                sum(isnull(sl.spot_amount ,0)) 'billings',
                'Billing Credits',
                 cs.billing_date,
                 fc.start_date
    FROM 		campaign_spot cs,
			    spot_liability sl,
                film_campaign fc
    WHERE		cs.spot_status != 'P'
    AND 		sl.liability_type = 7 
    AND 		cs.spot_id  = sl.spot_id
    and         cs.campaign_no = fc.campaign_no
    GROUP BY	fc.campaign_no,
                sl.creation_period,
                fc.branch_code,
                fc.business_unit_id,
                 cs.billing_date,
                 fc.start_date
union all
    SELECT 	    fc.campaign_no 'campaign_no',
                sl.creation_period  'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                2 as 'media_product_id',
                sum(isnull(sl.spot_amount ,0)) 'billings',
                'Billing Credits',
                 cs.billing_date,
                 fc.start_date
    FROM 		campaign_spot cs,
			    spot_liability sl,
                film_campaign fc
    WHERE		cs.spot_status != 'P'
    AND 		sl.liability_type = 8 
    AND 		cs.spot_id  = sl.spot_id
    and         cs.campaign_no = fc.campaign_no
    GROUP BY	fc.campaign_no,
                sl.creation_period,
                fc.branch_code,
                fc.business_unit_id,
                 cs.billing_date,
                 fc.start_date
union all
    SELECT 	    fc.campaign_no 'campaign_no',
                sl.creation_period  'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                3 as 'media_product_id',
                sum(isnull(sl.spot_amount ,0)) 'billings',
                'Billing Credits',
                 cs.billing_date,
                 fc.start_date
    FROM 		cinelight_spot cs,
			    cinelight_spot_liability sl,
                film_campaign fc
    WHERE		cs.spot_status != 'P'
    AND 		sl.liability_type = 13 
    AND 		cs.spot_id  = sl.spot_id
    and         cs.campaign_no = fc.campaign_no
    GROUP BY	fc.campaign_no,
                sl.creation_period,
                fc.branch_code,
                fc.business_unit_id,
                 cs.billing_date,
                 fc.start_date
union all
    SELECT 	    fc.campaign_no 'campaign_no',
                sl.creation_period  'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                6 as 'media_product_id',
                sum(isnull(sl.spot_amount ,0)) 'billings',
                'Billing Credits',
                 cs.billing_date,
                 fc.start_date
    FROM 		inclusion_spot cs,
			    inclusion_spot_liability sl,
                film_campaign fc
    WHERE		cs.spot_status != 'P'
    AND 		sl.liability_type = 16 
    AND 		cs.spot_id  = sl.spot_id
    and         cs.campaign_no = fc.campaign_no
    GROUP BY	fc.campaign_no,
                sl.creation_period,
                fc.branch_code,
                fc.business_unit_id,
                 cs.billing_date,
                 fc.start_date
	union all
    select      fc.campaign_no 'campaign_no',
                x.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                cp.media_product_id 'media_product_id',
                sum(isnull(cs.charge_rate * round(no_days / 7,2),0)) 'billings',
                'Standard',
                 x.screening_date,
                 fc.start_date
    from        outpost_spot cs,
                outpost_screening_date_xref x,
                outpost_package cp,
                film_campaign fc
    where       cs.billing_date = x.screening_date
    and         cs.package_id = cp.package_id
    and         cp.campaign_no = fc.campaign_no
    and         cs.spot_status <> 'P'
    group by    fc.campaign_no,
                x.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                cp.media_product_id,
                 x.screening_date,
                 fc.start_date
union all
    select      fc.campaign_no 'campaign_no',
                x.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                10 as 'media_product_id',
                sum(isnull((cs.charge_rate * round(no_days/7,2)),0)) 'billings',
                'Standard',
                 x.screening_date,
                 fc.start_date
    from        v_retail_wall_spots_non_proposed cs,
                outpost_screening_date_xref x,
                inclusion inc,
                film_campaign fc
    where       cs.op_billing_date = x.screening_date
    and         cs.inclusion_id = inc.inclusion_id
    and         inc.campaign_no = fc.campaign_no
    group by    fc.campaign_no,
                x.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                 x.screening_date,
                 fc.start_date
GO
