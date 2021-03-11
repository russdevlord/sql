USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_test_report]    Script Date: 11/03/2021 2:30:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[p_test_report]
	
AS
BEGIN
	select [complex_id],[complex_name],c.[exhibitor_id],e.exhibitor_name,
	c.[branch_code],b.branch_name,c.[film_market_no],f.film_market_desc,
	[opening_date],c.[town_suburb]
	from complex c 
	inner join exhibitor e on c.exhibitor_id=e.exhibitor_id and c.state_code=e.state_code
	left outer join branch b on c.branch_code=b.branch_code
	inner join film_market f on c.film_market_no=f.film_market_no
	where  e.exhibitor_status='A' 

END
GO
