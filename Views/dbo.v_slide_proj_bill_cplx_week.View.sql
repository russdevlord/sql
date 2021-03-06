/****** Object:  View [dbo].[v_slide_proj_bill_cplx_week]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_slide_proj_bill_cplx_week]
GO
/****** Object:  View [dbo].[v_slide_proj_bill_cplx_week]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[v_slide_proj_bill_cplx_week]
AS

select 		    spot.screening_date 'billing_date',
				b.country_code  'country_code',
                1 'business_unit_id',
                5 'media_product_id',
				'S' 'revenue_source',
				screen.complex_id 'complex_id',
				spot.campaign_no,
                sum((isnull(spot.gross_rate,0)) * (complex_list.list_rate / total_list.full_list)) / convert(numeric(20,16),count(screen.complex_id)) 'billings',
				sum((isnull(spot.gross_rate,0) - isnull(spot.nett_rate,0))  * (complex_list.list_rate / total_list.full_list)) / convert(numeric(20,16),count(screen.complex_id))  'agency_commission',
				sum(isnull(spot.nett_rate,0) * (complex_list.list_rate / total_list.full_list)) / convert(numeric(20,16),count(screen.complex_id))  'net_billings'
    from        slide_campaign_spot spot,
				slide_campaign_screening screen,
                slide_campaign sc,
				branch b,
				(select convert(numeric(20,16),(list_rate)) 'list_rate', screens, complex_id, campaign_no from slide_campaign_complex) as complex_list,
				(select convert(numeric(20,16),sum(list_rate)) 'full_list', slide_campaign_complex.campaign_no, sub_spot.spot_id from slide_campaign_complex, slide_campaign_spot sub_spot where slide_campaign_complex.campaign_no = sub_spot.campaign_no and slide_campaign_complex.complex_id in (select complex_id from slide_campaign_screening where spot_id = sub_spot.spot_id) group by slide_campaign_complex.campaign_no, sub_spot.spot_id) as total_list
    where       spot.campaign_no = sc.campaign_no
	and			spot.spot_id = screen.spot_id
	and			sc.branch_code = b.branch_code
    and         spot.billing_status in ('B', 'C', 'L' )
    and			complex_list.complex_id = screen.complex_id
	and			complex_list.campaign_no = spot.campaign_no
	and			total_list.campaign_no = spot.campaign_no
  	and			total_list.spot_id = spot.spot_id
    and         gross_rate != 0
	group by    spot.screening_date,
				b.country_code,
				screen.complex_id,
				spot.campaign_no,
				spot.spot_id
GO
