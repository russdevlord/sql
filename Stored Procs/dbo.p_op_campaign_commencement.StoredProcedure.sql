/****** Object:  StoredProcedure [dbo].[p_op_campaign_commencement]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_campaign_commencement]
GO
/****** Object:  StoredProcedure [dbo].[p_op_campaign_commencement]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_op_campaign_commencement] 			@start_date 			datetime,
                                    																			@end_date 			datetime,
																												@country_code		char(1)
as

declare @campaign_no					integer,
				@errorode   									integer,
				@outpost_panel_id				integer,
				@pack_max							integer,
				@outpost_panel_desc   	varchar(50),
				@print_id									integer,
				@product_desc					varchar(100),
				@error										integer,
				@sched_start_date				datetime,
				@print_name		      				varchar(50),
				@package_id						integer,
				@print_status							char(1)


/*
 * create temp tables 
 */

create table #outpost_panel_select
(
	campaign_no			integer				null,
	product_desc			varchar(100)   	null,
	print_id						integer				null,
	print_name				varchar(50)		null,
	duration					integer				null,
	start_date					datetime			null,
	print_status				char(1)				null,
	end_date					datetime			null,
	burst_start				datetime			null,
	burst_end					datetime			null		
)

/*
 * Declare Cursor
 */

declare 	commence_csr cursor static for
select 		film_campaign.campaign_no,
					film_campaign.product_desc
from 			film_campaign,
					branch
where		film_campaign.branch_code = branch.branch_code
and				branch.country_code = @country_code			
and				campaign_no in (	select 		film_campaign.campaign_no
														from 			film_campaign,
																			outpost_package,
																			outpost_spot
														where 		film_campaign.campaign_status = 'L'
														and				film_campaign.campaign_no = outpost_package.campaign_no
														and				film_campaign.campaign_no = outpost_spot.campaign_no
														and				outpost_package.package_id = outpost_spot.package_id
														and				outpost_package.campaign_no = outpost_spot.campaign_no
														and				outpost_spot.spot_status <> 'P'
														group by 	film_campaign.campaign_no,
																			film_campaign.product_desc,
																			outpost_package.package_id
														having		min(outpost_spot.screening_date) between @start_date and @end_date )
order by 	film_campaign.campaign_no
for 		read only

/*
 * Loop through Cursors
 */

open commence_csr 
fetch commence_csr into @campaign_no, @product_desc
while (@@fetch_status = 0)
begin
	
	declare 	camp_prints_csr cursor static for 
	select 		print_id
	from 			outpost_campaign_print
	where 		campaign_no = @campaign_no
	and				print_id in (	select 		print_id 
							 					from 			outpost_print_package,
							 										outpost_package,
																	outpost_spot
												where 		outpost_spot.package_id = outpost_package.package_id
												and				outpost_spot.campaign_no = @campaign_no
												and				outpost_package.campaign_no = @campaign_no
												and				outpost_print_package.package_id = outpost_package.package_id
												group by 	print_id
												having		min(outpost_spot.screening_date) between @start_date and @end_date)
	order by 	print_id
	for read only

	open camp_prints_csr
	fetch camp_prints_csr into @print_id
	while(@@fetch_status = 0)
	begin

		select 	@print_name = print_name,
						@print_status = print_status
		from 		outpost_print
		where 	print_id = @print_id
		
		
		
		select 	@sched_start_date = min(spot.screening_date)
		from 		outpost_spot spot,
						outpost_package cp,
						outpost_print_package ppack
		where 	spot.package_id = cp.package_id and
						cp.package_id = ppack.package_id and
						ppack.print_id = @print_id and
						spot.campaign_no = @campaign_no
						
									
		
		insert into #outpost_panel_select
		(campaign_no,
		product_desc,
		print_id,
		print_name,
		start_date,
		print_status,
		burst_start,
		burst_end
		) select @campaign_no,
						@product_desc,
						@print_id, 
						@print_name,
						@sched_start_date,
						@print_status,
						burst.start_date, 
						burst.end_date
		from 		outpost_spot spot,
						outpost_package cp,
						outpost_print_package ppack,
						outpost_package_burst burst
		where 	spot.package_id = cp.package_id and
						cp.package_id = ppack.package_id and
						ppack.print_id = @print_id and
						spot.campaign_no = @campaign_no and
						burst.package_id = cp.package_id
		
		
		select @error = @@error
		if (@error !=0)
		begin
			raiserror ('Error retrieving campaign prints information', 16, 1)
			close camp_prints_csr
			deallocate camp_prints_csr
			return @error
		end
		
		fetch camp_prints_csr into @print_id
		end	
	close camp_prints_csr
	deallocate camp_prints_csr
	fetch commence_csr into @campaign_no, @product_desc
end

close commence_csr
deallocate commence_csr


/*
 * Return the consolidated information 
 */

select 		#outpost_panel_select.campaign_no,
			#outpost_panel_select.product_desc,
			#outpost_panel_select.print_id,
			#outpost_panel_select.print_name,
			#outpost_panel_select.start_date,
			#outpost_panel_select.burst_start,
			#outpost_panel_select.burst_end,
			#outpost_panel_select.print_status,
			business_unit_id
from 		#outpost_panel_select,
			film_campaign
where		#outpost_panel_select.campaign_no = film_campaign.campaign_no
group by 	#outpost_panel_select.campaign_no,
			#outpost_panel_select.product_desc,
			#outpost_panel_select.print_id,
			#outpost_panel_select.print_name,
			#outpost_panel_select.start_date,
			#outpost_panel_select.burst_start,
			#outpost_panel_select.burst_end,
			#outpost_panel_select.print_status,
			business_unit_id
order by 	campaign_no asc
GO
