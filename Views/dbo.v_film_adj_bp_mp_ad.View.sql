/****** Object:  View [dbo].[v_film_adj_bp_mp_ad]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_film_adj_bp_mp_ad]
GO
/****** Object:  View [dbo].[v_film_adj_bp_mp_ad]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_film_adj_bp_mp_ad]
AS

    select      ap.finyear_end 'finyear', 
                ap.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                cp.media_product_id 'media_product_id',
                fc.agency_deal 'agency_deal',
                sum(sl.spot_amount) 'adjustment'
    from        v_spots_non_proposed cs,
				spot_liability sl,
                accounting_period ap,
                campaign_package cp,
                film_campaign fc,
				campaign_transaction ct,
				transaction_allocation ta
    where       cs.billing_date between ap.benchmark_start and ap.benchmark_end
    and         cs.package_id = cp.package_id
    and         cp.campaign_no = fc.campaign_no
	and			sl.spot_id = cs.spot_id
	and			ct.campaign_no = cs.campaign_no
	and			ta.allocation_id = sl.allocation_id
	and 		ta.from_tran_id = ct.tran_id 
	and			ta.to_tran_id is not null
	and			ct.tran_type  in (7,8)
    group by    ap.finyear_end,
                ap.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                cp.media_product_id,
                fc.agency_deal	
	union
    select      ap.finyear_end 'finyear', 
                ap.benchmark_end 'accounting_period',
                fc.branch_code  'branch_code',
                fc.business_unit_id 'business_unit_id',
                cp.media_product_id 'media_product_id',
                fc.agency_deal 'agency_deal',
                sum(sl.spot_amount) 'adjustment'
    from        v_cinelight_spots_non_proposed cs,
				cinelight_spot_liability sl,
                accounting_period ap,
                cinelight_package cp,
                film_campaign fc,
				campaign_transaction ct,
				transaction_allocation ta
    where       cs.billing_date between ap.benchmark_start and ap.benchmark_end
    and         cs.package_id = cp.package_id
    and         cp.campaign_no = fc.campaign_no
	and			sl.spot_id = cs.spot_id
	and			ct.campaign_no = cs.campaign_no
	and			ta.allocation_id = sl.allocation_id
	and 		ta.from_tran_id = ct.tran_id 
	and			ta.to_tran_id is not null
	and			ct.tran_type  in (7,8)
    group by    ap.finyear_end,
                ap.benchmark_end,
                fc.branch_code,
                fc.business_unit_id,
                cp.media_product_id,
                fc.agency_deal
GO
