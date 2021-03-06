/****** Object:  StoredProcedure [dbo].[p_op_programming_list]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_programming_list]
GO
/****** Object:  StoredProcedure [dbo].[p_op_programming_list]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_programming_list]		@screening_date	datetime,
													   @country				char(1),
													   @filter				char(1),
													   @name_id				integer
as

/*
 * Select List
 */
  select fcp.campaign_no,
			fc.product_desc,
			fc.client_id,
			client.client_name,
			fc.agency_id,
			agency.agency_name,
			fc.agency_deal,
         'N' as print_cert,
         'N' as fax_cert,
			'N' as email_cert,
			fcp.fax,
			fcp.email,
			fcp.send_method,
			b.state_code,
			fcp.film_campaign_program_id,
			fc.rep_id,
			fcp.contact,
			fcp.company
    from film_campaign fc,
			client,
			agency,
			branch b,
			film_campaign_program fcp
	where fc.start_date <= @screening_date and
			fc.makeup_deadline >= @screening_date and
			fc.campaign_status <> 'P' and
			fc.branch_code = b.branch_code and 
			b.country_code = @country and
			fcp.campaign_no = fc.campaign_no and
			fc.client_id = client.client_id and 
			fc.agency_id = agency.agency_id and
			fc.campaign_no in (select distinct campaign_no from outpost_spot where screening_date = @screening_Date and spot_status = 'X') and 
			fcp.active = 'Y' and
			((@filter = 'C' and client.client_id = @name_id) or
			 (@filter = 'A' and agency.agency_id = @name_id) or
			 (@filter = 'R' and fc.rep_id = @name_id) or
			 (@filter = '@'))
GO
