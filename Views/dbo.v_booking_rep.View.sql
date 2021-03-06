/****** Object:  View [dbo].[v_booking_rep]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_booking_rep]
GO
/****** Object:  View [dbo].[v_booking_rep]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_booking_rep]
as
select distinct first_name, last_name, revision_id,  (select sum(nett_amount) from booking_figures where rep_id =sales_rep.rep_id and revision_id = bf.revision_id) as rep_share, (select sum(nett_amount) from booking_figures where revision_id = bf.revision_id) as full_amount 
from sales_rep, booking_figures bf where sales_rep.rep_id = bf.rep_id
GO
