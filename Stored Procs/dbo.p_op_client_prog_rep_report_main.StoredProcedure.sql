/****** Object:  StoredProcedure [dbo].[p_op_client_prog_rep_report_main]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_client_prog_rep_report_main]
GO
/****** Object:  StoredProcedure [dbo].[p_op_client_prog_rep_report_main]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_client_prog_rep_report_main] 	@campaign_no		integer,
															@screening_date	datetime
    
as

declare @product_desc varchar(100),
		  @rep_id		 integer

/*
 * Return Dataset
 */

select @product_desc = fc.product_desc,
		 @rep_id = fc.rep_id
  from film_campaign fc
 where campaign_no = @campaign_no

select @screening_date as screening_date,
       @campaign_no as campaign_no,
       @product_desc as product_desc,
		 @rep_id as rep_id
GO
