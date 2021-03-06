/****** Object:  StoredProcedure [dbo].[p_campaign_branch_prints]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_branch_prints]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_branch_prints]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_campaign_branch_prints] @campaign_no integer,
									 @shell_code  char(7),
                                     @print_id    integer
												 
as

declare 	@actual_qty       		integer,
			@scheduled_qty_in 		integer,
			@scheduled_qty_out 		integer,
			@incoming_qty      		integer,
			@actual_nom_qty       	integer,
			@scheduled_nom_qty_in 	integer,
			@scheduled_nom_qty_out 	integer,
			@incoming_nom_qty      	integer,
			@branch_code			char(2),
			@branch_name			varchar(50),
			@deliv_branch			char(1),
			@branch_entered			char(1),
			@error					integer,
			@count					integer,
			@branch_campaign		integer,
			@print_medium			char(1),
			@three_d_type			int

create table #branch_select (
			branch_code  			char(2)     not null,
			branch_name  			varchar(50) not null,
			deliv_branch 			char(1)     not null,
			actual_qty	 			integer		not null,
			scheduled_qty_in		integer		not null,
			scheduled_qty_out		integer		not null,		
			incoming_qty			integer		not null,
			actual_nom_qty	 		integer		not null,
			scheduled_nom_qty_in	integer		not null,
			scheduled_nom_qty_out	integer		not null,		
			incoming_nom_qty		integer		not null,
			print_medium			char(1)		null,
			three_d_type			int			null,
			campaign_no				integer		null
)

/*
 * Update Campaign Delivery Branch
 */

select @branch_entered = 'N'

/*
 * Create the cursor static for the branch information
 */

if @campaign_no is null
	declare 	branch_csr cursor static for 
	select 		distinct branch.branch_code,
				branch.branch_name,
				ptran.campaign_no,
				ptran.print_medium,
				ptran.three_d_type,
				'N'
	--from 		print_transactions ptran,
	--			branch 
	--where 	ptran.print_id = @print_id 
	--and		ptran.branch_code is not null 
	--and		ptran.branch_code =* branch.branch_code
	FROM		print_transactions ptran LEFT OUTER JOIN branch ON ptran.branch_code = branch.branch_code
	WHERE		ptran.branch_code is not null 
	AND			ptran.print_id = @print_id 
	order by 	branch.branch_code DESC
else
	declare 	branch_csr cursor static for 
	select 		distinct branch.branch_code,
				branch.branch_name,
				ptran.campaign_no,
				ptran.print_medium,
				ptran.three_d_type,
				'N'
	from 		print_transactions ptran,
				branch 
	where 		ptran.print_id = @print_id 
	and			ptran.branch_code is not null 
	and			ptran.branch_code = branch.branch_code 
	and			ptran.campaign_no = @campaign_no
	union
	select 		distinct branch.branch_code,
				branch.branch_name,
				film_campaign_prints.campaign_no,
				film_campaign_prints.print_medium,
				film_campaign_prints.three_d_type,
				'N'
	from 		branch,
				film_campaign,
				film_campaign_prints 
	where 		film_campaign_prints.print_id = @print_id 
	and			film_campaign.delivery_branch is not null 
	and			film_campaign.delivery_branch = branch.branch_code 
	and			film_campaign_prints.campaign_no = @campaign_no
	and			film_campaign_prints.campaign_no = film_campaign.campaign_no
	order by 	branch.branch_code DESC
      

