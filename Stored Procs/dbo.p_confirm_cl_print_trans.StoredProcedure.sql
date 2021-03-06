/****** Object:  StoredProcedure [dbo].[p_confirm_cl_print_trans]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_confirm_cl_print_trans]
GO
/****** Object:  StoredProcedure [dbo].[p_confirm_cl_print_trans]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_confirm_cl_print_trans] @ptran_id  int
as

declare @error        	integer,
        @print_id     	integer,
		@campaign_no		integer,
        @errorode     		integer,
        @branch_qty   	integer,
        @actual_qty   	integer,
        @cinema_qty   	integer,
        @cinelight_id 	integer,
        @ptran_type   	char(1),
        @branch_code  	char(2),
        @complex_name 	varchar(50),
        @branch_name  	varchar(50)

/*
 * Select Print Tran into Variables
 */

begin transaction

select @ptran_type   	= pt.ptran_type_code,
	   @campaign_no		= pt.campaign_no,
       @print_id   	  	= pt.print_id,
       @branch_qty   	= pt.branch_qty,
       @cinema_qty   	= pt.cinema_qty,
       @cinelight_id   	= pt.cinelight_id,
       @branch_code  	= pt.branch_code,
       @branch_name  	= branch.branch_name
  --from cinelight_print_transaction pt,
  --     branch
  --where pt.ptran_id = @ptran_id and
  --      pt.branch_code *= branch.branch_code
  FROM	cinelight_print_transaction AS pt LEFT OUTER JOIN
                      branch ON pt.branch_code = branch.branch_code
  WHERE (pt.ptran_id = @ptran_id)       

if @@rowcount = 0
begin
	rollback transaction
	return -1
end
else
begin
	if (@cinelight_id != null)
	begin
		select @complex_name = complex.complex_name
		from complex, cinelight
		where cinelight.cinelight_id = @cinelight_id and
		cinelight.complex_id = complex.complex_id
	end
end

/*
 * Validate Transaction
 */


if @ptran_type = 'T'
begin

	if @cinema_qty > 0
	begin

		exec @errorode = p_confirmed_cl_print_qty 'B', @campaign_no, @print_id, @branch_code, @cinelight_id, @actual_qty OUTPUT
		if (@errorode != 0)
		begin
			rollback transaction
			return -1
		end

		if @cinema_qty > @actual_qty
		begin
			rollback transaction
			raiserror (50007,16,1, @cinema_qty, @branch_name, @complex_name)
			return -1
		end

	end
	else
	begin

		exec @errorode = p_confirmed_cl_print_qty 'C', @campaign_no, @print_id, @branch_code, @cinelight_id, @actual_qty OUTPUT
		if (@errorode != 0)
		begin
			rollback transaction
			return -1
		end
		
		if @branch_qty > @actual_qty
		begin
			rollback transaction
			raiserror (50007,16,1, @branch_qty, @complex_name, @branch_name)
			return -1
		end

	end

end

/*
 * Update Print Transaction
 */

update cinelight_print_transaction
	set ptran_status_code = 'C'
 where ptran_id = @ptran_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
   	return -1
end	

commit transaction
return 0
GO
