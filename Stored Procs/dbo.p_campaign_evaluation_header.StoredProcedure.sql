/****** Object:  StoredProcedure [dbo].[p_campaign_evaluation_header]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_evaluation_header]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_evaluation_header]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_campaign_evaluation_header]  @campaign_no 	int

as

/*
 * Return Campaign Evaluation Header Information
 */

select 		fc.campaign_no,
			fc.product_desc,   
			client_name,
			agency_name
from 		film_campaign fc,
			agency,
			client
where	 	fc.campaign_no = @campaign_no
and       	fc.agency_id = agency.agency_id 
and 	  	fc.client_id = client.client_id
/*
 * Return Success
 */

return 0
GO
