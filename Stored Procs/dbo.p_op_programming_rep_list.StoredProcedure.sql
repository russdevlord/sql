/****** Object:  StoredProcedure [dbo].[p_op_programming_rep_list]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_programming_rep_list]
GO
/****** Object:  StoredProcedure [dbo].[p_op_programming_rep_list]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_programming_rep_list] @screening_date	datetime,
													   @country				char(1),
													   @filter				char(1),
													   @name_id				integer
as

/*
 * Select List
 */

  select fc.campaign_no,
			fc.product_desc,
			fc.client_id,
			client.client_name,
			fc.agency_id,
			agency.agency_name,
			fc.agency_deal,
			b.state_code,
			fc.rep_id,
			'N' as print_cert,
			'N' as email_cert,
			rtrim(sr.first_name) + ' ' + rtrim(sr.last_name),
			sr.email
    from film_campaign fc,
			client,
			agency,
			branch b,
			sales_rep sr
	where fc.start_date <= @screening_date and
			fc.makeup_deadline >= @screening_date and
			fc.campaign_status <> 'P' and
			fc.branch_code = b.branch_code and 
			b.country_code = @country and
			fc.client_id = client.client_id and 
			fc.agency_id = agency.agency_id and
			fc.campaign_no in (select distinct campaign_no from outpost_spot where screening_date = @screening_Date and spot_status = 'X') and 
			fc.rep_id = sr.rep_id and
			((@filter = 'C' and client.client_id = @name_id) or
			 (@filter = 'A' and agency.agency_id = @name_id) or
			 (@filter = 'R' and fc.rep_id = @name_id) or
			 (@filter = '@'))
GO
