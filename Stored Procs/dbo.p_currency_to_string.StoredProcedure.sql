/****** Object:  StoredProcedure [dbo].[p_currency_to_string]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_currency_to_string]
GO
/****** Object:  StoredProcedure [dbo].[p_currency_to_string]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_currency_to_string] @source_currency   money,
								 @string_currency   varchar(30) OUTPUT
as

/*
 * Declare Variables
 */

declare @wip_currency		varchar(30),
        @string_length      integer,
        @start              integer,
        @index              integer,
        @first_time         tinyint

/*
 * Initialise Variables
 */

select @first_time = 0

/*
 * Convert Currency to String
 */

select @source_currency = round(@source_currency,2)
select @wip_currency = convert(varchar(30),abs(@source_currency))

select @string_length = len(@wip_currency)
if(@string_length < 4)
begin
    raiserror ('Currency to String Conversion Error.', 16, 1)
    select @string_currency = '$0.00'
    return -1
end

select @string_length = @string_length + 1
select @string_length = @string_length - 3
select @string_currency = substring(@wip_currency,@string_length,3)

while(@string_length > 1)
begin

    if(@first_time = 1)
        select @string_currency = ',' + @string_currency
    
    select @first_time = 1
    select @start = @string_length - 3
    if(@start < 1)
        select @start = 1
    select @index = @string_length - @start

    select @string_currency = substring(@wip_currency,@start,@index) + @string_currency
    select @string_length = @string_length - 3
    
end

if(@source_currency < 0)
    select @string_currency = '-$' + @string_currency
else
    select @string_currency = '$' + @string_currency

/*
 * Return Success
 */

return 0
GO
