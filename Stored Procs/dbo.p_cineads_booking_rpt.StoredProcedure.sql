/****** Object:  StoredProcedure [dbo].[p_cineads_booking_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cineads_booking_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_cineads_booking_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_cineads_booking_rpt] 
	
	@screening_date		datetime
	,@state_code		varchar(10)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		select c.complex_name
       ,c.state_code
       ,fm.film_market_desc
       ,film_plan_id as cinema_no
       ,sum(fp.duration) as 'total_time (sec)'
       ,cs.screening_date
		from film_campaign as fc
		inner join campaign_package as cp on cp.campaign_no = fc.campaign_no
		INNER JOIN campaign_spot as cs on cs.package_id = cp.package_id
		INNER JOIN complex as c on c.complex_id = cs.complex_id
		INNER JOIN print_package as pp on pp.package_id = cp.package_id
		inner join film_print as fp on fp.print_id = pp.print_id
		INNER JOIN film_market  as fm on fm.film_market_no = c.film_market_no
		where fc.business_unit_id = 9
		and ((cs.screening_date = @screening_date
				  and @state_code is null)
    		or(cs.screening_date = @screening_date
			   and @state_code is not null 
			   and c.state_code = @state_code) )
		GROUP BY c.complex_name, c.state_code, fm.film_market_desc, cs.screening_date, film_plan_id
		order by cs.screening_date, c.state_code, fm.film_market_desc, c.complex_name, cs.film_plan_id


END
GO
