/****** Object:  StoredProcedure [dbo].[p_proj_revision_generate]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_proj_revision_generate]
GO
/****** Object:  StoredProcedure [dbo].[p_proj_revision_generate]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

Create PROC [dbo].[p_proj_revision_generate]		@campaign_no		int, 
													@revision_no 		int, 
													@user_id 			int

as

/*
 * Declare Variables
 */

declare		@error_num           	int,
			@error					int,
			@revision_category		int,
			@revision_id			int,
			@default_comment		varchar (255),
			@confirm_date			datetime,
			@revision_type 			smallint,
			@figure_type			char(1)

set nocount on

select			@default_comment = 'System Generated Revision'

if ( @user_id > 1 )
begin 
	select			@revision_category = 2
	select 			@revision_type = 3
end

if ( @user_id = 1 )
begin 
	select 			@revision_category = 1
	select 			@revision_type = 4
end

if ( @revision_no != 0 )
begin
	select 			@revision_id =  max ( revision_id ) 
	from 			campaign_revision
	where 			campaign_revision.campaign_no = @campaign_no
	and 			campaign_revision.revision_no = @revision_no
end

if ( @revision_no = 0 )
begin
	select 			@revision_no = isnull ( max ( revision_no ) + 1  , 1 )
	from 			campaign_revision
	where 			campaign_revision.campaign_no = @campaign_no
end

if ( @revision_no = 1 )
begin

	select 			@confirm_date = IsNull ( max ( event_date ) , GetDate() )
	from 			film_campaign_event 
	where 			film_campaign_event.event_type = 'C'
	and 			film_campaign_event.campaign_no = @campaign_no

	select 	@revision_type = 1
	
end

if ( @revision_no != 1 )
begin
	select 			@confirm_date = GetDate()
end

if @revision_type = 1
	select			@figure_type = 'C' --Confirmation figures
else
	select			@figure_type = 'N' --Revision figures

/* Create temporary tables for latest values */

CREATE TABLE #work_revision 
(	
	flag 							char(3)				NOT NULL,
	campaign_no 					int 				NOT NULL, 
	confirmation_date 				datetime			NULL, 
	revision_transaction_type 		smallint 			NOT NULL,
	revenue_period 					datetime 			NOT NULL,
	billing_date 					datetime 			NULL,
	value 							money 				NOT NULL,
	cost 							money 				NOT NULL,
	units 							int 				NOT NULL,
	makegood 						money 				NOT NULL,
	revenue 						money 				NOT NULL
)

CREATE TABLE #delta_revision 
(
	revision_no 					int 				NULL,
	campaign_no 					int 				NOT NULL, 
	revision_transaction_type 		smallint 			NOT NULL,
	revenue_period 					datetime 			NOT NULL,
	billing_date 					datetime			NULL,
	value 							money 				NOT NULL,
	cost 							money 				NOT NULL,
	units 							int 				NOT NULL,
	makegood 						money 				NOT NULL,
	revenue 						money 				NOT NULL
)

CREATE TABLE #outpost_work_revision 
(	
	flag 							char(3)				NOT NULL,
	campaign_no 					int 				NOT NULL, 
	confirmation_date 				datetime			NULL, 
	revision_transaction_type 		smallint			NOT NULL,
	revenue_period 					datetime			NOT NULL,
	billing_date 					datetime			NULL,
	value 							money 				NOT NULL,
	cost 							money 				NOT NULL,
	units 							int 				NOT NULL,
	makegood 						money 				NOT NULL,
	revenue 						money 				NOT NULL
)

CREATE TABLE #outpost_delta_revision 
(
	revision_no 					int 				NULL,
	campaign_no 					int 				NOT NULL, 
	revision_transaction_type 		smallint 			NOT NULL,
	revenue_period 					datetime 			NOT NULL,
	billing_date 					datetime 			NULL,
	value 							money 				NOT NULL,
	cost 							money 				NOT NULL,
	units 							int 				NOT NULL,
	makegood 						money 				NOT NULL,
	revenue 						money 				NOT NULL
)

/*
 * Begin Transaction
 */

begin transaction


/* Inserts to temporary table */

/* 	
		1. FILM SPOTS 
		4. DMG SPOTS  
*/

insert 			#work_revision
select 			'NEW',
				campaign_no = campaign_spot.campaign_no,   
				confirmation_date = @confirm_date,
				revision_transaction_type = campaign_package.media_product_id,
				revenue_period = ( 	select 	max(benchmark_end) 
														from 			film_screening_date_xref 
														where 		film_screening_date_xref.screening_date = campaign_spot.billing_date ) ,
				billing_date = campaign_spot.billing_date,   
				value = sum ( campaign_spot.rate ),   
				cost = sum ( campaign_spot.charge_rate ),   
				units = count(*) ,
				makegood = SUM ( campaign_spot.makegood_rate),   
				revenue = SUM ( campaign_spot.charge_rate + campaign_spot.makegood_rate )
from 			campaign_spot,
				campaign_package 
where 			campaign_package.package_id = campaign_spot.package_id
and				campaign_spot.campaign_no = @campaign_no 
and 			campaign_spot.spot_status != 'P'
GROUP BY 		campaign_spot.campaign_no,
				campaign_spot.billing_date,
				campaign_package.media_product_id
HAVING  		sum(campaign_spot.rate) <> 0 
OR				sum(campaign_spot.charge_rate) <> 0     
OR				sum(campaign_spot.makegood_rate) <> 0 

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film & dmg spots', 16, 1)
	rollback transaction
	return -1
end


/* set revision type from 2 to 4 - dmg */
UPDATE 		#work_revision 
set 					revision_transaction_type = 4 
where 			revision_transaction_type = 2

select @error = @@error
if @error <> 0
begin
	raiserror ('Error updating dmg spots', 16, 1)
	rollback transaction
	return -1
end

/* 2. Film TakeOut */

insert 			#work_revision
select 			'NEW',
							campaign_no = inclusion_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 2, /* Film Takeout */
							inclusion_spot.revenue_period,
							billing_date = (select 		max(screening_date) 
														from 			film_screening_date_xref fdx
														where 	fdx.benchmark_end = inclusion_spot.revenue_period),   
							value = 0,   
							cost = SUM ( inclusion_spot.takeout_rate * - 1),  
							units = count(*),
							makegood = 0,   
							revenue = SUM ( inclusion_spot.takeout_rate * - 1)
from 				inclusion_spot  , inclusion 
where			inclusion.campaign_no = @campaign_no
and  					inclusion.inclusion_id = inclusion_spot.inclusion_id
and  					inclusion.include_revenue = 'Y' -- GB
and 					inclusion_spot.spot_status != 'P'
and 					inclusion.inclusion_category = 'F'
GROUP BY 	inclusion_spot.campaign_no,
							inclusion_spot.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film takeout spots', 16, 1)
	rollback transaction
	return -1
end

/* 3. FILM Billing Credits & Bad Debts */

insert 			#work_revision
select 			'NEW',
							campaign_no = campaign_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 3, /* Billing Credits And Bad Debts */
							revenue_period = spot_liability.creation_period  ,
							billing_date = (select 		max(screening_date) 
														from 			film_screening_date_xref fdx
														where 	fdx.benchmark_end = spot_liability.creation_period),   
							value = sum ( spot_liability.spot_amount ),   
							cost = sum ( spot_liability.spot_amount ),   
							units = 1 ,
							makegood = 0,   
							revenue = SUM ( spot_liability.spot_amount  )
from 				campaign_spot,
							spot_liability 
where			campaign_spot.campaign_no = @campaign_no
and 					campaign_spot.spot_status != 'P'
and 					spot_liability.liability_type = 7 
and 					campaign_spot.spot_id  = spot_liability.spot_id
GROUP BY		campaign_spot.campaign_no,
							spot_liability.creation_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 5. DMG TakeOut */

insert 			#work_revision
select 			'NEW',
							campaign_no = inclusion_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 5, /* DMG Takeout */
							inclusion_spot.revenue_period ,
							billing_date = (select 		max(screening_date) 
														from 			film_screening_date_xref fdx
														where 	fdx.benchmark_end = inclusion_spot.revenue_period),   
							value = 0,   
							cost = SUM ( inclusion_spot.takeout_rate * - 1),   
							units = count(*),
        					makegood = 0,   
							revenue = SUM ( inclusion_spot.takeout_rate * - 1)
from 				inclusion_spot,
							inclusion 
where			inclusion.campaign_no = @campaign_no
and  					inclusion.inclusion_id = inclusion_spot.inclusion_id
and  					inclusion.include_revenue = 'Y' -- GB
and					inclusion_spot.spot_status != 'P'
and 					inclusion.inclusion_category = 'D'
GROUP BY 	inclusion_spot.campaign_no,
							inclusion_spot.revenue_period,
							inclusion_spot.screening_date 

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg takeout', 16, 1)
	rollback transaction
	return -1
end

/* 6. DMG Billing Credits */

insert 			#work_revision
select 			'NEW',
							campaign_no = campaign_spot.campaign_no,   
							confirmation_date = spot_liability.creation_period,
							revision_transaction_type = 6, /* DMG Billing Credits */
							revenue_period = spot_liability.creation_period  ,
							billing_date =( select		max ( screening_date ) 
														from 			film_screening_date_xref fdx
														where 	fdx.benchmark_end = spot_liability.creation_period),  
							value = sum ( spot_liability.spot_amount ),   
							cost = sum ( spot_liability.spot_amount ),   
							units = 1 ,
							makegood = 0,   
							revenue = SUM ( spot_liability.spot_amount  )
