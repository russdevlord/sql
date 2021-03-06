/****** Object:  UserDefinedFunction [dbo].[f_outpost_certificate_campaign]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_outpost_certificate_campaign]
GO
/****** Object:  UserDefinedFunction [dbo].[f_outpost_certificate_campaign]    Script Date: 12/03/2021 10:03:48 AM ******/
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
