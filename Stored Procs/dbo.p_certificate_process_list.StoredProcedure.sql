/****** Object:  StoredProcedure [dbo].[p_certificate_process_list]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_process_list]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_process_list]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_certificate_process_list]	@screening_date		datetime,
																						@filter						char(1),
																						@name_id					char(50),
																						@exhibitor_id			int,
																						@campaign_no			int
as

/*
 * Select List
 */

select 		cplx.complex_id, 
				cplx.complex_name,
				cplx.certificate_type,
				cplx.certificate_send_method,
				cplx.fax,
				cd.certificate_locked,
				cd.certificate_generation_user,
				cd.certificate_revision,
				( select IsNull(max(revision),-1) from certificate_history where complex_id = cd.complex_id and screening_date = @screening_date) as last_revision,
				cd.complex_date_id,
				'N' as print_cert,
				'N' as fax_cert,
				'N' as email_cert,
				cplx.email,
				cplx.film_market_no,
				cplx.branch_code,
				cplx.contractor_code,
				cplx.state_code,
				'N' as ftp_cert,
				(select xml_path from complex_ftp_path where complex_id = cplx.complex_id) as xml_path,
				(select top 1 complex_name from data_translate_complex where complex_id = cplx.complex_id ) as external_complex_name,
				(select dead_print_path from complex_ftp_path where complex_id = cplx.complex_id) as dead_print_path
from 		complex_date cd with (nolock),
				complex cplx with (nolock)
where 		cd.screening_date = @screening_date
and			cd.certificate_generation is not null 
and			cd.complex_id = cplx.complex_id 
and			(cplx.exhibitor_id = @exhibitor_id
or				isnull(@exhibitor_id,0) = 0)			
and			(cd.certificate_status = 'G' 
or				cd.certificate_status = 'E') 
and			((@filter = 'U' and cd.certificate_generation_user = @name_id) 
or				(@filter = '@'))
and			(isnull(@campaign_no,0) = 0
or				cplx.complex_id in (select complex_id from campaign_spot where campaign_no = @campaign_no and spot_status = 'X' and screening_date = @screening_date))
union all
select 		cplx.complex_id, 
				cplx.complex_name,
				cplx.certificate_type,
				cplx.certificate_send_method,
				cplx_addr.fax,
				cd.certificate_locked,
				cd.certificate_generation_user,
				cd.certificate_revision,
				( select IsNull(max(revision),-1) from certificate_history where complex_id = cd.complex_id and screening_date = @screening_date) as last_revision,
				cd.complex_date_id,
				'N' as print_cert,
				'N' as fax_cert,
				'N' as email_cert,
				cplx_addr.email,
				cplx.film_market_no,
				cplx.branch_code,
				cplx.contractor_code,
				cplx.state_code,
				'N' as ftp_cert,
				(select xml_path from complex_ftp_path where complex_id = cplx.complex_id) as xml_path,
				(select top 1 complex_name from data_translate_complex where complex_id = cplx.complex_id ) as external_complex_name,
				(select dead_print_path from complex_ftp_path where complex_id = cplx.complex_id) as dead_print_path
from 		complex_date cd with (nolock),
				complex cplx with (nolock),
				complex_addresses cplx_addr
where 		cd.screening_date = @screening_date 
and			cd.certificate_generation is not null 
and			cd.complex_id = cplx.complex_id 
and			cplx.complex_id = cplx_addr.complex_id 
and			(cplx.exhibitor_id = @exhibitor_id
or				isnull(@exhibitor_id,0) = 0)		
and			(cd.certificate_status = 'G' 
or				cd.certificate_status = 'E') 
and			((@filter = 'U' and cd.certificate_generation_user = @name_id) 
or				(@filter = '@'))
and			(isnull(@campaign_no,0) = 0
or				cplx.complex_id in (select complex_id from campaign_spot where campaign_no = @campaign_no and spot_status = 'X' and screening_date = @screening_date))
order by cplx.film_market_no,
				cplx.complex_name
GO
