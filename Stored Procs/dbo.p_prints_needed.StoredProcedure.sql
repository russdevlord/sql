/****** Object:  StoredProcedure [dbo].[p_prints_needed]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_prints_needed]
GO
/****** Object:  StoredProcedure [dbo].[p_prints_needed]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_prints_needed] @campaign_no integer
as

set nocount on 

				
select 		@campaign_no,
			print_id,
			sum(max_pack_sum),
			sum(max_nom_pack_sum),
			print_medium,
			three_d_type,
			digital_distribution_charge
from		(select 	print_id, 
						max(sum_pack_sum) as max_pack_sum,
						max(prints_at_cinema) as max_nom_pack_sum,
						cplx.complex_id,
						print_medium,
						three_d_type,
						'N' as digital_distribution_charge
				from 	(select 	print_id, 
									sum(pack_sum) as sum_pack_sum,
									sum(nom_pack_sum) as prints_at_cinema,
									complex_id,
									screening_date,
									print_medium,
									three_d_type
						from		(select 	ppack.print_id,
												(case when pm.film = 'Y' then count(ppack.print_id) else 1 end) as pack_sum,
												count(ppack.print_id) as nom_pack_sum,
												spot.complex_id,
												spot.screening_date,
												cdm.print_medium,
												fp.three_d_type
									from 		campaign_spot spot,
												print_package ppack,
												complex_digital_medium cdm,
												print_medium pm,
												film_print_three_d_xref fp,
												print_package_three_d pp3d,
												print_package_medium pppm
									where		spot.package_id = ppack.package_id 
									and			spot.campaign_no = @campaign_no 
									and			spot.screening_date is not null 
									and			fp.print_id = ppack.print_id 
									and			pm.print_medium = cdm.print_medium 
									and			pppm.print_package_id = ppack.print_package_id 
									and			pp3d.print_package_id = ppack.print_package_id 
									and			pp3d.three_d_type = fp.three_d_type 
									and			pppm.print_medium = cdm.print_medium 
									and			spot.spot_type not in ('V', 'M', 'R') 
									and			spot.complex_id = cdm.complex_id
									group by 	spot.campaign_no,
												ppack.print_id,
												spot.screening_date,
												spot.complex_id,
												fp.three_d_type,
												cdm.print_medium,
												pm.film
									union all
									select 		pp.print_id,
												case when pm.film = 'Y' then fpc.max_screens else 1 end,
												fpc.max_screens,
												fpc.complex_id,
												fpd.screening_date,
												cdm.print_medium,
												fptdx.three_d_type
									from 		film_plan fp,
												film_plan_dates fpd,	
												film_plan_complex fpc,
												print_package pp,
												complex_digital_medium cdm,
												print_medium pm,
												film_print_three_d_xref fptdx
									where 		fp.film_plan_id = fpd.film_plan_id 
									and			fp.film_plan_id = fpc.film_plan_id 
									and			pp.package_id	= fp.package_id 
									and			fp.campaign_no = @campaign_no 
									and			fpc.complex_id = cdm.complex_id 
									and			fptdx.print_id = pp.print_id 
									and			pm.print_medium = cdm.print_medium
									union all
									select 		ppack.print_id,
												(case when pm.film = 'Y' then count(ppack.print_id) else 1 end) as pack_sum,
												count(ppack.print_id) as nom_pack_sum,
												iffs.complex_id,
												spot.screening_date,
												cdm.print_medium,
												fp.three_d_type
									from 		inclusion_spot spot,
												print_package ppack,
												complex_digital_medium cdm,
												print_medium pm,
												film_print_three_d_xref fp,
												print_package_three_d pp3d,
												print_package_medium pppm,
												inclusion_cinetam_package iffp,
												inclusion_cinetam_settings iffs
									where		spot.inclusion_id = iffp.inclusion_id
									and			spot.inclusion_id = iffs.inclusion_id
									and			iffp.package_id = ppack.package_id 
									and			spot.campaign_no = @campaign_no 
									and			spot.screening_date is not null 
									and			fp.print_id = ppack.print_id 
									and			pm.print_medium = cdm.print_medium 
									and			pppm.print_package_id = ppack.print_package_id 
									and			pp3d.print_package_id = ppack.print_package_id 
									and			pp3d.three_d_type = fp.three_d_type 
									and			pppm.print_medium = cdm.print_medium 
									and			spot.spot_type not in ('V', 'M', 'R') 
									and			iffs.complex_id = cdm.complex_id
									group by 	spot.campaign_no,
												ppack.print_id,
												spot.screening_date,
												iffs.complex_id,
												fp.three_d_type,
												cdm.print_medium,
												pm.film) as print_table
						group by 	print_id, 
									complex_id,
									screening_date,
									print_medium,
									three_d_type) as print_summed_table,
							complex cplx,
							complex_digital cd
				where 		not ( print_medium = 'F'
				and			three_d_type <> 1)
				and 		cplx.complex_id = print_summed_table.complex_id
				and			cplx.complex_id = cd.complex_id
				group by 	print_id, 
							cplx.complex_id,
							print_medium,
							three_d_type,
							cplx.no_cinemas,
							cd.complete) as digital_distribution
group by	print_id,
			print_medium,
			three_d_type,
			digital_distribution_charge
order by 	print_medium,
			three_d_type 


return 0

error:
	raiserror ('Error Retrieving Prints Required Information', 16, 1)
	close plan_prints_csr
	return -1
GO
