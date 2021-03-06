/****** Object:  StoredProcedure [dbo].[p_schedule_print_requirements]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_schedule_print_requirements]
GO
/****** Object:  StoredProcedure [dbo].[p_schedule_print_requirements]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROC [dbo].[p_schedule_print_requirements] @campaign_no	int

as

/*
 * Declare Variables
 */

declare 	@first_spot						datetime,
				@first_plan						datetime,
				@first_inclusion				datetime,
				@first_screening				datetime,
				@first_tap						datetime,
				@branch_code					char(1),
				@addr1								varchar(50),
				@addr2							varchar(50),
				@addr3							varchar(50),
				@addr4							varchar(50),
				@addr5							varchar(50),
				@material_deadline			datetime,
				@print_id							int,
				@digital_cinema_count	int
			
set nocount on 


create table #prints
(
	first_screening  	datetime			null,
	print_id				int					null,
	print_name			varchar(50)		null,   
	duration				smallint			null,   
	print_ratio			char(1)				null,   
	sound_format		char(1)				null,   
	requested_qty		int					null,
	print_medium		char(1)				null,
	three_d_type		int					null
)


insert into #prints
(
	print_id,
	print_name,
	duration,
	print_ratio,
	sound_format,
	requested_qty,
	print_medium,
	three_d_type
)	
select 		film_print.print_id,
				film_print.print_name,
				film_print.duration,
				film_print.print_ratio,
				film_print.sound_format,
				sum(film_campaign_prints.requested_qty),
				film_campaign_prints.print_medium,
				film_campaign_prints.three_d_type
from			film_print,
 	      		film_campaign_prints  
where		film_print.print_id = film_campaign_prints.print_id and  
    	   		film_campaign_prints.campaign_no = @campaign_no
group by 	film_print.print_id,
				film_print.print_name,
				film_print.duration,
				film_print.print_ratio,
				film_print.sound_format,
				film_campaign_prints.print_medium,
				film_campaign_prints.three_d_type
 
declare 	print_csr cursor forward_only static for
select		print_id
from			#prints
order by 	print_id
for			read only
	
open print_csr
fetch print_csr into @print_id
while(@@fetch_status = 0)
begin

	/*
	 * Get First Screening
	 */
	
	select		@first_spot = min(screening_date)
	from			campaign_spot
	where		campaign_no = @campaign_no 
	and			spot_status <> 'C' 
	and			spot_status <> 'H' 
	and			spot_status <> 'D' 
	and			package_id in (select package_id from print_package where print_id = @print_id)
	
	select		@first_screening = @first_spot
	
	select		@first_plan = min(fpd.screening_date)
	from			film_plan_dates fpd,
					film_plan fp
	where		fp.campaign_no = @campaign_no 
	and			fp.film_plan_id = fpd.film_plan_id 
	and			package_id in (select package_id from print_package where print_id = @print_id)
		   
	select		@first_inclusion = min(screening_date)
	from			inclusion_spot
	where		campaign_no = @campaign_no
	and			inclusion_id in (select inclusion_id from inclusion where inclusion_type in (24,29,30, 31,32))
	and			inclusion_id in (select inclusion_id from inclusion_cinetam_package where package_id in (select package_id from print_package where print_id = @print_id))

	if(@first_plan is null)
		select		@first_plan = end_date
		from			film_campaign
		where		campaign_no = @campaign_no
		
	if(@first_inclusion is null)
		select		@first_inclusion = end_date
		from			film_campaign
		where		campaign_no = @campaign_no

	if(@first_screening is null)
		select		@first_screening = end_date
		from			film_campaign
		where		campaign_no = @campaign_no
		
	if(@first_tap is null)
		select		@first_tap = end_date
		from			film_campaign
		where		campaign_no = @campaign_no

	if(@first_plan < @first_screening)
	begin
		select		@first_screening = @first_plan
	end

	if(@first_inclusion < @first_screening)
	begin
		select		@first_screening = @first_inclusion
	end

	if(@first_tap < @first_screening)
	begin
		select @first_screening = @first_tap
	end

	update 		#prints
	set			first_screening = @first_screening
	where		print_id = @print_id
    
	fetch print_csr into @print_id
end

deallocate print_csr

/*
 * Return Dataset
 */

select 		case #prints.first_screening 
					when '14-dec-2017' then '13-dec-2017' 
					when '21-dec-2017' then '20-dec-2017' 
					when '28-dec-2017' then '20-dec-2017' 
					when '4-jan-2018' then '20-dec-2017' 
					when '01-feb-2018' then '31-jan-2018' 	
--					when '20-dec-2018' then '17-dec-2018'			
					when '27-dec-2018' then '24-dec-2018'			
					when '03-jan-2019' then '24-dec-2018'
					when '10-jan-2019' then '24-dec-2018'
					when '24-dec-2020' then '21-dec-2020'
					when '31-dec-2020' then '21-dec-2020'
					when '07-jan-2021' then '21-dec-2020'
					when '08-apr-2021' then '07-apr-2021'
					else #prints.first_screening 
				end,
				branch_address.address_1,
				branch_address.address_2,
				branch_address.address_3,
				branch_address.address_4,
				branch_address.address_5,
				#prints.print_name,   
				#prints.duration,   
				#prints.print_ratio,   
				#prints.sound_format,   
				#prints.requested_qty,
				film_material_deadlines.material_deadline,
				#prints.print_medium,
				#prints.three_d_type,
				#prints.print_id
from			#prints,   
				film_campaign,
				branch_address,
				film_material_deadlines
where       film_campaign.campaign_no = @campaign_no 
and			film_material_deadlines.film_screening_date = #prints.first_screening
and			film_campaign.delivery_branch = branch_address.branch_code
and			address_category = 'FPD'

return 0
GO
