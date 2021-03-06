/****** Object:  StoredProcedure [dbo].[p_campaign_cl_branch_prints]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_cl_branch_prints]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_cl_branch_prints]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_campaign_cl_branch_prints] @campaign_no integer,
										@print_id    integer
												 
as

declare 	@actual_qty       	integer,
        	@scheduled_qty_in 	integer,
        	@scheduled_qty_out 	integer,
      		@incoming_qty      	integer,
			@branch_code			char(2),
			@branch_name			varchar(50),
			@deliv_branch			char(1),
			@branch_entered		char(1),
			@error					integer,
			@count					integer,
			@branch_campaign		integer

create table #branch_select
(
	branch_code  		char(2)     not null,
    branch_name  		varchar(50) not null,
    deliv_branch 		char(1)     not null,
	actual_qty	 		integer		not null,
	scheduled_qty_in	integer		not null,
	scheduled_qty_out	integer		not null,		
	incoming_qty		integer		not null,
	campaign_no			integer		null
)

/*
 * Update Campaign Delivery Branch
 */

select @branch_entered = 'N'

/*
 * Create the cursor static for the branch information
 */

if @campaign_no is null
	declare branch_csr cursor static for 
	select distinct branch.branch_code,
			 branch.branch_name,
			 ptran.campaign_no,
			 'N'
	 -- from cinelight_print_transaction ptran,
		--	 branch 
	 --where ptran.print_id = @print_id and
		--	 ptran.branch_code is not null and
		--	 ptran.branch_code =* branch.branch_code
	FROM	cinelight_print_transaction ptran LEFT OUTER JOIN branch ON ptran.branch_code = branch.branch_code
	WHERE	ptran.branch_code is not null 
	AND		ptran.print_id = @print_id 
	order by branch.branch_code DESC
else
	declare branch_csr cursor static for 
	select distinct branch.branch_code,
			 branch.branch_name,
			 ptran.campaign_no,
			 'N'
	 -- from cinelight_print_transaction ptran,
		--	 branch 
	 --where ptran.print_id = @print_id and
		--	 ptran.branch_code is not null and
		--	 ptran.branch_code =* branch.branch_code and
		--	 ptran.campaign_no = @campaign_no
	FROM	cinelight_print_transaction ptran LEFT OUTER JOIN branch ON ptran.branch_code = branch.branch_code
	WHERE	ptran.branch_code is not null 
	AND		ptran.print_id = @print_id
	AND		ptran.campaign_no = @campaign_no
	order by branch.branch_code DESC

open branch_csr
fetch branch_csr into @branch_code, @branch_name, @branch_campaign, @deliv_branch
while(@@fetch_status = 0)
begin

   select @deliv_branch = 'Y'
    where @branch_code in (	select	delivery_branch 
							from	film_campaign
                            where	(campaign_no = @campaign_no and @campaign_no is not null) 
                               or	(campaign_no = @branch_campaign and @campaign_no is null))

	if (@deliv_branch = 'N')
	begin
		select @count = count(ptran_id)
		  from cinelight_print_transaction
		 where print_id = @print_id and
				 branch_code = @branch_code and
				 (campaign_no = @campaign_no or
				 @campaign_no is null) and
				 (campaign_no = @branch_campaign or
				 @campaign_no is not null)

		if (@count > 0)
			select @deliv_branch = 'Y'

		if (@campaign_no is null and @branch_code = 'N' and @branch_entered = 'N')
			select @deliv_branch = 'Y'
	end

	if (@deliv_branch = 'Y')
	begin
		select @actual_qty = sum(branch_qty)
		  from cinelight_print_transaction
		 where print_id = @print_id and
				 branch_code = @branch_code and
				 ((campaign_no = @branch_campaign) or
				 (@branch_campaign is null and
				 campaign_no is null)) and
				 ptran_status_code = 'C'
		
		select @scheduled_qty_in = sum(branch_qty)
		  from cinelight_print_transaction
		 where print_id = @print_id and
				 branch_code = @branch_code and
				 ptran_status_code = 'S' and
				 ((campaign_no = @branch_campaign) or
				 (@branch_campaign is null and
				  campaign_no is null)) and
  				 branch_qty >= 0
		
		select @scheduled_qty_out = sum(branch_qty)
		  from cinelight_print_transaction
		 where print_id = @print_id and
				 branch_code = @branch_code and
				 ptran_status_code = 'S' and
				 ((campaign_no = @branch_campaign) or
				 (@branch_campaign is null and
				 campaign_no is null)) and
				 branch_qty < 0
		
		select @incoming_qty = sum(branch_qty)
		  from cinelight_print_transaction
		 where print_id = @print_id and
				 branch_code = @branch_code and
				  ((campaign_no = @branch_campaign) or
				 (@branch_campaign is null and
				 campaign_no is null)) and
				 ptran_type_code = 'I'
		
		insert into #branch_select (
				branch_code,
				branch_name,
				deliv_branch,
				actual_qty,
				scheduled_qty_in,
				scheduled_qty_out,		
				incoming_qty,
				campaign_no ) 
		values	(
				@branch_code,
				@branch_name, 
				@deliv_branch,
				isnull(@actual_qty,0),
				isnull(@scheduled_qty_in,0),
				isnUll(@scheduled_qty_out,0),
				isnUll(@incoming_qty,0),
				@branch_campaign )

		select @error = @@error
		if (@error !=0)
		begin
			goto error
		end

		select @branch_entered = 'Y'
		
		end

		fetch branch_csr into @branch_code, @branch_name, @branch_campaign, @deliv_branch
	end	

close branch_csr

/*
 * Return results
 */
select 	branch_code,
			branch_name,
			deliv_branch,
			incoming_qty,
			actual_qty,
			scheduled_qty_in,
			scheduled_qty_out,
			campaign_no
from #branch_select

return 0

error:

	raiserror ('Error retrieving Branch Prints information', 16, 1)
	close branch_csr
	return -1
GO
