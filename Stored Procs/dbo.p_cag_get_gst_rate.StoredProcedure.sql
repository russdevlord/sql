/****** Object:  StoredProcedure [dbo].[p_cag_get_gst_rate]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_get_gst_rate]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_get_gst_rate]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cag_get_gst_rate] @agreement_id				integer,
                               @tran_date					datetime,
                               @currency_code               char(3) OUTPUT,
                               @gst_rate					numeric(6,4) OUTPUT
--with recompile 
as

/*
 * Declare Variables
 */

declare @error        					integer,
        @rowcount     					integer,
        @errorode								integer,
        @gst_fixed						char(1),
        @gst_fixed_rate                 numeric(6,4),
        @old_gst_rate					numeric(6,4),
        @new_gst_rate					numeric(6,4),
        @gst_changeover					datetime
		  
/*
 * Get Agreement Information
 */



select   @gst_fixed = ca.gst_fixed,
         @gst_fixed_rate = ca.gst_rate,
         @currency_code = ca.currency_code,
		 @old_gst_rate = c.gst_rate,
		 @new_gst_rate = c.new_gst_rate,
		 @gst_changeover = c.changeover_date
  from cinema_agreement ca,
		 country c
 where ca.cinema_agreement_id = @agreement_id and
	   ca.currency_code = c.currency_code

if(@@error <> 0)				
begin
	raiserror ('Cinema Agreement GST Rate: Error Retrieving GST Information', 16, 1)
	goto error
end

/*
 * Determine GST Rate
 */

if(@gst_fixed = 'Y')
	select @gst_rate = @gst_fixed_rate
	else
		if(@tran_date >= @gst_changeover)
			select @gst_rate = @new_gst_rate
		else
			select @gst_rate = @old_gst_rate
	
/*
 * Return
 */

return 0

/*
 * Error Handler
 */

error:

	return -1
GO
