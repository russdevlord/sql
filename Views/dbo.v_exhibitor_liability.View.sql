/****** Object:  View [dbo].[v_exhibitor_liability]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_exhibitor_liability]
GO
/****** Object:  View [dbo].[v_exhibitor_liability]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_exhibitor_liability]
as
select exhibitor_name, complex_name, liability_type_desc, release_period, original_liability, cancelled, complex.state_code, sum(cinema_amount) as cin_amt 
from spot_liability,complex, liability_type, exhibitor
where  complex.complex_id = spot_liability.complex_id and release_period > '1-jul-2007' and complex.exhibitor_id = exhibitor.exhibitor_id 
and spot_liability.liability_type = liability_type.liability_type_id
group by exhibitor_name, complex_name, liability_type_desc, release_period, original_liability, cancelled, complex.state_code
union all
select exhibitor_name, complex_name, liability_type_desc, release_period, original_liability, cancelled, complex.state_code, sum(cinema_amount) as cin_amt 
from cinelight_spot_liability,complex, liability_type, exhibitor
where  complex.complex_id = cinelight_spot_liability.complex_id and release_period > '1-jul-2007' and complex.exhibitor_id = exhibitor.exhibitor_id 
and cinelight_spot_liability.liability_type = liability_type.liability_type_id
group by exhibitor_name, complex_name, liability_type_desc, release_period, original_liability, cancelled, complex.state_code

GO
