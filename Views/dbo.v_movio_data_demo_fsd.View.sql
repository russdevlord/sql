/****** Object:  View [dbo].[v_movio_data_demo_fsd]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_movio_data_demo_fsd]
GO
/****** Object:  View [dbo].[v_movio_data_demo_fsd]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






	create view [dbo].[v_movio_data_demo_fsd] 
	as
	select movio_data.membership_id, movio_data.movie_code, movio_data.film_name, movio_data.complex_name, movio_data.country_code, sum(movio_data.unique_transactions) as unique_transactions, 
	sum(adult_tickets) as adult_tickets, sum(child_tickets) as child_tickets,
	 cinetam_demographics.cinetam_demographics_id, cinetam_demographics.cinetam_demographics_desc, dbo.movio_data.screening_date, movio_complex_xref.complex_id
	from dbo.movio_data, dbo.cinetam_demographics, dbo.movio_complex_xref
	where  real_age > 13
	and movio_data.gender in ('Female','Male')
	and left(movio_data.gender,1) = cinetam_demographics.gender
	and movio_data.real_age between min_age and max_age
	and movio_complex_xref.complex_name = movio_data.complex_name
	group by membership_id, movie_code, film_name, movio_data.complex_name, country_code, cinetam_demographics_id, cinetam_demographics_desc, dbo.movio_data.screening_date, movio_complex_xref.complex_id



GO
