/****** Object:  UserDefinedFunction [dbo].[f_campaign_repname]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_campaign_repname]
GO
/****** Object:  UserDefinedFunction [dbo].[f_campaign_repname]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_campaign_repname] (@campaign_no int)
RETURNS varchar(70)
AS
BEGIN
	DECLARE  	@first_name				varchar(30),
							@last_name				varchar(30),
							@full_name					varchar(70)
        
   
	select			@first_name = first_name,
					@last_name = last_name
	from			sales_rep
	inner join		film_campaign on sales_rep.rep_id = film_campaign.rep_id
	where 			film_campaign.campaign_no = @campaign_no
    
	select 			@full_name   = isnull(@first_name, '') + ' ' + isnull(@last_name, '') 
	
	return(@full_name)   
   
  
END
GO