from 				campaign_spot  , spot_liability 
where			campaign_spot.campaign_no = @campaign_no
and 					campaign_spot.spot_status != 'P'
and 					spot_liability.liability_type = 8 
and 					campaign_spot.spot_id  = spot_liability.spot_id
GROUP BY 	campaign_spot.campaign_no,
							spot_liability.creation_period;

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 7. Cinelight Spots */

insert 			#work_revision
select 			'NEW',
							campaign_no = cinelight_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 7,
							revenue_period = (	select 	max(benchmark_end) 
																	from 			film_screening_date_xref 
																	where	 	film_screening_date_xref.screening_date = cinelight_spot.billing_date ) ,
							billing_date = cinelight_spot.billing_date,   
							value = sum ( cinelight_spot.rate ),   
							cost = sum ( cinelight_spot.charge_rate ),   
							units = count(*) ,
							makegood = SUM ( cinelight_spot.makegood_rate),   
							revenue = SUM ( cinelight_spot.charge_rate + cinelight_spot.makegood_rate )
from 				cinelight_spot  
where 			cinelight_spot.campaign_no = @campaign_no
and 					cinelight_spot.spot_status != 'P'
GROUP BY 	cinelight_spot.campaign_no,
							cinelight_spot.billing_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinelight spots', 16, 1)
	rollback transaction
	return -1
end

/* 8. Cinelight TakeOut */
	
insert	 		#work_revision
select			'NEW',
							campaign_no = inclusion_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 8, /* Cinelight Takeout */
							inclusion_spot.revenue_period,
							billing_date = (select 	max(screening_date) 
														from 	film_screening_date_xref fdx
														where 	fdx.benchmark_end = inclusion_spot.revenue_period),
							value = 0,   
							cost = SUM ( inclusion_spot.takeout_rate * - 1),   
							units = count(*),
							makegood = 0,   
							revenue = SUM ( inclusion_spot.takeout_rate * - 1)
from 				inclusion_spot,
							inclusion 
where			inclusion.campaign_no = @campaign_no
and  					inclusion.inclusion_id = inclusion_spot.inclusion_id
and  					inclusion.include_revenue = 'Y' -- GB
and					inclusion_spot.spot_status != 'P'
and 					inclusion.inclusion_category = 'C'
GROUP BY 	inclusion_spot.campaign_no,
							inclusion_spot.revenue_period,
							inclusion_spot.screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinelight takeouts', 16, 1)
	rollback transaction
	return -1
end

/* 9. Cinelight Billing Credits */

insert 			#work_revision
select 			'NEW',
							campaign_no = cinelight_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 9, /* Cinelight Billing Credits  */
							revenue_period = cinelight_spot_liability.creation_period  ,
							billing_date =( select 		max ( screening_date ) 
														from 			film_screening_date_xref fdx
														where 	fdx.benchmark_end = cinelight_spot_liability.creation_period),   
							value = sum ( cinelight_spot_liability.spot_amount ),   
							cost = sum ( cinelight_spot_liability.spot_amount ),   
							units = 1 ,
							makegood = 0,   
							revenue = SUM ( cinelight_spot_liability.spot_amount  )
from 				cinelight_spot,
							cinelight_spot_liability
where			cinelight_spot.campaign_no = @campaign_no
and 					cinelight_spot.spot_status != 'P'
and 					cinelight_spot_liability.liability_type = 13
and 					cinelight_spot.spot_id  = cinelight_spot_liability.spot_id
GROUP BY 	cinelight_spot.campaign_no,
							cinelight_spot.billing_date,
							cinelight_spot_liability.creation_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinelight billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 10. Cinemarketing SPOTS */

insert 			#work_revision
select 			'NEW',
							campaign_no = inclusion_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 10, /* Cinemarketing SPOTS  */
							revenue_period = (	select 	max(benchmark_end) 
																	from 			film_screening_date_xref 
																	where 		film_screening_date_xref.screening_date = inclusion_spot.billing_date ),
							billing_date = inclusion_spot.billing_date,   
							value = sum( rate ),   
							cost = sum ( charge_rate ),   
							units = count(*),
							makegood = 0,   
							revenue = SUM ( inclusion_spot.charge_rate )
from 				inclusion_spot,
							inclusion 
where			inclusion.campaign_no = @campaign_no
and  					inclusion.inclusion_id = inclusion_spot.inclusion_id
and					inclusion_spot.spot_status != 'P'
and 					inclusion.inclusion_type = 5
GROUP BY 	inclusion_spot.campaign_no,
							inclusion_spot.billing_date;

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinemarketing spots', 16, 1)
	rollback transaction
	return -1
end

/* 11. Cinemarketing Billing Credits */

insert 			#work_revision
select 			'NEW',
							campaign_no = inclusion_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 11, /* Cinemarketing Billing Credits  */
							revenue_period = inclusion_spot_liability.creation_period ,
							billing_date = (	select 		max ( screening_date ) 
															from 			film_screening_date_xref fdx
															where 	fdx.benchmark_end = inclusion_spot_liability.creation_period ),   
							value = sum ( inclusion_spot_liability.spot_amount ),   
							cost = sum ( inclusion_spot_liability.spot_amount ),   
							units = 1 ,
							makegood = 0,   
							revenue = SUM ( inclusion_spot_liability.spot_amount  )
from 				inclusion_spot,
							inclusion_spot_liability
where			inclusion_spot.campaign_no = @campaign_no
and 					inclusion_spot.spot_status != 'P'
and 					inclusion_spot_liability.liability_type = 16
and 					inclusion_spot.spot_id  = inclusion_spot_liability.spot_id
GROUP BY 	inclusion_spot.campaign_no,
							inclusion_spot_liability.creation_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinemarketing billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 12. Misc */

insert 			#work_revision
select			'NEW',
				campaign_no = inclusion.campaign_no,   
				confirmation_date = @confirm_date,
				revision_transaction_type = 12, /* Misc */
				inclusion.revenue_period,
				billing_date = (	select 		max ( screening_date ) 
												from 			film_screening_date_xref fdx
												where 	fdx.benchmark_end = inclusion.revenue_period ),   
				value = SUM ( inclusion.inclusion_qty * inclusion.inclusion_value ),
				cost = isnull(SUM ((inclusion.inclusion_qty * inclusion.inclusion_charge) - inclusion.vm_cost_amount) , 0),  
				units = 0,
				makegood = 0,   
				revenue = isnull(SUM ((inclusion.inclusion_qty * inclusion.inclusion_charge) - inclusion.vm_cost_amount) , 0)
from 			inclusion
inner join		film_campaign on inclusion.campaign_no = film_campaign.campaign_no
where			inclusion.campaign_no = @campaign_no
and 			inclusion.inclusion_category = 'S'
and 			inclusion.inclusion_format = 'S'
and  			inclusion.include_revenue = 'Y'
and				business_unit_id <>  11 
GROUP BY 		inclusion.campaign_no,
				inclusion.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new miscellanous', 16, 1)
	rollback transaction
	return -1
end

/* 12. VM Digital Misc */

insert 			#work_revision
select			'NEW',
				campaign_no = inclusion.campaign_no,   
				confirmation_date = @confirm_date,
				revision_transaction_type,
				inclusion.revenue_period,
				billing_date = (	select 		max ( screening_date ) 
												from 			film_screening_date_xref fdx
												where 	fdx.benchmark_end = inclusion.revenue_period ),   
				value = SUM ( inclusion.inclusion_qty * inclusion.inclusion_value ),
				cost = isnull(SUM ((inclusion.inclusion_qty * inclusion.inclusion_charge) - inclusion.vm_cost_amount) , 0),  
				units = 0,
				makegood = 0,   
				revenue = isnull(SUM ((inclusion.inclusion_qty * inclusion.inclusion_charge) - inclusion.vm_cost_amount) , 0)
from 			inclusion
inner join		inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
inner join		revision_transaction_type on inclusion_type.media_product_id = revision_transaction_type.media_product_id
and				revision_transaction_type.statrev_transaction_type_group_id = 1
inner join		film_campaign on inclusion.campaign_no = film_campaign.campaign_no
where			inclusion.campaign_no = @campaign_no
and 			inclusion.inclusion_category = 'S'
and 			inclusion.inclusion_format = 'S'
and  			inclusion.include_revenue = 'Y'
and				business_unit_id = 11 
GROUP BY 		inclusion.campaign_no,
				revision_transaction_type,
				inclusion.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new miscellanous', 16, 1)
	rollback transaction
	return -1
end

/* 13. Film Revenue Proxy SPOTS */

insert 			#work_revision
select 			'NEW',
							campaign_no = inclusion_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 13, /* Film Revenue Proxy SPOTS  */
							revenue_period = (	select 	max(benchmark_end) 
																	from 			film_screening_date_xref 
																	where 		film_screening_date_xref.screening_date = inclusion_spot.billing_date ),
							billing_date = inclusion_spot.billing_date,   
							value = sum( rate ),   
							cost = sum ( charge_rate ),   
							units = count(*),
							makegood = 0,   
							revenue = SUM ( inclusion_spot.charge_rate )
