/****** Object:  StoredProcedure [dbo].[p_print_cl_delivery_schedule]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_print_cl_delivery_schedule]
GO
/****** Object:  StoredProcedure [dbo].[p_print_cl_delivery_schedule]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_print_cl_delivery_schedule] 	@print_id 	integer

as
set nocount on 
declare @errorode       		integer,
		  @error					integer,
		  @rowcount 			integer,
        @branch_code 		char(2),
        @branch_name 		varchar(50),
		  @deliv_branch		char(1),
		  @print_name			varchar(50),
		  @actual_qty       	integer,
        @scheduled_qty_in 	integer,
        @scheduled_qty_out integer,
        @incoming_qty      integer,
		  @requested_qty		integer

/*
 * Create Temporary Tables
 */

create table #branches
(
	branch_code		char(2),
	branch_name 	varchar(50),
	deliv_branch	char(1)
)

create table #delivery
(
	print_id			integer,
	print_name		varchar(100),
	branch_code		char(2),
	branch_name		varchar(50),
	deliv_branch	char(1),
	actual_qty		integer,
	sch_qty_in		integer,
	sch_qty_out		integer,
	incoming_qty	integer,
	requested_qty	integer
)
/*
 * Get Prints and Branches
 */

insert into #branches
select distinct
       pt.branch_code,
       branch.branch_name,
       'N'
  from cinelight_print_transaction pt,
       branch
 where pt.ptran_type_code = 'I' and
       pt.branch_code = branch.branch_code and
       pt.print_id = @print_id

select @error = @@error
if (@error !=0)
begin
	goto error
end

/*
 * Declare cursor static for prints and branches
 */
 declare branch_csr cursor static for
  select branch_code,
		   branch_name,
		   deliv_branch
    from #branches
order by branch_code
for read only
 
open branch_csr
fetch branch_csr into @branch_code, @branch_name, @deliv_branch
while(@@fetch_status = 0)
begin

	select @print_name = print_name
	  from cinelight_print
	 where print_id = @print_id

	select @error = @@error
	if (@error !=0)
	begin
		goto error
	end

	select @actual_qty = sum(branch_qty)
	  from cinelight_print_transaction
	 where print_id = @print_id and
			 branch_code = @branch_code and
			 ptran_status_code = 'C'
	
	select @error = @@error
	if (@error !=0)
	begin
		goto error
	end

	select @scheduled_qty_in = sum(branch_qty)
	  from cinelight_print_transaction
	 where print_id = @print_id and
			 branch_code = @branch_code and
			 ptran_status_code = 'S' and
			 branch_qty >= 0
	
	select @error = @@error
	if (@error !=0)
	begin
		goto error
	end

	select @scheduled_qty_out = sum(branch_qty)
	  from cinelight_print_transaction
	 where print_id = @print_id and
			 branch_code = @branch_code and
			 ptran_status_code = 'S' and
			 branch_qty < 0
	
	select @error = @@error
	if (@error !=0)
	begin
		goto error
	end

	select @incoming_qty = sum(branch_qty)
	  from cinelight_print_transaction
	 where print_id = @print_id and
			 branch_code = @branch_code and
			 ptran_type_code = 'I'

insert into #delivery
			(print_id,
			 print_name,
			 branch_code,
			 branch_name,
			 deliv_branch,
			 actual_qty,
			 sch_qty_in,
			 sch_qty_out,
			 incoming_qty,
			 requested_qty
			) values 
			(@print_id,
			 @print_name,
			 @branch_code,
			 @branch_name,
			 @deliv_branch,
			 isnull(@actual_qty,0),
			 isnull(@scheduled_qty_in,0),
			 isnull(@scheduled_qty_out,0),
			 isnull(@incoming_qty,0),
			 isnull(@requested_qty,0)
			)
	select @error = @@error
	if (@error !=0)
	begin
		goto error
	end

		fetch branch_csr into @branch_code, @branch_name, @deliv_branch
	end
close branch_csr
deallocate branch_csr

/*
 * Return the consolidated information 
 */

  select print_id,
			print_name,
			branch_code,
			branch_name,
			deliv_branch,
			actual_qty,
			sch_qty_in,
			sch_qty_out,
			incoming_qty,
			requested_qty
    from #delivery

return 0

error:
	raiserror ('Error retrieving cinelight campaign delivery schedule', 16, 1)
	close branch_csr
	return -1
GO
