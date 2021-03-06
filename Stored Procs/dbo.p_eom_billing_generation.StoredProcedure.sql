/****** Object:  StoredProcedure [dbo].[p_eom_billing_generation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_eom_billing_generation]
GO
/****** Object:  StoredProcedure [dbo].[p_eom_billing_generation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[p_eom_billing_generation]		@campaign_no				int,
													@accounting_period		    datetime,
													@tran_date					datetime
as

/*
 * Declare Variables
 */

declare	@error        							int,
		@rowcount     							int,
		@errorode								int,
		@next_period							datetime,
		@billing_date							datetime,
		@acomm_nett								money,
		@acomm_gross							money,
		@pre_gst_calc							money,
		@exempt_gst_total						money,
		@pre_gst_total							money,
		@post_gst_total							money,
		@tran_id								int,
		@exempt_tran_id							int,
		@pre_tran_id							int,
		@post_tran_id							int,
		@acomm_tran_id							int,
		@takeout_exempt_tran_id					int,
		@takeout_pregst_tran_id					int,
		@takeout_postgst_tran_id				int,
		@agency_comm							numeric(6,4),			
		@pre_gst_rate							numeric(6,4),
		@post_gst_rate							numeric(6,4),
		@gst_changeover							datetime,
		@offset									int,
		@bill_csr_open							tinyint,
		@spot_csr_open							tinyint,
		@status									char(1),
		@rate									money,
		@makegood_rate							money,
		@tran_desc     							varchar(255),
		@tran_notes    							varchar(255),
		@period_desc    						varchar(255),
		@period_detailed_desc					varchar(255),
		@period_start							datetime,
		@campaign_country						char(1),
		@country_code							char(1),
		@month_name								char(3),
		@mode_desc								varchar(9),
		@gst_desc_on							char(1),
		@spot_id								int,		
		@complex_id								int,
		@spot_type								char(1),
		@mode									tinyint,
		@makegood_total							money,
		@agency_deal							char(1),
		@currency_string						varchar(30),
		@media_product_desc						varchar(30),
		@media_product_id						integer,
		@billing_tran_code						varchar(5),
		@acomm_tran_code						varchar(5),
		@t_billing_tran_code					varchar(5),
		@gst_exempt								char(1),
		@media_product_mode						int,
		@working_acomm							numeric(6,4),
		@trantype_desc							varchar(255),
		@takeout_desc							varchar(255),
		@account_id								int,
		@inclusion_id							int,
		@inclusion_desc							varchar(255)

set nocount on

/*
 * Initalise GST Full Description
 */

select @gst_desc_on = 'Y'

/*
 * Determine GST Rates, Agency Commission and Campaign Country
 */

select			@agency_comm = fc.commission,
				@pre_gst_rate = country.gst_rate,
				@gst_changeover = country.changeover_date,
				@post_gst_rate = country.new_gst_rate,
				@campaign_country = country.country_code,
				@agency_deal = fc.agency_deal,
				@gst_exempt = fc.gst_exempt
from			film_campaign fc,
				branch,
				country
where			fc.campaign_no = @campaign_no 
and				fc.branch_code = branch.branch_code 
and				branch.country_code = country.country_code

select @error = @@error,
       @rowcount = @@rowcount

if (@error !=0 or @rowcount=0)
begin
	raiserror ('Error', 16, 1)
	return -100
end	

/*
 * Initialise Variables
 */

select @bill_csr_open = 0
select @spot_csr_open = 0

if @gst_exempt = 'Y'
begin
    select  @pre_gst_rate = 0.0
    select  @post_gst_rate = 0.0
end

/*
 * Begin Transaction
 */

begin transaction

/* 
 * Loop Media Products
 * 1 - Onscreen Media  (Film / DMG / Showcase )
 * 2 - Cinelights
 * 3 - Cinemarketing
 * 4 - Retail
 * 5 - Retail Wall
 * 6 - Media Proxy
 * 7 - Takeout 
 * 8 - TAP 
 * 9 - Retail Activations
 * 10 - Cineads   
 * 11- FF Audience Sell
 * 12 - Road Block
 * 13 - MM Audience
 * 14 - FANDOM
 */

select @media_product_mode = 1