from 				inclusion_spot,
							inclusion 
where			inclusion.campaign_no = @campaign_no
and  					inclusion_spot.inclusion_id = inclusion.inclusion_id
and  					inclusion_spot.spot_status != 'P'
and 					inclusion.inclusion_type = 11
GROUP BY 	inclusion_spot.campaign_no,
							inclusion_spot.billing_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film revenue proxy', 16, 1)
	rollback transaction
	return -1
end

/* 16. Cinemarketing TakeOut */

insert 			#work_revision
select 			'NEW',
							campaign_no = inclusion_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 16, /* Cinemarketing Takeout */
							inclusion_spot.revenue_period,
							billing_date = (select 		max(screening_date) 
														from 			film_screening_date_xref fdx
														where 	fdx.benchmark_end = inclusion_spot.revenue_period),
							value = 0,   
							cost = SUM ( inclusion_spot.takeout_rate * - 1), 
							units = count(*),
							makegood = 0,   
							revenue = SUM ( inclusion_spot.takeout_rate * - 1)
from 				inclusion_spot,
							inclusion 
where			inclusion.campaign_no = @campaign_no
and					inclusion_spot.spot_status != 'P'
and 					inclusion.inclusion_category = 'I'
and  					inclusion.include_revenue = 'Y' -- GB
and  					inclusion_spot.inclusion_id = inclusion.inclusion_id
GROUP BY 	inclusion_spot.campaign_no,
							inclusion_spot.revenue_period,
							inclusion_spot.billing_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinemarketing takeout', 16, 1)
	rollback transaction
	return -1
end

/* 17. DMG Revenue Proxy SPOTS */

insert 			#work_revision
select 			'NEW',
							campaign_no = inclusion_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 17, /* DMG Revenue Proxy SPOTS   */
							revenue_period = (	select 	max(benchmark_end) 
																	from 			film_screening_date_xref 
																	where 		film_screening_date_xref.screening_date = inclusion_spot.billing_date ),
							billing_date = inclusion_spot.billing_date,   
							value = sum( rate ),   
							cost = sum ( charge_rate ),   
							units = count(*),
							makegood = 0,   
							revenue = SUM ( inclusion_spot.charge_rate )
from 				inclusion_spot,
							inclusion 
where			inclusion.campaign_no = @campaign_no
and  					inclusion_spot.inclusion_id = inclusion.inclusion_id
and					inclusion_spot.spot_status != 'P'
and 					inclusion.inclusion_type = 12
GROUP BY 	inclusion_spot.campaign_no,
							inclusion_spot.billing_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg revenue proxy spots', 16, 1)
	rollback transaction
	return -1
end

/* 20. Cinelight Revenue Proxy SPOTS */

insert 			#work_revision
select 			'NEW',
							campaign_no = inclusion_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 20, /* Cinelight Revenue Proxy SPOTS  */
							revenue_period = inclusion_spot.revenue_period,
							billing_date = inclusion_spot.billing_date,   
							value = sum( rate ),   
							cost = sum ( charge_rate ),   
							units = count(*),
							makegood = 0,   
							revenue = SUM ( inclusion_spot.charge_rate )
from				inclusion_spot,
							inclusion 
where			inclusion.campaign_no = @campaign_no
and 					inclusion_spot.inclusion_id = inclusion.inclusion_id
and					inclusion_spot.spot_status != 'P'
and 					inclusion.inclusion_type = 13
GROUP BY 	inclusion_spot.campaign_no,
							inclusion_spot.billing_date,
							inclusion_spot.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinelight revenue proxy spots', 16, 1)
	rollback transaction
	return -1
end

/* 1l. TAP NORMAL Spots */

insert 			#work_revision
select 			'NEW',
							campaign_no = inclusion_spot.campaign_no,   
							confirmation_date = @confirm_date,
							transaction_type = 52, /* Cinemarketing SPOTS  */
							inclusion_spot.revenue_period,
							screening_date, 
							convert(numeric(38,16), sum(rate)),
							convert(numeric(38,16), sum(charge_rate)),
							units = count(*) ,   
							0,
							convert(numeric(38,16), sum(charge_rate))
from 				inclusion_spot,
							inclusion
where			inclusion.campaign_no = @campaign_no
and  					inclusion.inclusion_id = inclusion_spot.inclusion_id
and					inclusion_spot.spot_status != 'P'
and						spot_type = 'T'
and 					inclusion.inclusion_type = 24
GROUP BY 	inclusion_spot.campaign_no,
							inclusion_spot.screening_date,
							inclusion_spot.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film takeout spots', 16, 1)
	rollback transaction
	return -1
end
							
/* 2. TAP TakeOut */

insert 			#work_revision
select 			'NEW',
							campaign_no = inclusion_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 53, /* TAP Takeout */
							inclusion_spot.revenue_period,
							billing_date = (select 		max(screening_date) 
														from 			film_screening_date_xref fdx
														where 	fdx.benchmark_end = inclusion_spot.revenue_period),   
							value = 0,   
							cost = SUM ( inclusion_spot.takeout_rate * - 1),  
							units = count(*),
							makegood = 0,   
							revenue = SUM ( inclusion_spot.takeout_rate * - 1)
from 				inclusion_spot  , inclusion 
where			inclusion.campaign_no = @campaign_no
and  					inclusion.inclusion_id = inclusion_spot.inclusion_id
and  					inclusion.include_revenue = 'Y' -- GB
and 					inclusion_spot.spot_status != 'P'
and 					inclusion.inclusion_category = 'T'
GROUP BY 	inclusion_spot.campaign_no,
							inclusion_spot.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film takeout spots', 16, 1)
	rollback transaction
	return -1
end							
							
/* 1l. FF Audience NORMAL Spots */

insert 			#work_revision
select 			'NEW',
				campaign_no = inclusion_spot.campaign_no,   
				confirmation_date = @confirm_date,
				case film_campaign.business_unit_id when 2 then 1 else 4 end, 
				inclusion_spot.revenue_period,
				screening_date, 
				convert(numeric(38,16), sum(rate)),
				convert(numeric(38,16), sum(charge_rate)),
				units = count(*) ,   
				0,
				convert(numeric(38,16), sum(charge_rate))
from			inclusion_spot,
				inclusion,
				film_campaign
where			inclusion.campaign_no = @campaign_no
and				inclusion.campaign_no = film_campaign.campaign_no
and				inclusion.inclusion_id = inclusion_spot.inclusion_id
and				inclusion_spot.spot_status != 'P'
and				spot_type in ('F','K', 'A')
and 			inclusion.inclusion_type in (29,30, 31,32)
GROUP BY	 	inclusion_spot.campaign_no,
				inclusion_spot.screening_date,
				inclusion_spot.revenue_period, film_campaign.business_unit_id
														

/* 1l. VM Digital Audience NORMAL Spots */

insert 			#work_revision
select 			'NEW',
				campaign_no = inclusion_spot.campaign_no,   
				confirmation_date = @confirm_date,
				revision_transaction_type.revision_transaction_type,
				inclusion_spot.revenue_period,
				screening_date, 
				convert(numeric(38,16), sum(rate)),
				convert(numeric(38,16), sum(charge_rate)),
				units = count(*) ,   
				0,
				convert(numeric(38,16), sum(charge_rate))
from			inclusion_spot
inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
inner join		revision_transaction_type on inclusion_type.media_product_id = revision_transaction_type.media_product_id
and				revision_transaction_type.statrev_transaction_type_group_id = 1
where			inclusion.campaign_no = @campaign_no
and				inclusion_spot.spot_status != 'P'
and 			inclusion.inclusion_type between 34 and 65
GROUP BY	 	inclusion_spot.campaign_no,
				inclusion_spot.screening_date,
				revision_transaction_type.revision_transaction_type,
				inclusion_spot.revenue_period

/* VM Digital TakeOut */

insert 			#work_revision
select 			'NEW',
				campaign_no = inclusion_spot.campaign_no,   
				confirmation_date = @confirm_date,
				revision_transaction_type.revision_transaction_type,
				inclusion_spot.revenue_period,
				billing_date = (	select			max(screening_date) 
									from 			film_screening_date_xref fdx
									where 			fdx.benchmark_end = inclusion_spot.revenue_period),   
				value = 0,   
				cost = SUM ( inclusion_spot.takeout_rate * - 1),  
				units = count(*),
				makegood = 0,   
				revenue = SUM ( inclusion_spot.takeout_rate * - 1)
from 			inclusion_spot
inner join		inclusion on inclusion.inclusion_id = inclusion_spot.inclusion_id
inner join		inclusion_category on inclusion.inclusion_category = inclusion_category.inclusion_category
inner join		revision_transaction_type on inclusion_category.media_product_id = revision_transaction_type.media_product_id
and				revision_transaction_type.statrev_transaction_type_group_id = 2
where			inclusion.campaign_no = @campaign_no
and  			inclusion.include_revenue = 'Y' 
and 			inclusion_spot.spot_status != 'P'
and 			inclusion.inclusion_category in ('A', 'B', 'E', 'H', 'J', 'K', 'L', 'N', 'O')
GROUP BY 		inclusion_spot.campaign_no,
				revision_transaction_type.revision_transaction_type,
				inclusion_spot.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film takeout spots', 16, 1)
	rollback transaction
	return -1
