/****** Object:  View [dbo].[v_screening_cert_auto_confirm]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_screening_cert_auto_confirm]
GO
/****** Object:  View [dbo].[v_screening_cert_auto_confirm]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[v_screening_cert_auto_confirm]
as
select		complex_id, 
				screening_date
from		(SELECT	complex_id,
								film_market_code,
								complex_name,
								groupcount,
								confirmationcount,-- > 0
								errorcount,-- = 0
								pdf_filename,
								ho_processed_flag, -- = N
								primarygroupid,
								film_market_no,
								screening_date
				FROM		(SELECT			DISTINCT CG.complex_id,
														FM.film_market_code,
														C.complex_name,
														(SELECT			COUNT(DISTINCT CI.certificate_group) 
														FROM				certificate_group CG2, 
																				certificate_item CI 
														WHERE			CG2.complex_id = CG.complex_id 
														AND				CG2.screening_date = CG.screening_date 
														AND				CI.certificate_group = CG2.certificate_group_id) AS GroupCount,
														(SELECT			COUNT(DISTINCT certificate_group_id) 
														FROM				screening_confirmations SC 
														WHERE			SC.certificate_group_id IN (	SELECT		certificate_group_id 
																																	FROM			certificate_group 
																																	WHERE		complex_id = CG.complex_id 
																																	AND			screening_date = CG.screening_date) 
														AND				SC.certificate_item_id = 0) AS ConfirmationCount,
														(SELECT			COUNT(DISTINCT certificate_group_id) 
														FROM				screening_confirmations SC 
														WHERE			SC.certificate_group_id IN (	SELECT		certificate_group_id 
																																	FROM			certificate_group 
																																	WHERE		complex_id = CG.complex_id 
																																	AND			screening_date = CG.screening_date) 
														AND				SC.certificate_item_id >= 0 
														AND				ISNULL(SC.item_shown,'N') = 'N' ) AS ErrorCount,
														CONVERT(CHAR(8),CG.screening_date,112) AS pdf_filename, 
														ISNULL((	SELECT		HO_processed_flag 
																			FROM			screening_confirmations SC 
																			WHERE		SC.certificate_group_id IN (SELECT		TOP 1 certificate_group_id 
																																					FROM			certificate_group 
																																					WHERE		complex_id = CG.complex_id 
																																					AND			screening_date = CG.screening_date 
																																					ORDER BY	group_no) 
																			AND			SC.certificate_item_id = -1),'N') AS HO_processed_flag, 
														CG2.certificate_group_id AS PrimaryGroupId,
														C.film_market_no,
														CG.screening_date 
									FROM			certificate_group CG 
									JOIN			complex C 
										ON		C.complex_id = CG.complex_id 
									JOIN			(SELECT			complex_id,
																				screening_date,
																				MIN(group_no) AS group_no 
														FROM				certificate_group 
														GROUP BY		complex_id,
																				screening_date) AS CG1 
										ON		CG1.complex_id = CG.complex_id 
										AND	CG1.screening_date = CG.screening_date 
									JOIN			(SELECT			complex_id,
																				screening_date,
																				certificate_group_id,
																				group_no 
														FROM				certificate_group) AS CG2 
										ON		CG2.complex_id = CG1.complex_id 
										AND	CG2.screening_date = CG1.screening_date 
										AND	CG2.group_no = CG1.group_no 
									JOIN			film_market FM
										ON		FM.film_market_no = C.film_market_no 
									join			complex_date cd
										on	cg.complex_id = cd.complex_id
										and	cg.screening_date = cd.screening_date
--									WHERE		CG.screening_date between dateadd(wk, -21, '2016-04-14') and '2016-04-14') AS ResultSet ) as temp_table
									WHERE		cd.movies_confirmed = 0) AS ResultSet ) as temp_table
where		confirmationcount > 0
and			errorcount = 0
and			ho_processed_flag = 'N'
GO
