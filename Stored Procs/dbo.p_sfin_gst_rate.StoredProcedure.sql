USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_gst_rate]    Script Date: 11/03/2021 2:30:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_gst_rate] @campaign_no	char(7),
                            @gst_rate		numeric(6,4) OUTPUT
as

declare @error        		integer,
        @rowcount     		integer,
        @errorode					integer,
        @exempt				char(1),
        @calc_rate			numeric(6,4)

/*
 * Get Rate
 */

select @exempt = sc.gst_exempt,
       @calc_rate = c.gst_rate
  from slide_campaign sc,
       branch b,
       country c
 where sc.branch_code = b.branch_code and
       b.country_code = c.country_code

select @error = @@error
if (@error !=0)
begin
	raiserror ('Error Retrieving GST Rate.', 16, 1)
	return -1
end	

/*
 * Determine Rate
 */

if(@exempt = 'Y')
	select @gst_rate = 0
else
	select @gst_rate = @calc_rate

/*
 * Return Success
 */

return 0
GO
