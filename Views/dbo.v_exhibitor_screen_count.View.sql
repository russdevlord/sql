USE [production]
GO
/****** Object:  View [dbo].[v_exhibitor_screen_count]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[v_exhibitor_screen_count]
as
select exhibitor.state_code, exhibitor_name, exhibitor_status, film_complex_status, cinema.active_flag, complex_name, film_market_no, cinema_no from exhibitor
inner join complex on exhibitor.exhibitor_id = complex.exhibitor_id
inner join cinema on complex.complex_id = cinema.complex_id
GO
