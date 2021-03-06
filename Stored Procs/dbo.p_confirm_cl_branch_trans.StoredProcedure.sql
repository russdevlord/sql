/****** Object:  StoredProcedure [dbo].[p_confirm_cl_branch_trans]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_confirm_cl_branch_trans]
GO
/****** Object:  StoredProcedure [dbo].[p_confirm_cl_branch_trans]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_confirm_cl_branch_trans] @campaign_no	  integer,
											  @print_id      integer,
                                   @branch_code   char(2),
                                   @tran_date     datetime,
                                   @incoming      char(1),
                                   @tran_in       char(1),
                                   @tran_out      char(1),
                                   @adjs          char(1)
as

declare @error				integer,
        @ptran_id			integer,
        @errorode				integer,
        @tran_qty			integer,
        @cinelight_id		integer,
		@actual_qty		integer,
        @complex_name	varchar(50),
        @branch_name 	varchar(50)

begin transaction

/*
 * Setup Confirmed date
 */

if @tran_date = NULL
	select @tran_date = getdate()
 
/*
 * Get Branch Name
 */

select @branch_name = branch_name
  from branch
 where branch_code = @branch_code

select @branch_name = @branch_name + ' Branch'

/*
 * Begin Processing
 */

if @tran_in = 'Y'
begin
	declare in_csr cursor static for
 select pt.ptran_id,
        pt.branch_qty,
        pt.cinelight_id,
        cplx.complex_name
	from cinelight_print_transaction pt,
        complex cplx,
		cinelight cl
  where (pt.campaign_no = @campaign_no or
		  @campaign_no is null) and
		  pt.print_id = @print_id and
        pt.branch_code = @branch_code and
        pt.ptran_status_code = 'S' and
        pt.ptran_type_code = 'T' and
        pt.branch_qty > 0 and
		pt.cinelight_id = cl.cinelight_id and
		cl.complex_id = cplx.complex_id

	open in_csr
   fetch in_csr into @ptran_id, @tran_qty, @cinelight_id, @complex_name
	while(@@fetch_status = 0)
   begin

		exec @errorode = p_confirmed_cl_print_qty 'C', @campaign_no, @print_id, @branch_code, @cinelight_id, @actual_qty OUTPUT
		if (@errorode != 0)
		begin
			rollback transaction
			close in_csr
         deallocate in_csr
			return -1
		end

		if @tran_qty > @actual_qty
		begin
			rollback transaction
			raiserror (50007, 16,1, @tran_qty, @complex_name, @branch_name)
			close in_csr
         deallocate in_csr
			return -1
		end

		update cinelight_print_transaction
			set ptran_status_code = 'C',
             ptran_date = @tran_date
		 where ptran_id = @ptran_id

		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ( 'Error', 16, 1) 
			close in_csr
         deallocate in_csr
			return @error
		end	

	   fetch in_csr into @ptran_id, @tran_qty, @cinelight_id, @complex_name

	end

	close in_csr
   deallocate in_csr

end

if @tran_out = 'Y'
begin

declare out_csr cursor static for
 select pt.ptran_id,
        pt.cinema_qty,
        cplx.complex_name
   from cinelight_print_transaction pt,
        complex cplx,
		cinelight cl
  where (pt.campaign_no = @campaign_no or
		  @campaign_no is null) and
		  pt.print_id = @print_id and
        pt.branch_code = @branch_code and
        pt.ptran_status_code = 'S' and
        pt.ptran_type_code = 'T' and
        pt.branch_qty < 0 and
		pt.cinelight_id = cl.cinelight_id and
        cl.complex_id = cplx.complex_id

	open out_csr
   fetch out_csr into @ptran_id, @tran_qty, @complex_name
	while(@@fetch_status = 0)
   begin

		exec @errorode = p_confirmed_cl_print_qty 'B', @campaign_no, @print_id, @branch_code, 0, @actual_qty OUTPUT
		if (@errorode != 0)
		begin
			rollback transaction
			close out_csr
         deallocate out_csr
			return -1
		end

		if @tran_qty > @actual_qty
		begin
			rollback transaction
			raiserror (50007,16,1, @tran_qty, @branch_name, @complex_name)
			close out_csr
         deallocate out_csr
			return @error
		end

		update cinelight_print_transaction
			set ptran_status_code = 'C',
             ptran_date = @tran_date
		 where ptran_id = @ptran_id

		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ( 'Error', 16, 1) 
			close out_csr
         deallocate out_csr
			return @error
		end	

	   fetch out_csr into @ptran_id, @tran_qty, @complex_name

	end

	close out_csr
   deallocate out_csr

end

if @incoming = 'Y'
begin

	update cinelight_print_transaction
		set ptran_status_code = 'C',
      ptran_date = @tran_date
    where campaign_no = @campaign_no and
			 print_id = @print_id and
          branch_code = @branch_code and
          ptran_status_code = 'S' and
          ptran_type_code = 'I'

	select @error = @@error
   if ( @error !=0 )
   begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
   	return @error
	end	

end

if @adjs = 'Y'
begin

	update cinelight_print_transaction
		set ptran_status_code = 'C',
          ptran_date = @tran_date
    where campaign_no = @campaign_no and
		    print_id = @print_id and
          branch_code = @branch_code and
          ptran_status_code = 'S' and
          ptran_type_code <> 'I' and
          cinema_qty = 0

	select @error = @@error
   if ( @error !=0 )
   begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
   	return @error
	end	

end

commit transaction
return 0
GO
