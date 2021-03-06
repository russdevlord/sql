/****** Object:  StoredProcedure [dbo].[p_film_campaign_audit_listing]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_audit_listing]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_audit_listing]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_film_campaign_audit_listing]		@billing_period_start		datetime,
												@billing_period_end			datetime,
												@country_code				char(1),
												@cinema_agreement_id		int

as 

declare  	@error						integer,
			@campaign_no				integer,
			@product_desc				varchar(100),
			@start_date					datetime,
			@end_date					datetime,
			@campaign_status			varchar(30),
			@campaign_type				varchar(30),
			@confirmed_cost				money,
			@agency_deal         		char(1),
			@client_id					integer,
			@agency_id					integer,
			@state_code       			char(3),
			@client_name      			varchar(50),
			@email            			varchar(50),
			@address_1        			varchar(50),
			@address_2        			varchar(50),
			@town_suburb     	  		varchar(30),
			@postcode        	 		varchar(5),
			@phone           	 		varchar(20),
			@fax              			varchar(20),
			@campaign_screening_with	char(1),
			@business_unit_desc			varchar(30),
			@commission					numeric(6,4),
			@total_media				money,
			@invoiced_media				money,
			@complex_count				int,
			@package_code				varchar(5),
			@duration					int,
			@average_rate				money,
			@package_screening_with		char(1),
			@package_total_media		money,
			@package_invoiced_media		money,
			@package_id					int,
			@package_desc				varchar(100)

set nocount on

create table #campaign_info (
	campaign_no					integer 			null,
	product_desc		     	varchar(100)		null,
	start_date					datetime			null,
	end_date					datetime			null,
	campaign_status     	  	varchar(30)			null,
	campaign_type				varchar(30)			null,
	confirmed_cost				money				null,
	state_code       			char(3)				null,
	client_name      			varchar(50)			null,
	email            			varchar(50)			null,
	address_1        			varchar(50)			null,
	address_2        			varchar(50)			null,
	town_suburb     	  		varchar(30)			null,
	postcode        	 		varchar(5)			null,
	phone           	 		varchar(20)			null,
	fax              			varchar(20)			null,
	campaign_screening_with		char(1)				null,
	business_unit_desc			varchar(30)			null,
	commission					numeric(6,4)		null,
	total_media					money				null,
	invoiced_media				money				null,
	package_code				varchar(5)			null,
	duration					int					null,
	average_rate				money				null,
	package_screening_with		char(1)				null,
	package_total_media			money				null,
	package_invoiced_media		money				null,
	package_desc				varchar(100)		null
)

declare 	campaign_csr cursor forward_only static for
select 		campaign_no,
			product_desc,
			start_date,
			end_date,
			campaign_status_desc,
			campaign_type_desc,
			confirmed_cost,
			agency_deal,
			client_id,
			agency_id,
			campaign_cost,
			commission,
			business_unit_desc
from 		film_campaign,
			campaign_type,
			campaign_status,
			branch,
			business_unit
where 		film_campaign.campaign_status = campaign_status.campaign_status_code
and			film_campaign.campaign_type = campaign_type.campaign_type_code
and			film_campaign.branch_code = branch.branch_code
and			branch.country_code = @country_code
and 		campaign_status != 'P'
and			film_campaign.campaign_no in (select distinct campaign_no  from campaign_spot where billing_period between @billing_period_start and @billing_period_end)
and			business_unit.business_unit_id = film_campaign.business_unit_id
order by 	campaign_no

open campaign_csr
fetch campaign_csr into @campaign_no,
						@product_desc,
						@start_date,
						@end_date,
						@campaign_status,
						@campaign_type,
						@confirmed_cost,
						@agency_deal,
						@client_id,
						@agency_id,
						@total_media,
						@commission,
						@business_unit_desc
while (@@fetch_status=0)
begin

	if @agency_deal = 'N'
		select 	@state_code = state_code,
				@client_name = client_name,
				@email = email,
				@address_1 = address_1,
				@address_2 = address_2,
				@town_suburb = town_suburb,
				@postcode = postcode,
				@phone = phone,
				@fax = fax
		from 	client
		where 	client_id = @client_id
	else
		select 	@state_code = state_code,
				@client_name = agency_name,
				@email = email,
				@address_1 = address_1,
				@address_2 = address_2,
				@town_suburb = town_suburb,
				@postcode = postcode,
				@phone = phone,
				@fax = fax
		from 	agency
		where 	agency_id = @agency_id


	select 	@complex_count = count(spot_id)
	from	campaign_spot
	where 	campaign_no = @campaign_no 
	and		complex_id in (	select 	complex_id 
							from 	cinema_agreement_policy 
							where	cinema_agreement_id = @cinema_agreement_id
							and    	processing_start_date <= @billing_period_start
             				and    	isnull(processing_end_date,'1-jan-2050') >= @billing_period_end)

	if @complex_count > 0
		select @campaign_screening_with = 'Y'
	else
		select @campaign_screening_with = 'N'

	select 	@invoiced_media = isnull(sum(charge_rate),0)
	from	campaign_spot
	where	campaign_no = @campaign_no
	and		billing_period >= @billing_period_start
	and		billing_period <= @billing_period_end
	

	declare		package_csr cursor forward_only static for
	select		package_id, 
				package_code,
				duration,
				package_desc
	from		campaign_package
	where		campaign_no = @campaign_no
	order by 	package_code

	
	open package_csr
	fetch package_csr into @package_id, @package_code, @duration, @package_desc
	while(@@fetch_status=0)
	begin

		
		select 	@complex_count = count(spot_id)
		from	campaign_spot
		where 	campaign_no = @campaign_no 
		and		package_id = @package_id
		and		complex_id in (	select 	complex_id 
								from 	cinema_agreement_policy 
								where	cinema_agreement_id = @cinema_agreement_id
								and    	processing_start_date <= @billing_period_start
	             				and    	isnull(processing_end_date,'1-jan-2050') >= @billing_period_end)
	
		if @complex_count > 0
			select @package_screening_with = 'Y'
		else
			select @package_screening_with = 'N'
	
		select 	@package_invoiced_media = isnull(sum(charge_rate),0)
		from	campaign_spot
		where	campaign_no = @campaign_no
		and		package_id = @package_id
		and		billing_period >= @billing_period_start
		and		billing_period <= @billing_period_end

		select 	@package_total_media = isnull(sum(charge_rate),0)
		from	campaign_spot
		where	campaign_no = @campaign_no
		and		package_id = @package_id

		select 	@average_rate = avg(charge_rate)
		from	campaign_spot
		where	campaign_no = @campaign_no
		and		package_id = @package_id
		and 	charge_rate != 0

		insert into #campaign_info (
			campaign_no,
			product_desc,
			start_date,
			end_date,
			campaign_status,
			campaign_type,
			confirmed_cost,
			state_code,
			client_name,
			email,
			address_1,
			address_2,
			town_suburb,
			postcode,
			phone,
			fax,
			total_media,
			commission,
			business_unit_desc,
			campaign_screening_with,
			invoiced_media,
			package_code,
			duration,
			average_rate,
			package_screening_with,
			package_total_media,
			package_invoiced_media,
			package_desc) values
			(@campaign_no,
			@product_desc,
			@start_date,
			@end_date,
			@campaign_status,
			@campaign_type,
			@confirmed_cost,
			@state_code,
			@client_name,
			@email,
			@address_1,
			@address_2,
			@town_suburb,
			@postcode,
			@phone,
			@fax,
			@total_media,
			@commission,
			@business_unit_desc,
			@campaign_screening_with,
			@invoiced_media,
			@package_code,
			@duration,
			@average_rate,
			@package_screening_with,
			@package_total_media,
			@package_invoiced_media,
			@package_desc)

		fetch package_csr into @package_id, @package_code, @duration, @package_desc
	end
	deallocate package_csr

	fetch campaign_csr into @campaign_no,
							@product_desc,
							@start_date,
							@end_date,
							@campaign_status,
							@campaign_type,
							@confirmed_cost,
							@agency_deal,
							@client_id,
							@agency_id,
							@total_media,
							@commission,
							@business_unit_desc
end 
close campaign_csr
deallocate  campaign_csr

select 		ci.campaign_no,
			ci.product_desc,
			ci.start_date,
			ci.end_date,
			ci.campaign_status,
			ci.campaign_type,
			ci.confirmed_cost,
			ci.state_code,
			ci.client_name,
			ci.email,
			ci.address_1,
			ci.address_2,
			ci.town_suburb,
			ci.postcode,
			ci.phone,
			ci.fax,
			ci.total_media,
			ci.commission,
			ci.business_unit_desc,
			ci.campaign_screening_with,
			ci.invoiced_media,
			ci.package_code,
			ci.duration,
			ci.average_rate,
			ci.package_screening_with,
			ci.package_total_media,
			ci.package_invoiced_media,
			ci.package_desc,
			@cinema_agreement_id
from 		#campaign_info ci
order by 	ci.campaign_no

return 0
GO
