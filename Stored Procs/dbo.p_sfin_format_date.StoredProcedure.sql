/****** Object:  StoredProcedure [dbo].[p_sfin_format_date]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_format_date]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_format_date]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_sfin_format_date] @date			datetime,
                               @format			tinyint,
                               @date_str 		varchar(11) OUTPUT
as

/*
 * Declare Variables
 */

declare @temp_str			varchar(12),
        @month_str		char(3),
        @year_str			char(4),
        @day				tinyint

/*
 * Format Date
 */

select @temp_str = convert(varchar(12),@date,107)
select @month_str = substring(@temp_str, 1, 3)
select @day = convert(tinyint, substring(@temp_str,5,2))
select @year_str = substring(@temp_str, 9,4)

if(@format = 1)
	if @day < 10 
		select @date_str = convert(char(1), @day) + '-' + @month_str + '-' + @year_str
	else
		select @date_str = convert(char(2), @day) + '-' + @month_str + '-' + @year_str
else
	select @date_str = @month_str + '-' + @year_str

/*
 * Return
 */

return 0
GO
