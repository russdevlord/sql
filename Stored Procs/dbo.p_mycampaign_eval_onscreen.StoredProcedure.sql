/****** Object:  StoredProcedure [dbo].[p_mycampaign_eval_onscreen]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_mycampaign_eval_onscreen]
GO
/****** Object:  StoredProcedure [dbo].[p_mycampaign_eval_onscreen]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_mycampaign_eval_onscreen]		@campaign_no				int,
																					@screening_date			datetime,
																					@cumulative_flag			char(1)
																		
as
																		
select 		fc.campaign_no,  
					fc.product_desc,   
					fc.campaign_status,
					fc.start_date,
					fc.end_date, 
					c.client_name,   
					a.agency_name,
					mc.classification_id,
					mc.movie_name,
					cnty.country_name,
					mc.country_code,
					cpack.package_code,
					cpack.package_desc,
					sum(case when spot.spot_type = 'S' then 1 else 0 end) as scheduled_count,
					sum(case when spot.spot_type in ('M','V') then 1 else 0 end) as makeup_count
from 			campaign_package AS cpack 
					INNER JOIN campaign_spot AS spot ON cpack.package_id = spot.package_id 
					INNER JOIN	v_certificate_item_distinct AS ci ON spot.spot_id = ci.spot_reference 
					INNER JOIN	certificate_group AS cg ON ci.certificate_group = cg.certificate_group_id 
					INNER JOIN	complex_date AS cd ON spot.screening_date = cd.screening_date AND spot.complex_id = cd.complex_id 
					INNER JOIN complex AS cplx ON cd.complex_id = cplx.complex_id
					INNER JOIN branch as b on cplx.branch_code = b.branch_code
					INNER JOIN movie_country  AS mc ON mc.country_code = b.country_code
					INNER JOIN film_campaign AS fc ON fc.campaign_no = cpack.campaign_no  
					INNER JOIN agency AS a ON fc.agency_id = a.agency_id
					INNER JOIN client AS c ON c.client_id = fc.client_id
					INNER JOIN country AS cnty ON cnty.country_code = b.country_code
					LEFT OUTER JOIN	movie_history AS mh ON cg.certificate_group_id = mh.certificate_group 
where 		fc.campaign_no = @campaign_no				
and 			spot.spot_status = 'X' 
and 		((spot.screening_date = @screening_date and @cumulative_flag = 'N') or (spot.screening_date <= @screening_date and @cumulative_flag = 'Y'))	
group by 	fc.campaign_no,  
					fc.product_desc,   
					fc.campaign_status,
					fc.start_date,
					fc.end_date, 
					c.client_name,   
					a.agency_name,
					mc.classification_id,
					mc.movie_name,
					cnty.country_name,
					mc.country_code,
					cpack.package_code,
					cpack.package_desc	
			
			
return 0
GO