end

/* VM Digital Billing Credits & Bad Debts */

insert 			#work_revision
select 			'NEW',
				campaign_no = inclusion_spot.campaign_no,   
				confirmation_date = @confirm_date,
				revision_transaction_type, /* Billing Credits And Bad Debts */
				revenue_period = inclusion_spot_liability.creation_period  ,
				billing_date = (	select			max(screening_date) 
									from 			film_screening_date_xref fdx
									where 			fdx.benchmark_end = inclusion_spot_liability.creation_period),   
				value = sum ( inclusion_spot_liability.spot_amount ),   
				cost = sum ( inclusion_spot_liability.spot_amount ),   
				units = 1 ,
				makegood = 0,   
				revenue = SUM ( inclusion_spot_liability.spot_amount  )
from 			inclusion_spot
inner join		inclusion_spot_liability on inclusion_spot.spot_id  = inclusion_spot_liability.spot_id
inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
inner join		revision_transaction_type on inclusion_type.media_product_id = revision_transaction_type.media_product_id
and				revision_transaction_type.statrev_transaction_type_group_id = 3
where			inclusion_spot.campaign_no = @campaign_no
and 			inclusion_spot.spot_status != 'P'
and 			inclusion_spot_liability.liability_type = 172
GROUP BY		inclusion_spot.campaign_no,
				revision_transaction_type,
				inclusion_spot_liability.creation_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 23. CineMarketing Revenue Proxy SPOTS*/

insert 			#work_revision
select 			'NEW',
							campaign_no = inclusion_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 23, /* CineMarketing Revenue Proxy SPOTS */
							revenue_period = inclusion_spot.revenue_period,
							billing_date = inclusion_spot.billing_date,   
							value = sum( rate ),   
							cost = sum ( charge_rate ),   
							units = count(*),
							makegood = 0,   
							revenue = SUM ( inclusion_spot.charge_rate )
from 				inclusion_spot,
							inclusion 
where			inclusion.campaign_no = @campaign_no
and  					inclusion_spot.inclusion_id = inclusion.inclusion_id
and					inclusion_spot.spot_status != 'P'
and 					inclusion.inclusion_type = 14
GROUP BY 	inclusion_spot.campaign_no,
							inclusion_spot.billing_date,
							inclusion_spot.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinemarketing revenue proxy spots', 16, 1)
	rollback transaction
	return -1
end

/* 24. Retail Spots */

insert 			#outpost_work_revision
select 			'NEW',
							campaign_no = outpost_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 100,  
				--			revision_transaction_type = outpost_player.media_product_id, --GB
							benchmark_end ,
							billing_date = outpost_spot.billing_date,   
							value = sum ( outpost_spot.rate * (round((no_days / 7),2))),   
							cost = sum ( outpost_spot.charge_rate * (round((no_days / 7),2))),   
							units = count(*) ,
							makegood = SUM ( outpost_spot.makegood_rate * (round((no_days / 7),2))),   
							revenue = SUM ( (outpost_spot.charge_rate + outpost_spot.makegood_rate) * (round((no_days / 7),2)))
from				outpost_spot,
							outpost_screening_date_xref, 
							outpost_panel, 
							outpost_player_xref,
							outpost_player
where 			outpost_spot.campaign_no = @campaign_no
and 					outpost_spot.spot_status != 'P'
and						outpost_screening_date_xref.screening_date = outpost_spot.billing_date
and						outpost_spot.outpost_panel_id 	= outpost_panel.outpost_panel_id  
and						outpost_panel.outpost_panel_id 	= outpost_player_xref.outpost_panel_id  
and						outpost_player.player_name  	= outpost_player_xref.player_name 
and 					outpost_player.media_product_id = 9  
GROUP BY 	outpost_spot.campaign_no,
							outpost_spot.billing_date,
							benchmark_end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail spots', 16, 1)
	rollback transaction
	return -1
end

/* 25. Retail TakeOut */  -- was 24

insert 			#outpost_work_revision
select 			'NEW',
							campaign_no = inclusion_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 101, /* Retail Takeout */
							inclusion_spot.revenue_period,
							billing_date = (select 		max(screening_date) 
														from 			outpost_screening_date_xref fdx
														where 	fdx.benchmark_end = inclusion_spot.revenue_period),
							value = 0,   
							cost = SUM ( inclusion_spot.takeout_rate * - 1),   
							units = count(*),
							makegood = 0,   
							revenue = SUM ( inclusion_spot.takeout_rate * - 1)
from 				inclusion_spot,
							inclusion 
where			inclusion.campaign_no = @campaign_no
and					inclusion_spot.spot_status != 'P'
and 					inclusion.inclusion_category = 'R'
and  					inclusion.include_revenue = 'Y' -- GB
and  					inclusion.inclusion_id = inclusion_spot.inclusion_id
GROUP BY 	inclusion_spot.campaign_no,
							inclusion_spot.revenue_period,
							inclusion_spot.screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail takeouts', 16, 1)
	rollback transaction
	return -1
end

/* 26. Retail Billing Credits */

insert 			#outpost_work_revision
select 			'NEW',
							campaign_no = outpost_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 102, /* Retail Billing Credits  */
							revenue_period = outpost_spot_liability.creation_period  ,
							billing_date =( select 		max ( screening_date ) 
														from 			outpost_screening_date_xref fdx
														where 	fdx.benchmark_end = outpost_spot_liability.creation_period),   
							value = sum ( outpost_spot_liability.spot_amount ),   
							cost = sum ( outpost_spot_liability.spot_amount ),   
							units = 1 ,
							makegood = 0,   
							revenue = SUM ( outpost_spot_liability.spot_amount  )
from 				outpost_spot,   
							outpost_spot_liability ,
							outpost_panel  	,
							outpost_player_xref ,
							outpost_player --GB
where			outpost_spot.campaign_no = @campaign_no
and 					outpost_spot.spot_status != 'P'
and 					outpost_spot_liability.liability_type = 152
and 					outpost_spot.spot_id  = outpost_spot_liability.spot_id
and 					outpost_spot.outpost_panel_id 	= outpost_panel.outpost_panel_id  
and 					outpost_panel.outpost_panel_id 	= outpost_player_xref.outpost_panel_id  
and 					outpost_player.player_name  	= outpost_player_xref.player_name 
and 					outpost_player.media_product_id in (9  ,16)
GROUP BY 	outpost_spot.campaign_no,
							outpost_spot.billing_date,
							outpost_spot_liability.creation_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 27. Retail Wall Spots */

insert 			#outpost_work_revision
select 			'NEW',
							campaign_no = inclusion_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 103,
							benchmark_end ,
							billing_date = inclusion_spot.op_billing_date,   
							value = sum ( inclusion_spot.rate * (round((no_days / 7),2))),   
							cost = sum ( inclusion_spot.charge_rate * (round((no_days / 7),2))),   
							units = count(*) ,
							makegood = SUM ( inclusion_spot.makegood_rate * (round((no_days / 7),2))),   
							revenue = SUM ( (inclusion_spot.charge_rate + inclusion_spot.makegood_rate) * (round((no_days / 7),2)))
from 				inclusion_spot,
							outpost_screening_date_xref 
where 			inclusion_spot.campaign_no = @campaign_no
and 					inclusion_spot.spot_status != 'P'
and						outpost_screening_date_xref.screening_date = inclusion_spot.op_billing_date
GROUP BY 	inclusion_spot.campaign_no,
							inclusion_spot.op_billing_date,
							benchmark_end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail spots', 16, 1)
	rollback transaction
	return -1
end

/* 29. Retail Billing Credits */  --26

insert 			#outpost_work_revision
select 			'NEW',
							campaign_no = outpost_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 105, /* Retail Billing Credits  */
							revenue_period = outpost_spot_liability.creation_period  ,
							billing_date =( select 		max ( screening_date ) 
														from 			outpost_screening_date_xref fdx
														where 	fdx.benchmark_end = outpost_spot_liability.creation_period),   
							value = sum ( outpost_spot_liability.spot_amount ),   
							cost = sum ( outpost_spot_liability.spot_amount ),   
							units = 1 ,
							makegood = 0,   
							revenue = SUM ( outpost_spot_liability.spot_amount  )
from 				outpost_spot,
							outpost_spot_liability
where			outpost_spot.campaign_no = @campaign_no
and 					outpost_spot.spot_status != 'P'
and 					outpost_spot_liability.liability_type = 156
and 					outpost_spot.spot_id  = outpost_spot_liability.spot_id
GROUP BY 	outpost_spot.campaign_no,
							outpost_spot.billing_date,
							outpost_spot_liability.creation_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail billing credits', 16, 1)
	rollback transaction
	return -1
end

-- Added by GB --10/11/2009

/* 30. Retail Super Wall Spots */

insert 			#outpost_work_revision
select 			'NEW',
							campaign_no = outpost_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 106,  
							benchmark_end ,
							billing_date = outpost_spot.billing_date,   
							value = sum ( outpost_spot.rate * (round((no_days / 7),2))),   
							cost = sum ( outpost_spot.charge_rate * (round((no_days / 7),2))),   
							units = count(*) ,
							makegood = SUM ( outpost_spot.makegood_rate * (round((no_days / 7),2))),   
							revenue = SUM ( (outpost_spot.charge_rate + outpost_spot.makegood_rate) * (round((no_days / 7),2)))