while(@media_product_mode <=14)
begin 

	/*
	 * Loop Modes x 4
	 */
	 
	select @mode = 1
	
	while(@mode<=4)
	begin
	
	   /*
	    * Initialise Spot Types
	    */
	
	    if(@mode = 1)
	    begin
	        select @mode_desc = 'Scheduled'
            select @working_acomm = @agency_comm
	    end
	    
	    if(@mode = 2)
	    begin
		    select @spot_type = 'Y'
		    select @mode_desc = 'Standby'
            select @working_acomm = @agency_comm
	    end
	    
	    if(@mode = 3)
	    begin
		    select @spot_type = 'C'
		    select @mode_desc = 'Contra'
	        select @working_acomm = 0.0
	    end
	    
	    if(@mode = 4)
	    begin
		    select @spot_type = 'D'
		    select @mode_desc = 'Make Good'
	        select @working_acomm = 0.0
	    end
	
	   /*
	    * Loop through billing periods
	    */
	
		if @media_product_mode = 1 --onscreen but not cineads
		begin
			declare 		bill_csr cursor static for
			select			distinct fsd.billing_period,
							mp.media_product_id,
							mp.media_product_desc,
							fc.onscreen_account_id,
							@working_acomm,
							null
			from 			campaign_spot spot,
							campaign_package pack,
							media_product mp,
							film_screening_dates fsd,
							film_campaign fc
			where 			spot.campaign_no = @campaign_no 
			and				spot.package_id = pack.package_id 
			and				pack.media_product_id = mp.media_product_id 
			and				spot.billing_period = @accounting_period 
			and				fc.campaign_no = pack.campaign_no 
			and				spot.spot_status <> 'P' 
			and				spot.billing_date = fsd.screening_date 
			and				(( @mode = 1 
			and				spot.spot_type in ('S','B','N','R')) 
			or				( @mode >= 1 
			and				spot.spot_type = @spot_type )) 
			and				fc.business_unit_id <> 9
			order by 		mp.media_product_id ASC,
							fsd.billing_period ASC
			for 			read only
		end
		else if @media_product_mode = 2 --cinelights
		begin
			declare 		bill_csr cursor static for
			select 			distinct fsd.billing_period,
							mp.media_product_id,
							mp.media_product_desc,
							fc.cinelight_account_id,
							@working_acomm,
							null
			from 			cinelight_spot spot,
							cinelight_package pack,
							media_product mp,
							film_screening_dates fsd,
							film_campaign fc
			where 			spot.campaign_no = @campaign_no 
			and				spot.package_id = pack.package_id 
			and				pack.media_product_id = mp.media_product_id 
			and				spot.billing_period = @accounting_period 
			and				spot.billing_date = fsd.screening_date 
			and				pack.campaign_no = fc.campaign_no 
			and				spot.spot_status <> 'P' 
			and				(( @mode = 1 
			and				spot.spot_type in ('S','B','N','R')) 
			or				( @mode >= 1 
			and				spot.spot_type = @spot_type )) 
			order by 		mp.media_product_id ASC,
							fsd.billing_period ASC
			for 			read only
		end
		else if @media_product_mode = 3 --cinemarketing
		begin
			declare 		bill_csr cursor static for
			select 			distinct fsd.billing_period,
							mp.media_product_id,
							mp.media_product_desc,
							case isnull(inc.account_no,0) when 0 then fc.onscreen_account_id else inc.account_no end,
							@working_acomm,
							null
			from 			inclusion_spot spot,
							inclusion inc,
							film_campaign fc,
							inclusion_type inc_typ,
							media_product mp,
							film_screening_dates fsd
			where 			spot.campaign_no = @campaign_no 
			and				spot.inclusion_id = inc.inclusion_id 
			and				inc_typ.media_product_id = mp.media_product_id 
			and				inc.inclusion_type = inc_typ.inclusion_type 
			and				spot.billing_period = @accounting_period 
			and				spot.billing_date = fsd.screening_date 
			and				fc.campaign_no = inc.campaign_no 
			and				spot.spot_status <> 'P' 
			and				(( @mode = 1 
			and				spot.spot_type in ('S','B','N','R')) 
			or				( @mode >= 1 
			and				spot.spot_type = @spot_type )) 
			and				inc.inclusion_type = 5 
			and				inc.inclusion_category = 'S'
			and				inc.invoice_client = 'Y'
			order by 		mp.media_product_id ASC,
							fsd.billing_period ASC
			for 			read only
		end
		else if @media_product_mode = 4 --retail panels
		begin
			declare 		bill_csr cursor static for
			select 			distinct fsd.billing_period,
							mp.media_product_id,
							mp.media_product_desc,
							fc.outpost_account_id,
							@working_acomm,
							null
			from 			outpost_spot spot,
							outpost_package pack,
							media_product mp,
							outpost_screening_dates fsd,
							film_campaign fc
			where 			spot.campaign_no = @campaign_no 
			and				spot.package_id = pack.package_id 
			and				pack.media_product_id = mp.media_product_id 
			and				spot.billing_period = @accounting_period 
			and				spot.billing_date = fsd.screening_date 
			and				pack.campaign_no = fc.campaign_no 
			and				spot.tran_id is null 
			and				spot.spot_status <> 'P' 
			and				(( @mode = 1 
			and				spot.spot_type in ('S','B','N','R')) 
			or				( @mode >= 1 
			and				spot.spot_type = @spot_type ))
			order by 		mp.media_product_id ASC,
							fsd.billing_period ASC
			for 			read only
		end
		else if @media_product_mode = 5 --retail wall
		begin
			declare 		bill_csr cursor static for
			select 			distinct fsd.billing_period,
							mp.media_product_id,
							mp.media_product_desc,
							case isnull(inc.account_no,0) when 0 then fc.outpost_account_id else inc.account_no end,
							inc.commission,
							null
			from 			inclusion_spot spot,
							inclusion inc,
							inclusion_type inc_typ,
							media_product mp,
							outpost_screening_dates fsd,
							film_campaign fc
			where 			spot.campaign_no = @campaign_no 
			and				spot.inclusion_id = inc.inclusion_id 
			and				inc_typ.media_product_id = mp.media_product_id 
			and				inc.inclusion_type = inc_typ.inclusion_type 
			and				spot.billing_period = @accounting_period 
			and				spot.op_billing_date = fsd.screening_date 
			and				spot.tran_id is null 
			and				inc.campaign_no = fc.campaign_no 
			and				spot.spot_status <> 'P' 
			and				(( @mode = 1 
			and				spot.spot_type in ('S','B','N','R')) 
			or				( @mode >= 1 
			and				spot.spot_type = @spot_type )) 
			and				inc.inclusion_type = 18 
			and				inc.inclusion_category = 'S' 
			and				inc.invoice_client = 'Y'
			order by	 	mp.media_product_id ASC,
							fsd.billing_period ASC
			for 			read only
		end
		else if @media_product_mode = 6 --media proxy
		begin
			declare 		bill_csr cursor static for
			select 			distinct fsd.billing_period,
							mp.media_product_id,
							mp.media_product_desc,
							case mp.media_product_id when 1 then fc.onscreen_account_id when 2 then fc.onscreen_account_id when 3 then fc.cinelight_account_id when 6 then case isnull(inc.account_no,0) when 0 then fc.onscreen_account_id else inc.account_no end else inc.account_no end,
							@working_acomm,
							null
			from 			inclusion_spot spot,
							inclusion inc,
							inclusion_type inc_typ,
							media_product mp,
							film_campaign fc,
							film_screening_dates fsd
			where 			spot.campaign_no = @campaign_no 
			and				spot.inclusion_id = inc.inclusion_id 
			and				inc_typ.media_product_id = mp.media_product_id 
			and				inc.inclusion_type = inc_typ.inclusion_type 
			and				spot.billing_period = @accounting_period 
			and				spot.screening_date = fsd.screening_date 
			and				fc.campaign_no = inc.campaign_no 
			and				spot.spot_status <> 'P' 
			and				@mode = 1 
			and				inc.inclusion_format = 'M' 
			and				inc.inclusion_category = 'S'		
			and				inc.invoice_client = 'Y'
			order by	 	mp.media_product_id ASC,
							fsd.billing_period ASC
			for 			read only
		end
		else if @media_product_mode = 7 --takeouts
		begin
			declare 		bill_csr cursor static for
			select 			distinct spot.billing_period,
							inc.inclusion_type,
							inc.inclusion_category,
							case  
								when inc.inclusion_category in ('T', 'F', 'D') then fc.onscreen_account_id 
								when inc.inclusion_category = 'C' then fc.cinelight_account_id 
								when inc.inclusion_category in ('A', 'B', 'E', 'H', 'I', 'J', 'K', 'L', 'N', 'O') then case isnull(inc.account_no,0) when 0 then fc.onscreen_account_id else inc.account_no end 
								when inc.inclusion_category = 'R' then fc.outpost_account_id																
								else inc.account_no 
							end,
							@working_acomm,
							inc.inclusion_id
			from 			inclusion_spot spot,
							inclusion inc,
							film_campaign fc
			where 			spot.campaign_no = @campaign_no 
			and				spot.inclusion_id = inc.inclusion_id 
			and				spot.billing_period = @accounting_period 
			and				spot.spot_status <> 'P' 
			and				inc.inclusion_category <> 'M' 
			and				inc.inclusion_category <> 'S' 
			and				inc.inclusion_category <> 'G' 
			and				fc.campaign_no = inc.campaign_no 
			and				@mode = 1 
			order by 		spot.billing_period ASC,
							inc.inclusion_type ASC,
							inc.inclusion_category ASC
			for 			read only
            
            select			@working_acomm = 0.0
		end
		else if @media_product_mode = 8 --TAP Campaigns
		begin
			declare 		bill_csr cursor static for
			select 			distinct spot.billing_period,
							mp.media_product_id,
							mp.media_product_desc,
							fc.onscreen_account_id,
							@working_acomm,
							null
			from 			inclusion_spot spot,
							inclusion inc,
							inclusion_type inc_typ,
							media_product mp,
							film_campaign fc
			where 			spot.campaign_no = @campaign_no 
			and				spot.inclusion_id = inc.inclusion_id 
			and				inc_typ.media_product_id = mp.media_product_id 
			and				inc.inclusion_type = inc_typ.inclusion_type 
			and				spot.billing_period = @accounting_period 
			and				fc.campaign_no = inc.campaign_no 
			and				fc.campaign_no = inc.campaign_no 
			and				spot.spot_status <> 'P' 
			and				inc.inclusion_type = 24 
			and				inc.inclusion_category = 'S' 
			and				inc.invoice_client = 'Y' 
			and				@mode = 1 
			order by 		mp.media_product_id ASC,
							spot.billing_period ASC
			for 			read only
		end		
		else if @media_product_mode = 9 --Sports campaigns
		begin
			declare 		bill_csr cursor static for
			select 			distinct fsd.billing_period,
							16,
							'VM Sports',
							case isnull(inc.account_no,0) when 0 then fc.outpost_account_id else inc.account_no  end,
							@working_acomm,
							null
			from 			inclusion_spot spot,
							inclusion inc,
							film_campaign fc,
							outpost_screening_dates fsd
			where 			spot.campaign_no = @campaign_no 
			and				spot.inclusion_id = inc.inclusion_id 
			and				spot.billing_period = @accounting_period 
			and				spot.op_screening_date = fsd.screening_date 
			and				fc.campaign_no = inc.campaign_no 
			and				spot.spot_status <> 'P' 
			and				@mode = 1 
			and				inc.inclusion_format = 'R' 
			and				inc.inclusion_category = 'S' 
			and				inc.invoice_client = 'Y' 
			and				inc.inclusion_type = 26
			order by 		fsd.billing_period ASC
			for 			read only
		end
		else if @media_product_mode = 10 --CINEads campaigns
		begin
			declare 		bill_csr cursor static for
			select 			distinct fsd.billing_period,
							mp.media_product_id,
							mp.media_product_desc,
							fc.onscreen_account_id,
							@working_acomm,
							null
			from 			campaign_spot spot,
							campaign_package pack,
							media_product mp,
							film_screening_dates fsd,
							film_campaign fc
			where 			spot.campaign_no = @campaign_no 
			and				spot.package_id = pack.package_id 
			and				pack.media_product_id = mp.media_product_id 
			and				spot.billing_period = @accounting_period 
			and				fc.campaign_no = pack.campaign_no 
			and				spot.spot_status <> 'P' 
			and				spot.billing_date = fsd.screening_date 
			and				(( @mode = 1 
			and				spot.spot_type in ('S','B','N','R')) 
			or				( @mode >= 1 
			and				spot.spot_type = @spot_type )) 
			and				fc.business_unit_id = 9
			order by 		mp.media_product_id ASC,
							fsd.billing_period ASC
			for 			read only		
		end
		else if @media_product_mode = 11 --FF Audience 
		begin
			declare 		bill_csr cursor static for
			select 			distinct spot.billing_period,
							case business_unit_id when 2 then 1 else 2 end,
							'Follow Film',
							fc.onscreen_account_id,
							@working_acomm,
							null
			from 			inclusion_spot spot,
							inclusion inc,
							film_campaign fc
			where 			spot.campaign_no = @campaign_no 
			and				spot.inclusion_id = inc.inclusion_id 
			and				spot.billing_period = @accounting_period 
			and				fc.campaign_no = inc.campaign_no 
			and				fc.campaign_no = inc.campaign_no 
			and				spot.spot_status <> 'P' 
			and				inc.inclusion_type in (29) 
			and				inc.inclusion_category = 'S' 
			and				inc.invoice_client = 'Y' 
			and				@mode = 1 
			order by 		spot.billing_period ASC
			for 			read only	
		end 
		else if @media_product_mode = 12 --Roadblock
		begin
			declare 		bill_csr cursor static for
			select 			distinct spot.billing_period,
							case business_unit_id when 2 then 1 else 2 end,
							'Roadblock',
							fc.onscreen_account_id,
							@working_acomm,
							null
			from 			inclusion_spot spot,
							inclusion inc,
							film_campaign fc
			where 			spot.campaign_no = @campaign_no 
			and				spot.inclusion_id = inc.inclusion_id 
			and				spot.billing_period = @accounting_period 
			and				fc.campaign_no = inc.campaign_no 
			and				fc.campaign_no = inc.campaign_no 
			and				spot.spot_status <> 'P' 
			and				inc.inclusion_type in (30, 31) 
			and				inc.inclusion_category = 'S' 
			and				inc.invoice_client = 'Y' 
			and				@mode = 1 
			order by 		spot.billing_period ASC
			for 			read only	
		end 
		else if @media_product_mode = 13 --MM Audience
		begin
			declare 		bill_csr cursor static for
			select 			distinct spot.billing_period,
							case business_unit_id when 2 then 1 else 2 end,
							'MAP',
							fc.onscreen_account_id,
							@working_acomm,
							null
			from 			inclusion_spot spot,
							inclusion inc,
							film_campaign fc
			where 			spot.campaign_no = @campaign_no 
			and				spot.inclusion_id = inc.inclusion_id 
			and				spot.billing_period = @accounting_period 
			and				fc.campaign_no = inc.campaign_no 
			and				fc.campaign_no = inc.campaign_no 
			and				spot.spot_status <> 'P' 
			and				inc.inclusion_type in (32) 
			and				inc.inclusion_category = 'S' 
			and				inc.invoice_client = 'Y' 
			and				@mode = 1 
			order by 		spot.billing_period ASC
			for 			read only	
		end 
		else if @media_product_mode = 14 --FANDOM
		begin
			declare 		bill_csr cursor static for
			select 			distinct spot.billing_period,
							inc_typ.media_product_id,
							mp.media_product_desc,
							fc.onscreen_account_id,
							@working_acomm,
							spot.inclusion_id
			from 			inclusion_spot spot
			inner join		inclusion inc on spot.inclusion_id = inc.inclusion_id 
			inner join		inclusion_type inc_typ on inc.inclusion_type = inc_typ.inclusion_type
			inner join		film_campaign fc on inc.campaign_no = fc.campaign_no
			inner join		media_product mp on inc_typ.media_product_id = mp.media_product_id
			where 			spot.campaign_no = @campaign_no 
			and				spot.billing_period = @accounting_period 
			and				spot.spot_status <> 'P' 
			and				inc.inclusion_type between 34 and 65
			and				inc.inclusion_category = 'S' 
			and				inc.invoice_client = 'Y' 
			and				@mode = 1 
			order by 		spot.billing_period ASC
			for 			read only	
		end 
		
	    open bill_csr
	    select @bill_csr_open = 1
	    fetch bill_csr into @next_period, @media_product_id, @media_product_desc, @account_id, @working_acomm, @inclusion_id
	    while(@@fetch_status = 0)
	    begin

	
	       /*
	        * Initialise Totals
	        */
	
		    select			@exempt_gst_total = 0,
							@pre_gst_total = 0,
							@post_gst_total = 0,
							@tran_id = 0,
							@pre_tran_id = 0,
							@exempt_tran_id = 0,
							@post_tran_id = 0,
							@makegood_total = 0,
							@takeout_exempt_tran_id = 0,
							@takeout_pregst_tran_id = 0,
							@takeout_postgst_tran_id = 0
	
			if @media_product_mode < 7 or @media_product_mode = 11 or @media_product_mode = 12 or @media_product_mode = 13 or @media_product_mode = 14
			begin			

		       /*
		        * Setup Billing and Agency Commission Tran Codes
		        * based on Media Product
		        */
		       
				if @media_product_id = 1 -- FILM
				begin
					if @media_product_mode = 1 	or @media_product_mode >= 10
						select 		@billing_tran_code = 'FBILL',
									@acomm_tran_code = 'FACOM'
					else if	@media_product_mode = 6
						select 		@billing_tran_code = 'MPFBL',
									@acomm_tran_code = 'MPFAC'
				end
				else if @media_product_id = 2 -- DMG 
				begin
					if @media_product_mode = 1 or @media_product_mode >= 10	
						select 		@billing_tran_code = 'DBILL',
									@acomm_tran_code = 'DACOM'
					else if @media_product_mode = 6
						select		@billing_tran_code = 'MPDBL',
									@acomm_tran_code = 'MPDAC'
				end
				else if @media_product_id = 3 -- CINELIGHTS
				begin
					if @media_product_mode = 2
						select 		@billing_tran_code = 'CBILL',
									@acomm_tran_code = 'CACOM'
					else if @media_product_mode = 6
						select 		@billing_tran_code = 'MPCLB',
								@acomm_tran_code = 'MPCLA'
				end
				else if @media_product_id = 6 -- IN-FOYER
				begin
					if @media_product_mode = 3
						select		@billing_tran_code = 'IBILL',
									@acomm_tran_code = 'IACOM'
					else if @media_product_mode = 6
						select		@billing_tran_code = 'MPCMB',
									@acomm_tran_code = 'MPCMA'
				end
				else if @media_product_id = 9 -- RETAIL PANELS
				begin
					select		@billing_tran_code = 'RBILL',
								@acomm_tran_code = 'RACOM'
				end
				else if @media_product_id = 10 -- RETAIL MOVING WALL
				begin
					select 		@billing_tran_code = 'RWLBI',
								@acomm_tran_code = 'RWLAC'
				end
				else if @media_product_id between 22 and 28 or @media_product_id = 50 -- VM Digitial - FANDOM
				begin
					select 		@billing_tran_code = 'FANBI',
								@acomm_tran_code = 'FANAC'
				end
				else if @media_product_id between 29 and 35 or @media_product_id = 51 -- VM Digitial - The Latch
				begin
					select 		@billing_tran_code = 'LLABI',
								@acomm_tran_code = 'LLAAC'
				end
				else if @media_product_id between 36 and 42 or @media_product_id = 52 -- VM Digitial - Thrillist
				begin
					select 		@billing_tran_code = 'TLABI',
								@acomm_tran_code = 'TLAAC'
				end
				else if @media_product_id between 43 and 49 or @media_product_id = 53 -- VM Digitial - Popsugar
				begin
					select 		@billing_tran_code = 'PLABI',
								@acomm_tran_code = 'PLAAC'
				end
			end
			else if @media_product_mode = 7 
			begin

				/*
  				 * Set the tran type for the actual item based on inclusion_type and inclusion_category
				 * stored in @media_product_id and @media_product_desc respectively
				 */

				if @media_product_desc = 'A'
					select 		@t_billing_tran_code = 'FANTO',
								@takeout_desc = 'FANDOM Commerce Takeout'
				else if @media_product_desc = 'B'
					select 		@t_billing_tran_code = 'FANTO',
								@takeout_desc = 'FANDOM Content Takeout'
				else if @media_product_desc = 'C'
					select 		@t_billing_tran_code = 'CTAKE',
								@takeout_desc = 'Cinelights Takeout'
	       		else if @media_product_desc = 'D'
					select 		@t_billing_tran_code = 'DTAKE',
								@takeout_desc = 'DMG Takeout'
	       		else if @media_product_desc = 'E'
					select 		@t_billing_tran_code = 'LLATO',
								@takeout_desc = 'The Latch Commerce Takeout'
				else if @media_product_desc = 'F'
					select 		@t_billing_tran_code = 'FTAKE',
								@takeout_desc = 'Main Block Takeout'
				else if @media_product_desc = 'H'
					select 		@t_billing_tran_code = 'FANTO',
								@takeout_desc = 'FANDOM Direct Takeout'
				else if @media_product_desc = 'I'
					select 		@t_billing_tran_code = 'ITAKE',
								@takeout_desc = 'Cinemarketing Takeout'
				else if @media_product_desc = 'J'
					select 		@t_billing_tran_code = 'LLATO',
								@takeout_desc = 'The Latch Content Takeout'
				else if @media_product_desc = 'K'
					select 		@t_billing_tran_code = 'TLATO',
								@takeout_desc = 'Thrillist Content Takeout'
				else if @media_product_desc = 'L'
					select 		@t_billing_tran_code = 'PLATO',
								@takeout_desc = 'Popsugar Content Takeout'
				else if @media_product_desc = 'N'
					select 		@t_billing_tran_code = 'TLATO',
								@takeout_desc = 'Thrilllist Commerce Takeout'
				else if @media_product_desc = 'O'
					select 		@t_billing_tran_code = 'PLATO',
								@takeout_desc = 'Popsugar Commerce Takeout'
				else if @media_product_desc = 'R'
					select 		@t_billing_tran_code = 'RTAKE',
								@takeout_desc = 'Retail Panel Takeout'
				else if @media_product_desc = 'T'
					select 		@t_billing_tran_code = 'TTAKE',
								@takeout_desc = 'TAP Takeout'

			
				select 		@billing_tran_code = trantype_code,
							@trantype_desc = trantype_desc
				from		inclusion_type_category_xref,
							transaction_type
				where		inclusion_type_category_xref.trantype_id = transaction_type.trantype_id
				and			inclusion_type_category_xref.inclusion_type = @media_product_id
				and			inclusion_type_category_xref.inclusion_category = 'S' --this gives the non takeout tran type.
				
			end
			else if @media_product_mode = 8
			begin
					select 	@billing_tran_code = 'TBILL',
							@acomm_tran_code = 'TACOM'
			end
			else if @media_product_mode = 9
			begin
					select 	@billing_tran_code = 'SPBIL',
							@acomm_tran_code = 'SPACM'
			end
			else if @media_product_mode = 10
			begin
					select 	@billing_tran_code = 'ABILL',
							@acomm_tran_code = 'AACOM'
			end

	       /*
	        * Setup Period Description
	        */
	
		    exec @errorode = p_month_name @next_period, @month_name OUTPUT
	
		    if(@errorode !=0)
		    begin
				print 1
			    rollback transaction
			    goto error
		    end
	
		    select 	@period_desc = @month_name + ' ' + datename(yy, @next_period)

			select 	@period_start = start_date
			from	accounting_period 
			where	end_date = @next_period

			select 	@period_detailed_desc = 'For activity during ' + convert(varchar(10), @period_start, 103) + ' to ' + convert(varchar(10), @next_period, 103)

		    /***************************
	        * Calculate Period Totals *
	        ***************************/
	
			if @media_product_mode = 1 --onscreen
			begin
				declare 		spot_csr cursor static for
				select 			spot.spot_id,
								spot.spot_status,
								spot.charge_rate,
								spot.makegood_rate,
								acc.country_code,
								spot.billing_date
				from 			campaign_spot spot,
								campaign_package pack,
								account acc,
								film_screening_dates fsd,
								film_campaign fc
				where 			spot.campaign_no = @campaign_no 
				and				spot.campaign_no = fc.campaign_no 
				and				(( @mode = 1 
				and				spot.spot_type in ('S','B','N','R')) 
				or				( @mode >= 1 
				and				spot.spot_type = @spot_type )) 
				and				spot.package_id = pack.package_id 
				and				spot.spot_status <> 'P' 
				and				pack.media_product_id = @media_product_id 
				and				spot.billing_period = @accounting_period 
				and				fc.onscreen_account_id = acc.account_id 
				and				fc.onscreen_account_id = @account_id
				and				spot.billing_date = fsd.screening_date 
				and				fsd.billing_period = @next_period 
				and				fc.business_unit_id <> 9
				order by		acc.country_code,
								spot.package_id,
								spot.spot_id
				for				read only
			end
			else if @media_product_mode = 2 --cinelights
			begin
				declare 		spot_csr cursor static for
				select 			spot.spot_id,
								spot.spot_status,
								spot.charge_rate,
								spot.makegood_rate,
								acc.country_code,
								spot.billing_date
				from 			cinelight_spot spot,
								cinelight_package pack,
								cinelight cl,
								account acc,
								film_campaign fc,
								film_screening_dates fsd
				where 			spot.campaign_no = @campaign_no 
				and				(( @mode = 1 
				and				spot.spot_type in ('S','B','N','R')) 
				or				( @mode >= 1 
				and				spot.spot_type = @spot_type )) 
				and				spot.spot_status <> 'P' 
				and				spot.package_id = pack.package_id 
				and				pack.media_product_id = @media_product_id 
				and				spot.billing_period = @accounting_period 
				and				spot.cinelight_id = cl.cinelight_id 
				and				fc.cinelight_account_id = acc.account_id 
				and				fc.cinelight_account_id = @account_id 
				and				spot.billing_date = fsd.screening_date 
				and				fsd.billing_period = @next_period 
				and				fc.campaign_no = spot.campaign_no
				order by	 	acc.country_code,
								spot.package_id,
								spot.spot_id
				for				read only
			end
			else if @media_product_mode = 3 --cinemarketing
			begin
				declare 		spot_csr cursor static for
				select 			spot.spot_id,
								spot.spot_status,
								spot.charge_rate,
								0.0,
								(select country_code from account where account_id = @account_id),
								spot.billing_date
				from 			inclusion_spot spot,
								inclusion_type inc_typ,
								inclusion inc,
								film_screening_dates fsd,
								film_campaign fc
				where 			spot.campaign_no = @campaign_no 
				and				(( @mode = 1 
				and				spot.spot_type in ('S','B','N','R')) 
				or				( @mode >= 1 
				and				spot.spot_type = @spot_type )) 
				and				spot.inclusion_id = inc.inclusion_id 
				and				inc_typ.inclusion_type = inc.inclusion_type 
				and				inc_typ.media_product_id = @media_product_id 
				and				spot.spot_status <> 'P' 
				and				spot.billing_period = @accounting_period 
				and				inc.campaign_no = fc.campaign_no 
				and				spot.billing_date = fsd.screening_date 
				and				fsd.billing_period = @next_period 
				and				inc.inclusion_type = 5 
				and				inc.inclusion_category = 'S' 
				and				inc.invoice_client = 'Y' 
				and				(inc.account_no = @account_id 
				or				(fc.onscreen_account_id = @account_id 
				and				inc.account_no is null))
				order by	 	spot.inclusion_id,
								spot.spot_id
				for				read only
			end	
			else if @media_product_mode = 4 --retail panels
			begin
				declare 		spot_csr cursor static for
				select 			spot.spot_id,
								spot.spot_status,
								spot.charge_rate,
								spot.makegood_rate,
								acc.country_code,
								spot.billing_date
				from 			outpost_spot spot,
								outpost_package pack,
								outpost_panel cl,
								outpost_venue cplx,
								account acc,
								outpost_screening_dates fsd,
								film_campaign fc
				where 			spot.campaign_no = @campaign_no 
				and				(( @mode = 1 
				and				spot.spot_type in ('S','B','N','R')) 
				or				( @mode >= 1 
				and				spot.spot_type = @spot_type )) 
				and				spot.spot_status <> 'P' 
				and				spot.package_id = pack.package_id 
				and				pack.media_product_id = @media_product_id 
				and				spot.billing_period = @accounting_period 
				and				spot.outpost_panel_id = cl.outpost_panel_id 
				and				cl.outpost_venue_id = cplx.outpost_venue_id 
				and				fc.outpost_account_id = acc.account_id 
				and				spot.billing_date = fsd.screening_date 
				and				fsd.billing_period = @next_period 
				and				fc.campaign_no = spot.campaign_no
				and				fc.outpost_account_id = @account_id
				order by 		acc.country_code,
								spot.package_id,
								spot.spot_id
				for				read only
			end
			else if @media_product_mode = 5 --retail wall
			begin
				declare 		spot_csr cursor static for
				select 			spot.spot_id,
								spot.spot_status,
								spot.charge_rate,
								0.0,
								(select country_code from account where account_id = @account_id),
								spot.billing_date
				from 			inclusion_spot spot,
								inclusion_type inc_typ,
								inclusion inc,
								outpost_screening_dates fsd,
								film_campaign fc
				where 			spot.campaign_no = @campaign_no 
				and				(( @mode = 1 
				and				spot.spot_type in ('S','B','N','R')) 
				or				( @mode >= 1 
				and				spot.spot_type = @spot_type )) 
				and				spot.inclusion_id = inc.inclusion_id 
				and				inc_typ.inclusion_type = inc.inclusion_type 
				and				inc_typ.media_product_id = @media_product_id 
				and				inc.commission = @working_acomm 
				and				spot.spot_status <> 'P' 
				and				spot.billing_period = @accounting_period 
				and				spot.op_billing_date = fsd.screening_date 
				and				inc.campaign_no = fc.campaign_no 
				and				fsd.billing_period = @next_period 
				and				inc.inclusion_type = 18 
				and				inc.inclusion_category = 'S' 
				and				inc.invoice_client = 'Y' 
				and				(inc.account_no = @account_id 
				or				(fc.outpost_account_id = @account_id 
				and				inc.account_no is null))
				order by		spot.inclusion_id,
								spot.spot_id
				for				read only
			end	
			else if @media_product_mode = 6 --media proxy
			begin
				declare 		spot_csr cursor static for
				select 			spot.spot_id,
								spot.spot_status,
								spot.charge_rate,
								0.0,
								(select country_code from account where account_id = @account_id),
								spot.screening_date
				from 			inclusion_spot spot,
								inclusion_type inc_typ,
								inclusion inc,
								complex cplx,
								state st,
								film_screening_dates fsd
				where 			spot.campaign_no = @campaign_no 
				and				spot.inclusion_id = inc.inclusion_id 
				and				inc_typ.inclusion_type = inc.inclusion_type 
				and				inc_typ.media_product_id = @media_product_id 
				and				spot.billing_period = @accounting_period 
				and				spot.complex_id = cplx.complex_id 
				and				cplx.state_code = st.state_code 
				and				spot.screening_date = fsd.screening_date 
				and				spot.spot_status <> 'P' 
				and				fsd.billing_period = @next_period 
				and				@mode = 1 
				and				inc.inclusion_type in (11,14,12,13) 
				and				inc.invoice_client = 'Y'
				order by 		st.country_code,
								spot.inclusion_id,
								spot.spot_id
				for				read only
			end	
			else if @media_product_mode = 7 --takeout
			begin
				declare 		spot_csr cursor static for
				select 			spot.spot_id,
								spot.spot_status,
								spot.takeout_rate,
								0.0,
								(select country_code from account where account_id = @account_id) as country_code,
								spot.billing_period
				from 			inclusion_spot spot,
								inclusion inc,
								branch br,
								film_campaign fc
				where	 		spot.campaign_no = @campaign_no 
				and				spot.inclusion_id = inc.inclusion_id 
				and				spot.inclusion_id = @inclusion_id
				and				inc.inclusion_type = @media_product_id 
				and				inc.inclusion_category = @media_product_desc 
				and				spot.billing_period = @accounting_period 
				and				spot.spot_status <> 'P' 
				and				@mode = 1 
				and				@accounting_period = @next_period 
				and				fc.campaign_no = inc.campaign_no 
				and				fc.campaign_no = spot.campaign_no 
				and				fc.branch_code = br.branch_code
				and				(
									(inc.inclusion_category in ('T', 'F', 'D') 
					and				fc.onscreen_account_id = @account_id)
					or				(inc.inclusion_category = 'C' 
					and				fc.cinelight_account_id = @account_id)
					or				(inc.inclusion_category in ('A', 'B', 'E', 'H', 'I', 'J', 'K', 'L', 'N', 'O') 
					and				((isnull(inc.account_no,0) = 0
					and				fc.onscreen_account_id = @account_id)
					or				inc.account_no = @account_id))
					or				(inc.inclusion_category = 'R' 
					and				fc.outpost_account_id = @account_id)
								)
				order by		br.country_code,
								spot.inclusion_id,
								spot.spot_id
				for				read only
			end	
			else if @media_product_mode = 8 --TAP
			begin
				declare 		spot_csr cursor static for
				select 			spot.spot_id,
								spot.spot_status,
								spot.charge_rate,
								0.0,
								acc.country_code,
								spot.billing_date
				from 			inclusion_spot spot,
								inclusion_type inc_typ,
								inclusion inc,
								film_campaign fc,
								account acc
				where 			spot.campaign_no = @campaign_no 
				and				spot.inclusion_id = inc.inclusion_id 
				and				inc_typ.inclusion_type = inc.inclusion_type 
				and				spot.spot_status <> 'P' 
				and				spot.billing_period = @accounting_period 
				and				inc.campaign_no = fc.campaign_no 
				and				inc.inclusion_type = 24 
				and				inc.inclusion_category = 'S' 
				and				inc.invoice_client = 'Y' 
				and				@mode = 1 
				and				fc.onscreen_account_id = @account_id 
				and				fc.onscreen_account_id = acc.account_id
				order by 		acc.country_code,
								spot.inclusion_id,
								spot.spot_id
				for				read only
			end	
			else if @media_product_mode = 9 --Sports
			begin
				declare 		spot_csr cursor static for
				select 			spot.spot_id,
								spot.spot_status,
								spot.charge_rate,
								0.0,
								acc.country_code,
								spot.op_billing_date
				from 			inclusion_spot spot,
								inclusion inc,
								film_campaign fc,
								account acc
				where 			spot.campaign_no = @campaign_no 
				and				spot.inclusion_id = inc.inclusion_id 
				and				spot.billing_period = @accounting_period 
				and				fc.outpost_account_id = acc.account_id
				and				acc.account_id = @account_id
				and				fc.campaign_no = inc.campaign_no 
				and				spot.spot_status <> 'P' 
				and				@mode = 1 
				and				inc.inclusion_format = 'R' 
				and				inc.inclusion_category = 'S' 
				and				inc.invoice_client = 'Y' 
				and				inc.inclusion_type = 26
				order by 		acc.country_code,
								spot.inclusion_id,
								spot.spot_id
				for read only
			end	
			if @media_product_mode = 10 --Cineads onscreen
			begin
				declare 		spot_csr cursor static for
				select 			spot.spot_id,
								spot.spot_status,
								spot.charge_rate,
								spot.makegood_rate,
								acc.country_code,
								spot.billing_date
				from 			campaign_spot spot,
								campaign_package pack,
								complex cplx,
								account acc,
								film_screening_dates fsd,
								film_campaign fc
				where 			spot.campaign_no = @campaign_no 
				and				spot.campaign_no = fc.campaign_no 
				and				(( @mode = 1 
				and				spot.spot_type in ('S','B','N','R')) 
				or				( @mode >= 1 
				and				spot.spot_type = @spot_type )) 
				and				spot.package_id = pack.package_id 
				and				spot.spot_status <> 'P' 
				and				pack.media_product_id = @media_product_id 
				and				spot.billing_period = @accounting_period 
				and				spot.complex_id = cplx.complex_id 
				and				fc.onscreen_account_id = acc.account_id
				and				acc.account_id = @account_id
				and				spot.billing_date = fsd.screening_date 
				and				fsd.billing_period = @next_period 
				and				fc.business_unit_id = 9
				order by	 	acc.country_code,
								spot.package_id,
								spot.spot_id
				for				read only
			end		
			else if @media_product_mode = 11 --FF Audience 
			begin
				declare 		spot_csr cursor static for
				select 			spot.spot_id,
								spot.spot_status,
								spot.charge_rate,
								0.0,
								acc.country_code,
								spot.billing_date
				from 			inclusion_spot spot,
								inclusion inc,
								film_campaign fc,
								account acc,
								inclusion_cinetam_package pack
				where 			spot.campaign_no = @campaign_no 
				and				spot.inclusion_id = inc.inclusion_id 
				and				pack.inclusion_id = inc.inclusion_id 
				and				spot.spot_status <> 'P' 
				and				spot.billing_period = @accounting_period 
				and				inc.campaign_no = fc.campaign_no 
				and				inc.inclusion_type in (29) 
				and				inc.inclusion_category = 'S' 
				and				inc.invoice_client = 'Y' 
				and				@mode = 1 
				and				fc.onscreen_account_id = @account_id 
				and				fc.onscreen_account_id = acc.account_id
				order by 		acc.country_code,
								spot.inclusion_id,
								spot.spot_id
				for read only
			end	
			else if @media_product_mode = 12 --Roadblock 
			begin
				declare 		spot_csr cursor static for
				select 			spot.spot_id,
								spot.spot_status,
								spot.charge_rate,
								0.0,
								acc.country_code,
								spot.billing_date
				from 			inclusion_spot spot,
								inclusion inc,
								film_campaign fc,
								account acc,
								inclusion_cinetam_package pack
				where 			spot.campaign_no = @campaign_no 
				and				spot.inclusion_id = inc.inclusion_id 
				and				pack.inclusion_id = inc.inclusion_id 
				and				spot.spot_status <> 'P' 
				and				spot.billing_period = @accounting_period 
				and				inc.campaign_no = fc.campaign_no 
				and				inc.inclusion_type in (30,31) 
				and				inc.inclusion_category = 'S' 
				and				inc.invoice_client = 'Y' 
				and				@mode = 1 
				and				fc.onscreen_account_id = @account_id 
				and				fc.onscreen_account_id = acc.account_id 
				order by 		acc.country_code,
								spot.inclusion_id,
								spot.spot_id
				for				read only
			end	
			else if @media_product_mode = 13 --MM Aud 
			begin
				declare 		spot_csr cursor static for
				select 			spot.spot_id,
								spot.spot_status,
								spot.charge_rate,
								0.0,
								acc.country_code,
								spot.billing_date
				from 			inclusion_spot spot,
								inclusion inc,
								film_campaign fc,
								account acc,
								inclusion_cinetam_package pack
				where 			spot.campaign_no = @campaign_no 
				and				spot.inclusion_id = inc.inclusion_id 
				and				pack.inclusion_id = inc.inclusion_id 
				and				spot.spot_status <> 'P' 
				and				spot.billing_period = @accounting_period 
				and				inc.campaign_no = fc.campaign_no 
				and				inc.inclusion_type in (32) 
				and				inc.inclusion_category = 'S' 
				and				inc.invoice_client = 'Y' 
				and				@mode = 1 
				and				fc.onscreen_account_id = @account_id 
				and				fc.onscreen_account_id = acc.account_id 
				order by 		acc.country_code,
								spot.inclusion_id,
								spot.spot_id
				for				read only
			end	
			else if @media_product_mode = 14 --FANDOM
			begin
				declare 		spot_csr cursor static for
				select 			spot.spot_id,
								spot.spot_status,
								spot.charge_rate,
								0.0,
								acc.country_code,
								spot.billing_date
				from 			inclusion_spot spot,
								inclusion inc,
								film_campaign fc,
								account acc
				where 			spot.campaign_no = @campaign_no 
				and				spot.inclusion_id = inc.inclusion_id 
				and				spot.spot_status <> 'P' 
				and				spot.billing_period = @accounting_period 
				and				inc.campaign_no = fc.campaign_no 
				and				inc.inclusion_type in (34,36,37,38,39,41,43,44,45,46,48,50,51,52,53,55,57,58,59,60)
				and				inc.invoice_client = 'Y' 
				and				@mode = 1 
				and				fc.onscreen_account_id = @account_id 
				and				fc.onscreen_account_id = acc.account_id 
				and				inc.inclusion_id = @inclusion_id
				order by 		acc.country_code,
								spot.inclusion_id,
								spot.spot_id
				for				read only
			end	

		    open spot_csr
		    fetch spot_csr into @spot_id, @status, @rate, @makegood_rate, @country_code, @billing_date
		    while(@@fetch_status = 0)
		    begin
	
	           /*
	            * Increment Rate and Weighting totals
	            */
	            
	            select @makegood_total = @makegood_total + @makegood_rate
	
			    if(@status <> 'D' and @rate <> 0)
			    begin
	
	     	       /*
	                * Determine Billing Amounts
	                */
	
				    if(@country_code <> @campaign_country )
					    select @exempt_gst_total = @exempt_gst_total + @rate
				    else
				    begin
					    if(@accounting_period >= @gst_changeover)
						    select @post_gst_total = @post_gst_total + @rate
					    else
						    select @pre_gst_total = @pre_gst_total + @rate
				    end
	            end 
	
	           /*
	            * Fetch Next Spot
	            */
	
	    	    fetch spot_csr into @spot_id, @status, @rate, @makegood_rate, @country_code, @billing_date
	
		    end
		    close spot_csr
			deallocate spot_csr
	
		   /**************************************
	        * Create International Transactions  *
	        **************************************/
	
			if @media_product_mode <> 7
			begin

			    if(@exempt_gst_total > 0)
			    begin
		
				   /*
				    * Setup Transaction Information
				    */
				
		            select @tran_desc = @mode_desc + ' International ' + @media_product_desc + ' Screenings (' + @period_desc + ')'
		            select @tran_notes = @period_detailed_desc

					if @media_product_mode = 14
					begin
						select			@inclusion_desc = inclusion_desc
						from			inclusion
						where			inclusion_id =	@inclusion_id

						select			@tran_notes = @tran_notes + ' - '  + left(@inclusion_desc, 251 - len(@tran_notes))
					end
		
			       /*
		            * Create Billing Transaction
		            */
		
				    exec @errorode = p_ffin_create_transaction @billing_tran_code,
		                                                    @campaign_no,
															@account_id,
		                                                    @tran_date,
		                                                    @tran_desc,
		                                                    @tran_notes,
		                                                    @exempt_gst_total,
		                                                    0.0,
															'Y',	
		                                                    @exempt_tran_id OUTPUT
		
				    if(@errorode !=0)
				    begin
						print 2
					    rollback transaction
					    goto error
				    end
		
					if (@media_product_mode = 7 or @media_product_mode = 14) and (@exempt_tran_id > 0)
					begin
						insert into inclusion_tran_xref values (@inclusion_id, @exempt_tran_id )

						select @error = @@ERROR
						if @error <> 0
						begin
							print 3
							rollback transaction
							goto error
						end
					end

			  	   /*
		            * Set Tran Id
		            */
		
				   select @tran_id = @exempt_tran_id
		
			  	   /*
		            * Create Agency Commission
		            */
		
				    if(@working_acomm > 0)
				    begin
					
					    select @acomm_nett = round(@exempt_gst_total * @working_acomm,2)	* -1
					    select @acomm_gross = @acomm_nett
					    select @tran_desc = 'A/Comm - ' + @mode_desc + ' International ' + @media_product_desc + ' Screenings (' + @period_desc + ')'
		                select @tran_notes = @period_detailed_desc

						if @media_product_mode = 14
						begin
							select			@inclusion_desc = inclusion_desc
							from			inclusion
							where			inclusion_id =	@inclusion_id

							select			@tran_notes = @tran_notes + ' - '  + left(@inclusion_desc, 251 - len(@tran_notes))
						end
		                
					    exec @errorode = p_ffin_create_transaction @acomm_tran_code,
														        @campaign_no,
																@account_id,
														        @tran_date,
														        @tran_desc,
		                                                        @tran_notes,
														        @acomm_nett,
														        0.0,
																'Y',
														        @acomm_tran_id OUTPUT
					    if(@errorode !=0)
					    begin
							print 4
						    rollback transaction
						    goto error
					    end
		
						if (@media_product_mode = 7 or @media_product_mode = 14) and (@acomm_tran_id > 0)
						begin
							insert into inclusion_tran_xref values (@inclusion_id, @acomm_tran_id )

							select @error = @@ERROR
							if @error <> 0
							begin
								rollback transaction
								goto error
							end
						end

					   /*
					    *	Allocate Agency Commision to Billing
					    */
		
					    exec @errorode = p_ffin_allocate_transaction @acomm_tran_id, @exempt_tran_id, @acomm_nett, @accounting_period
					    if(@errorode !=0)
					    begin
						    rollback transaction
						    goto error
					    end
                        
				    end
		
				    if(@mode = 3 and @exempt_gst_total > 0)
				    begin
				
					    select @acomm_nett = (isnull(@exempt_gst_total,0)) * -1
					    select @tran_desc = 'Contra Credit - ' + @mode_desc + ' International ' + @media_product_desc + ' Screenings (' + @period_desc + ')'
		                select @tran_notes = @period_detailed_desc
		
						if @media_product_mode = 14
						begin
							select			@inclusion_desc = inclusion_desc
							from			inclusion
							where			inclusion_id =	@inclusion_id

							select			@tran_notes = @tran_notes + ' - '  + left(@inclusion_desc, 251 - len(@tran_notes))
						end

					    exec @errorode = p_ffin_create_transaction 'FCCRD',
														        @campaign_no,
																@account_id,
														        @tran_date,
														        @tran_desc,
		                                                        @tran_notes,
														        @acomm_nett,
														        0.0,
																'Y',
														        @acomm_tran_id OUTPUT
					    if(@errorode !=0)
					    begin
							print 6
						    rollback transaction
						    goto error
					    end
		            
						if (@media_product_mode = 7 or @media_product_mode = 14) and (@acomm_tran_id > 0)
						begin
							insert into inclusion_tran_xref values (@inclusion_id, @acomm_tran_id )

							select @error = @@ERROR
							if @error <> 0
							begin
								rollback transaction
								goto error
							end
						end

		               /*
					    *	Allocate Contra Credit to Contra Campaign
				        */
		
					    exec @errorode = p_ffin_allocate_transaction @acomm_tran_id, @exempt_tran_id, @acomm_nett, @accounting_period
					    if(@errorode !=0)
					    begin
							print 8
						    rollback transaction
						    goto error
					    end
		
		            end
		
			    end
		
			   /*******************************
		        * Create Pre-GST Transactions *
		        *******************************/
		
			    if(@pre_gst_total > 0)
			    begin
		
				   /*
				    * Setup Transaction Information
				    */
		
				    select @tran_desc = @mode_desc + ' ' + @media_product_desc + ' Screenings (' + @period_desc + ')'
				    if(@pre_gst_rate > 0 and @gst_desc_on = 'Y' and @pre_gst_total <> 0)
					    select @tran_notes = 'GST@' + convert(varchar(4),convert(numeric(3,1), round(@pre_gst_rate * 100,1))) + '% ' + @period_detailed_desc
 		            else
		                select @tran_notes = @period_detailed_desc

					if @media_product_mode = 14
					begin
						select			@inclusion_desc = inclusion_desc
						from			inclusion
						where			inclusion_id =	@inclusion_id

						select			@tran_notes = @tran_notes + ' - '  + left(@inclusion_desc, 251 - len(@tran_notes))
					end

		
			  	   /*
		            * Create Billing Transaction
		            */
		
				    exec @errorode = p_ffin_create_transaction @billing_tran_code,
		                                                    @campaign_no,
															@account_id,
			                                                @tran_date,
			                                                @tran_desc,
		                                                    @tran_notes,
			                                                @pre_gst_total,
			                                                @pre_gst_rate,
															'Y',
			                                                @pre_tran_id OUTPUT
		
				    if(@errorode !=0)
				    begin
					    rollback transaction
					    goto error
				    end
		
					if (@media_product_mode = 7 or @media_product_mode = 14) and (@pre_tran_id > 0)
					begin
						insert into inclusion_tran_xref values (@inclusion_id, @pre_tran_id )

						select @error = @@ERROR
						if @error <> 0
						begin
							rollback transaction
							goto error
						end
					end

			  	   /*
		            * Set Tran Id
		            */
		
				    select @tran_id = @pre_tran_id
		
			  	   /*
		            * Create Agency Commission
		            */
		
				    if(@working_acomm > 0)
				    begin
					
					    select @acomm_nett = round(@pre_gst_total * @working_acomm,2)	* -1
					    select @acomm_gross = @acomm_nett + round(@acomm_nett * @pre_gst_rate,2)
					    select @tran_desc = 'A/Comm - ' + @mode_desc + ' ' + @media_product_desc + ' Screenings (' + @period_desc + ')'
		
		    		    if(@pre_gst_rate > 0 and @gst_desc_on = 'Y' and @acomm_nett <> 0)
						    select @tran_notes = 'GST@' + convert(varchar(4),convert(numeric(3,1), round(@pre_gst_rate * 100,1))) + '% ' + @period_detailed_desc
		                else
		                    select @tran_notes = @period_detailed_desc
		
						if @media_product_mode = 14
						begin
							select			@inclusion_desc = inclusion_desc
							from			inclusion
							where			inclusion_id =	@inclusion_id

							select			@tran_notes = @tran_notes + ' - '  + left(@inclusion_desc, 251 - len(@tran_notes))
						end

					    exec @errorode = p_ffin_create_transaction @acomm_tran_code,
															    @campaign_no,
																@account_id,
														 	    @tran_date,
															    @tran_desc,
		                                                        @tran_notes,
															    @acomm_nett,
															    @pre_gst_rate,
																'Y',
															    @acomm_tran_id OUTPUT
					    if(@errorode !=0)
					    begin
						    rollback transaction
						    goto error
					    end
		
						if (@media_product_mode = 7 or @media_product_mode = 14) and (@acomm_tran_id > 0)
						begin
							insert into inclusion_tran_xref values (@inclusion_id, @acomm_tran_id )

							select @error = @@ERROR
							if @error <> 0
							begin
								rollback transaction
								goto error
							end
						end

					   /*
					    *	Allocate Agency Commision to Billing
					    */
		
					    exec @errorode = p_ffin_allocate_transaction @acomm_tran_id, @pre_tran_id, @acomm_nett, @accounting_period
					    if(@errorode !=0)
					    begin
						    rollback transaction
						    goto error
					    end
		
				    end
		
				    if(@mode = 3 and @pre_gst_total > 0)
				    begin
				
					    select @acomm_nett = (isnull(@pre_gst_total,0)) * -1
					    select @tran_desc = 'Contra Credit - ' + @mode_desc + ' ' + @media_product_desc + ' Screenings (' + @period_desc + ')'
		                select @tran_notes = ''
		
		    		    if(@pre_gst_rate > 0 and @gst_desc_on = 'Y' and @acomm_nett <> 0)
						    select @tran_notes = 'GST@' + convert(varchar(4),convert(numeric(3,1), round(@pre_gst_rate * 100,1))) + '% ' + @period_detailed_desc
		                else
		                    select @tran_notes = @period_detailed_desc
		
						if @media_product_mode = 14
						begin
							select			@inclusion_desc = inclusion_desc
							from			inclusion
							where			inclusion_id =	@inclusion_id

							select			@tran_notes = @tran_notes + ' - '  + left(@inclusion_desc, 251 - len(@tran_notes))
						end

					    exec @errorode = p_ffin_create_transaction 'FCCRD',
															    @campaign_no,
																@account_id,
														 	    @tran_date,
															    @tran_desc,
		                                                        @tran_notes,
															    @acomm_nett,
															    @pre_gst_rate,
																'Y',
															    @acomm_tran_id OUTPUT
		
					    if(@errorode !=0)
					    begin
						    rollback transaction
						    goto error
					    end
		            
						if (@media_product_mode = 7 or @media_product_mode = 14) and (@acomm_tran_id > 0)
						begin
							insert into inclusion_tran_xref values (@inclusion_id, @acomm_tran_id )

							select @error = @@ERROR
							if @error <> 0
							begin
								rollback transaction
								goto error
							end
						end

		               /*
					    *	Allocate Contra Credit to Contra Campaign
				        */
		
					    exec @errorode = p_ffin_allocate_transaction @acomm_tran_id, @pre_tran_id, @acomm_nett, @accounting_period
					    if(@errorode !=0)
					    begin
						    rollback transaction
						    goto error
					    end
		
		            end
		
			    end
		
		       /********************************
		        * Create Post-GST Transactions *
		        ********************************/
		
			    if(@post_gst_total >= 0)
			    begin
		
		    	   /*
				    * Setup Transaction Information
				    */
				
		            if(@pre_gst_total > 0)
				    begin
		
					    exec @errorode = p_month_name @gst_changeover, @month_name OUTPUT
					    if(@errorode !=0)
					    begin
						    rollback transaction
						    goto error
					    end
		
					    select @period_desc = 'From: ' + datename(dd, @gst_changeover) + '-' + @month_name + '-' + datename(yy, @gst_changeover)
		
				    end
		
				    select @tran_desc = @mode_desc + ' ' + @media_product_desc + ' Screenings (' + @period_desc + ')'
		
		            select @tran_notes = @period_detailed_desc
		
		            if(@mode = 4 and @makegood_total > 0)
		            begin
		            
		           	    exec @errorode = p_currency_to_string @makegood_total, @currency_string OUTPUT
			            if(@errorode !=0)
			            begin
				            rollback transaction
				            goto error
			            end
		
		                select @tran_notes = 'Make Good Value: ' + @currency_string + ' less Agency Commssion.'
		
		            end
		
				    if(@post_gst_rate > 0 and @gst_desc_on = 'Y' and @post_gst_total <> 0)
					    select @tran_notes = 'GST@' + convert(varchar(4),convert(numeric(3,1),round(@post_gst_rate * 100,1))) + '% ' + @period_detailed_desc
		
					if @media_product_mode = 14
					begin
						select			@inclusion_desc = inclusion_desc
						from			inclusion
						where			inclusion_id =	@inclusion_id

						select			@tran_notes = @tran_notes + ' - '  + left(@inclusion_desc, 251 - len(@tran_notes))
					end


			  	   /*
		            * Create Billing Transaction
		            */
		
				    exec @errorode = p_ffin_create_transaction @billing_tran_code,
		                                            	    @campaign_no,
															@account_id,
			                                                @tran_date,
			                                                @tran_desc,
		                                                    @tran_notes,
			                                                @post_gst_total,
			                                                @post_gst_rate,
															'Y',
			                                                @post_tran_id OUTPUT
				    if(@errorode !=0)
				    begin
					    rollback transaction
					    goto error
				    end
		
					if (@media_product_mode = 7 or @media_product_mode = 14) and (@post_tran_id > 0)
					begin
						insert into inclusion_tran_xref values (@inclusion_id, @post_tran_id )

						select @error = @@ERROR
						if @error <> 0
						begin
							print 1
							rollback transaction
							goto error
						end
					end

			       /*
		            * Set Tran Id
		            */
		
				    select @tran_id = @post_tran_id
		
			       /*
		            * Create Agency Commission
		            */
		
				    if(@working_acomm > 0)
				    begin
					
					    select @acomm_nett = round(@post_gst_total * @working_acomm,2)	* -1
					    select @acomm_gross = @acomm_nett + round(@acomm_nett * @post_gst_rate,2)
		 				select @tran_desc = 'A/Comm on ' + @mode_desc + ' ' + @media_product_desc +' Screenings (' + @period_desc + ')'
		
					    if(@post_gst_rate > 0 and @gst_desc_on = 'Y' and @acomm_nett <> 0)
						    select @tran_notes = 'GST@' + convert(varchar(4),convert(numeric(3,1),round(@post_gst_rate * 100,1))) + '% ' + @period_detailed_desc
		                else
		                    select @tran_notes = @period_detailed_desc
		
						if @media_product_mode = 14
						begin
							select			@inclusion_desc = inclusion_desc
							from			inclusion
							where			inclusion_id =	@inclusion_id

							select			@tran_notes = @tran_notes + ' - '  + left(@inclusion_desc, 251 - len(@tran_notes))
						end

					    exec @errorode = p_ffin_create_transaction @acomm_tran_code,
														        @campaign_no,
																@account_id,
														        @tran_date,
														        @tran_desc,
		                                                        @tran_notes,
														        @acomm_nett,
														        @post_gst_rate,
																'Y',
														        @acomm_tran_id OUTPUT
					    if(@errorode !=0)
					    begin
						    rollback transaction
						    goto error
					    end
		
						if (@media_product_mode = 7 or @media_product_mode = 14) and (@acomm_tran_id > 0)
						begin
							insert into inclusion_tran_xref values (@inclusion_id, @acomm_tran_id )

							select @error = @@ERROR
							if @error <> 0
							begin
								rollback transaction
								goto error
							end
						end

					   /*
					    *	Allocate Agency Commision to Billing
				        */
		
					    exec @errorode = p_ffin_allocate_transaction @acomm_tran_id, @post_tran_id, @acomm_nett, @accounting_period
					    if(@errorode !=0)
					    begin
						    rollback transaction
						    goto error
					    end
				    end
		
				    if(@mode = 3 and @post_gst_total > 0)
				    begin
				
					    select @acomm_nett = (isnull(@post_gst_total,0)) * -1
					    select @tran_desc = 'Contra Credit - ' + @mode_desc + ' ' + @media_product_desc + ' Screenings (' + @period_desc + ')'
		                select @tran_notes = ''
		
					    if(@post_gst_rate > 0 and @gst_desc_on = 'Y' and @acomm_nett <> 0)
						    select @tran_notes = 'GST@' + convert(varchar(4),convert(numeric(3,1),round(@post_gst_rate * 100,1))) + '% ' + @period_detailed_desc
		                else
		                    select @tran_notes = @period_detailed_desc
		
						if @media_product_mode = 14
						begin
							select			@inclusion_desc = inclusion_desc
							from			inclusion
							where			inclusion_id =	@inclusion_id

							select			@tran_notes = @tran_notes + ' - '  + left(@inclusion_desc, 251 - len(@tran_notes))
						end

					    exec @errorode = p_ffin_create_transaction 'FCCRD',
															    @campaign_no,
																@account_id,
														 	    @tran_date,
															    @tran_desc,
		                                                        @tran_notes,
															    @acomm_nett,
															    @post_gst_rate,
																'Y',
															    @acomm_tran_id OUTPUT
		
					    if(@errorode !=0)
					    begin
						    rollback transaction
						    goto error
					    end
		            
						if (@media_product_mode = 7 or @media_product_mode = 14) and (@acomm_tran_id > 0)
						begin
							insert into inclusion_tran_xref values (@inclusion_id, @acomm_tran_id )

							select @error = @@ERROR
							if @error <> 0
							begin
								rollback transaction
								goto error
							end
						end

		               /*
					    *	Allocate Contra Credit to Contra Campaign
				        */
		
					    exec @errorode = p_ffin_allocate_transaction @acomm_tran_id, @post_tran_id, @acomm_nett, @accounting_period
					    if(@errorode !=0)
					    begin
						    rollback transaction
						    goto error
					    end
		
		            end
		
			    end
			end
			else if @media_product_mode = 7
			begin

			    if(@exempt_gst_total > 0)
			    begin
		
				   /*
				    * Setup Transaction Information
				    */
				
		            select @tran_desc = ' International ' + @trantype_desc + ' (' + @period_desc + ')'
		            select @tran_notes = 'Takeout Credit Transaction'
		
			       /*
		            * Create Billing Transaction
		            */
		
				    exec @errorode = p_ffin_create_transaction @billing_tran_code,
		                                                    @campaign_no,
															@account_id,
		                                                    @tran_date,
		                                                    @tran_desc,
		                                                    @tran_notes,
		                                                    @exempt_gst_total,
		                                                    0.0,
															'N',	
		                                                    @exempt_tran_id OUTPUT
		
				    if(@errorode !=0)
				    begin
					    rollback transaction
					    goto error
				    end
		
					if (@media_product_mode = 7 or @media_product_mode = 14) and (@exempt_tran_id > 0)
					begin
						insert into inclusion_tran_xref values (@inclusion_id, @exempt_tran_id )

						select @error = @@ERROR
						if @error <> 0
						begin
							rollback transaction
							goto error
						end
					end

			  	   /*
		            * Set Tran Id
		            */
		
				   select @tran_id = @exempt_tran_id

					/*
					 * Create Takeout
					 */

				    select @tran_desc ='International ' +  @takeout_desc + ' (' + @period_desc + ')'
		
		            select @tran_notes = 'Takeout Transaction'

					select @acomm_nett = -1 * @exempt_gst_total
		
					exec @errorode = p_ffin_create_transaction @t_billing_tran_code,
		                                            	    @campaign_no,
															@account_id,
			                                                @tran_date,
			                                                @tran_desc,
		                                                    @tran_notes,
			                                                @acomm_nett,
			                                                0.0,
															'N',
			                                                @takeout_exempt_tran_id OUTPUT

				    if(@errorode !=0)
				    begin
					    rollback transaction
					    goto error
				    end

						if (@media_product_mode = 7 or @media_product_mode = 14) and (@takeout_exempt_tran_id > 0)
						begin
							insert into inclusion_tran_xref values (@inclusion_id, @takeout_exempt_tran_id )

							select @error = @@ERROR
							if @error <> 0
							begin
								rollback transaction
								goto error
							end
						end


				end		
		
			   /*******************************
		        * Create Pre-GST Transactions *
		        *******************************/
		
			    if(@pre_gst_total > 0)
			    begin
		
				   /*
				    * Setup Transaction Information
				    */
		
				    select @tran_desc = @trantype_desc + ' (' + @period_desc + ')'
	                select @tran_notes = 'Takeout Credit Transaction'
		
			  	   /*
		            * Create Billing Transaction
		            */
		
				    exec @errorode = p_ffin_create_transaction @billing_tran_code,
		                                                    @campaign_no,
															@account_id,
			                                                @tran_date,
			                                                @tran_desc,
		                                                    @tran_notes,
			                                                @pre_gst_total,
			                                                @pre_gst_rate,
															'N',
			                                                @pre_tran_id OUTPUT
		
				    if(@errorode !=0)
				    begin
					    rollback transaction
					    goto error
				    end
		
					if (@media_product_mode = 7 or @media_product_mode = 14) and (@pre_tran_id > 0)
					begin
						insert into inclusion_tran_xref values (@inclusion_id, @pre_tran_id )

						select @error = @@ERROR
						if @error <> 0
						begin
							rollback transaction
							goto error
						end
					end

			  	   /*
		            * Set Tran Id
		            */
		
				    select @tran_id = @pre_tran_id

					/*
					 * Create Takeout
					 */

				    select @tran_desc = @takeout_desc + ' (' + @period_desc + ')'
		
		            select @tran_notes = 'Takeout Transaction'
		
					select @acomm_nett = -1 * @pre_gst_total

					exec @errorode = p_ffin_create_transaction @t_billing_tran_code,
		                                            	    @campaign_no,
															@account_id,
			                                                @tran_date,
			                                                @tran_desc,
		                                                    @tran_notes,
			                                                @acomm_nett,
			                                                @pre_gst_rate,
															'N',
			                                                @takeout_pregst_tran_id OUTPUT

				    if(@errorode !=0)
				    begin
					    rollback transaction
					    goto error
				    end

					if (@media_product_mode = 7 or @media_product_mode = 14) and (@takeout_pregst_tran_id > 0)
					begin
						insert into inclusion_tran_xref values (@inclusion_id, @takeout_pregst_tran_id )

						select @error = @@ERROR
						if @error <> 0
						begin
							rollback transaction
							goto error
						end
					end


			    end
		
		       /********************************
		        * Create Post-GST Transactions *
		        ********************************/
		
			    if(@post_gst_total >= 0)
			    begin
		
		    	   /*
				    * Setup Transaction Information
				    */
				
		            if(@pre_gst_total > 0)
				    begin
		
					    exec @errorode = p_month_name @gst_changeover, @month_name OUTPUT
					    if(@errorode !=0)
					    begin
						    rollback transaction
						    goto error
					    end
		
					    select @period_desc = 'From: ' + datename(dd, @gst_changeover) + '-' + @month_name + '-' + datename(yy, @gst_changeover)
		
				    end
		
				    select @tran_desc = @trantype_desc + ' (' + @period_desc + ')'
		
		            select @tran_notes = 'Takeout Credit Transaction'
		
		
			  	   /*
		            * Create Billing Transaction
		            */

				    exec @errorode = p_ffin_create_transaction @billing_tran_code,
		                                            	    @campaign_no,
															@account_id,
			                                                @tran_date,
			                                                @tran_desc,
		                                                    @tran_notes,
			                                                @post_gst_total,
			                                                @post_gst_rate,
															'N',
			                                                @post_tran_id OUTPUT
				    if(@errorode !=0)
				    begin
					    rollback transaction
					    goto error
				    end
		
					if (@media_product_mode = 7 or @media_product_mode = 14) and (@post_tran_id > 0)
					begin
						insert into inclusion_tran_xref values (@inclusion_id, @post_tran_id )

						select @error = @@ERROR
						if @error <> 0
						begin
							rollback transaction
							goto error
						end
					end

			       /*
		            * Set Tran Id
		            */
		
				    select @tran_id = @post_tran_id

					/*
					 * Create Takeout
					 */

				    select @tran_desc = @takeout_desc + ' (' + @period_desc + ')'
		
		            select @tran_notes = 'Takeout Transaction'
		
					select @acomm_nett = -1 * @post_gst_total

					exec @errorode = p_ffin_create_transaction @t_billing_tran_code,
		                                            	    @campaign_no,
															@account_id,
			                                                @tran_date,
			                                                @tran_desc,
		                                                    @tran_notes,
			                                                @acomm_nett,
			                                                @post_gst_rate,
															'N',
			                                                @takeout_postgst_tran_id OUTPUT

				    if(@errorode !=0)
				    begin
					    rollback transaction
					    goto error
				    end

					if (@media_product_mode = 7 or @media_product_mode = 14) and (@takeout_postgst_tran_id > 0)
					begin
						insert into inclusion_tran_xref values (@inclusion_id, @takeout_postgst_tran_id )

						select @error = @@ERROR
						if @error <> 0
						begin
							rollback transaction
							goto error
						end
					end



			    end
		
			end			

			if @media_product_mode = 1 --onscreen
			begin
				declare 	spot_csr cursor static for
				select 		spot.spot_id,
							spot.spot_status,
							spot.charge_rate,
							spot.makegood_rate,
							st.country_code,
							spot.billing_date
				from 		campaign_spot spot,
							campaign_package pack,
							complex cplx,
							state st,
							film_screening_dates fsd,
							film_campaign fc
				where 		spot.campaign_no = @campaign_no and
							spot.campaign_no = fc.campaign_no and
							(( @mode = 1 and
							spot.spot_type in ('S','B','N','R')) or
							( @mode >= 1 and
							spot.spot_type = @spot_type )) and
							spot.package_id = pack.package_id and
							pack.media_product_id = @media_product_id and
							spot.billing_period = @accounting_period and
							spot.complex_id = cplx.complex_id and
							cplx.state_code = st.state_code and
							spot.spot_status <> 'P' and
							spot.billing_date = fsd.screening_date and
							fsd.billing_period = @next_period and
							fc.business_unit_id <> 9
				order by 	st.country_code,
							spot.package_id,
							spot.spot_id
				for read only
			end
			else if @media_product_mode = 2 --cinelights
			begin
				declare 	spot_csr cursor static for
				select 		spot.spot_id,
							spot.spot_status,
							spot.charge_rate,
							spot.makegood_rate,
							st.country_code,
							spot.billing_date
				from 		cinelight_spot spot,
							cinelight_package pack,
							cinelight cl,
							complex cplx,
							state st,
							film_screening_dates fsd
				where 		spot.campaign_no = @campaign_no and
							(( @mode = 1 and
							spot.spot_type in ('S','B','N','R')) or
							( @mode >= 1 and
							spot.spot_type = @spot_type )) and
							spot.package_id = pack.package_id and
							pack.media_product_id = @media_product_id and
							spot.spot_status <> 'P' and
							spot.billing_period = @accounting_period and
							spot.cinelight_id = cl.cinelight_id and
							cl.complex_id = cplx.complex_id and
							cplx.state_code = st.state_code and
							spot.billing_date = fsd.screening_date and
							fsd.billing_period = @next_period 
				order by 	st.country_code,
							spot.package_id,
							spot.spot_id
				for read only
			end	
			else if @media_product_mode = 3 --cinemarketing
			begin
				declare 	spot_csr cursor static for
				select 		spot.spot_id,
							spot.spot_status,
							spot.charge_rate,
							0.0,
							st.country_code,
							spot.billing_date
				from 		inclusion_spot spot,
							inclusion_type inc_typ,
							inclusion inc,
							complex cplx,
							state st,
							film_screening_dates fsd
				where 		spot.campaign_no = @campaign_no and
							(( @mode = 1 and
							spot.spot_type in ('S','B','N','R')) or
							( @mode >= 1 and
							spot.spot_type = @spot_type )) and
							spot.inclusion_id = inc.inclusion_id and
							inc_typ.inclusion_type = inc.inclusion_type and
							inc_typ.media_product_id = @media_product_id and
							spot.spot_status <> 'P' and
							spot.billing_period = @accounting_period and
							spot.complex_id = cplx.complex_id and
							cplx.state_code = st.state_code and
							spot.billing_date = fsd.screening_date and
							fsd.billing_period = @next_period and
							inc.inclusion_type = 5 and
							inc.inclusion_category = 'S' and
							inc.invoice_client = 'Y'
				order by 	st.country_code,
							spot.inclusion_id,
							spot.spot_id
				for read only
			end	
			else if @media_product_mode = 4 --retail panels
			begin
				declare 	spot_csr cursor static for
				select 		spot.spot_id,
							spot.spot_status,
							spot.charge_rate,
							spot.makegood_rate,
							st.country_code,
							spot.billing_date
				from 		outpost_spot spot,
							outpost_package pack,
							outpost_panel cl,
							outpost_venue cplx,
							state st,
							outpost_screening_dates fsd
				where 		spot.campaign_no = @campaign_no and
							(( @mode = 1 and
							spot.spot_type in ('S','B','N','R')) or
							( @mode >= 1 and
							spot.spot_type = @spot_type )) and
							spot.package_id = pack.package_id and
							pack.media_product_id = @media_product_id and
							spot.spot_status <> 'P' and
							spot.billing_period = @accounting_period and
							spot.outpost_panel_id = cl.outpost_panel_id and
							cl.outpost_venue_id = cplx.outpost_venue_id and
							cplx.state_code = st.state_code and
							spot.billing_date = fsd.screening_date and
							fsd.billing_period = @next_period 
				order by 	st.country_code,
							spot.package_id,
							spot.spot_id
				for read only
			end	
			else if @media_product_mode = 5 --retail wall
			begin
				declare 	spot_csr cursor static for
				select 		spot.spot_id,
							spot.spot_status,
							spot.charge_rate,
							0.0,
							st.country_code,
							spot.billing_date
				from 		inclusion_spot spot,
							inclusion_type inc_typ,
							inclusion inc,
							outpost_venue cplx,
							state st,
							outpost_screening_dates fsd
				where 		spot.campaign_no = @campaign_no and
							(( @mode = 1 and
							spot.spot_type in ('S','B','N','R')) or
							( @mode >= 1 and
							spot.spot_type = @spot_type )) and
							spot.inclusion_id = inc.inclusion_id and
							inc_typ.inclusion_type = inc.inclusion_type and
							inc_typ.media_product_id = @media_product_id and
							spot.spot_status <> 'P' and
							spot.billing_period = @accounting_period and
							spot.outpost_venue_id = cplx.outpost_venue_id and
							inc.commission = @working_acomm and
							cplx.state_code = st.state_code and
							spot.op_billing_date = fsd.screening_date and
							fsd.billing_period = @next_period and
							inc.inclusion_type = 18 and
							inc.inclusion_category = 'S' and
							inc.invoice_client = 'Y'
				order by 	st.country_code,
							spot.inclusion_id,
							spot.spot_id
				for read only
			end	
			else if @media_product_mode = 6 --media proxy
			begin
				declare 	spot_csr cursor static for
				select 		spot.spot_id,
							spot.spot_status,
							spot.charge_rate,
							0.0,
							st.country_code,
							spot.screening_date
				from 		inclusion_spot spot,
							inclusion_type inc_typ,
							inclusion inc,
							complex cplx,
							state st,
							film_screening_dates fsd
				where 		spot.campaign_no = @campaign_no and
							spot.inclusion_id = inc.inclusion_id and
							inc_typ.inclusion_type = inc.inclusion_type and
							inc_typ.media_product_id = @media_product_id and
							spot.billing_period = @accounting_period and
							spot.complex_id = cplx.complex_id and
							cplx.state_code = st.state_code and
							spot.spot_status <> 'P' and
							spot.screening_date = fsd.screening_date and
							fsd.billing_period = @next_period and
							@mode = 1 and
							inc.inclusion_type in (11,14,12,13) and
							inc.invoice_client = 'Y'
				order by 	st.country_code,
							spot.inclusion_id,
							spot.spot_id
				for read only
			end	
			else if @media_product_mode = 7 --takeout
			begin
				declare 	spot_csr cursor static for
				select 		spot.spot_id,
							spot.spot_status,
							spot.charge_rate,
							0.0,
							br.country_code,
							spot.screening_date
				from 		inclusion_spot spot,
							inclusion inc,
							film_campaign fc,
							branch br
				where 		spot.campaign_no = @campaign_no and
							spot.inclusion_id = @inclusion_id and
							spot.inclusion_id = inc.inclusion_id and
							inc.inclusion_type = @media_product_id and
							inc.inclusion_category = @media_product_desc and
							spot.billing_period = @accounting_period and
							fc.campaign_no = spot.campaign_no and
							spot.spot_status <> 'P' and
							fc.campaign_no = inc.campaign_no and
							fc.branch_code = br.branch_code and
							@accounting_period = @next_period and
							@mode = 1 
				order by 	br.country_code,
							spot.inclusion_id,
							spot.spot_id
				for read only
			end	
			else if @media_product_mode = 8 --TAP
			begin
				declare 	spot_csr cursor static for
				select 		spot.spot_id,
							spot.spot_status,
							spot.charge_rate,
							0.0,
							b.country_code,
							spot.billing_date
				from 		inclusion_spot spot,
							inclusion_type inc_typ,
							inclusion inc,
							branch b,
							film_campaign fc
				where 		fc.campaign_no = @campaign_no and
							spot.campaign_no = @campaign_no and
							spot.campaign_no = fc.campaign_no and 
							spot.inclusion_id = inc.inclusion_id and
							inc_typ.inclusion_type = inc.inclusion_type and
							spot.spot_status <> 'P' and
							spot.billing_period = @accounting_period and
							fc.branch_code = b.branch_code and
							spot.billing_period = @next_period and
							inc.inclusion_type = 24 and
							inc.inclusion_category = 'S' and
							inc.invoice_client = 'Y'
				order by 	b.country_code,
							spot.inclusion_id,
							spot.spot_id
				for			read only
			end	
			else if @media_product_mode = 9 --Sports
			begin
				declare 	spot_csr cursor static for
				select		spot.spot_id,
							spot.spot_status,
							spot.charge_rate,
							0.0,
							b.country_code,
							spot.billing_date
				from 		inclusion_spot spot,
							inclusion_type inc_typ,
							inclusion inc,
							branch b,
							film_campaign fc
				where 		fc.campaign_no = @campaign_no and
							spot.campaign_no = @campaign_no and
							spot.campaign_no = fc.campaign_no and 
							spot.inclusion_id = inc.inclusion_id and
							inc_typ.inclusion_type = inc.inclusion_type and
							spot.spot_status <> 'P' and
							spot.billing_period = @accounting_period and
							fc.branch_code = b.branch_code and
							spot.billing_period = @next_period and
							inc.inclusion_type = 26 and
							inc.inclusion_category = 'S' and
							inc.inclusion_format = 'R' and
							inc.invoice_client = 'Y'
				order by 	b.country_code,
							spot.inclusion_id,
							spot.spot_id
				for read only
			end	
			if @media_product_mode = 10 --onscreen
			begin
				declare 	spot_csr cursor static for
				select 		spot.spot_id,
							spot.spot_status,
							spot.charge_rate,
							spot.makegood_rate,
							st.country_code,
							spot.billing_date
				from 		campaign_spot spot,
							campaign_package pack,
							complex cplx,
							state st,
							film_screening_dates fsd,
							film_campaign fc
				where 		spot.campaign_no = @campaign_no and
							spot.campaign_no = fc.campaign_no and
							(( @mode = 1 and
							spot.spot_type in ('S','B','N','R')) or
							( @mode >= 1 and
							spot.spot_type = @spot_type )) and
							spot.package_id = pack.package_id and
							pack.media_product_id = @media_product_id and
							spot.billing_period = @accounting_period and
							spot.complex_id = cplx.complex_id and
							cplx.state_code = st.state_code and
							spot.spot_status <> 'P' and
							spot.billing_date = fsd.screening_date and
							fsd.billing_period = @next_period and
							fc.business_unit_id = 9
				order by 	st.country_code,
							spot.package_id,
							spot.spot_id
				for read only
			end
			else if @media_product_mode = 11 --FF Audience
			begin
				declare 	spot_csr cursor static for
				select 		spot.spot_id,
							spot.spot_status,
							spot.charge_rate,
							0.0,
							b.country_code,
							spot.billing_date
				from 		inclusion_spot spot,
							inclusion_type inc_typ,
							inclusion inc,
							branch b,
							film_campaign fc
				where 		fc.campaign_no = @campaign_no and
							spot.campaign_no = @campaign_no and
							spot.campaign_no = fc.campaign_no and 
							spot.inclusion_id = inc.inclusion_id and
							inc_typ.inclusion_type = inc.inclusion_type and
							spot.spot_status <> 'P' and
							spot.billing_period = @accounting_period and
							fc.branch_code = b.branch_code and
							spot.billing_period = @next_period and
							inc.inclusion_type in (29) and
							inc.inclusion_category = 'S' and
							inc.invoice_client = 'Y'
				order by 	b.country_code,
							spot.inclusion_id,
							spot.spot_id
				for			read only
			end	
			else if @media_product_mode = 12 --Roadblock
			begin
				declare 	spot_csr cursor static for
				select 		spot.spot_id,
							spot.spot_status,
							spot.charge_rate,
							0.0,
							b.country_code,
							spot.billing_date
				from 		inclusion_spot spot,
							inclusion_type inc_typ,
							inclusion inc,
							branch b,
							film_campaign fc
				where 		fc.campaign_no = @campaign_no and
							spot.campaign_no = @campaign_no and
							spot.campaign_no = fc.campaign_no and 
							spot.inclusion_id = inc.inclusion_id and
							inc_typ.inclusion_type = inc.inclusion_type and
							spot.spot_status <> 'P' and
							spot.billing_period = @accounting_period and
							fc.branch_code = b.branch_code and
							spot.billing_period = @next_period and
							inc.inclusion_type in (30,31) and
							inc.inclusion_category = 'S' and
							inc.invoice_client = 'Y'
				order by 	b.country_code,
							spot.inclusion_id,
							spot.spot_id
				for			read only
			end	
			else if @media_product_mode = 13 --MM Audience
			begin
				declare 	spot_csr cursor static for
				select 		spot.spot_id,
							spot.spot_status,
							spot.charge_rate,
							0.0,
							b.country_code,
							spot.billing_date
				from 		inclusion_spot spot,
							inclusion_type inc_typ,
							inclusion inc,
							branch b,
							film_campaign fc
				where 		fc.campaign_no = @campaign_no and
							spot.campaign_no = @campaign_no and
							spot.campaign_no = fc.campaign_no and 
							spot.inclusion_id = inc.inclusion_id and
							inc_typ.inclusion_type = inc.inclusion_type and
							spot.spot_status <> 'P' and
							spot.billing_period = @accounting_period and
							fc.branch_code = b.branch_code and
							spot.billing_period = @next_period and
							inc.inclusion_type in (32) and
							inc.inclusion_category = 'S' and
							inc.invoice_client = 'Y'
				order by 	b.country_code,
							spot.inclusion_id,
							spot.spot_id
				for			read only
			end	
			else if @media_product_mode = 14 --VM Digital
			begin
				declare 	spot_csr cursor static for
				select 		spot.spot_id,
							spot.spot_status,
							spot.charge_rate,
							0.0,
							b.country_code,
							spot.billing_date
				from 		inclusion_spot spot,
							inclusion_type inc_typ,
							inclusion inc,
							branch b,
							film_campaign fc
				where 		fc.campaign_no = @campaign_no and
							spot.campaign_no = @campaign_no and
							spot.campaign_no = fc.campaign_no and 
							spot.inclusion_id = @inclusion_id and
							spot.inclusion_id = inc.inclusion_id and
							inc_typ.inclusion_type = inc.inclusion_type and
							spot.spot_status <> 'P' and
							spot.billing_period = @accounting_period and
							fc.branch_code = b.branch_code and
							spot.billing_period = @next_period and
							inc.inclusion_type between 34 and 65 and
							inc.inclusion_category = 'H' and
							inc.invoice_client = 'Y'
				order by 	b.country_code,
							spot.inclusion_id,
							spot.spot_id
				for			read only
			end	
		
	        open spot_csr
		    fetch spot_csr into @spot_id, @status, @rate, @makegood_rate, @country_code, @billing_date
		    while(@@fetch_status = 0)
		    begin

				if @media_product_mode = 1 or @media_product_mode = 10
				begin

					/*
					 * Insert Spot Tran Xref 
					 */
					
					if(@exempt_tran_id > 0)
					begin
					
						insert into film_spot_xref (
									spot_id,
									tran_id ) values (
									@spot_id,
									@exempt_tran_id )
													
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end
					
					if(@pre_tran_id > 0)
					begin
					
						insert into film_spot_xref (
									spot_id,
									tran_id ) values (
									@spot_id,
									@pre_tran_id )
					
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end
					
					if(@post_tran_id > 0)
					begin
					
					insert into film_spot_xref (
								spot_id,
								tran_id ) values (
								@spot_id,
								@post_tran_id )
					
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end
					
					/*
					 * Update Spot Tran Id
					 */
					
					update campaign_spot set tran_id = @tran_id where spot_id = @spot_id
					
					select @error = @@error
					if (@error !=0)
					begin
						rollback transaction
						goto error
					end	
				end
				else if @media_product_mode = 2
				begin

					/*
					 * Insert Cinelight Tran Xref 
					 */
					
					if(@exempt_tran_id > 0)
					begin
					
						insert into cinelight_spot_xref (
									spot_id,
									tran_id ) values (
									@spot_id,
									@exempt_tran_id )
													
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end
					
					if(@pre_tran_id > 0)
					begin
					
						insert into cinelight_spot_xref (
									spot_id,
									tran_id ) values (
									@spot_id,
									@pre_tran_id )
					
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end
					
					if(@post_tran_id > 0)
					begin
					
					insert into cinelight_spot_xref (
								spot_id,
								tran_id ) values (
								@spot_id,
								@post_tran_id )
					
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end
					
					/*
					 * Update Spot Tran Id
					 */
					
					update cinelight_spot set tran_id = @tran_id where spot_id = @spot_id
					
					select @error = @@error
					if (@error !=0)
					begin
						rollback transaction
						goto error
					end	
				end
				else if @media_product_mode = 4
				begin

					/*
					 * Insert Retail Tran Xref 
					 */
					
					if(@exempt_tran_id > 0)
					begin
					
						insert into outpost_spot_xref (
									spot_id,
									tran_id ) values (
									@spot_id,
									@exempt_tran_id )
													
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end
					
					if(@pre_tran_id > 0)
					begin
					
						insert into outpost_spot_xref (
									spot_id,
									tran_id ) values (
									@spot_id,
									@pre_tran_id )
					
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end
					
					if(@post_tran_id > 0)
					begin
					
					insert into outpost_spot_xref (
								spot_id,
								tran_id ) values (
								@spot_id,
								@post_tran_id )
					
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end
					
					/*
					 * Update Spot Tran Id
					 */
					
					update outpost_spot set tran_id = @tran_id where spot_id = @spot_id
					
					select @error = @@error
					if (@error !=0)
					begin
						rollback transaction
						goto error
					end	
				end
				else if (@media_product_mode = 3 or @media_product_mode > 4) and @media_product_mode <> 10
				begin

					/*
					 * Insert Inclusion Tran Xref 
					 */
					
					if(@exempt_tran_id > 0)
					begin
					
						insert into inclusion_spot_xref (
									spot_id,
									tran_id ) values (
									@spot_id,
									@exempt_tran_id )
													
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end
					
					if(@pre_tran_id > 0)
					begin
					
						insert into inclusion_spot_xref (
									spot_id,
									tran_id ) values (
									@spot_id,
									@pre_tran_id )
					
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end
					
					if(@post_tran_id > 0)
					begin
					
					insert into inclusion_spot_xref (
								spot_id,
								tran_id ) values (
								@spot_id,
								@post_tran_id )
					
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end
					
					if(@takeout_exempt_tran_id > 0)
					begin
					
					insert into inclusion_spot_xref (
								spot_id,
								tran_id ) values (
								@spot_id,
								@takeout_exempt_tran_id )
					
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end

					if(@takeout_pregst_tran_id > 0)
					begin
					
					insert into inclusion_spot_xref (
								spot_id,
								tran_id ) values (
								@spot_id,
								@takeout_pregst_tran_id )
					
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end

					if(@takeout_postgst_tran_id > 0)
					begin
					
					insert into inclusion_spot_xref (
								spot_id,
								tran_id ) values (
								@spot_id,
								@takeout_postgst_tran_id )
					
						select @error = @@error
						if (@error !=0)
						begin
							rollback transaction
							goto error
						end	
					end

					/*
					 * Update Spot Tran Id
					 */
					
					update inclusion_spot set tran_id = @tran_id where spot_id = @spot_id
					
					select @error = @@error
					if (@error !=0)
					begin
						rollback transaction
						goto error
					end	
				end
		
		       /*
	            * Fetch Next Spot
	            */
	
	    	   fetch spot_csr into @spot_id, @status, @rate, @makegood_rate, @country_code, @billing_date
	
		    end
		    close spot_csr
			deallocate spot_csr



	       /*
	        * Generate Spot Liability and Calculate Weighted Spot Values
	        */
	
	        execute @errorode = p_spot_liability_generation @campaign_no, @mode, @tran_id, @media_product_mode
	        
	        if(@errorode !=0)
	        begin
		        rollback transaction
		        goto error
	        end
	       
	       /*
	        * Fetch next Billing Period
	        */
	
	        fetch bill_csr into @next_period, @media_product_id, @media_product_desc, @account_id, @working_acomm, @inclusion_id
	
	    end
	    close bill_csr
		deallocate bill_csr
	    select @bill_csr_open = 0
	    
	    select @mode = @mode + 1
	    
	end
	
	select @media_product_mode = @media_product_mode + 1

