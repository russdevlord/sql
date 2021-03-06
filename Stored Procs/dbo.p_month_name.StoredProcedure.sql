/****** Object:  StoredProcedure [dbo].[p_month_name]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_month_name]
GO
/****** Object:  StoredProcedure [dbo].[p_month_name]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_month_name] @source_date		datetime,
								 @month_name      char(3)  OUTPUT
as
set nocount on 
/*
 * Declare Variables
 */

declare  @month					integer

/*
 * Get Date Parts
 */

select @month = datepart(month,@source_date)

if(@month = 1)
	select @month_name = 'Jan'

if(@month = 2)
	select @month_name = 'Feb'

if(@month = 3)
	select @month_name = 'Mar'

if(@month = 4)
	select @month_name = 'Apr'

if(@month = 5)
	select @month_name = 'May'

if(@month = 6)
	select @month_name = 'Jun'

if(@month = 7)
	select @month_name = 'Jul'

if(@month = 8)
	select @month_name = 'Aug'

if(@month = 9)
	select @month_name = 'Sep'

if(@month = 10)
	select @month_name = 'Oct'

if(@month = 11)
	select @month_name = 'Nov'

if(@month = 12)
	select @month_name = 'Dec'

/*
 * Return Success
 */

return 0
GO