from 				outpost_spot,
							outpost_screening_date_xref , 
							outpost_panel , 
							outpost_player_xref,
							outpost_player --GB
where 			outpost_spot.campaign_no = @campaign_no
and 					outpost_spot.spot_status != 'P'
and						outpost_screening_date_xref.screening_date = outpost_spot.billing_date
and 					outpost_spot.outpost_panel_id 	= outpost_panel.outpost_panel_id  
and 					outpost_panel.outpost_panel_id 	= outpost_player_xref.outpost_panel_id  
and 					outpost_player.player_name  	= outpost_player_xref.player_name 
and 					outpost_player.media_product_id = 11 
GROUP BY 	outpost_spot.campaign_no,
							outpost_spot.billing_date,
							benchmark_end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail spots', 16, 1)
	rollback transaction
	return -1
end


/* 32. Retail Super Wall Billing Credits */

insert 			#outpost_work_revision
select 			'NEW',
							campaign_no = outpost_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 108, /* Retail Billing Credits  */
							revenue_period = outpost_spot_liability.creation_period  ,
							billing_date =( select 		max ( screening_date ) 
														from 			outpost_screening_date_xref fdx
														where 	fdx.benchmark_end = outpost_spot_liability.creation_period),   
							value = sum ( outpost_spot_liability.spot_amount ),   
							cost = sum ( outpost_spot_liability.spot_amount ),   
							units = 1 ,
							makegood = 0,   
							revenue = SUM ( outpost_spot_liability.spot_amount  )
from 				outpost_spot,   
							outpost_spot_liability, 
							outpost_panel, 
							outpost_player_xref, 
							outpost_player
where			outpost_spot.campaign_no = @campaign_no
and 					outpost_spot.spot_status != 'P'
and 					outpost_spot_liability.liability_type = 161
and 					outpost_spot.spot_id  = outpost_spot_liability.spot_id
and 					outpost_spot.outpost_panel_id 	= outpost_panel.outpost_panel_id  
and 					outpost_panel.outpost_panel_id 	= outpost_player_xref.outpost_panel_id  
and 					outpost_player.player_name  	= outpost_player_xref.player_name 
and 					outpost_player.media_product_id = 11  
GROUP BY 	outpost_spot.campaign_no,
							outpost_spot.billing_date,
							outpost_spot_liability.creation_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 1i. Petro NORMAL Spots */


insert 		#outpost_work_revision
select 		'NEW',
						campaign_no = outpost_spot.campaign_no,   
						confirmation_date = @confirm_date,
						transaction_type = 120,  
						benchmark_end ,
						billing_date = outpost_spot.billing_date,   
						value = sum ( outpost_spot.rate * (round((no_days / 7),2))),   
						cost = sum ( outpost_spot.charge_rate * (round((no_days / 7),2))),   
						units = count(*) ,
						makegood = SUM ( outpost_spot.makegood_rate * (round((no_days / 7),2))),   
						revenue = SUM ( (outpost_spot.charge_rate + outpost_spot.makegood_rate) * (round((no_days / 7),2)))
from 			outpost_spot,
						outpost_panel,
						outpost_player_xref,
						outpost_player,
						outpost_screening_date_xref
where 		outpost_spot.campaign_no = @campaign_no
and 				outpost_spot.spot_status != 'P'
and 				outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 				outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 				outpost_player.player_name = outpost_player_xref.player_name 
and					outpost_spot.billing_date = outpost_screening_date_xref.screening_date
and 				outpost_player.media_product_id = 12  
and					spot_type <> 'R' 
and 				spot_type <> 'W'
and					((spot_status = 'A'
and					spot_type <> 'M'
and					spot_type <> 'V')
or						spot_status in ('X', 'R'))
GROUP BY 	outpost_spot.campaign_no,
						outpost_spot.billing_date,
						benchmark_end,
						no_days

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail normal spots', 16, 1)
	rollback transaction
	return -1
end

/* 1j. Petro CStore Spots */


insert 			#outpost_work_revision
select 		'NEW',
						campaign_no = outpost_spot.campaign_no,   
						confirmation_date = @confirm_date,
						transaction_type = 123,  
						benchmark_end ,
						billing_date = outpost_spot.billing_date,   
						value = sum ( outpost_spot.rate * (round((no_days / 7),2))),   
						cost = sum ( outpost_spot.charge_rate * (round((no_days / 7),2))),   
						units = count(*) ,
						makegood = SUM ( outpost_spot.makegood_rate * (round((no_days / 7),2))),   
						revenue = SUM ( (outpost_spot.charge_rate + outpost_spot.makegood_rate) * (round((no_days / 7),2)))
from 			outpost_spot,
						outpost_panel,
						outpost_player_xref,
						outpost_player,
						outpost_screening_date_xref
where 		outpost_spot.campaign_no = @campaign_no
and 				outpost_spot.spot_status != 'P'
and 				outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 				outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 				outpost_player.player_name = outpost_player_xref.player_name 
and					outpost_spot.screening_date = outpost_screening_date_xref.screening_date
and 				outpost_player.media_product_id = 13  
and					spot_type <> 'R' 
and 				spot_type <> 'W'
and					((spot_status = 'A'
and					spot_type <> 'M'
and					spot_type <> 'V')
or						spot_status in ('X', 'R'))
GROUP BY 	outpost_spot.campaign_no,
						outpost_spot.billing_date,   
						benchmark_end,
						no_days

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail normal spots', 16, 1)
	rollback transaction
	return -1
end

/* 26. Retail Billing Credits */

insert 			#outpost_work_revision
select 			'NEW',
							campaign_no = outpost_spot.campaign_no,   
							confirmation_date = @confirm_date,
							revision_transaction_type = 102, /* Retail Billing Credits  */
							revenue_period = outpost_spot_liability.creation_period  ,
							billing_date =( select 		max ( screening_date ) 
														from 			outpost_screening_date_xref fdx
														where 	fdx.benchmark_end = outpost_spot_liability.creation_period),   
							value = sum ( outpost_spot_liability.spot_amount ),   
							cost = sum ( outpost_spot_liability.spot_amount ),   
							units = 1 ,
							makegood = 0,   
							revenue = SUM ( outpost_spot_liability.spot_amount  )
from 				outpost_spot,   
							outpost_spot_liability ,
							outpost_panel  	,
							outpost_player_xref ,
							outpost_player --GB
where			outpost_spot.campaign_no = @campaign_no
and 					outpost_spot.spot_status != 'P'
and 					outpost_spot_liability.liability_type in (152,161)
and 					outpost_spot.spot_id  = outpost_spot_liability.spot_id
and 					outpost_spot.outpost_panel_id 	= outpost_panel.outpost_panel_id  
and 					outpost_panel.outpost_panel_id 	= outpost_player_xref.outpost_panel_id  
and 					outpost_player.player_name  	= outpost_player_xref.player_name 
and 					outpost_player.media_product_id  in (12,13,17)
GROUP BY 	outpost_spot.campaign_no,
							outpost_spot.billing_date,
							outpost_spot_liability.creation_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 1j. TAB Spots */

insert 			#outpost_work_revision
select 		'NEW',
						campaign_no = outpost_spot.campaign_no,   
						confirmation_date = @confirm_date,
						transaction_type = 150,  
						benchmark_end ,
						billing_date = outpost_spot.billing_date,   
						value = sum ( outpost_spot.rate * (round((no_days / 7),2))),   
						cost = sum ( outpost_spot.charge_rate * (round((no_days / 7),2))),   
						units = count(*) ,
						makegood = SUM ( outpost_spot.makegood_rate * (round((no_days / 7),2))),   
						revenue = SUM ( (outpost_spot.charge_rate + outpost_spot.makegood_rate) * (round((no_days / 7),2)))
from 			outpost_spot,
						outpost_panel,
						outpost_player_xref,
						outpost_player,
						outpost_screening_date_xref
where 		outpost_spot.campaign_no = @campaign_no
and 				outpost_spot.spot_status != 'P'
and 				outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 				outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 				outpost_player.player_name = outpost_player_xref.player_name 
and					outpost_spot.screening_date = outpost_screening_date_xref.screening_date
and 				outpost_player.media_product_id = 16  
and					spot_type <> 'R' 
and 				spot_type <> 'W'
and					((spot_status = 'A'
and					spot_type <> 'M'
and					spot_type <> 'V')
or						spot_status in ('X', 'R'))
GROUP BY 	outpost_spot.campaign_no,
						outpost_spot.billing_date,   
						benchmark_end,
						no_days
							
							
select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail normal spots', 16, 1)
	rollback transaction
	return -1
end

/* 1j. TAB Spots */

insert 			#outpost_work_revision
select 		'NEW',
						campaign_no = outpost_spot.campaign_no,   
						confirmation_date = @confirm_date,
						transaction_type = 160,  
						benchmark_end ,
						billing_date = outpost_spot.billing_date,   
						value = sum ( outpost_spot.rate * (round((no_days / 7),2))),   
						cost = sum ( outpost_spot.charge_rate * (round((no_days / 7),2))),   
						units = count(*) ,
						makegood = SUM ( outpost_spot.makegood_rate * (round((no_days / 7),2))),   
						revenue = SUM ( (outpost_spot.charge_rate + outpost_spot.makegood_rate) * (round((no_days / 7),2)))