end

/*
 * Allocate all takeout to relevant transaction groups
 */

exec @errorode = p_ffin_allocate_takeout_transaction @campaign_no
if(@errorode !=0)
begin
	rollback transaction
	goto error
end

/*
 * Bill Film Inclusions
 */

exec @errorode = p_eom_billing_inclusions @campaign_no, @accounting_period
if(@errorode !=0)
begin
	rollback transaction
	goto error
end

/*
 * Bill Film Inclusions
 */

exec @errorode = p_eom_billing_inclusions_invoicing_plans @campaign_no, @accounting_period
if(@errorode !=0)
begin
	rollback transaction
	goto error
end

/*
 * Allocate all prepayments to all transactions
 */

exec @errorode = p_ffin_payment_allocation @campaign_no
if(@errorode !=0)
begin
	rollback transaction
	goto error
end


/*
 * Commit and Return
 */

commit transaction
return 0

/*
 * Error Handler
 */

error:
	 if (@bill_csr_open = 1)
     begin
		 close bill_csr
		 deallocate bill_csr
	 end
	 if (@spot_csr_open = 1)
     begin
		 close spot_csr
		 deallocate spot_csr
	 end
	 raiserror ('Error: Failed to Generate Billings for Campaign %n',16,1, @campaign_no)
	 return -100
GO
