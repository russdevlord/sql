USE [production]
GO
/****** Object:  View [dbo].[v_rep_book_camp]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_rep_book_camp]
as
select campaign_no, rep_id, sum(nett_amount)/ (select sum(nett_amount) from booking_figures aa where aa.campaign_no = booking_figures.campaign_no) as rep_share from booking_figures
where campaign_no not in (select campaign_no from booking_figures  group by campaign_no having sum(nett_amount) = 0) group by campaign_no, rep_id
union
select campaign_no, rep_id, 1.0 as rep_share from booking_figures  where campaign_no not in (select campaign_no from film_campaign where campaign_status = 'P') group by campaign_no, rep_id having sum(nett_amount) = 0
GO
