/****** Object:  UserDefinedFunction [dbo].[f_package_unders]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_package_unders]
GO
/****** Object:  UserDefinedFunction [dbo].[f_package_unders]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[f_package_unders] (@package_id int, @screening_date datetime)
RETURNS int
AS
BEGIN
   DECLARE  @unders         int,
            @campaign_no    int
            
    select      @campaign_no = campaign_no
    from        campaign_package
    where       package_id = @package_id            
            
    select      @unders = count(spot_id) 
    from        campaign_spot
    where       package_id = @package_id
    and         (spot_status = 'U'    
    or          spot_status = 'N')
    and         spot_redirect is null
    and         screening_date < @screening_date
    
    select      @unders = @unders + count(spot_id) 
    from        campaign_spot,
                campaign_package_associates
    where       campaign_package_associates.child_package_id = @package_id
    and         campaign_spot.package_id = campaign_package_associates.parent_package_id
    and         (spot_status = 'U'    
    or          spot_status = 'N')
    and         spot_redirect is null
    and         screening_date < @screening_date    
    

    if @unders > 0
       return(@package_id) 
    else
        return (0)
         
   
   error:
        return(0)
   
END
GO
