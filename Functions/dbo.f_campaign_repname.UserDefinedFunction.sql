USE [production]
GO
/****** Object:  UserDefinedFunction [dbo].[f_campaign_repname]    Script Date: 11/03/2021 2:30:32 PM ******/
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