open branch_csr
fetch branch_csr into @branch_code, @branch_name, @branch_campaign, @print_medium, @three_d_type, @deliv_branch
while(@@fetch_status = 0)
begin

	select 	@deliv_branch = 'Y'
	where 	@branch_code in (	select delivery_branch 
								from 	film_campaign
								where 	(campaign_no = @campaign_no and @campaign_no is not null) 
								or 		(campaign_no = @branch_campaign and @campaign_no is null))

	if (@deliv_branch = 'N')
	begin
		select 	@count = count(ptran_id)
		from 	print_transactions
		where 	print_id = @print_id 
		and		branch_code = @branch_code 
		and		print_medium = @print_medium
		and		three_d_type = @three_d_type
		and		(campaign_no = @campaign_no 
		or		@campaign_no is null) 
		and		(campaign_no = @branch_campaign 
		or		@campaign_no is not null)

		if (@count > 0)
			select @deliv_branch = 'Y'

		if (@campaign_no is null and @branch_code = 'N' and @branch_entered = 'N')
			select @deliv_branch = 'Y'
	end

	if (@deliv_branch = 'Y')
	begin
		select 	@actual_qty = sum(branch_qty),
				@actual_nom_qty = sum(branch_nominal_qty)
		from 	print_transactions
		where 	print_id = @print_id 
		and		branch_code = @branch_code 
		and		print_medium = @print_medium
		and		three_d_type = @three_d_type
		and		((campaign_no = @branch_campaign 
		and		@shell_code is null) 
		or		(@branch_campaign is null 
		and		@shell_code is null 
		and		campaign_no is null) 
		or 		(@shell_code is not null 
		and 	campaign_no is null)) 
		and		ptran_status = 'C'
		
		select 	@scheduled_qty_in = sum(branch_qty),
				@scheduled_nom_qty_in = sum(branch_nominal_qty)
		from 	print_transactions
		where 	print_id = @print_id 
		and		branch_code = @branch_code 
		and		ptran_status = 'S' 
		and		print_medium = @print_medium
		and		three_d_type = @three_d_type
		and		((campaign_no = @branch_campaign 
		and		@shell_code is null) 
		or		(@branch_campaign is null 
		and		@shell_code is null 
		and		campaign_no is null) 
		or 		(@shell_code is not null 
		and 	campaign_no is null)) 
		and		branch_qty >= 0
		
		select 	@scheduled_qty_out = sum(branch_qty),
				@scheduled_nom_qty_out = sum(branch_nominal_qty)
		from 	print_transactions
		where 	print_id = @print_id 
		and		branch_code = @branch_code 
		and		ptran_status = 'S' 
		and		print_medium = @print_medium
		and		three_d_type = @three_d_type
		and		((campaign_no = @branch_campaign 
		and		@shell_code is null) 
		or		(@branch_campaign is null 
		and		@shell_code is null 
		and		campaign_no is null) 
		or 		(@shell_code is not null 
		and		campaign_no is null)) 
		and		branch_qty < 0
		
		select 	@incoming_qty = sum(branch_qty),
				@incoming_nom_qty = sum(branch_nominal_qty)
		from 	print_transactions
		where 	print_id = @print_id 
		and		branch_code = @branch_code 
		and		print_medium = @print_medium
		and		three_d_type = @three_d_type
		and		((campaign_no = @branch_campaign 
		and		@shell_code is null) 
		or		(@branch_campaign is null 
		and		@shell_code is null 
		and		campaign_no is null) 
		or 		(@shell_code is not null 
		and		campaign_no is null)) 
		and		ptran_type = 'I'
		
		insert into #branch_select (
			branch_code,
			branch_name,
			deliv_branch,
			actual_qty,
			scheduled_qty_in,
			scheduled_qty_out,		
			incoming_qty,
			actual_nom_qty,
			scheduled_nom_qty_in,
			scheduled_nom_qty_out,		
			incoming_nom_qty,
			print_medium,
			three_d_type,
			campaign_no ) 
		values	(
			@branch_code,
			@branch_name, 
			@deliv_branch,
			isnull(@actual_qty,0),
			isnull(@scheduled_qty_in,0),
			isnull(@scheduled_qty_out,0),
			isnull(@incoming_qty,0),
			isnull(@actual_nom_qty,0),
			isnull(@scheduled_nom_qty_in,0),
			isnull(@scheduled_nom_qty_out,0),		
			isnull(@incoming_nom_qty,0),
			@print_medium,
			@three_d_type,
			@branch_campaign )

		select @error = @@error
		if (@error !=0)
		begin
			goto error
		end

		select @branch_entered = 'Y'
		
		end

		fetch branch_csr into @branch_code, @branch_name, @branch_campaign, @print_medium, @three_d_type, @deliv_branch
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
		incoming_nom_qty,
		actual_nom_qty,
		scheduled_nom_qty_in,
		scheduled_nom_qty_out,
		campaign_no,		
		print_medium,
		three_d_type
from 	#branch_select

return 0

error:

	raiserror ('Error retrieving Branch Prints information', 16, 1)
	close branch_csr
	return -1
GO
