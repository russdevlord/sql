/****** Object:  StoredProcedure [dbo].[p_schedule_cl_print_requirements]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_schedule_cl_print_requirements]
GO
/****** Object:  StoredProcedure [dbo].[p_schedule_cl_print_requirements]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_schedule_cl_print_requirements] @campaign_no	int
as
set nocount on 
/*
 * Declare Variables
 */

declare	@first_spot					datetime,
				@first_plan					datetime,
				@first_screening			datetime,
				@branch_code				char(1),
				@addr1							varchar(50),
				@addr2							varchar(50),
				@addr3								varchar(50),
				@addr4								varchar(50),
				@addr5								varchar(50),
				@material_deadline        	datetime,
				@print_id							int


create table #prints
(
	first_screening  	datetime		null,
	print_id			int				null,
	print_name			varchar(50)		null,   
	requested_qty		int				null	
)


insert into #prints
(
	print_id,
	print_name,
	requested_qty
)	
select 		cinelight_print.print_id,
			cinelight_print.print_name,
			sum(cinelight_campaign_print.requested_qty)
from		cinelight_print,   
       		cinelight_campaign_print  
where		cinelight_print.print_id = cinelight_campaign_print.print_id and  
    	   	cinelight_campaign_print.campaign_no = @campaign_no
group by 	cinelight_print.print_id,
			cinelight_print.print_name
 

declare 	print_csr cursor forward_only static for
select		print_id
from		#prints
order by 	print_id                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
for			read only
	
open print_csr
fetch print_csr into @print_id
while(@@fetch_status = 0)
begin

	/*
	 * Get First Screening
	 */
	
	select @first_spot = min(screening_date)
	  from cinelight_spot
	 where campaign_no = @campaign_no and
	       spot_status <> 'C' and
	       spot_status <> 'H' and
	       spot_status <> 'D' and
		   package_id in (select package_id from cinelight_print_package where print_id = @print_id)
	
	select @first_screening = @first_spot
	
	update 	#prints
	set		first_screening = @first_screening
	where	print_id = @print_id

	fetch print_csr into @print_id
end

deallocate print_csr

/*
 * Return Dataset
 */

select 		#prints.first_screening,
			branch_address.address_1,
			branch_address.address_2,
			branch_address.address_3,
			branch_address.address_4,
			branch_address.address_5,
			#prints.print_name,   
			#prints.requested_qty,
			dateadd(dd, -7, case #prints.first_screening when '22-dec-2016' then '21-dec-2016' when '29-dec-2016' then '21-dec-2016' when '5-jan-2017' then '21-dec-2016' else #prints.first_screening end) as material_deadline,
			#prints.print_id
from		#prints,   
			film_campaign,
			branch_address
where       film_campaign.campaign_no = @campaign_no 
and			film_campaign.delivery_branch = branch_address.branch_code
and			address_category = 'CPD'


return
GO
