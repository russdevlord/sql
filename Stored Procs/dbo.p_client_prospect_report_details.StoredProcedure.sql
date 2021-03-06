/****** Object:  StoredProcedure [dbo].[p_client_prospect_report_details]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_client_prospect_report_details]
GO
/****** Object:  StoredProcedure [dbo].[p_client_prospect_report_details]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_client_prospect_report_details]		@client_prospect_id					int

as

declare		@type											char(1),
					@media_group							varchar(30),
					@sorting_group						char(1),
					@market										varchar(30),
					@duration									varchar(10),
					@rate											money,
					@discount									numeric(6,4),
					@commissionable					char(1),
					@charge_rate							money,
					@package_id							int,
					@screening_date_1				datetime,
					@no_spots_1								int,
					@screening_date_2				datetime,
					@no_spots_2								int,
					@screening_date_3				datetime,
					@no_spots_3								int,
					@screening_date_4				datetime,
					@no_spots_4								int,
					@screening_date_5				datetime,
					@no_spots_5								int,
					@screening_date_6				datetime,
					@no_spots_6								int,
					@screening_date_7				datetime,
					@no_spots_7								int,
					@screening_date_8				datetime,
					@no_spots_8								int,
					@screening_date_9				datetime,
					@no_spots_9								int,
					@screening_date_10				datetime,
					@no_spots_10							int,
					@total_screeens						int,
					@total_cost									money,
					@total_value								money,
					@start_date								datetime,
					@end_date									datetime,
					@page											int
					
create table #results
(
		row_type									char(1),
		sorting_group							char(1),
		media_group							varchar(30),
		market										varchar(30),
		duration									varchar(10),
		rate												money,
		discount									numeric(6,4),
		commissionable					char(1),
		charge_rate							money,
		screening_date_1					datetime,
		no_spots_1								int,
		screening_date_2					datetime,
		no_spots_2								int,
		screening_date_3					datetime,
		no_spots_3								int,
		screening_date_4					datetime,
		no_spots_4								int,
		screening_date_5					datetime,
		no_spots_5								int,
		screening_date_6					datetime,
		no_spots_6								int,
		screening_date_7					datetime,
		no_spots_7								int,
		screening_date_8					datetime,
		no_spots_8								int,
		screening_date_9					datetime,
		no_spots_9								int,
		screening_date_10				datetime,
		no_spots_10							int,
		total_screeens						int,
		total_cost									money,
		total_value								money,
		page											int
)					

select	@page = 0

declare		burst_dates_csr cursor for
select		set_start_date, 
					set_end_date
from			(select		row_number() over (order by film_screening_dates.screening_date ) as rowid, 
										film_screening_dates.screening_date as set_start_date, 
										dateadd(wk, 9, film_screening_dates.screening_date) as set_end_date
					from			client_prospect, 
										film_screening_dates
					where		client_prospect_id = @client_prospect_id
					and				film_screening_dates.screening_date between client_prospect.start_date and client_prospect.end_date) as temp_table
where		(rowid - 1) % 10 = 0
order by	set_start_date
for				read only


open burst_dates_csr
fetch burst_dates_csr into @start_date, @end_Date
while(@@fetch_status = 0)
begin
	select	@page = @page + 1

	declare		client_prospect_package_csr cursor for
	select		package_id,
						client_prospect_media_group_desc,
						client_prospect_market_desc,
						sorting_group,
						duration,
						rate,
						discount,
						'Y',
						charge_rate			
	from			client_prospect_package, 
						client_prospect_media_group,
						client_prospect_market				
	where		client_prospect_package.client_prospect_id = @client_prospect_id
	and				client_prospect_package.client_prospect_media_group_id = client_prospect_media_group.client_prospect_media_group_id
	and				client_prospect_market.client_prospect_market_id = client_prospect_package.client_prospect_market_id
	for				read only
						
	open client_prospect_package_csr
	fetch client_prospect_package_csr into @package_id, @media_group, @market, @sorting_group,@duration,@rate,@discount,@commissionable,@charge_rate
	while(@@fetch_status = 0)
	begin

		declare		spot_csr cursor for
		select		screening_date,
							sum(client_prospect_spots.no_screens) as no_screens
		from			client_prospect_spots,
							client_prospect_package, 
							client_prospect_media_group,
							client_prospect_market					
		where		client_prospect_package.client_prospect_id = @client_prospect_id
		and				client_prospect_package.client_prospect_id = client_prospect_spots.client_prospect_id
		and				client_prospect_package.client_prospect_media_group_id = client_prospect_media_group.client_prospect_media_group_id
		and				client_prospect_market.client_prospect_market_id = client_prospect_package.client_prospect_market_id
		and				client_prospect_package.package_id = client_prospect_spots.package_id
		and				client_prospect_package.package_id = @package_id
		and				client_prospect_media_group.client_prospect_media_group_desc = @media_group
		and				client_prospect_market.client_prospect_market_desc = @market
		and				client_prospect_spots.screening_date between @start_date and @end_date
		group by	screening_date
		order by	screening_date
		for				read only
		
		select		@screening_date_1			= null,
							@no_spots_1							= null,
							@screening_date_2			= null,
							@no_spots_2							= null,
							@screening_date_3			= null,
							@no_spots_3							= null,
							@screening_date_4			= null,
							@no_spots_4							= null,
							@screening_date_5			= null,
							@no_spots_5							= null,
							@screening_date_6			= null,
							@no_spots_6							= null,
							@screening_date_7			= null,
							@no_spots_7							= null,
							@screening_date_8			= null,
							@no_spots_8							= null,
							@screening_date_9			= null,
							@no_spots_9							= null,
							@screening_date_10			= null,
							@no_spots_10						= null		
		
		open spot_csr
		fetch spot_csr into @screening_date_1, @no_spots_1

		if @@fetch_status = 0
			fetch spot_csr into @screening_date_2, @no_spots_2

		if @@fetch_status = 0
			fetch spot_csr into @screening_date_3, @no_spots_3

		if @@fetch_status = 0
			fetch spot_csr into @screening_date_4, @no_spots_4

		if @@fetch_status = 0
			fetch spot_csr into @screening_date_5, @no_spots_5

		if @@fetch_status = 0
			fetch spot_csr into @screening_date_6, @no_spots_6

		if @@fetch_status = 0
			fetch spot_csr into @screening_date_7, @no_spots_7

		if @@fetch_status = 0
			fetch spot_csr into @screening_date_8, @no_spots_8

		if @@fetch_status = 0
			fetch spot_csr into @screening_date_9, @no_spots_9
			
		if @@fetch_status = 0
			fetch spot_csr into @screening_date_10, @no_spots_10

		close spot_csr
		deallocate spot_csr
									
		select		@total_screeens	= sum(client_prospect_spots.no_screens),
							@total_cost				= sum(client_prospect_spots.no_screens * client_prospect_spots.charge_rate),
							@total_value			= sum(client_prospect_spots.no_screens * client_prospect_spots.rate)
		from			client_prospect_spots,
							client_prospect_package, 
							client_prospect_media_group,
							client_prospect_market					
		where		client_prospect_package.client_prospect_id = @client_prospect_id
		and				client_prospect_package.client_prospect_id = client_prospect_spots.client_prospect_id
		and				client_prospect_package.package_id = client_prospect_spots.package_id
		and				client_prospect_package.package_id = @package_id
		and				client_prospect_package.client_prospect_media_group_id = client_prospect_media_group.client_prospect_media_group_id
		and				client_prospect_market.client_prospect_market_id = client_prospect_package.client_prospect_market_id
		and				client_prospect_media_group.client_prospect_media_group_desc = @media_group
		and				client_prospect_market.client_prospect_market_desc = @market


		insert into #results values
		(
			'A',
			@sorting_group,
			@media_group,
			@market,
			@duration,
			@rate,
			@discount,
			@commissionable,
			@charge_rate,
			@screening_date_1,
			@no_spots_1,
			@screening_date_2,
			@no_spots_2,
			@screening_date_3,
			@no_spots_3,
			@screening_date_4,
			@no_spots_4,
			@screening_date_5,
			@no_spots_5,
			@screening_date_6,
			@no_spots_6,
			@screening_date_7,
			@no_spots_7,
			@screening_date_8,
			@no_spots_8,
			@screening_date_9,
			@no_spots_9,
			@screening_date_10,
			@no_spots_10,
			@total_screeens,
			@total_cost,
			@total_value,
			@page
		)
		fetch client_prospect_package_csr into @package_id, @media_group, @market, @sorting_group,@duration,@rate,@discount,@commissionable,@charge_rate
	end

	close client_prospect_package_csr
	deallocate  client_prospect_package_csr

	fetch burst_dates_csr into @start_date, @end_Date
end

insert  into #results 
				(row_type,
				sorting_group,
				media_group,
				total_cost,
				total_value,
				page,
				commissionable)
select	'I',
				'A',
				client_prosect_inclusion_type_desc,
				total_value,
				total_charge,
				1,
				commissionable
from		client_prospect_inclusion,
				client_prospect_inclusion_type
where	client_prospect_inclusion.client_prospect_id = @client_prospect_id
and			client_prospect_inclusion.client_prosect_inclusion_type_id = client_prospect_inclusion_type.client_prosect_inclusion_type_id

select * from #results order by row_type, sorting_group					
					
return 0
GO
