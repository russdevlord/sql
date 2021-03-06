/****** Object:  StoredProcedure [dbo].[p_cnvt_acct_period_to_calendar]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cnvt_acct_period_to_calendar]
GO
/****** Object:  StoredProcedure [dbo].[p_cnvt_acct_period_to_calendar]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cnvt_acct_period_to_calendar]     @accounting_period datetime,
                                               @period_start datetime OUTPUT,
                                               @period_end   datetime OUTPUT
as
                             

declare @error      integer,
        @year       integer,
        @month      integer,
        @temp_date  datetime


    select @temp_date = convert(datetime, '1-' + datename(mm,@accounting_period) + '-' + datename(yy,@accounting_period))
    if @@error != 0 return -1

    select @period_start = @temp_date
    if @@error != 0 return -1

    select @period_end = dateadd(dd,-1,dateadd(mm,1,@temp_date))
    if @@error != 0 return -1

return 0
GO
