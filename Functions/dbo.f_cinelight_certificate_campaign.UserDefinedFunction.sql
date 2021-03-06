/****** Object:  UserDefinedFunction [dbo].[f_cinelight_certificate_campaign]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_cinelight_certificate_campaign]
GO
/****** Object:  UserDefinedFunction [dbo].[f_cinelight_certificate_campaign]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_cinelight_certificate_campaign] (@certificate_item_id int)
RETURNS int
AS
BEGIN
   DECLARE  @campaign_no         int,
            @camp_rows          int
   
            
    select      @campaign_no = cinelight_spot.campaign_no
    from        cinelight_spot,
                cinelight_certificate_xref
    where       cinelight_certificate_xref.certificate_item_id = @certificate_item_id
    and         cinelight_spot.spot_id = cinelight_certificate_xref.spot_id
    group by    cinelight_spot.campaign_no
            
    select @camp_rows = @@rowcount
    
    if @camp_rows = 0
        return 0
    else
        return @campaign_no
         
   
    error:
        return(0)
   
END
GO
