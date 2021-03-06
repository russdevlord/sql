/****** Object:  View [dbo].[v_xml_prints]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_xml_prints]
GO
/****** Object:  View [dbo].[v_xml_prints]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO




CREATE VIEW [dbo].[v_xml_prints]
AS
SELECT      fp.print_id as print_no,
					fp.print_name,    
					fpfl.filename,
					fp.actual_duration as duration,
					fpfl.folder_size as size,
					fpfl.uuid as uuid,
					fpfl.three_d_type,
					fpfl.print_medium,
					fpfl.edit_rate,
					fpfl.cpl_duration ,
					fpfl.country_code
FROM			film_print fp,
					film_print_file_locations fpfl
WHERE		fp.print_id = fpfl.print_id
and				uuid is not null



GO
