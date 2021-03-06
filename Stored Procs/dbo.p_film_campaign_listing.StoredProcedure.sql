/****** Object:  StoredProcedure [dbo].[p_film_campaign_listing]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_listing]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_listing]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_film_campaign_listing]

as 

declare  @error					integer,
			@campaign_no			integer,
			@product_desc			varchar(100),
			@start_date				datetime,
			@end_date				datetime,
		  	@campaign_status		varchar(30),
		   @campaign_type			varchar(30),
		   @confirmed_cost		money,
		   @agency_deal         char(1),
		   @client_id				integer,
		   @agency_id				integer,
			@state_code       	char(3),
		   @client_name      	varchar(50),
    		@email            	varchar(50),
    		@address_1        	varchar(50),
    		@address_2        	varchar(50),
    		@town_suburb     	  	varchar(30),
    		@postcode        	 	varchar(5),
    		@phone           	 	varchar(20),
    		@fax              	varchar(20)

create table #campaign_info (
	campaign_no					integer 			null,
	product_desc		     	varchar(100)	null,
	start_date					datetime			null,
	end_date						datetime			null,
	campaign_status     	  	varchar(30)		null,
	campaign_type				varchar(30)		null,
	confirmed_cost				money				null,
	state_code       			char(3)			null,
	client_name      			varchar(50)		null,
   email            			varchar(50)		null,
	address_1        			varchar(50)		null,
	address_2        			varchar(50)		null,
	town_suburb     	  		varchar(30)		null,
	postcode        	 		varchar(5)		null,
	phone           	 		varchar(20)		null,
	fax              			varchar(20)		null
)

declare campaign_csr cursor static for
 select campaign_no,
		  product_desc,
		  start_date,
		  end_date,
		  campaign_status_desc,
		  campaign_type_desc,
		  confirmed_cost,
		  agency_deal,
		  client_id,
		  agency_id
   from film_campaign,
		  campaign_type,
		  campaign_status
  where film_campaign.campaign_status in ('L', 'F') and
		 film_campaign.campaign_status = campaign_status.campaign_status_code and
		 film_campaign.campaign_type = campaign_type.campaign_type_code
order by campaign_no

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
								@agency_id
while (@@fetch_status=0)
begin

	if @agency_deal = 'N'
		select @state_code = state_code,
				@client_name = client_name,
				@email = email,
				@address_1 = address_1,
				@address_2 = address_2,
				@town_suburb = town_suburb,
				@postcode = postcode,
				@phone = phone,
				@fax = fax
		 from client
		where client_id = @client_id
	else
		select @state_code = state_code,
				@client_name = agency_name,
				@email = email,
				@address_1 = address_1,
				@address_2 = address_2,
				@town_suburb = town_suburb,
				@postcode = postcode,
				@phone = phone,
				@fax = fax
		 from agency
		where agency_id = @agency_id

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
	fax) values
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
	@fax)

	fetch campaign_csr into @campaign_no,
									@product_desc,
									@start_date,
									@end_date,
									@campaign_status,
									@campaign_type,
									@confirmed_cost,
									@agency_deal,
									@client_id,
									@agency_id
end 
close campaign_csr
deallocate  campaign_csr

  select ci.campaign_no,
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
			c.complex_name,
			fm.film_market_desc,
			fcc.screens
	 from #campaign_info ci,
			film_campaign_complex fcc,
			complex c,
			film_market fm
	where ci.campaign_no = fcc.campaign_no and
			fcc.complex_id = c.complex_id and
			c.film_market_no = fm.film_market_no
order by ci.campaign_no,
			c.film_market_no,
			c.complex_name

return 1
GO
