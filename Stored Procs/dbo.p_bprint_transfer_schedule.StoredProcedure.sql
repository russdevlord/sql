/****** Object:  StoredProcedure [dbo].[p_bprint_transfer_schedule]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_bprint_transfer_schedule]
GO
/****** Object:  StoredProcedure [dbo].[p_bprint_transfer_schedule]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_bprint_transfer_schedule]	@branch_scope tinyint,
												@branch_code  char(2)
as

if @branch_scope = 1
	begin
		SELECT	MIN(branch.branch_name),
				MIN(complex.complex_name),
				fc.campaign_no, 
				MIN(fc.product_desc),
				pt.print_id, 
				MIN(fp.print_name),
				pt.print_medium,
				pt.three_d_type, 
				SUM(pt.branch_qty),
				SUM(pt.branch_nominal_qty)
		FROM	film_print AS fp INNER JOIN
				print_transactions AS pt ON fp.print_id = pt.print_id LEFT OUTER JOIN
				film_campaign AS fc ON pt.campaign_no = fc.campaign_no INNER JOIN
				branch ON pt.branch_code = branch.branch_code INNER JOIN
				complex ON pt.complex_id = complex.complex_id
		WHERE	(pt.ptran_type = 'T') 
		AND		(pt.ptran_status = 'S') 
		AND		(pt.cinema_qty < 0)
		GROUP BY pt.branch_code, 
				pt.complex_id,
				pt.print_id, 
				fc.campaign_no, 
				pt.print_medium, 
				pt.three_d_type
	end
else
	begin
		SELECT	MIN(branch.branch_name),
				MIN(complex.complex_name),
				fc.campaign_no,
				MIN(fc.product_desc),
				pt.print_id,
				MIN(fp.print_name), 
				pt.print_medium, 
				pt.three_d_type, 
				SUM(pt.branch_qty),
				SUM(pt.branch_nominal_qty)
		FROM	film_print AS fp INNER JOIN
				print_transactions AS pt ON fp.print_id = pt.print_id LEFT OUTER JOIN
				film_campaign AS fc ON pt.campaign_no = fc.campaign_no INNER JOIN
				branch ON pt.branch_code = branch.branch_code INNER JOIN
				complex ON pt.complex_id = complex.complex_id
		WHERE	(pt.ptran_type = 'T') 
		AND		(pt.ptran_status = 'S') 
		AND		(pt.cinema_qty < 0) 
		AND		(pt.branch_code = @branch_code)
		GROUP BY pt.branch_code,
				pt.complex_id, 
				pt.print_id, 
				fc.campaign_no, 
				pt.print_medium, 
				pt.three_d_type
	end
GO