from 			outpost_spot,
						outpost_panel,
						outpost_player_xref,
						outpost_player,
						outpost_screening_date_xref
where 		outpost_spot.campaign_no = @campaign_no
and 				outpost_spot.spot_status != 'P'
and 				outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 				outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 				outpost_player.player_name = outpost_player_xref.player_name 
and					outpost_spot.screening_date = outpost_screening_date_xref.screening_date
and 				outpost_player.media_product_id = 17  
and					spot_type <> 'R' 
and 				spot_type <> 'W'
and					((spot_status = 'A'
and					spot_type <> 'M'
and					spot_type <> 'V')
or						spot_status in ('X', 'R'))
GROUP BY 	outpost_spot.campaign_no,
						outpost_spot.billing_date,   
						benchmark_end,
						no_days
							
							
select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail normal spots', 16, 1)
	rollback transaction
	return -1
end

/* insert existing compaign transactions as a negative value to figure out the delta */

insert 			#work_revision
select 			flag = 'OLD',   
							campaign_revision.campaign_no,   
							campaign_revision.confirmation_date,   
							revision_transaction.revision_transaction_type,
							revision_transaction.revenue_period,   
							revision_transaction.billing_date,   
							value * -1,   
							cost * -1,   
							units * -1,   
							makegood * -1,   
							revenue * -1  
from 				campaign_revision,   
							revision_transaction  
where			revision_transaction.revision_id = campaign_revision.revision_id 
and 					campaign_revision.campaign_no = @campaign_no 

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting old revisions', 16, 1)
	rollback transaction
	return -1
end

insert 			#outpost_work_revision
select 			flag = 'OLD',   
							campaign_revision.campaign_no,   
							campaign_revision.confirmation_date,   
							outpost_revision_transaction.revision_transaction_type,
							outpost_revision_transaction.revenue_period,   
							outpost_revision_transaction.billing_date,   
							value * -1,   
							cost * -1,   
							units * -1,   
							makegood * -1,   
							revenue * -1  
from 				campaign_revision,   
							outpost_revision_transaction  
where			outpost_revision_transaction.revision_id = campaign_revision.revision_id 
and 					campaign_revision.campaign_no = @campaign_no 

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting old retail revisions', 16, 1)
	rollback transaction
	return -1
end

