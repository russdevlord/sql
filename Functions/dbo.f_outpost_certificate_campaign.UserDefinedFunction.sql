USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_outpost_certificate_campaign]    Script Date: 11/03/2021 2:30:32 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[f_outpost_certificate_campaign] (@certificate_item_id int)
RETURNS int
AS
BEGIN
   DECLARE  @campaign_no         int
            
    select      @campaign_no = outpost_spot.campaign_no
    from        outpost_spot,
                outpost_certificate_xref
    where       outpost_certificate_xref.certificate_item_id = @certificate_item_id
    and         outpost_spot.spot_id = outpost_certificate_xref.spot_id
    group by    outpost_spot.campaign_no
            
    return @campaign_no
         
   
    error:
        return(0)
   
END
GO
