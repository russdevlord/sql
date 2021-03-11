USE [production]
GO
/****** Object:  View [dbo].[v_movio_transactions_by_demo]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create view [dbo].[v_movio_transactions_by_demo]
as
select country_code, screening_date, cinetam_demographics_desc, sum(unique_transactions) as tot_trans, sum(adult_tickets) as tot_adult_tickets, sum(child_tickets) as tot_child_tickets
 from [v_movio_data_demo_fsd]
group by country_code,screening_date, cinetam_demographics_desc
union all
select country_code, screening_date, cinetam_reporting_demographics_desc, sum(unique_transactions) as tot_trans, sum(adult_tickets) as tot_adult_tickets, sum(child_tickets) as tot_child_tickets
 from [v_movio_data_demo_fsd], cinetam_reporting_demographics_xref, cinetam_reporting_demographics
where  [v_movio_data_demo_fsd].cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
and  cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id =  cinetam_reporting_demographics.cinetam_reporting_demographics_id
and					cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id not in (8,13) 
group by country_code, screening_date, cinetam_reporting_demographics_desc


GO
