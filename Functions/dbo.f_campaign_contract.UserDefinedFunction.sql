/****** Object:  UserDefinedFunction [dbo].[f_campaign_contract]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_campaign_contract]
GO
/****** Object:  UserDefinedFunction [dbo].[f_campaign_contract]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[f_campaign_contract] (@campaign_no int)
RETURNS char(1)
AS
BEGIN
   DECLARE  @onscreen_count     int,
            @cinelight_count    int,
            @retail_count       int,
            @retail_contract    char(1),
            @onscreen_contract  char(1),
            @cinelight_contract char(1),
            @contract_recd      char(1)
        

    select  @contract_recd = 'N'
    
    select  @onscreen_contract = contract_received,
            @cinelight_contract = cinelight_contract_received,
            @retail_contract = outpost_contract_received
    from    film_campaign
    where   campaign_no = @campaign_no            

    select  @onscreen_count = isnull(count(spot_id),0)
    from    campaign_spot
    where   campaign_no = @campaign_no

    select  @cinelight_count = isnull(count(spot_id),0)
    from    cinelight_spot
    where   campaign_no = @campaign_no

    select  @retail_count = isnull(count(spot_id),0)
    from    outpost_spot
    where   campaign_no = @campaign_no
    
    select  @retail_count = @retail_count + isnull(count(spot_id),0)
    from    inclusion_spot
    where   campaign_no = @campaign_no
    and     inclusion_id in (select inclusion_id from inclusion where campaign_no = @campaign_no and inclusion_type = 18)
    
    if ((@onscreen_count > 0 and @onscreen_contract = 'Y') or @onscreen_count = 0) and ((@cinelight_count > 0 and @cinelight_contract = 'Y') or @cinelight_count = 0) and ((@retail_count > 0 and @retail_contract = 'Y') or @retail_count = 0)
        select @contract_recd = 'Y'
        
    return(@contract_recd)   
   
  
END

GO
