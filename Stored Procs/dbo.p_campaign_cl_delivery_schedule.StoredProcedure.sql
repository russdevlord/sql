/****** Object:  StoredProcedure [dbo].[p_campaign_cl_delivery_schedule]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_cl_delivery_schedule]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_cl_delivery_schedule]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
cREATE PROC [dbo].[p_campaign_cl_delivery_schedule] 	@campaign_no 	integer

as

declare @errorode       		integer,
		@error					integer,
		@rowcount 			integer,
        @branch_code 		char(2),
        @branch_name 		varchar(50),
		@deliv_branch		char(1),
		@print_id				integer,
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
select 		distinct
			pt.branch_code,
			branch.branch_name,
			'N'
from 		cinelight_print_transaction pt,
			branch
where		pt.ptran_type_code = 'I' and
			pt.branch_code = branch.branch_code and
			pt.print_id = @print_id

select @error = @@error
if (@error !=0)
begin
	goto error
end

select @branch_code = fc.delivery_branch,
       @branch_name = branch.branch_name
  from film_campaign fc,
       branch
 where fc.campaign_no = @campaign_no and
       fc.delivery_branch = branch.branch_code

select @error = @@error
if (@error !=0)
begin
	goto error
end

update #branches
   set deliv_branch = 'Y'
 where branch_code = @branch_code

select @error = @@error,
		 @rowcount = @rowcount
if (@error !=0)
begin
	goto error
end

if (@@rowcount = 0)
begin
	insert into #branches values (@branch_code, @branch_name, 'Y')
end

/*
 * Declare cursor static for campaign prints and campaign branches
 */
 
 declare prints_csr cursor static for
  select print_id 
 	 from cinelight_campaign_print
   where campaign_no = @campaign_no
order by print_id
for read only

open prints_csr
fetch prints_csr into @print_id
while(@@fetch_status = 0)
begin
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

		select @requested_qty = requested_qty
  		  from cinelight_campaign_print
		 where campaign_no = @campaign_no and
				 print_id = @print_id

		select @error = @@error
		if (@error !=0)
		begin
			goto error
		end

		select @actual_qty = sum(branch_qty)
		  from cinelight_print_transaction
		 where campaign_no = @campaign_no and
				 print_id = @print_id and
				 branch_code = @branch_code and
				 ptran_status_code = 'C'
		
		select @error = @@error
		if (@error !=0)
		begin
			goto error
		end

		select @scheduled_qty_in = sum(branch_qty)
		  from cinelight_print_transaction
		 where campaign_no = @campaign_no and
				 print_id = @print_id and
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
		 where campaign_no = @campaign_no and
				 print_id = @print_id and
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
		 where campaign_no = @campaign_no and
				 print_id = @print_id and
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
	fetch prints_csr into @print_id
end


close prints_csr
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
	raiserror ('Error retrieving campaign delivery schedule', 16, 1)
	close prints_csr
	deallocate branch_csr
	deallocate prints_csr
	return -1
GO
