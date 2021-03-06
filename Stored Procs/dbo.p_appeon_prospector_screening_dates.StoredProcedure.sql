/****** Object:  StoredProcedure [dbo].[p_appeon_prospector_screening_dates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_appeon_prospector_screening_dates]
GO
/****** Object:  StoredProcedure [dbo].[p_appeon_prospector_screening_dates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[p_appeon_prospector_screening_dates]

		 @from_date datetime,
		 @to_date datetime
AS
BEGIN

	SET NOCOUNT ON;

	-- for testing    
	--declare @from_date datetime, @to_date datetime

--	set @from_date = '2014-05-22' 
--	set @to_date = '2014-10-09'

	-- drop table #dates

	create table #dates(
	row int identity,
	screening_date datetime,
	[day] int,
	[month] varchar(20))

	insert into #dates (screening_date, [day], [month])
	select screening_date,DAY(screening_date),convert(varchar(3),DateName( month , DateAdd( month , month(screening_date) , -1 )))
	from screening_dates
	where screening_date between @from_date and @to_date



	select row,screening_date,[day],[month], case when row <= 10 then 1
				   when row > 10 then SUBSTRING(cast(row as varchar(5)),0,2) + 1
				   end as page  
	from #dates

END
GO