insert INTO #delta_revision
(
	campaign_no, 
	revision_transaction_type,	
	revenue_period ,	
	billing_date, 
	value,
	cost,
	units,
	makegood,
	revenue
)
( 	select 		#work_revision.campaign_no,
				#work_revision.revision_transaction_type,   
				#work_revision.revenue_period,   
				#work_revision.billing_date,   
				sum ( #work_revision.value),   
				sum ( #work_revision.cost) ,   
				sum ( #work_revision.units),   
				sum ( #work_revision.makegood),   
				sum ( #work_revision.revenue )  
	from 		#work_revision
	GROUP BY 	#work_revision.campaign_no,
				#work_revision.revision_transaction_type,   
				#work_revision.revenue_period,   
				#work_revision.billing_date
	HAVING   	sum ( #work_revision.value) <> 0  
	OR			sum ( #work_revision.cost) <> 0  
	OR			sum ( #work_revision.units) <> 0  
	OR			sum ( #work_revision.makegood) <> 0  
	OR			sum ( #work_revision.revenue )  <> 0)

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting into delta temp table', 16, 1)
	rollback transaction
	return -1
end

insert INTO #outpost_delta_revision
(
	campaign_no, 
	revision_transaction_type,	
	revenue_period ,	
	billing_date, 
	value,
	cost,
	units,
	makegood,
	revenue
)
( 	select 		#outpost_work_revision.campaign_no,
				#outpost_work_revision.revision_transaction_type,   
				#outpost_work_revision.revenue_period,   
				#outpost_work_revision.billing_date,   
				sum ( #outpost_work_revision.value),   
				sum ( #outpost_work_revision.cost) ,   
				sum ( #outpost_work_revision.units),   
				sum ( #outpost_work_revision.makegood),   
				sum ( #outpost_work_revision.revenue )  
	from 		#outpost_work_revision
	GROUP BY 	#outpost_work_revision.campaign_no,
				#outpost_work_revision.revision_transaction_type,   
				#outpost_work_revision.revenue_period,   
				#outpost_work_revision.billing_date
	HAVING   	sum ( #outpost_work_revision.value) <> 0  
	OR			sum ( #outpost_work_revision.cost) <> 0  
	OR			sum ( #outpost_work_revision.units) <> 0  
	OR			sum ( #outpost_work_revision.makegood) <> 0  
	OR			sum ( #outpost_work_revision.revenue )  <> 0)

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting into retail delta temp table', 16, 1)
	rollback transaction
	return -1
end

/* Now add required revision transactions 
The temporary table now contains:
-	NEW -	the current picture of spots etc
-	OLD -	revision transactions from previous snapshot as negatives
The net effect is that if you add all the values up in the 
temporary table, any none zero value is a change to the cell (row).
The group by gives you the delta for each row.
Total Revision Was:	Key A	10, 	Key B 10
Total Revision s/b:	Key B 10,	Key C 10

Temporary Table:	
Key A -10 OLD,
Key B -10 OLD,
Key B	 10 NEW,
Key C	 10 NEW

A group by produces this delta:
Key A -10
Key C	 10

Revision now holds:	Key A: 10

*/

DELETE from #delta_revision 
where   	IsNull( #delta_revision.value , 0 ) = 0 
and			IsNull( #delta_revision.cost , 0 ) = 0 
and			IsNull( #delta_revision.makegood, 0 ) = 0
and			IsNull( #delta_revision.revenue, 0 ) = 0

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting from delta table', 16, 1)
	rollback transaction
	return -1
end

DELETE from #outpost_delta_revision 
where   	IsNull( #outpost_delta_revision.value , 0 ) = 0 
and			IsNull( #outpost_delta_revision.cost , 0 ) = 0 
and			IsNull( #outpost_delta_revision.makegood, 0 ) = 0
and			IsNull( #outpost_delta_revision.revenue, 0 ) = 0

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting from retail delta table', 16, 1)
	rollback transaction
	return -1
end

/* Add new campaign revision records from temporary table */
IF ( IsNull( @revision_id, 0 ) = 0 )
begin
	insert INTO campaign_revision  
	( 
	campaign_no,   
	revision_type,   
	revision_category,   
	revision_no,
	confirmed_by,
	confirmation_date,
	comment 
	)   select  temp_table.campaign_no,
                @revision_type,   
				@revision_category,   
				@revision_no,
				@user_id,
				@confirm_date,
				@default_comment
        from    (select #delta_revision.campaign_no   
                from 		#delta_revision 
                where 		NOT EXISTS (select 	* 
				                from 	campaign_revision
				                where 	campaign_revision.campaign_no = #delta_revision.campaign_no
				                and 	campaign_revision.revision_no = @revision_no)
                GROUP BY 	#delta_revision.campaign_no
                union
                select      #outpost_delta_revision.campaign_no   
                from 		#outpost_delta_revision 
                where 		NOT EXISTS (select 	* 
				                from 	campaign_revision
				                where 	campaign_revision.campaign_no = #outpost_delta_revision.campaign_no
				                and 	campaign_revision.revision_no = @revision_no)
                GROUP BY 	#outpost_delta_revision.campaign_no) as temp_table         
 

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting into campaign revision', 16, 1)
		rollback transaction
		return -1
	end

	insert INTO revision_transaction  
	( 
	revision_id,   
	revision_transaction_type,   
	revenue_period,   
	billing_date,   
	delta_date,   
	value,   
	cost,   
	units,   
	makegood,   
	revenue
	)  
	select		campaign_revision.revision_id,   
				#delta_revision.revision_transaction_type,   
				#delta_revision.revenue_period,   
				#delta_revision.billing_date,   
				@confirm_date,   
				#delta_revision.value,   
				#delta_revision.cost,   
				#delta_revision.units,   
				#delta_revision.makegood,   
				#delta_revision.revenue
	from 		campaign_revision,
				#delta_revision
	where  		campaign_revision.campaign_no = #delta_revision.campaign_no
	and 		campaign_revision.revision_no = @revision_no

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting revision transaction', 16, 1)
		rollback transaction
		return -1
	end

	insert INTO outpost_revision_transaction  
	( 
	revision_id,   
	revision_transaction_type,   
	revenue_period,   
	billing_date,   
	delta_date,   
	value,   
	cost,   
	units,   
	makegood,   
	revenue
	)  
	select		campaign_revision.revision_id,   
				#outpost_delta_revision.revision_transaction_type,   
				#outpost_delta_revision.revenue_period,   
				#outpost_delta_revision.billing_date,   
				@confirm_date,   
				#outpost_delta_revision.value,   
				#outpost_delta_revision.cost,   
				#outpost_delta_revision.units,   
				#outpost_delta_revision.makegood,   
				#outpost_delta_revision.revenue
	from 		campaign_revision,
				#outpost_delta_revision
	where  		campaign_revision.campaign_no = #outpost_delta_revision.campaign_no
	and 		campaign_revision.revision_no = @revision_no

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting revision transaction', 16, 1)
		rollback transaction
		return -1
	end

    if @figure_type = 'C' 
    begin
	    insert into booking_figures
	    (
	    campaign_no,
	    rep_id,
	    branch_code,
	    revision_id,
	    revision_group,
	    figure_date,
	    booking_period,
	    figure_type,
	    nett_amount,
	    figure_comment
	    )
	    select 		#delta_revision.campaign_no,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    campaign_revision.revision_id,
				    revision_transaction_type.revision_group,
				    @confirm_date,
				    (select sales_period from film_sales_period where status = 'C'),
				    @figure_type,
				    sum ( #delta_revision.cost * booking_percent),
				    campaign_revision.comment
	    from		#delta_revision,
				    campaign_revision,
				    film_campaign_reps,
				    revision_transaction_type
	    where		revision_transaction_type.revision_transaction_type = #delta_revision.revision_transaction_type
	    and			campaign_revision.revision_no = @revision_no
	    and			film_campaign_reps.campaign_no = #delta_revision.campaign_no
	    and			campaign_revision.campaign_no = #delta_revision.campaign_no
	    and			film_campaign_reps.campaign_no = campaign_revision.campaign_no
	    and			film_campaign_reps.booking_percent > 0
	    group by	#delta_revision.campaign_no,
				    campaign_revision.revision_id,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    revision_transaction_type.revision_group,
				    campaign_revision.comment	

	    select @error = @@error
	    if @error <> 0
	    begin
		    raiserror ('Error inserting new booking figures', 16, 1)
		    rollback transaction
		    return -1
	    end

	    insert into booking_figures
	    (
	    campaign_no,
	    rep_id,
	    branch_code,
	    revision_id,
	    revision_group,
	    figure_date,
	    booking_period,
	    figure_type,
	    nett_amount,
	    figure_comment
	    )
	    select 		#outpost_delta_revision.campaign_no,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    campaign_revision.revision_id,
				    revision_transaction_type.revision_group,
				    @confirm_date,
				    (select sales_period from film_sales_period where status = 'C'),
				    @figure_type,
				    sum ( #outpost_delta_revision.cost * booking_percent),
				    campaign_revision.comment
	    from		#outpost_delta_revision,
				    campaign_revision,
				    film_campaign_reps,
				    revision_transaction_type
	    where		revision_transaction_type.revision_transaction_type = #outpost_delta_revision.revision_transaction_type
	    and			campaign_revision.revision_no = @revision_no
	    and			film_campaign_reps.campaign_no = #outpost_delta_revision.campaign_no
	    and			campaign_revision.campaign_no = #outpost_delta_revision.campaign_no
	    and			film_campaign_reps.campaign_no = campaign_revision.campaign_no
	    and			film_campaign_reps.booking_percent > 0
	    group by	#outpost_delta_revision.campaign_no,
				    campaign_revision.revision_id,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    revision_transaction_type.revision_group,
				    campaign_revision.comment	

	    select @error = @@error
	    if @error <> 0
	    begin
		    raiserror ('Error inserting new retail booking figures', 16, 1)
		    rollback transaction
		    return -1
	    end

	    insert into booking_figure_team_xref
	    (
	    team_id,
	    figure_id
	    )
	    select		campaign_rep_teams.team_id,
				    booking_figures.figure_id
	    from		film_campaign_reps,
				    campaign_rep_teams,
				    campaign_revision,
				    booking_figures
	    where		film_campaign_reps.campaign_reps_id = campaign_rep_teams.campaign_reps_id
	    and			campaign_revision.revision_no = @revision_no
	    and			campaign_revision.revision_id = booking_figures.revision_id
	    and			campaign_revision.campaign_no = booking_figures.campaign_no
	    and			campaign_revision.campaign_no = film_campaign_reps.campaign_no
	    and			film_campaign_reps.campaign_no = @campaign_no
	    and 		booking_figures.rep_id = film_campaign_reps.rep_id
	
	    select @error = @@error
	    if @error <> 0
	    begin
		    raiserror ('Error inserting new booking figures - teams link', 16, 1)
		 rollback transaction
		    return -1
	    end

    end
    else
    begin
	    insert into booking_figures
	    (
	    campaign_no,
	    rep_id,
	    branch_code,
	    revision_id,
	    revision_group,
	    figure_date,
	    booking_period,
	    figure_type,
	    nett_amount,
	    figure_comment
	    )
	    select 		#delta_revision.campaign_no,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    campaign_revision.revision_id,
				    revision_transaction_type.revision_group,
				    @confirm_date,
				    (select sales_period from film_sales_period where status = 'C'),
				    @figure_type,
				    sum ( #delta_revision.cost * booking_percent),
				    campaign_revision.comment
	    from		#delta_revision,
				    campaign_revision,
				    film_campaign_reps,
				    revision_transaction_type
	    where		revision_transaction_type.revision_transaction_type = #delta_revision.revision_transaction_type
	    and			campaign_revision.revision_no = @revision_no
	    and			film_campaign_reps.campaign_no = #delta_revision.campaign_no
	    and			campaign_revision.campaign_no = #delta_revision.campaign_no
	    and			film_campaign_reps.campaign_no = campaign_revision.campaign_no
	    and			film_campaign_reps.booking_percent > 0
	    group by	#delta_revision.campaign_no,
				    campaign_revision.revision_id,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    revision_transaction_type.revision_group,
				    campaign_revision.comment	
	    having		sum ( #delta_revision.cost * booking_percent) <> 0

	    select @error = @@error
	    if @error <> 0
	    begin
		    raiserror ('Error inserting new booking figures', 16, 1)
		    rollback transaction
		    return -1
	    end

	    insert into booking_figures
	    (
	    campaign_no,
	    rep_id,
	    branch_code,
	    revision_id,
	    revision_group,
	    figure_date,
	    booking_period,
	    figure_type,
	    nett_amount,
	    figure_comment
	    )
	    select 		#outpost_delta_revision.campaign_no,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    campaign_revision.revision_id,
				    revision_transaction_type.revision_group,
				    @confirm_date,
				    (select sales_period from film_sales_period where status = 'C'),
				    @figure_type,
				    sum ( #outpost_delta_revision.cost * booking_percent),
				    campaign_revision.comment
	    from		#outpost_delta_revision,
				    campaign_revision,
				    film_campaign_reps,
				    revision_transaction_type
	    where		revision_transaction_type.revision_transaction_type = #outpost_delta_revision.revision_transaction_type
	    and			campaign_revision.revision_no = @revision_no
	    and			film_campaign_reps.campaign_no = #outpost_delta_revision.campaign_no
	    and			campaign_revision.campaign_no = #outpost_delta_revision.campaign_no
	    and			film_campaign_reps.campaign_no = campaign_revision.campaign_no
	    and			film_campaign_reps.booking_percent > 0
	    group by	#outpost_delta_revision.campaign_no,
				    campaign_revision.revision_id,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    revision_transaction_type.revision_group,
				    campaign_revision.comment	
	    having		sum ( #outpost_delta_revision.cost * booking_percent) <> 0

	    select @error = @@error
	    if @error <> 0
	    begin
		    raiserror ('Error inserting new retail booking figures', 16, 1)
		    rollback transaction
		    return -1
	    end

	    insert into booking_figure_team_xref
	    (
	    team_id,
	    figure_id
	    )
	    select		campaign_rep_teams.team_id,
				    booking_figures.figure_id
	    from		film_campaign_reps,
				    campaign_rep_teams,
				    campaign_revision,
				    booking_figures
	    where		film_campaign_reps.campaign_reps_id = campaign_rep_teams.campaign_reps_id
	    and			campaign_revision.revision_no = @revision_no
	    and			campaign_revision.revision_id = booking_figures.revision_id
	    and			campaign_revision.campaign_no = booking_figures.campaign_no
	    and			campaign_revision.campaign_no = film_campaign_reps.campaign_no
	    and			film_campaign_reps.campaign_no = @campaign_no
	    and 		booking_figures.rep_id = film_campaign_reps.rep_id
	   group by  campaign_rep_teams.team_id,
				    booking_figures.figure_id
	
	    select @error = @@error
	    if @error <> 0
	    begin
		    raiserror ('Error inserting new booking figures - teams link', 16, 1)
		    rollback transaction
		    return -1
	    end
    end
end
	

IF ( IsNull( @revision_id, 0 ) != 0 )
begin
	insert INTO revision_transaction  
	( 
	revision_id,   
	revision_transaction_type,   
	revenue_period,   
	billing_date,   
	delta_date,   
	value,   
	cost,   
	units,   
	makegood,   
	revenue 
	)  
	select		@revision_id,   
				#delta_revision.revision_transaction_type,   
				#delta_revision.revenue_period,   
				#delta_revision.billing_date,   
				@confirm_date,   
				sum ( #delta_revision.value ),   
				sum ( #delta_revision.cost ),   
				sum ( #delta_revision.units ),   
				sum ( #delta_revision.makegood ),   
				sum ( #delta_revision.revenue )
	from 		#delta_revision
	GROUP BY    #delta_revision.revision_transaction_type,   
				#delta_revision.revenue_period,   
				#delta_revision.billing_date

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting new revision transactions', 16, 1)
		rollback transaction
		return -1
	end

	insert INTO outpost_revision_transaction  
	( 
	revision_id,   
	revision_transaction_type,   
	revenue_period,   
	billing_date,   
	delta_date,   
	value,   
	cost,   
	units,   
	makegood,   
	revenue 
	)  
	select		@revision_id,   
				#outpost_delta_revision.revision_transaction_type,   
				#outpost_delta_revision.revenue_period,   
				#outpost_delta_revision.billing_date,   
				@confirm_date,   
				sum ( #outpost_delta_revision.value ),   
				sum ( #outpost_delta_revision.cost ),   
				sum ( #outpost_delta_revision.units ),   
				sum ( #outpost_delta_revision.makegood ),   
				sum ( #outpost_delta_revision.revenue )
	from 		#outpost_delta_revision
	where		#outpost_delta_revision.revision_transaction_type >= 100
	GROUP BY    #outpost_delta_revision.revision_transaction_type,   
				#outpost_delta_revision.revenue_period,   
				#outpost_delta_revision.billing_date

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting new revision transactions', 16, 1)
		rollback transaction
		return -1
	end

    if @figure_type = 'C'
    begin
	    insert into booking_figures
	    (
	    campaign_no,
	    rep_id,
	    branch_code,
	    revision_id,
	    revision_group,
	    figure_date,
	    booking_period,
	    figure_type,
	    nett_amount,
	    figure_comment
	    )
	    select 		#delta_revision.campaign_no,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    @revision_id,
				    revision_transaction_type.revision_group,
				    @confirm_date,
				    (select sales_period from film_sales_period where status = 'C'),
				    @figure_type,
				    sum ( #delta_revision.cost * booking_percent),
				    campaign_revision.comment
	    from		#delta_revision,
				    campaign_revision,
				    film_campaign_reps,
				    revision_transaction_type
	    where		revision_transaction_type.revision_transaction_type = #delta_revision.revision_transaction_type
	    and			campaign_revision.revision_id = @revision_id
	    and			film_campaign_reps.campaign_no = #delta_revision.campaign_no
	    and			campaign_revision.campaign_no = #delta_revision.campaign_no
	    and			film_campaign_reps.campaign_no = campaign_revision.campaign_no
	    and			film_campaign_reps.booking_percent > 0
	    group by	#delta_revision.campaign_no,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    revision_transaction_type.revision_group,
				    campaign_revision.comment	

	    select @error = @@error
	    if @error <> 0
	    begin
		    raiserror ('Error inserting new booking figures', 16, 1)
		    rollback transaction
		    return -1
	    end

	    insert into booking_figures
	    (
	    campaign_no,
	    rep_id,
	    branch_code,
	    revision_id,
	    revision_group,
	    figure_date,
	    booking_period,
	    figure_type,
	    nett_amount,
	    figure_comment
	    )
	    select 		#outpost_delta_revision.campaign_no,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    @revision_id,
				    revision_transaction_type.revision_group,
				    @confirm_date,
				    (select sales_period from film_sales_period where status = 'C'),
				    @figure_type,
				    sum ( #outpost_delta_revision.cost * booking_percent),
				    campaign_revision.comment
	    from		#outpost_delta_revision,
				    campaign_revision,
				    film_campaign_reps,
				    revision_transaction_type
	    where		revision_transaction_type.revision_transaction_type = #outpost_delta_revision.revision_transaction_type
	    and			campaign_revision.revision_id = @revision_id
	    and			film_campaign_reps.campaign_no = #outpost_delta_revision.campaign_no
	    and			campaign_revision.campaign_no = #outpost_delta_revision.campaign_no
	    and			film_campaign_reps.campaign_no = campaign_revision.campaign_no
	    and			film_campaign_reps.booking_percent > 0
	    group by	#outpost_delta_revision.campaign_no,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    revision_transaction_type.revision_group,
				    campaign_revision.comment	

	    select @error = @@error
	    if @error <> 0
	    begin
		    raiserror ('Error inserting new booking figures', 16, 1)
		    rollback transaction
		    return -1
	    end

	    insert into booking_figure_team_xref
	    (
	    team_id,
	    figure_id
	    )
	    select		campaign_rep_teams.team_id,
				    booking_figures.figure_id
	    from		film_campaign_reps,
				    campaign_rep_teams,
				    campaign_revision,
				    booking_figures
	    where		film_campaign_reps.campaign_reps_id = campaign_rep_teams.campaign_reps_id
	    and			campaign_revision.revision_id = @revision_id
	    and			campaign_revision.revision_id = booking_figures.revision_id
	    and			campaign_revision.campaign_no = booking_figures.campaign_no
	    and			campaign_revision.campaign_no = film_campaign_reps.campaign_no
	    and			film_campaign_reps.campaign_no = @campaign_no
	    and 		booking_figures.rep_id = film_campaign_reps.rep_id
	
	    select @error = @@error
	    if @error <> 0
	    begin
		    raiserror ('Error inserting new booking figures - teams link', 16, 1)
		    rollback transaction
		    return -1
        end
    end
    else
    begin
	    insert into booking_figures
	    (
	    campaign_no,
	    rep_id,
	    branch_code,
	    revision_id,
	    revision_group,
	    figure_date,
	    booking_period,
	    figure_type,
	    nett_amount,
	    figure_comment
	    )
	    select 		#delta_revision.campaign_no,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    @revision_id,
				    revision_transaction_type.revision_group,
				    @confirm_date,
				    (select sales_period from film_sales_period where status = 'C'),
				    @figure_type,
				    sum ( #delta_revision.cost * booking_percent),
				    campaign_revision.comment
	    from		#delta_revision,
				    campaign_revision,
				    film_campaign_reps,
				    revision_transaction_type
	    where		revision_transaction_type.revision_transaction_type = #delta_revision.revision_transaction_type
	    and			campaign_revision.revision_id = @revision_id
	    and			film_campaign_reps.campaign_no = #delta_revision.campaign_no
	    and			campaign_revision.campaign_no = #delta_revision.campaign_no
	    and			film_campaign_reps.campaign_no = campaign_revision.campaign_no
	    and			film_campaign_reps.booking_percent > 0
	    group by	#delta_revision.campaign_no,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    revision_transaction_type.revision_group,
				    campaign_revision.comment	
	    having		sum ( #delta_revision.cost * booking_percent) <> 0

	    select @error = @@error
	    if @error <> 0
	    begin
		    raiserror ('Error inserting new booking figures', 16, 1)
		    rollback transaction
		    return -1
	    end

    insert into booking_figures
	    (
	    campaign_no,
	    rep_id,
	    branch_code,
	    revision_id,
	    revision_group,
	    figure_date,
	    booking_period,
	    figure_type,
	    nett_amount,
	    figure_comment
	    )
	    select 		#outpost_delta_revision.campaign_no,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    @revision_id,
				    revision_transaction_type.revision_group,
				    @confirm_date,
				    (select sales_period from film_sales_period where status = 'C'),
				    @figure_type,
				    sum ( #outpost_delta_revision.cost * booking_percent),
				    campaign_revision.comment
	    from		#outpost_delta_revision,
				    campaign_revision,
				    film_campaign_reps,
				    revision_transaction_type
	    where		revision_transaction_type.revision_transaction_type = #outpost_delta_revision.revision_transaction_type
	    and			campaign_revision.revision_id = @revision_id
	    and			film_campaign_reps.campaign_no = #outpost_delta_revision.campaign_no
	    and			campaign_revision.campaign_no = #outpost_delta_revision.campaign_no
	    and			film_campaign_reps.campaign_no = campaign_revision.campaign_no
	    and			film_campaign_reps.booking_percent > 0
	    group by	#outpost_delta_revision.campaign_no,
				    film_campaign_reps.rep_id,
				    film_campaign_reps.branch_code,
				    revision_transaction_type.revision_group,
				    campaign_revision.comment	
	    having		sum ( #outpost_delta_revision.cost * booking_percent) <> 0

	    select @error = @@error
	    if @error <> 0
	    begin
		    raiserror ('Error inserting new booking figures', 16, 1)
		    rollback transaction
		    return -1
	    end

	    insert into booking_figure_team_xref
	    (
	    team_id,
	    figure_id
	    )
	    select		campaign_rep_teams.team_id,
				    booking_figures.figure_id
	    from		film_campaign_reps,
				    campaign_rep_teams,
				    campaign_revision,
				    booking_figures
	    where		film_campaign_reps.campaign_reps_id = campaign_rep_teams.campaign_reps_id
	    and			campaign_revision.revision_id = @revision_id
	    and			campaign_revision.revision_id = booking_figures.revision_id
	    and			campaign_revision.campaign_no = booking_figures.campaign_no
	    and			campaign_revision.campaign_no = film_campaign_reps.campaign_no
	    and			film_campaign_reps.campaign_no = @campaign_no
	    and 		booking_figures.rep_id = film_campaign_reps.rep_id
	
	    select @error = @@error
	    if @error <> 0
	    begin
		    raiserror ('Error inserting new booking figures - teams link', 16, 1)
		    rollback transaction
		    return -1
        end
    end
end

commit transaction
return 0
GO
