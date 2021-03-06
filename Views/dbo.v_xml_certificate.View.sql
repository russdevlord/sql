/****** Object:  View [dbo].[v_xml_certificate]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_xml_certificate]
GO
/****** Object:  View [dbo].[v_xml_certificate]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view [dbo].[v_xml_certificate]
as
select					certificate_group.complex_id,
							certificate_group.screening_Date,
							certificate_group.certificate_group_id,
							session_time,
							certificate_group.three_d_type,
							certificate_group.premium_cinema,
							certificate_tms_section.section_position,
							exhibitor_section_code,
							occurence,
							vm_section_name,
							certificate_tms_section.sort_order,
							movie_or_cinema,
							temp_table.exhibitor_id,
							temp_table.print_id,
							temp_table.three_d_type_print,
							temp_table.uuid,
							temp_table.filename,
							temp_table.cpl_duration,
							temp_table.edit_rate, 	
							temp_table.sequence_no,
							(select 		movie_name 
							from 			data_translate_movie 
							where 			movie_history_sessions_certificate.movie_id = data_translate_movie.movie_id 
							and 				data_provider_id in (	select 		data_provider_id 
																						from 			data_translate_complex 
																						where 		complex_id = certificate_group.complex_id) 
							and 				process_date = (			select 		max(process_date) 
																						from 			data_translate_movie 
																						where 		data_provider_id in (	select 		data_provider_id 
																																				from 			data_translate_complex 
																																				where 		complex_id =  certificate_group.complex_id) 
																						and 			data_translate_movie.movie_id = movie_history_sessions_certificate.movie_id)) as movie_name,
							(select 		complex_name 
							from 			data_translate_complex 
							where 			movie_history_sessions_certificate.complex_id = data_translate_complex.complex_id 
							and 				process_date = (			select 		max(process_date) 
																						from 			data_translate_complex 
																						where 		data_translate_complex.complex_id = movie_history_sessions_certificate.complex_id)) as external_complex_name
from					movie_history_sessions_certificate 
inner join			certificate_group 
on						certificate_group.certificate_group_id = movie_history_sessions_certificate.certificate_group_id
inner join			complex 
on						complex.complex_id = movie_history_sessions_certificate.complex_id
inner join			certificate_tms_section 
on						complex.exhibitor_id = certificate_tms_section.exhibitor_id
left outer join	(select					certificate_item_tms_section_xref.section_position,
															certificate_item_tms_section_xref.exhibitor_id,
															certificate_item.certificate_group,
															sequence_no,
															print_id,
															certificate_item.three_d_type as three_d_type_print,
															v_xml_prints.uuid,
															v_xml_prints.filename,
															v_xml_prints.cpl_duration,
															v_xml_prints.edit_rate
							from						certificate_item_tms_section_xref 
							inner join				certificate_item on certificate_item_tms_section_xref.certificate_item_id = certificate_item.certificate_item_id
							inner join				v_xml_prints on v_xml_prints.print_no = certificate_item.print_id) as temp_table 
on						certificate_group.certificate_group_id = temp_table.certificate_group
and						certificate_tms_section.section_position = temp_table.section_position
and						certificate_tms_section.exhibitor_id = temp_table.exhibitor_id






GO
