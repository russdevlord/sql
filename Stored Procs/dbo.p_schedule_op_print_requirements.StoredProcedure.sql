/****** Object:  StoredProcedure [dbo].[p_schedule_op_print_requirements]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_schedule_op_print_requirements]
GO
/****** Object:  StoredProcedure [dbo].[p_schedule_op_print_requirements]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROC [dbo].[p_schedule_op_print_requirements] @campaign_no	int
as
set nocount on 

/*==============================================================*
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  2   18-Feb-2011 DYI  Added Courier Address			*
 *                                                              *
 *==============================================================*/

declare @print_id			int,
	@first_spot			datetime,
	@op_wall_first_spot		datetime

create table #prints (
		first_screening  		datetime		null,
		print_id			int			null,
		print_name			varchar(50)		null,
		requested_qty			int			null,
		print_medium			varchar(30)		null,
		duration			int			null )

insert into #prints (
		print_id,
		print_name,
		requested_qty,
		print_medium,
		duration )	
select		outpost_print.print_id,
		outpost_print.print_name,
		sum(outpost_campaign_print.requested_qty),
		outpost_print_medium.print_medium_desc,
		outpost_print.duration
from		outpost_print,   
		outpost_campaign_print,
		outpost_print_medium
where		outpost_print.print_id = outpost_campaign_print.print_id and  
		outpost_campaign_print.campaign_no = @campaign_no and
		outpost_print.print_medium = outpost_print_medium.print_medium
group by 	outpost_print.print_id,
		outpost_print.print_name,
		outpost_print_medium.print_medium_desc,
		outpost_print.duration
 
declare print_csr cursor forward_only static for
select		print_id
from		#prints
order by	print_id
for read only
	
open print_csr
fetch print_csr into @print_id
while(@@fetch_status = 0)
begin
	/*
	 * Get First Screening
	 */
	
	select	@first_spot = min(screening_date)
	from	outpost_spot
	where	campaign_no = @campaign_no and
		spot_status <> 'C' and
		spot_status <> 'H' and
		spot_status <> 'D' and
		package_id in (select package_id from outpost_print_package where print_id = @print_id)

	select  @op_wall_first_spot = min(op_screening_date)
	from    inclusion_spot,
		inclusion
	where 	inclusion.campaign_no = @campaign_no
	and	inclusion_spot.inclusion_id = inclusion.inclusion_id
	and	inclusion_type = 18
	and     spot_status <> 'D' 
	and     spot_status <> 'C' 
	and     spot_status <> 'H' 
	and     op_screening_date is not null

	update 	#prints
	set	first_screening = isnull(@first_spot, @op_wall_first_spot)
	where	print_id = @print_id
	fetch print_csr into @print_id
end
deallocate print_csr

/*
 * Return Dataset A stands for actual Prints data and B for delivery adresses
 */
 
select	row_type = 'A',
	first_screening,
	print_name,   
	requested_qty,
	material_deadline = dateadd(dd, -5, first_screening),
	duration,
	NULL, NULL, NULL, NULL, NULL, NULL as address_category_desc, NULL, print_id
FROM	#prints
UNION	
SELECT	'B',
	NULL, NULL, NULL, NULL, NULL,
	branch_address.address_1,
	branch_address.address_2,
	branch_address.address_3,
	branch_address.address_4,
	branch_address.address_5,
	address_category.address_category_desc,
	address_category.address_category_code,
	null
from	film_campaign,
	branch_address,
	address_category
where	film_campaign.campaign_no = @campaign_no 
and	film_campaign.delivery_branch = branch_address.branch_code
AND 	branch_address.address_category = address_category.address_category_code
and	address_category.address_category_code IN ( 'OPD' , 'RPO')
ORDER BY row_type, address_category_desc

return
GO
