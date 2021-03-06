/****** Object:  StoredProcedure [dbo].[p_statrev_revision_generate]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_revision_generate]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_revision_generate]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

create PROC [dbo].[p_statrev_revision_generate]	@campaign_no		int, 
												@revision_no 		int, 
												@user_id 			int

as

/*
 * Declare Variables
 */

declare		@error_num           		int,
			@error						int,
			@revision_category			int,
			@revision_id				int,
			@default_comment			varchar (255),
			@confirm_date				datetime,
			@revision_type 				smallint,
			@figure_type				char(1),
			@accounting_period			datetime,
			@campaign_status			char(1),
			@confirm_cutover			datetime

set nocount on

select			@campaign_status = campaign_status
from			film_campaign
where			campaign_no = @campaign_no

/*if @campaign_status = 'P'
	return 0*/

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
	from 			statrev_campaign_revision
	where 			statrev_campaign_revision.campaign_no = @campaign_no
	and 			statrev_campaign_revision.revision_no = @revision_no
end

if ( @revision_no = 0 )
begin
	select 			@revision_no = isnull ( max ( revision_no ) + 1  , 1 )
	from 			statrev_campaign_revision
	where 			statrev_campaign_revision.campaign_no = @campaign_no
end

if ( @revision_no = 1 )
begin
	select 			@confirm_date = IsNull ( max ( event_date ) , GetDate() )
	from 			film_campaign_event 
	where 			film_campaign_event.event_type = 'C'
	and 			film_campaign_event.campaign_no = @campaign_no

	select 			@revision_type = 1
end

select 			@confirm_cutover = IsNull ( max ( event_date ) , GetDate() )
from 			film_campaign_event 
where 			film_campaign_event.event_type = 'C'
and 			film_campaign_event.campaign_no = @campaign_no


if ( @revision_no != 1 )
begin
	select 			@confirm_date = GetDate()
end

if @revision_type = 1
begin
	select			@figure_type = 'C' --Confirmation figures
end
else
begin
	select			@figure_type = 'N' --Revision figures
end

select 			@accounting_period = min(end_date)
from 			accounting_period
where			status ='O'

/* Create temporary tables for latest values */

CREATE TABLE #work_revision 
(	
	flag 							char(3)		NOT NULL,
	campaign_no 					int 		NOT NULL, 
	confirmation_date 				datetime 	NULL, 
	transaction_type 				smallint 	NOT NULL,
	revenue_period 					datetime 	NOT NULL,
	screening_date 					datetime 	not NULL,
	cost 							numeric(38,16) 		NOT NULL,
	units 							int 		NOT NULL,
	avg_rate						numeric(38,32)	not null
)

CREATE TABLE #outpost_work_revision 
(	
	flag 							char(3)		NOT NULL,
	campaign_no 					int 		NOT NULL, 
	confirmation_date 				datetime 	NULL, 
	transaction_type 				smallint 	NOT NULL,
	revenue_period 					datetime 	NOT NULL,
	screening_date 					datetime 	not NULL,
	cost 							numeric(38,16) 		NOT NULL,
	units 							int 		NOT NULL,
	avg_rate						numeric(38,32)	not null
)

CREATE TABLE #work_deferred_revision 
(	
	flag 							char(3)		NOT NULL,
	campaign_no 					int 		NOT NULL, 
	confirmation_date 				datetime 	NULL, 
	transaction_type 				smallint 	NOT NULL,
	cost 							numeric(38,16) 		NOT NULL,
	units 							int 		NOT NULL,
	avg_rate						numeric(38,32)	not null
)

CREATE TABLE #outpost_deferred_work_revision 
(	
	flag 							char(3)		NOT NULL,
	campaign_no 					int 		NOT NULL, 
	confirmation_date 				datetime 	NULL, 
	transaction_type 				smallint 	NOT NULL,
	cost 							numeric(38,16) 		NOT NULL,
	units 							int 		NOT NULL,
	avg_rate						numeric(38,32)	not null
)

CREATE TABLE #delta_revision 
(
	revision_no 					int 		NULL,
	campaign_no 					int 		NOT NULL, 
	transaction_type 				smallint 	NOT NULL,
	revenue_period 					datetime 	NOT NULL,
	screening_date 					datetime 	not NULL,
	cost 							numeric(38,16) 		NOT NULL,
	units 							int 		NOT NULL,
	avg_rate						numeric(38,32)	not null
)

CREATE TABLE #outpost_delta_revision 
(
	revision_no 					int 		NULL,
	campaign_no 					int 		NOT NULL, 
	transaction_type 				smallint 	NOT NULL,
	revenue_period 					datetime 	NOT NULL,
	screening_date 					datetime 	not NULL,
	cost 							numeric(38,16) 		NOT NULL,
	units 							int 		NOT NULL,
	avg_rate						numeric(38,32)	not null
)

CREATE TABLE #delta_deferred_revision 
(
	revision_no 					int 		NULL,
	campaign_no 					int 		NOT NULL, 
	transaction_type 				smallint 	NOT NULL,
	cost 							numeric(38,16) 		NOT NULL,
	units 							int 		NOT NULL,
	avg_rate						numeric(38,32)	not null
)

CREATE TABLE #outpost_deferred_delta_revision 
(
	revision_no 					int 		NULL,
	campaign_no 					int 		NOT NULL, 
	transaction_type 				smallint 	NOT NULL,
	cost 							numeric(38,16) 		NOT NULL,
	units 							int 		NOT NULL,
	avg_rate						numeric(38,32)	not null
)

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Average Rates
 */

exec @error = p_statrev_create_campaign_avgs @campaign_no

if @error <> 0
begin
	raiserror ('Error updating campaign average rates', 16, 1)
	rollback transaction
	return -1
end
/*
 *
 * NORMAL Inserts to temporary tables 
 *
 */

/* 	1a. FILM NORMAL SPOTS  */

insert 			#work_revision
select			'NEW',
				campaign_no = campaign_spot.campaign_no,   
				confirmation_date = @confirm_date,
				transaction_type = 1,
				revenue_period = ( 	select			max(benchmark_end) 
									from 			film_screening_date_xref 
									where 			film_screening_date_xref.screening_date = campaign_spot.screening_date ) ,
				screening_date = campaign_spot.screening_date,   
				revenue = convert(numeric(38,16), sum(avg_rate)),
				units = count(*) ,   
				min(avg_rate)
from 			campaign_spot,
				campaign_package,
				statrev_spot_rates,
				film_campaign	
where 			campaign_package.package_id = campaign_spot.package_id
and				campaign_spot.campaign_no = @campaign_no 
and				((spot_status = 'A'
and				spot_type <> 'M'
and				spot_type <> 'V')
or				spot_status in ('X', 'R'))
and				spot_type <> 'R' 
and 			spot_type <> 'W'
and 			spot_type <> 'F'
and 			spot_type <> 'K'
and 			spot_type <> 'A'
and 			spot_type <> 'T'
and				statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and				statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and				campaign_package.campaign_no = film_campaign.campaign_no
and				revenue_group = 1
and				business_unit_id = 2
GROUP BY		campaign_spot.campaign_no,
				campaign_spot.screening_date


select			@error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film spots', 16, 1)
	rollback transaction
	return -1
end

/* 	1b. DMG NORMAL SPOTS  */

insert 		#work_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 4,
			revenue_period = ( 	select 	max(benchmark_end) 
								from 	film_screening_date_xref 
								where 	film_screening_date_xref.screening_date = campaign_spot.screening_date ) ,
			screening_date = campaign_spot.screening_date,   
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates,
			film_campaign
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and 		spot_type <> 'F'
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and			campaign_package.campaign_no = film_campaign.campaign_no
and			revenue_group = 2
and			business_unit_id = 3
GROUP BY 	campaign_spot.campaign_no,
			campaign_spot.screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg normal spots', 16, 1)
	rollback transaction
	return -1
end



/* 	1c. Showcase NORMAL SPOTS  */

insert 		#work_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 42,
			revenue_period = ( 	select 	max(benchmark_end) 
								from 	film_screening_date_xref 
								where 	film_screening_date_xref.screening_date = campaign_spot.screening_date ) ,
			screening_date = campaign_spot.screening_date,   
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates,
			film_campaign
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and 		spot_type <> 'F'
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and			campaign_package.campaign_no = film_campaign.campaign_no
and			revenue_group = 3
and			business_unit_id = 5
GROUP BY 	campaign_spot.campaign_no,
			campaign_spot.screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg normal spots', 16, 1)
	rollback transaction
	return -1
end

/* 1d. Cinelight NORMAL Spots */

insert 		#work_revision
select 		'NEW',
			campaign_no = cinelight_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 7,
			revenue_period = ( 	select 	max(benchmark_end) 
								from 	film_screening_date_xref 
								where 	film_screening_date_xref.screening_date = cinelight_spot.screening_date ) ,
			screening_date = cinelight_spot.screening_date,   
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		cinelight_spot,
			cinelight_package,
			statrev_spot_rates	
where 		cinelight_package.package_id = cinelight_spot.package_id
and			cinelight_spot.campaign_no = @campaign_no 
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and 		spot_type <> 'F'
and			statrev_spot_rates.campaign_no = dbo.f_spot_cl_redirect_backwards(cinelight_spot.campaign_no)
and			statrev_spot_rates.spot_id = cinelight_spot.spot_id
and			revenue_group = 4
GROUP BY 	cinelight_spot.campaign_no,
			cinelight_spot.screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinelight normal spots', 16, 1)
	rollback transaction
	return -1
end

/* 1e. Cinemarketing NORMAL Spots */

insert 		#work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 10, /* Cinemarketing SPOTS  */
			revenue_period = (	select 	max(benchmark_end) 
								from 	film_screening_date_xref 
								where 	film_screening_date_xref.screening_date = inclusion_spot.screening_date ),
			screening_date = inclusion_spot.screening_date,   
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		inclusion_spot,
			inclusion,
			statrev_spot_rates
where		inclusion.campaign_no = @campaign_no
and  		inclusion.inclusion_id = inclusion_spot.inclusion_id
and			inclusion_spot.spot_status != 'P'
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and 		spot_type <> 'F'
and 		spot_type <> 'T'
and			spot_type <> 'K'
and			spot_type <> 'A'
and 		inclusion.inclusion_type = 5
and			revenue_group = 5
and			statrev_spot_rates.campaign_no = inclusion_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_inc_redirect_backwards(inclusion_spot.spot_id)
GROUP BY 	inclusion_spot.campaign_no,
			inclusion_spot.screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinemarketing normal spots', 16, 1)
	rollback transaction
	return -1
end

/* 1f. Retail NORMAL Spots */

insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 100,  
			benchmark_end ,
			screening_date = outpost_spot.screening_date,   
			revenue = convert(numeric(38,16), no_days) * convert(numeric(38,16), sum(avg_rate)) / convert(numeric(38,16), 7),
			units = count(*) ,   
			min(avg_rate)
from 		outpost_spot,
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			statrev_spot_rates,
			outpost_screening_date_xref
where 		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.spot_status != 'P'
and 		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name = outpost_player_xref.player_name 
and			outpost_spot.screening_date = outpost_screening_date_xref.screening_date
and 		outpost_player.media_product_id = 9  
and			statrev_spot_rates.campaign_no = outpost_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id)
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and 		spot_type <> 'F'
and			revenue_group = 50 
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
GROUP BY 	outpost_spot.campaign_no,
			outpost_spot.screening_date,
            benchmark_end,
			no_days

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail normal spots', 16, 1)
	rollback transaction
	return -1
end

/* 1g. Retail Wall NORMAL Spots */

insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 103,
			benchmark_end ,
			screening_date = inclusion_spot.op_screening_date,   
			revenue = convert(numeric(38,16), no_days) * convert(numeric(38,16), sum(avg_rate)) / convert(numeric(38,16), 7),
			units = count(*) ,   
			min(avg_rate)
from 		inclusion_spot,
            outpost_screening_date_xref,
			statrev_spot_rates,
			inclusion
where 		inclusion_spot.campaign_no = @campaign_no
and         outpost_screening_date_xref.screening_date = inclusion_spot.op_screening_date
and  		statrev_spot_rates.spot_id =  dbo.f_spot_inc_redirect_backwards(inclusion_spot.spot_id)
and			statrev_spot_rates.campaign_no = inclusion_spot.campaign_no
and			inclusion_spot.spot_status != 'P'
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and 		spot_type <> 'F'
and 		inclusion.inclusion_type = 18
and			revenue_group = 51		
and			inclusion.inclusion_id = inclusion_spot.inclusion_id
GROUP BY 	inclusion_spot.campaign_no,
			inclusion_spot.op_screening_date,
            benchmark_end,
			no_days

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail Wall normal spots', 16, 1)
	rollback transaction
	return -1
end

/* 1h. Retail Super Wall NORMAL Spots */

insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 106,  
			benchmark_end ,
			screening_date = outpost_spot.screening_date,   
			revenue = convert(numeric(38,16), no_days) * convert(numeric(38,16), sum(avg_rate)) / convert(numeric(38,16), 7),
			units = count(*) ,   
			min(avg_rate)
from 		outpost_spot,
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			statrev_spot_rates,
			outpost_screening_date_xref
where 		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.spot_status != 'P'
and 		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name = outpost_player_xref.player_name 
and			outpost_spot.screening_date = outpost_screening_date_xref.screening_date
and 		outpost_player.media_product_id = 11  
and			statrev_spot_rates.campaign_no = outpost_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id)
and			revenue_group = 53 
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and 		spot_type <> 'F'
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
GROUP BY 	outpost_spot.campaign_no,
			outpost_spot.screening_date,
            benchmark_end,
			no_days

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail Super Wall normal spots', 16, 1)
	rollback transaction
	return -1
end

/* 1i. Petro NORMAL Spots */


insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 200,  
			benchmark_end ,
			screening_date = outpost_spot.screening_date,   
			revenue = convert(numeric(38,16), no_days) * convert(numeric(38,16), sum(avg_rate)) / convert(numeric(38,16), 7),
			units = count(*) ,   
			min(avg_rate)
from 		outpost_spot,
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			statrev_spot_rates,
			outpost_screening_date_xref
where 		outpost_spot.campaign_no = @campaign_no
and			outpost_spot.spot_status != 'P'
and 		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name = outpost_player_xref.player_name 
and			outpost_spot.screening_date = outpost_screening_date_xref.screening_date
and			outpost_player.media_product_id = 12  
and			statrev_spot_rates.campaign_no = outpost_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id)
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and 		spot_type <> 'F'
and			revenue_group = 100 
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
GROUP BY 	outpost_spot.campaign_no,
			outpost_spot.screening_date,
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
						transaction_type = 207,  
						benchmark_end ,
						screening_date = outpost_spot.screening_date,   
						revenue = convert(numeric(38,16), no_days) * convert(numeric(38,16), sum(avg_rate)) / convert(numeric(38,16), 7),
						units = count(*) ,   
						min(avg_rate)
from 			outpost_spot,
						outpost_panel,
						outpost_player_xref,
						outpost_player,
						statrev_spot_rates,
						outpost_screening_date_xref
where 		outpost_spot.campaign_no = @campaign_no
and 				outpost_spot.spot_status != 'P'
and 				outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 				outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 				outpost_player.player_name = outpost_player_xref.player_name 
and					outpost_spot.screening_date = outpost_screening_date_xref.screening_date
and 				outpost_player.media_product_id = 13  
and					statrev_spot_rates.campaign_no = outpost_spot.campaign_no
and					statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id)
and					spot_type <> 'R' 
and 				spot_type <> 'W'
and					revenue_group = 101 
and					((spot_status = 'A'
and					spot_type <> 'M'
and					spot_type <> 'V')
or						spot_status in ('X', 'R'))
GROUP BY 	outpost_spot.campaign_no,
						outpost_spot.screening_date,
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

insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 250,  
			benchmark_end ,
			screening_date = outpost_spot.screening_date,   
			revenue = convert(numeric(38,16), no_days) * convert(numeric(38,16), sum(avg_rate)) / convert(numeric(38,16), 7),
			units = count(*) ,   
			min(avg_rate)
from 		outpost_spot,
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			statrev_spot_rates,
			outpost_screening_date_xref
where 		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.spot_status != 'P'
and 		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name = outpost_player_xref.player_name 
and			outpost_spot.screening_date = outpost_screening_date_xref.screening_date
and 		outpost_player.media_product_id = 16  
and			statrev_spot_rates.campaign_no = outpost_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id)
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and 		spot_type <> 'F'
and			revenue_group = 150 
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
GROUP BY 	outpost_spot.campaign_no,
			outpost_spot.screening_date,
            benchmark_end,
			no_days							
							
select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail normal spots', 16, 1)
	rollback transaction
	return -1
end


/* 1l. TAP NORMAL Spots */
if @confirm_cutover > '14-aug-2018'
begin
	insert 			#work_revision
	select			'NEW',
					campaign_no = inclusion_spot.campaign_no,   
					confirmation_date = @confirm_date,
					case film_campaign.business_unit_id when 2 then 1 else 4 end,
					inclusion_spot.revenue_period,
					screening_date, 
					revenue = convert(numeric(38,16), sum(avg_rate)),
					units = count(*) ,   
					min(charge_rate)
	from 			inclusion_spot,
					inclusion,
					statrev_spot_rates,
					film_campaign
	where			inclusion.campaign_no = @campaign_no
	and				inclusion.campaign_no = film_campaign.campaign_no
	and  			inclusion.inclusion_id = inclusion_spot.inclusion_id
	and				inclusion_spot.spot_id = statrev_spot_rates.spot_id
	and				inclusion_spot.campaign_no = statrev_spot_rates.campaign_no
	and				inclusion_spot.spot_status != 'P'
	and				spot_type in ('F', 'K', 'A', 'T')
	and 			inclusion.inclusion_type in (24, 29,30,31,32)
	GROUP BY 		inclusion_spot.campaign_no,
					inclusion_spot.screening_date,
					inclusion_spot.revenue_period,
					film_campaign.business_unit_id

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting new Retail normal spots', 16, 1)
		rollback transaction
		return -1
	end
end
else 
begin
	insert 			#work_revision
	select 			'NEW',
					campaign_no = inclusion_spot.campaign_no,   
					confirmation_date = @confirm_date,
					case film_campaign.business_unit_id when 2 then 1 else 4 end, /* FF Aud & Roadblock SPOTS  */
					inclusion_spot.revenue_period,
					screening_date, 
					revenue = convert(numeric(38,16), sum(charge_rate)),
					units = count(*) ,   
					min(charge_rate)
	from 			inclusion_spot,
					inclusion, 
					film_campaign
	where			inclusion.campaign_no = @campaign_no
	and				inclusion.campaign_no = film_campaign.campaign_no
	and  			inclusion.inclusion_id = inclusion_spot.inclusion_id
	and				inclusion_spot.spot_status != 'P'
	and				spot_type in ('F', 'K', 'A', 'T')
	and 			inclusion.inclusion_type in (24, 29, 30, 31, 32)
	GROUP BY 		inclusion_spot.campaign_no,
					inclusion_spot.screening_date,
					inclusion_spot.revenue_period,
					film_campaign.business_unit_id

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting new Retail normal spots', 16, 1)
		rollback transaction
		return -1
	end
end
 

/* 1i. Petro EXTRA Spots */


insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 260,  
			benchmark_end ,
			screening_date = outpost_spot.screening_date,   
			revenue = convert(numeric(38,16), no_days) * convert(numeric(38,16), sum(avg_rate)) / convert(numeric(38,16), 7),
			units = count(*) ,   
			min(avg_rate)
from 		outpost_spot,
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			statrev_spot_rates,
			outpost_screening_date_xref
where 		outpost_spot.campaign_no = @campaign_no
and			outpost_spot.spot_status != 'P'
and 		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name = outpost_player_xref.player_name 
and			outpost_spot.screening_date = outpost_screening_date_xref.screening_date
and			outpost_player.media_product_id = 17
and			statrev_spot_rates.campaign_no = outpost_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id)
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and 		spot_type <> 'F'
and			revenue_group = 160 
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
GROUP BY 	outpost_spot.campaign_no,
			outpost_spot.screening_date,
			benchmark_end,
			no_days

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail normal spots', 16, 1)
	rollback transaction
	return -1
end

/* VM Digital */

insert 			#work_revision
select 			'NEW',
				campaign_no = inclusion_spot.campaign_no,   
				confirmation_date = @confirm_date,
				statrev_transaction_type.statrev_transaction_type,
				inclusion_spot.revenue_period,
				screening_date, 
				revenue = convert(numeric(38,16), sum(charge_rate)),
				units = count(*) ,   
				min(charge_rate)
from 			inclusion_spot
inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		film_campaign on inclusion_spot.campaign_no = film_campaign.campaign_no
inner join		inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
inner join		statrev_transaction_type on inclusion_type.media_product_id = statrev_transaction_type.media_product_id 
and				statrev_transaction_type.statrev_transaction_type_group_id = 1
where			inclusion.campaign_no = @campaign_no
and				((spot_status = 'A'
and				spot_type <> 'M'
and				spot_type <> 'V')
or				spot_status in ('X', 'R'))
and				spot_type <> 'R' 
and				spot_type <> 'W'
and				spot_type <> 'F'
and				spot_type <> 'K'
and				spot_type <> 'A'
and				spot_type <> 'T'
and 			inclusion.inclusion_type between 34 and 65
and				inclusion.inclusion_format = 'T'
GROUP BY 		inclusion_spot.campaign_no,
				inclusion_spot.screening_date,
				statrev_transaction_type.statrev_transaction_type,
				inclusion_spot.revenue_period,
				film_campaign.business_unit_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new VM Digital normal spots', 16, 1)
	rollback transaction
	return -1
end

/*
 * VM Digital Cancelled
 */

insert 			#work_revision
select 			'NEW',
				campaign_no = inclusion_spot.campaign_no,   
				confirmation_date = @confirm_date,
				statrev_transaction_type.statrev_transaction_type,
				inclusion_spot.revenue_period,
				screening_date, 
				revenue = convert(numeric(38,16), sum(charge_rate)),
				units = count(*) ,   
				min(charge_rate)
from 			inclusion_spot
inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		film_campaign on inclusion_spot.campaign_no = film_campaign.campaign_no
inner join		inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
inner join		statrev_transaction_type on inclusion_type.media_product_id = statrev_transaction_type.media_product_id 
and				statrev_transaction_type.statrev_transaction_type_group_id = 6
where			inclusion.campaign_no = @campaign_no
and				spot_status in ('C')
and				spot_type <> 'R' 
and				spot_type <> 'W'
and				dandc = 'N'
and 			inclusion.inclusion_type between 34 and 65
and				inclusion.inclusion_format = 'T'
GROUP BY 		inclusion_spot.campaign_no,
				inclusion_spot.screening_date,
				statrev_transaction_type.statrev_transaction_type,
				inclusion_spot.revenue_period,
				film_campaign.business_unit_id

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new VM Digital normal spots', 16, 1)
	rollback transaction
	return -1
end


/* 2a. Film TakeOut */

insert 		#work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 2, /* Film Takeout */
			inclusion_spot.revenue_period,
			screening_date = (select 	max(screening_date) 
				from 	film_screening_date_xref fdx, accounting_period acp
				where 	fdx.benchmark_end = acp.benchmark_end and acp.end_date = inclusion_spot.revenue_period),   
			cost = SUM ( inclusion_spot.takeout_rate * - 1),  
			units = count(*),
			0
from 		inclusion_spot, 
			inclusion, 
			film_campaign 
where		inclusion.campaign_no = @campaign_no
and			inclusion.campaign_no = film_campaign.campaign_no
and  		inclusion.inclusion_id = inclusion_spot.inclusion_id
and  		inclusion.include_revenue = 'Y' -- GB
and 		inclusion_spot.spot_status != 'P'
and 		inclusion.inclusion_category in ('F', 'D')
and			business_unit_id = 2
GROUP BY 	inclusion_spot.campaign_no,
			inclusion_spot.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film takeout spots', 16, 1)
	rollback transaction
	return -1
end

/* 2b. DMG TakeOut */

insert 		#work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 5, /* DMG Takeout */
			inclusion_spot.revenue_period ,
			screening_date = (select 	max(screening_date) 
							from 	film_screening_date_xref fdx, accounting_period acp
							where 	fdx.benchmark_end = acp.benchmark_end and acp.end_date = inclusion_spot.revenue_period),   
			cost = SUM ( inclusion_spot.takeout_rate * - 1),   
			units = count(*),
        	0
from 		inclusion_spot,
			inclusion,
			film_campaign
where		inclusion.campaign_no = @campaign_no
and			inclusion.campaign_no = film_campaign.campaign_no
and  		inclusion.inclusion_id = inclusion_spot.inclusion_id
and  		inclusion.include_revenue = 'Y' 
and			inclusion_spot.spot_status != 'P'
and 		inclusion.inclusion_category in ('F', 'D')
and			business_unit_id = 3
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


/* 2c. SHOWCASE TakeOut */

insert 		#work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 43, /* SHOWCASE Takeout */
			inclusion_spot.revenue_period ,
			screening_date = (select 	max(screening_date) 
							from 	film_screening_date_xref fdx, accounting_period acp
							where 	fdx.benchmark_end = acp.benchmark_end and acp.end_date = inclusion_spot.revenue_period),   
			cost = SUM ( inclusion_spot.takeout_rate * - 1),   
			units = count(*),
        	0
from 		inclusion_spot,
			inclusion,
			film_campaign
where		inclusion.campaign_no = @campaign_no
and			inclusion.campaign_no = film_campaign.campaign_no
and  		inclusion.inclusion_id = inclusion_spot.inclusion_id
and  		inclusion.include_revenue = 'Y' 
and			inclusion_spot.spot_status != 'P'
and 		inclusion.inclusion_category = 'D'
and			film_campaign.business_unit_id = 5
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

/* 2d. Cinelight TakeOut */

insert 		#work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 8, /* Cinelight Takeout */
			inclusion_spot.revenue_period,
			screening_date = (	select 	max(screening_date) 
								from 	film_screening_date_xref fdx, accounting_period acp
								where 	fdx.benchmark_end = acp.benchmark_end and acp.end_date = inclusion_spot.revenue_period),
			cost = SUM ( inclusion_spot.takeout_rate * - 1),   
			units = count(*),
			0
from 		inclusion_spot,
			inclusion 
where		inclusion.campaign_no = @campaign_no
and  		inclusion.inclusion_id = inclusion_spot.inclusion_id
and  		inclusion.include_revenue = 'Y' -- GB
and			inclusion_spot.spot_status != 'P'
and 		inclusion.inclusion_category = 'C'
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

/* 2e. Cinemarketing TakeOut */

insert 		#work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 16, /* Cinemarketing Takeout */
			inclusion_spot.revenue_period,
			screening_date = (select 	max(screening_date) 
							from 	film_screening_date_xref fdx, accounting_period acp
							where 	fdx.benchmark_end = acp.benchmark_end and acp.end_date = inclusion_spot.revenue_period),
			cost = SUM ( inclusion_spot.takeout_rate * - 1), 
			units = count(*),
			0
from 		inclusion_spot,
			inclusion 
where		inclusion.campaign_no = @campaign_no
and			inclusion_spot.spot_status != 'P'
and 		inclusion.inclusion_category = 'I'
and  		inclusion.include_revenue = 'Y' -- GB
and  		inclusion_spot.inclusion_id = inclusion.inclusion_id
GROUP BY 	inclusion_spot.campaign_no,
			inclusion_spot.revenue_period,
			inclusion_spot.screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinemarketing takeout', 16, 1)
	rollback transaction
	return -1
end

/* 2f. Retail TakeOut */

insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 101, /* Retail Takeout */
			inclusion_spot.revenue_period,
			screening_date = (select 	max(screening_date) 
							from 	outpost_screening_date_xref fdx, accounting_period acp
							where 	fdx.benchmark_end = acp.benchmark_end and acp.end_date = inclusion_spot.revenue_period),
			cost = SUM ( inclusion_spot.takeout_rate * - 1),   
			units = count(*),
			0
from 		inclusion_spot,
			inclusion 
where		inclusion.campaign_no = @campaign_no
and			inclusion_spot.spot_status != 'P'
and 		inclusion.inclusion_category = 'R'
and  		inclusion.include_revenue = 'Y'
and  		inclusion.inclusion_id = inclusion_spot.inclusion_id
GROUP BY 	inclusion_spot.campaign_no,
			inclusion_spot.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail takeouts', 16, 1)
	rollback transaction
	return -1
end


/* 2l. TAP Panel TakeOut */

insert 			#work_revision
select 			'NEW',
				campaign_no = inclusion_spot.campaign_no,   
				confirmation_date = @confirm_date,
				transaction_type = 53, 
				inclusion_spot.revenue_period,
				screening_date = (	select				max(screening_date) 
									from 				film_screening_date_xref fdx, accounting_period acp
									where 				fdx.benchmark_end = acp.benchmark_end 
									and					acp.end_date = inclusion_spot.revenue_period),
				cost = SUM ( inclusion_spot.takeout_rate * - 1), 
				units = count(*),
				0
from 			inclusion_spot,
				inclusion 
where			inclusion.campaign_no = @campaign_no
and				inclusion_spot.spot_status != 'P'
and 			inclusion.inclusion_category = 'T'
and  			inclusion.include_revenue = 'Y' 
and  			inclusion_spot.inclusion_id = inclusion.inclusion_id
GROUP BY 		inclusion_spot.campaign_no,
				inclusion_spot.revenue_period,
				inclusion_spot.screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new TAP takeout', 16, 1)
	rollback transaction
	return -1
end

/* 2m. VM Digital TakeOut */

insert 			#work_revision
select			'NEW',
				campaign_no = inclusion_spot.campaign_no,   
				confirmation_date = @confirm_date,
				statrev_transaction_type.statrev_transaction_type,
				inclusion_spot.revenue_period,
				screening_date = (	select			max(screening_date) 
									from 			film_screening_date_xref fdx, accounting_period acp
									where 			fdx.benchmark_end = acp.benchmark_end 
									and				acp.end_date = inclusion_spot.revenue_period),   
				cost = SUM ( inclusion_spot.takeout_rate * - 1),  
				units = count(*),
				0
from 			inclusion_spot
inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		film_campaign on inclusion_spot.campaign_no = inclusion.campaign_no and inclusion.campaign_no = film_campaign.campaign_no
inner join		inclusion_category on inclusion.inclusion_category = inclusion_category.inclusion_category
inner join		statrev_transaction_type on inclusion_category.media_product_id = statrev_transaction_type.media_product_id
and				statrev_transaction_type.statrev_transaction_type_group_id = 2
where			inclusion.campaign_no = @campaign_no
and				inclusion.include_revenue = 'Y' 
and		 		inclusion_spot.spot_status != 'P'
and 			inclusion.inclusion_category in ('A', 'B', 'E', 'H', 'J', 'K', 'L', 'N', 'O') 
GROUP BY 		inclusion_spot.campaign_no,
				statrev_transaction_type.statrev_transaction_type,
				inclusion_spot.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film takeout spots', 16, 1)
	rollback transaction
	return -1
end

/* 3a. FILM Billing Credits */

insert 		#work_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 3, /* Billing Credits And Bad Debts */
			revenue_period = benchmark_end ,
			screening_date = (select 	max(screening_date) 
							from 	film_screening_date_xref fdx
							where 	fdx.benchmark_end = accounting_period.benchmark_end ),   
			cost = sum ( spot_liability.spot_amount ),   
			units = 1 ,
			 0
from 		campaign_spot,
			spot_liability,
			accounting_period,
			film_campaign 
where		campaign_spot.campaign_no = @campaign_no
and			accounting_period.end_date = spot_liability.creation_period
and 		campaign_spot.spot_status != 'P'
and 		spot_liability.liability_type in (7,8,36)
and			business_unit_id = 2
and 		campaign_spot.spot_id  = spot_liability.spot_id
and			film_campaign.campaign_no = campaign_spot.campaign_no
GROUP BY	campaign_spot.campaign_no,
			benchmark_end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 3b. DMG Billing Credits */

insert 		#work_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 6, /* Billing Credits And Bad Debts */
			revenue_period = benchmark_end ,
			screening_date = (select 	max(screening_date) 
							from 	film_screening_date_xref fdx
							where 	fdx.benchmark_end = accounting_period.benchmark_end ),   
			cost = sum ( spot_liability.spot_amount ),   
			units = 1 ,
			 0
from 		campaign_spot,
			spot_liability,
			accounting_period,
			film_campaign 
where		campaign_spot.campaign_no = @campaign_no
and			accounting_period.end_date = spot_liability.creation_period
and 		campaign_spot.spot_status != 'P'
and 		spot_liability.liability_type in (7,8,36)
and			business_unit_id = 3
and 		campaign_spot.spot_id  = spot_liability.spot_id
and			film_campaign.campaign_no = campaign_spot.campaign_no
GROUP BY	campaign_spot.campaign_no,
			benchmark_end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg billing credits', 16, 1)
	rollback transaction
	return -1
end



/* 3c. SHOWCASE Billing Credits */

insert 		#work_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 44, /* Billing Credits And Bad Debts */
			revenue_period = benchmark_end ,
			screening_date = (select 	max(screening_date) 
							from 	film_screening_date_xref fdx
							where 	fdx.benchmark_end = accounting_period.benchmark_end ),   
			cost = sum ( spot_liability.spot_amount ),   
			units = 1 ,
			 0
from 		campaign_spot,
			spot_liability,
			accounting_period,
			film_campaign 
where		campaign_spot.campaign_no = @campaign_no
and			accounting_period.end_date = spot_liability.creation_period
and 		campaign_spot.spot_status != 'P'
and 		spot_liability.liability_type in (7,8,36)
and			business_unit_id = 5
and 		campaign_spot.spot_id  = spot_liability.spot_id
and			film_campaign.campaign_no = campaign_spot.campaign_no
GROUP BY	campaign_spot.campaign_no,
			benchmark_end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 3d. Cinelight Billing Credits */

insert 		#work_revision
select 		'NEW',
			campaign_no = cinelight_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 9, /* Cinelight Billing Credits  */
			revenue_period = benchmark_end,
			screening_date =( 	select 	max ( screening_date ) 
								from 	film_screening_date_xref fdx
								where 	fdx.benchmark_end = acp.benchmark_end ),   
			cost = sum ( cinelight_spot_liability.spot_amount ),   
			units = 1 ,
			0
from 		cinelight_spot,
			cinelight_spot_liability,
			accounting_period acp
where		cinelight_spot.campaign_no = @campaign_no
and			acp.end_date = cinelight_spot_liability.creation_period
and 		cinelight_spot.spot_status != 'P'
and 		cinelight_spot_liability.liability_type = 13
and 		cinelight_spot.spot_id  = cinelight_spot_liability.spot_id
GROUP BY 	cinelight_spot.campaign_no,
			acp.benchmark_end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinelight billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 3e. Cinemarketing Billing Credits */

insert 		#work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 11, /* Cinemarketing Billing Credits  */
			revenue_period = benchmark_end,
			screening_date = (	select 	max ( screening_date ) 
								from 	film_screening_date_xref fdx
								where 	fdx.benchmark_end = acp.benchmark_end),   
			cost = sum ( inclusion_spot_liability.spot_amount ),   
			units = 1 ,
			0
from 		inclusion_spot,
			inclusion_spot_liability,
			accounting_period acp
where		inclusion_spot.campaign_no = @campaign_no
and			acp.end_date = inclusion_spot_liability.creation_period
and 		inclusion_spot.spot_status != 'P'
and 		inclusion_spot_liability.liability_type = 16
and 		inclusion_spot.spot_id  = inclusion_spot_liability.spot_id
GROUP BY 	inclusion_spot.campaign_no,
			acp.benchmark_end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinemarketing billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 3f. Retail Billing Credits */

insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 102, /* Retail Billing Credits  */
			revenue_period = benchmark_end,
			screening_date =( select 	max ( screening_date ) 
							from 	outpost_screening_date_xref fdx
							where	fdx.benchmark_end = acp.benchmark_end),   
			cost = sum ( outpost_spot_liability.spot_amount ),   
			units = 1 ,
			0
from 		outpost_spot,   
			outpost_spot_liability, 
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			accounting_period acp
where		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.spot_status != 'P'
and 		outpost_spot_liability.liability_type in (152,161)
and 		outpost_spot.spot_id  = outpost_spot_liability.spot_id
and 		outpost_spot.outpost_panel_id 	= outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id 	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name  	= outpost_player_xref.player_name 
and 		outpost_player.media_product_id = 9  
and			acp.end_date = outpost_spot_liability.creation_period
GROUP BY 	outpost_spot.campaign_no,
			acp.benchmark_end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 3p. Petro Billing Credits */

insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 202, /* Petro Billing Credits  */
			revenue_period = benchmark_end,
			screening_date =( select 	max ( screening_date ) 
							from 	outpost_screening_date_xref fdx
							where	fdx.benchmark_end = acp.benchmark_end),   
			cost = sum ( outpost_spot_liability.spot_amount ),   
			units = 1 ,
			0
from 		outpost_spot,   
			outpost_spot_liability, 
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			accounting_period acp
where		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.spot_status != 'P'
and 		outpost_spot_liability.liability_type in (152,161)
and 		outpost_spot.spot_id  = outpost_spot_liability.spot_id
and 		outpost_spot.outpost_panel_id 	= outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id 	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name  	= outpost_player_xref.player_name 
and 		outpost_player.media_product_id in (12,13,17)
and			acp.end_date = outpost_spot_liability.creation_period
GROUP BY 	outpost_spot.campaign_no,
			acp.benchmark_end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail billing credits', 16, 1)
	rollback transaction
	return -1
end



/* 3g. Retail Wall Billing Credits */  

insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 105, /* Retail Billing Credits  */
			revenue_period = benchmark_end,
			screening_date =( select 	max ( screening_date ) 
							from 	outpost_screening_date_xref fdx
							where	fdx.benchmark_end = acp.benchmark_end),   
			cost = sum ( outpost_spot_liability.spot_amount ),   
			units = 1 ,
			0
from 		outpost_spot,
			outpost_spot_liability,
			accounting_period acp
where		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.spot_status != 'P'
and			acp.end_date = outpost_spot_liability.creation_period
and 		outpost_spot_liability.liability_type = 156
and 		outpost_spot.spot_id  = outpost_spot_liability.spot_id
and 		acp.end_date = outpost_spot_liability.creation_period
GROUP BY 	outpost_spot.campaign_no,
			acp.benchmark_end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail Wall billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 3h. Retail Super Wall Billing Credits */

insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 108, /* Retail Billing Credits  */
			revenue_period = benchmark_end,
			screening_date =( select 	max ( screening_date ) 
							from 	outpost_screening_date_xref fdx
							where	fdx.benchmark_end = acp.benchmark_end ),   
			cost = sum ( outpost_spot_liability.spot_amount ),   
			units = 1 ,
			0
from 		outpost_spot,   
			outpost_spot_liability,
			outpost_panel,
			outpost_player_xref,
			outpost_player, 
			accounting_period acp
where		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.spot_status != 'P'
and 		outpost_spot_liability.liability_type in (152,161)
and 		outpost_spot.spot_id  = outpost_spot_liability.spot_id
and 		outpost_spot.outpost_panel_id 	= outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id 	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name  	= outpost_player_xref.player_name 
and 		outpost_player.media_product_id in (11,16)
and 		acp.end_date = outpost_spot_liability.creation_period
GROUP BY 	outpost_spot.campaign_no,
			acp.benchmark_end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail Super Wall billing credits', 16, 1)
	rollback transaction
	return -1
end


/* 3a. VM Digital Billing Credits */

insert 			#work_revision
select			'NEW',
				campaign_no = inclusion_spot.campaign_no,   
				confirmation_date = @confirm_date,
				statrev_transaction_type.statrev_transaction_type, 
				revenue_period = benchmark_end ,
				screening_date = (select 	max(screening_date) 
								from 	film_screening_date_xref fdx
								where 	fdx.benchmark_end = accounting_period.benchmark_end ),   
				cost = sum ( inclusion_spot_liability.spot_amount ),   
				units = 1 ,
				0
from 			inclusion_spot
inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
inner join		inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
inner join		inclusion_spot_liability on inclusion_spot.spot_id  = inclusion_spot_liability.spot_id
inner join		accounting_period on inclusion_spot_liability.creation_period = accounting_period.end_date
inner join		film_campaign on inclusion_spot.campaign_no = film_campaign.campaign_no
inner join		statrev_transaction_type on inclusion_type.media_product_id = statrev_transaction_type.media_product_id
and				statrev_transaction_type.statrev_transaction_type_group_id = 3
where			inclusion_spot.campaign_no = @campaign_no
and 			inclusion_spot.spot_status != 'P'
and 			inclusion_spot_liability.liability_type in (172)
GROUP BY		inclusion_spot.campaign_no,
				statrev_transaction_type.statrev_transaction_type, 
				benchmark_end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 4. Agency Direct Showcase Misc */

insert 		#work_revision
select 		'NEW',
			campaign_no = inclusion.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 12, /* Misc */
			inclusion.revenue_period,
			screening_date = (select 	max(screening_date) 
							from 	film_screening_date_xref fdx, accounting_period acp
							where 	fdx.benchmark_end = acp.benchmark_end and acp.end_date = inclusion.revenue_period),
			cost = isnull(SUM ((inclusion.inclusion_qty * inclusion.inclusion_charge) - inclusion.vm_cost_amount) , 0),  
			units = 0,
			0 
from 		inclusion 
where		inclusion.campaign_no = @campaign_no
and  		inclusion.inclusion_category = 'S'
and 		inclusion.inclusion_format = 'S'
and  		inclusion.include_revenue = 'Y'
and			inclusion.campaign_no in (select campaign_no from film_campaign where business_unit_id IN (2,3,5) and campaign_no = @campaign_no)
GROUP BY 	inclusion.campaign_no,
			inclusion.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new miscellanous', 16, 1)
	rollback transaction
	return -1
end

/* 4. VM Digital Misc */

insert 		#work_revision
select 		'NEW',
			campaign_no = inclusion.campaign_no,   
			confirmation_date = @confirm_date,
			statrev_transaction_type.statrev_transaction_type,
			inclusion.revenue_period,
			screening_date = (select 	max(screening_date) 
							from 	film_screening_date_xref fdx, accounting_period acp
							where 	fdx.benchmark_end = acp.benchmark_end and acp.end_date = inclusion.revenue_period),
			cost = isnull(SUM ((inclusion.inclusion_qty * inclusion.inclusion_charge) - inclusion.vm_cost_amount) , 0),  
			units = 0,
			0 
from 		inclusion 
inner join	inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
inner join	statrev_transaction_type on inclusion_type.media_product_id = statrev_transaction_type.media_product_id
and			statrev_transaction_type.statrev_transaction_type_group_id = 1
where		inclusion.campaign_no = @campaign_no
and  		inclusion.inclusion_category = 'S'
and 		inclusion.inclusion_format = 'S'
and  		inclusion.include_revenue = 'Y'
and			inclusion.campaign_no in (select campaign_no from film_campaign where business_unit_id IN (11) and campaign_no = @campaign_no)
GROUP BY 	inclusion.campaign_no,
			statrev_transaction_type.statrev_transaction_type,
			inclusion.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new miscellanous', 16, 1)
	rollback transaction
	return -1
end

/* Retail Misc */
insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = inclusion.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 121, /* Misc */
			inclusion.revenue_period,
			screening_date = (select 	max(screening_date) 
							from 	outpost_screening_date_xref fdx, accounting_period acp
							where 	fdx.benchmark_end = acp.benchmark_end and acp.end_date = inclusion.revenue_period),
			cost = isnull(SUM ((inclusion.inclusion_qty * inclusion.inclusion_charge) - inclusion.vm_cost_amount) , 0),  
			units = 0,
			0 
from 		inclusion 
where		inclusion.campaign_no = @campaign_no
and  		inclusion.inclusion_category = 'S'
and 		inclusion.inclusion_format = 'S'
and  		inclusion.include_revenue = 'Y'
and			inclusion.campaign_no in (select campaign_no from film_campaign where business_unit_id IN (6) and campaign_no = @campaign_no)
GROUP BY 	inclusion.campaign_no,
			inclusion.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new miscellanous', 16, 1)
	rollback transaction
	return -1
end

/* Petro Misc */
insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = inclusion.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 214, /* Misc */
			inclusion.revenue_period,
			screening_date = (select 	max(screening_date) 
							from 	outpost_screening_date_xref fdx, accounting_period acp
							where 	fdx.benchmark_end = acp.benchmark_end and acp.end_date = inclusion.revenue_period),
			cost = isnull(SUM ((inclusion.inclusion_qty * inclusion.inclusion_charge) - inclusion.vm_cost_amount) , 0),  
			units = 0,
			0 
from 		inclusion 
where		inclusion.campaign_no = @campaign_no
and  		inclusion.inclusion_category = 'S'
and 		inclusion.inclusion_format = 'S'
and  		inclusion.include_revenue = 'Y'
and			inclusion.campaign_no in (select campaign_no from film_campaign where business_unit_id IN (7) and campaign_no = @campaign_no)
GROUP BY 	inclusion.campaign_no,
			inclusion.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new miscellanous', 16, 1)
	rollback transaction
	return -1
end

/* Tower TV Misc */
insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = inclusion.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 257, /* Misc */
			inclusion.revenue_period,
			screening_date = (select 	max(screening_date) 
							from 	outpost_screening_date_xref fdx, accounting_period acp
							where 	fdx.benchmark_end = acp.benchmark_end and acp.end_date = inclusion.revenue_period),
			cost = isnull(SUM ((inclusion.inclusion_qty * inclusion.inclusion_charge) - inclusion.vm_cost_amount) , 0),  
			units = 0,
			0 
from 		inclusion 
where		inclusion.campaign_no = @campaign_no
and  		inclusion.inclusion_category = 'S'
and 		inclusion.inclusion_format = 'S'
and  		inclusion.include_revenue = 'Y'
and			inclusion.campaign_no in (select campaign_no from film_campaign where business_unit_id IN (8) and campaign_no = @campaign_no)
GROUP BY 	inclusion.campaign_no,
			inclusion.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new miscellanous', 16, 1)
	rollback transaction
	return -1
end

/* CINEads Misc */
insert 		#work_revision
select 		'NEW',
			campaign_no = inclusion.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 66, /* Misc */
			inclusion.revenue_period,
			screening_date = (select 	max(screening_date) 
							from 	film_screening_date_xref fdx, accounting_period acp
							where 	fdx.benchmark_end = acp.benchmark_end and acp.end_date = inclusion.revenue_period),
			cost = isnull(SUM ((inclusion.inclusion_qty * inclusion.inclusion_charge) - inclusion.vm_cost_amount) , 0),  
			units = 0,
			0 
from 		inclusion 
where		inclusion.campaign_no = @campaign_no
and  		inclusion.inclusion_category = 'S'
and 		inclusion.inclusion_format = 'S'
and  		inclusion.include_revenue = 'Y'
and			inclusion.campaign_no in (select campaign_no from film_campaign where business_unit_id IN (9) and campaign_no = @campaign_no)
GROUP BY 	inclusion.campaign_no,
			inclusion.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new miscellanous', 16, 1)
	rollback transaction
	return -1
end

/* 5a. FILM Cancelled SPOTS  */


insert 		#work_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 34,
			revenue_period = ( 	select 	max(benchmark_end) 
								from 	film_screening_date_xref 
								where 	film_screening_date_xref.screening_date = campaign_spot.billing_date ) ,
			screening_date = campaign_spot.billing_date,   
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates,
			film_campaign	
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			spot_status in ('C')
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and			dandc = 'N'
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and			campaign_package.campaign_no = film_campaign.campaign_no
and			revenue_group = 1
and			business_unit_id = 2
GROUP BY 	campaign_spot.campaign_no,
			campaign_spot.billing_date


select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film spots', 16, 1)
	rollback transaction
	return -1
end


/* 	5b. DMG Cancelled SPOTS  */

insert 		#work_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 35,
			revenue_period = ( 	select 	max(benchmark_end) 
								from 	film_screening_date_xref 
								where 	film_screening_date_xref.screening_date = campaign_spot.billing_date ) ,
			screening_date = campaign_spot.billing_date,   
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates,
			film_campaign
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			spot_status in ('C')
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and			dandc = 'N'
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and			campaign_package.campaign_no = film_campaign.campaign_no
and			revenue_group = 2
and			business_unit_id = 3
GROUP BY 	campaign_spot.campaign_no,
			campaign_spot.billing_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg normal spots', 16, 1)
	rollback transaction
	return -1
end

/* 	5c. SHOWCASE Cancelled SPOTS  */

insert 		#work_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 50,
			revenue_period = ( 	select 	max(benchmark_end) 
								from 	film_screening_date_xref 
								where 	film_screening_date_xref.screening_date = campaign_spot.billing_date ) ,
			screening_date = campaign_spot.billing_date,   
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates,
			film_campaign
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			spot_status in ('C')
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and			dandc = 'N'
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and			campaign_package.campaign_no = film_campaign.campaign_no
and			revenue_group = 3
and			business_unit_id = 5
GROUP BY 	campaign_spot.campaign_no,
			campaign_spot.billing_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg normal spots', 16, 1)
	rollback transaction
	return -1
end

/* 5d. Cinelight Cancelled Spots */

insert 		#work_revision
select 		'NEW',
			campaign_no = cinelight_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 36,
			revenue_period = ( 	select 	max(benchmark_end) 
								from 	film_screening_date_xref 
								where 	film_screening_date_xref.screening_date = cinelight_spot.billing_date ) ,
			screening_date = cinelight_spot.billing_date,   
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		cinelight_spot,
			cinelight_package,
			statrev_spot_rates	
where 		cinelight_package.package_id = cinelight_spot.package_id
and			cinelight_spot.campaign_no = @campaign_no 
and			spot_status in ('C')
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and			dandc = 'N'
and			statrev_spot_rates.campaign_no = cinelight_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_cl_redirect_backwards(cinelight_spot.spot_id)
and			revenue_group = 4
GROUP BY 	cinelight_spot.campaign_no,
			cinelight_spot.billing_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinelight normal spots', 16, 1)
	rollback transaction
	return -1
end


/* 5e. Cinemarketing Cancelled SPOTS */

insert 		#work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 37, /* Cinemarketing SPOTS  */
			revenue_period = (	select 	max(benchmark_end) 
								from 	film_screening_date_xref 
								where 	film_screening_date_xref.screening_date = inclusion_spot.billing_date ),
			screening_date = inclusion_spot.billing_date,   
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		inclusion_spot,
			inclusion,
			statrev_spot_rates
where		inclusion.campaign_no = @campaign_no
and  		inclusion.inclusion_id = inclusion_spot.inclusion_id
and			inclusion_spot.spot_status != 'P'
and			spot_status in ('C')
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and			dandc = 'N'
and 		inclusion.inclusion_type = 5
and			revenue_group = 5
and			statrev_spot_rates.campaign_no = dbo.f_spot_inc_redirect_backwards(inclusion_spot.campaign_no)
and			statrev_spot_rates.spot_id = inclusion_spot.spot_id
GROUP BY 	inclusion_spot.campaign_no,
			inclusion_spot.billing_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinemarketing normal spots', 16, 1)
	rollback transaction
	return -1
end

/* 5f. Retail Cancelled Spots */

insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 115,  
			benchmark_end ,
			screening_date = outpost_spot.billing_date,   
			revenue = (no_days / 7) * (convert(numeric(38,16), sum(avg_rate))),
			units = count(*) ,   
			min(avg_rate)
from 		outpost_spot,
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			statrev_spot_rates,
			outpost_screening_date_xref
where 		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.spot_status != 'P'
and 		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name = outpost_player_xref.player_name 
and			outpost_spot.billing_date = outpost_screening_date_xref.screening_date
and 		outpost_player.media_product_id = 9  
and			statrev_spot_rates.campaign_no = dbo.f_spot_op_redirect_backwards(outpost_spot.campaign_no)
and			statrev_spot_rates.spot_id = outpost_spot.spot_id
and			revenue_group = 50 
and			spot_status in ('C')
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and			dandc = 'N'
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

/* 5g. Retail Wall Cancelled Spots */

insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 116,
			benchmark_end ,
			screening_date = inclusion_spot.op_screening_date,   
			revenue = (no_days / 7) * convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		inclusion_spot,
            outpost_screening_date_xref,
			statrev_spot_rates,
			inclusion
where 		inclusion_spot.campaign_no = @campaign_no
and         outpost_screening_date_xref.screening_date = inclusion_spot.op_screening_date
and  		inclusion.inclusion_id = inclusion_spot.inclusion_id
and			inclusion_spot.spot_status != 'P'
and			spot_status in ('C')
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and			dandc = 'N'
and 		inclusion.inclusion_type = 18
and			statrev_spot_rates.campaign_no = inclusion_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_inc_redirect_backwards(inclusion_spot.spot_id)
and			revenue_group = 51		
GROUP BY 	inclusion_spot.campaign_no,
			inclusion_spot.op_screening_date,
            benchmark_end,
			no_days

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail Wall normal spots', 16, 1)
	rollback transaction
	return -1
end

/* 5h. Retail Super Wall Cancelled Spots */

insert 		#outpost_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 117,  
			benchmark_end ,
			screening_date = outpost_spot.billing_date,   
			revenue = (no_days / 7) * (convert(numeric(38,16), sum(avg_rate))),
			units = count(*) ,   
			min(avg_rate)
from 		outpost_spot,
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			statrev_spot_rates,
			outpost_screening_date_xref
where 		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.spot_status != 'P'
and 		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name = outpost_player_xref.player_name 
and			outpost_spot.billing_date = outpost_screening_date_xref.screening_date
and 		outpost_player.media_product_id = 11  
and			statrev_spot_rates.campaign_no = outpost_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id)
and			revenue_group = 53 
and			spot_status in ('C')
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and			dandc = 'N'
GROUP BY 	outpost_spot.campaign_no,
			outpost_spot.billing_date,
            benchmark_end,
			no_days

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail Super Wall normal spots', 16, 1)
	rollback transaction
	return -1
end


/*
 *
 * DEFERRED Inserts to temporary tables
 *
 */

/* 	6a. FILM Unallocated & Active Makeups SPOTS  */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 26,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates,
			film_campaign	
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			((spot_status = 'A'
and			(spot_type = 'M'
or			spot_type = 'V')
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id))
or			(spot_status in ('U', 'N')
and			spot_redirect is null)
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id))
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			revenue_group = 1
and			business_unit_id = 2
and			campaign_package.campaign_no = film_campaign.campaign_no
and			dandc = 'N'
GROUP BY 	campaign_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/* 	6b. DMG Unallocated & Active Makeups SPOTS  */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 27,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates	,
			film_campaign
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			((spot_status = 'A'
and			(spot_type = 'M'
or			spot_type = 'V')
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id))
or			(spot_status in ('U', 'N')
and			spot_redirect is null)
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id))
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			revenue_group = 2
and			business_unit_id = 3
and			campaign_package.campaign_no = film_campaign.campaign_no
and			dandc = 'N'
GROUP BY 	campaign_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/* 	6c. SHOWCASE Unallocated & Active Makeups SPOTS  */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 48,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates	,
			film_campaign
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			((spot_status = 'A'
and			(spot_type = 'M'
or			spot_type = 'V')
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id))
or			(spot_status in ('U', 'N')
and			spot_redirect is null)
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id))
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			revenue_group = 3
and			business_unit_id = 5
and			campaign_package.campaign_no = film_campaign.campaign_no
and			dandc = 'N'
GROUP BY 	campaign_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new SHOWCASE unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/* 	6d. Cinelight Unallocated & Active Makeups SPOTS  */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = cinelight_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 28,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		cinelight_spot,
			cinelight_package,
			statrev_spot_rates	
where 		cinelight_package.package_id = cinelight_spot.package_id
and			cinelight_spot.campaign_no = @campaign_no 
and			((spot_status = 'A'
and			(spot_type = 'M'
or			spot_type = 'V')
and			statrev_spot_rates.spot_id = dbo.f_spot_cl_redirect_backwards(cinelight_spot.spot_id))
or			(spot_status in ('U', 'N')
and			spot_redirect is null)
and			statrev_spot_rates.spot_id = dbo.f_spot_cl_redirect_backwards(cinelight_spot.spot_id))
and			statrev_spot_rates.campaign_no = cinelight_spot.campaign_no
and			revenue_group = 4
and			media_product_id = 3
and			dandc = 'N'
GROUP BY 	cinelight_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinelight unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/*  6e. Cinemarketing Unallocated & Acvtive Makeup Spots   */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 29,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		inclusion_spot,
			inclusion,
			statrev_spot_rates	
where 		inclusion.inclusion_id = inclusion_spot.inclusion_id
and			inclusion_spot.campaign_no = @campaign_no 
and			((spot_status = 'A'
and			(spot_type = 'M'
or			spot_type = 'V')
and			statrev_spot_rates.spot_id = dbo.f_spot_inc_redirect_backwards(inclusion_spot.spot_id))
or			(spot_status in ('U', 'N')
and			spot_redirect is null)
and			statrev_spot_rates.spot_id = dbo.f_spot_inc_redirect_backwards(inclusion_spot.spot_id))
and			statrev_spot_rates.campaign_no = inclusion_spot.campaign_no
and 		inclusion.inclusion_type = 5
and			revenue_group = 5
and			dandc = 'N'
GROUP BY 	inclusion_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinemarketing unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/* 6f. Retail Unallocated Spots */

insert 		#outpost_deferred_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 109,  
			revenue = (convert(numeric(38,16), sum(avg_rate))),
			units = count(*) ,   
			min(avg_rate)
from 		outpost_spot,
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			statrev_spot_rates
where 		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.spot_status != 'P'
and 		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name = outpost_player_xref.player_name 
and 		outpost_player.media_product_id = 9  
and			revenue_group = 50 
and			((spot_status = 'A'
and			(spot_type = 'M'
or			spot_type = 'V')
and			statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id))
or			(spot_status in ('U', 'N')
and			spot_redirect is null)
and			statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id))
and			statrev_spot_rates.campaign_no = outpost_spot.campaign_no
and			dandc = 'N'
GROUP BY 	outpost_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/* 6g. Retail Moving Wall Unallocated Spots */

insert 		#outpost_deferred_work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 110,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		inclusion_spot,
			statrev_spot_rates,
			inclusion
where 		inclusion_spot.campaign_no = @campaign_no
and  		inclusion.inclusion_id = inclusion_spot.inclusion_id
and			inclusion_spot.spot_status != 'P'
and			((spot_status = 'A'
and			(spot_type = 'M'
or			spot_type = 'V')
and			statrev_spot_rates.spot_id = dbo.f_spot_inc_redirect_backwards(inclusion_spot.spot_id))
or			(spot_status in ('U', 'N')
and			spot_redirect is null)
and			statrev_spot_rates.spot_id = dbo.f_spot_inc_redirect_backwards(inclusion_spot.spot_id))
and			statrev_spot_rates.campaign_no = inclusion_spot.campaign_no
and 		inclusion.inclusion_type = 18
and			revenue_group = 51		
and			dandc = 'N'
GROUP BY 	inclusion_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail Wall unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/* 6h. Retail Super Wall Unallocated Spots */

insert 		#outpost_deferred_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 111,  
			revenue = (convert(numeric(38,16), sum(avg_rate))),
			units = count(*) ,   
			min(avg_rate)
from 		outpost_spot,
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			statrev_spot_rates
where 		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.spot_status != 'P'
and 		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name = outpost_player_xref.player_name 
and 		outpost_player.media_product_id = 11  
and			revenue_group = 53 
and			((spot_status = 'A'
and			(spot_type = 'M'
or			spot_type = 'V')
and			statrev_spot_rates.spot_id = dbo.f_spot_inc_redirect_backwards(outpost_spot.spot_id))
or			(spot_status in ('U', 'N')
and			spot_redirect is null)
and			statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id))
and			statrev_spot_rates.campaign_no = outpost_spot.campaign_no
and			dandc = 'N'
GROUP BY 	outpost_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail Super Wall unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/* 	7a. FILM Unassigned D&C SPOTS  */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 30,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates	,
			film_campaign
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			spot_status in ('C', 'U', 'N')
and			dandc = 'Y'
and			campaign_spot.spot_id not in (select 	spot_id 
							from 	delete_charge_spots, 
									delete_charge
							where	delete_charge.delete_charge_id = delete_charge_spots.delete_charge_id
							and		delete_charge_spots.source_dest = 'S'
							and		delete_charge.source_campaign = campaign_spot.campaign_no
							and		delete_charge.confirmed = 'Y')
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and			revenue_group = 1
and			business_unit_id = 2
and			spot_type <> 'R'
and			spot_type <> 'W'
and			campaign_package.campaign_no = film_campaign.campaign_no
GROUP BY 	campaign_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film D&C spots', 16, 1)
	rollback transaction
	return -1
end

/* 	7b. DMG Unassigned D&C SPOTS  */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 31,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates,
			film_campaign
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			spot_status in ('C', 'U', 'N')
and			dandc = 'Y'
and			campaign_spot.spot_id not in (select 	spot_id 
							from 	delete_charge_spots, 
									delete_charge
							where	delete_charge.delete_charge_id = delete_charge_spots.delete_charge_id
							and		delete_charge_spots.source_dest = 'S'
							and		delete_charge.source_campaign = campaign_spot.campaign_no
							and		delete_charge.confirmed = 'Y')
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and			revenue_group = 2
and			spot_type <> 'R'
and			spot_type <> 'W'
and			business_unit_id = 3
and			campaign_package.campaign_no = film_campaign.campaign_no
GROUP BY 	campaign_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg D&C spots', 16, 1)
	rollback transaction
	return -1
end

/* 	2b. SHOWCASE Unassigned D&C SPOTS  */
insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 49,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates,
			film_campaign
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			spot_status in ('C', 'U', 'N')
and			dandc = 'Y'
and			campaign_spot.spot_id not in (select 	spot_id 
							from 	delete_charge_spots, 
									delete_charge
							where	delete_charge.delete_charge_id = delete_charge_spots.delete_charge_id
							and		delete_charge_spots.source_dest = 'S'
							and		delete_charge.source_campaign = campaign_spot.campaign_no
							and		delete_charge.confirmed = 'Y')
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and			revenue_group = 3
and			spot_type <> 'R'
and			spot_type <> 'W'
and			business_unit_id = 5
and			campaign_package.campaign_no = film_campaign.campaign_no
GROUP BY 	campaign_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new SHOWCASE D&C spots', 16, 1)
	rollback transaction
	return -1
end

/* 	3b. Cinelight Unassigned D&C SPOTS  */
insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = cinelight_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 32,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		cinelight_spot,
			cinelight_package,
			statrev_spot_rates	
where 		cinelight_package.package_id = cinelight_spot.package_id
and			cinelight_spot.campaign_no = @campaign_no 
and			spot_status in ('C', 'U', 'N')
and			dandc = 'Y'
and			cinelight_spot.spot_id not in (select 	spot_id 
							from 	delete_charge_cinelight_spots, 
									delete_charge
							where	delete_charge.delete_charge_id = delete_charge_cinelight_spots.delete_charge_id
							and		delete_charge_cinelight_spots.source_dest = 'S'
							and		delete_charge.source_campaign = cinelight_spot.campaign_no
							and		delete_charge.confirmed = 'Y')
and			statrev_spot_rates.campaign_no = cinelight_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_cl_redirect_backwards(cinelight_spot.spot_id)
and			revenue_group = 4
and			media_product_id = 3
GROUP BY 	cinelight_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinelight D&C spots', 16, 1)
	rollback transaction
	return -1
end

/* 	4b. Cinemarketing Unassigned D&C SPOTS  */
insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 33,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		inclusion_spot,
			inclusion,
			statrev_spot_rates	
where 		inclusion.inclusion_id = inclusion_spot.inclusion_id
and			inclusion_spot.campaign_no = @campaign_no 
and			spot_status in ('C', 'U', 'N')
and			dandc = 'Y'
and			inclusion_spot.spot_id not in (select 	spot_id 
							from 	delete_charge_spots, 
									delete_charge
							where	delete_charge.delete_charge_id = delete_charge_spots.delete_charge_id
							and		delete_charge_spots.source_dest = 'S'
							and		delete_charge.source_campaign = inclusion_spot.campaign_no
							and		delete_charge.confirmed = 'Y')
and			statrev_spot_rates.campaign_no = inclusion_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_inc_redirect_backwards(inclusion_spot.spot_id)
and 		inclusion.inclusion_type = 5
and			revenue_group = 5
GROUP BY 	inclusion_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinemarketing D&C spots', 16, 1)
	rollback transaction
	return -1
end

/* 5b. Retail Unassigned D&C Spots */

insert 		#outpost_deferred_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 112,  
			revenue = (convert(numeric(38,16), sum(avg_rate))),
			units = count(*) ,   
			min(avg_rate)
from 		outpost_spot,
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			statrev_spot_rates
where 		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.spot_status != 'P'
and 		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name = outpost_player_xref.player_name 
and 		outpost_player.media_product_id = 9  
and			statrev_spot_rates.campaign_no = outpost_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id)
and			revenue_group = 50 
and			spot_status in ('C', 'U', 'N')
and			dandc = 'Y'
and			outpost_spot.spot_id not in (select 	spot_id 
							from 	outpost_delete_charge_spots, 
									outpost_delete_charge
							where	outpost_delete_charge.delete_charge_id = outpost_delete_charge_spots.delete_charge_id
							and		outpost_delete_charge_spots.source_dest = 'S'
							and		outpost_delete_charge.source_campaign = outpost_spot.campaign_no
							and		outpost_delete_charge.confirmed = 'Y')
GROUP BY 	outpost_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail D&C spots', 16, 1)
	rollback transaction
	return -1
end

/* 6b. Retail Moving Wall Unassigned D&C Spots */

insert 		#outpost_deferred_work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 113,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		inclusion_spot,
			statrev_spot_rates,
			inclusion
where 		inclusion_spot.campaign_no = @campaign_no
and  		inclusion.inclusion_id = inclusion_spot.inclusion_id
and			inclusion_spot.spot_status != 'P'
and			spot_status in ('C', 'U', 'N')
and			dandc = 'Y'
and			statrev_spot_rates.spot_id = dbo.f_spot_inc_redirect_backwards(inclusion_spot.spot_id)
and			statrev_spot_rates.campaign_no = inclusion_spot.campaign_no
and			inclusion_spot.spot_id not in (select 	spot_id 
							from 	outpost_delete_charge_inclusion_spots, 
									outpost_delete_charge
							where	outpost_delete_charge.delete_charge_id = outpost_delete_charge_inclusion_spots.delete_charge_id
							and		outpost_delete_charge_inclusion_spots.source_dest = 'S'
							and		outpost_delete_charge.source_campaign = inclusion_spot.campaign_no
							and		outpost_delete_charge.confirmed = 'Y')
and 		inclusion.inclusion_type = 18
and			revenue_group = 51		
GROUP BY 	inclusion_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail Wall D&C spots', 16, 1)
	rollback transaction
	return -1
end

/* 7b. Retail Super Wall Unassigned D&C Spots */
insert 		#outpost_deferred_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 114,  
			revenue = (convert(numeric(38,16), sum(avg_rate))),
			units = count(*) ,   
			min(avg_rate)
from 		outpost_spot,
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			statrev_spot_rates
where 		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name = outpost_player_xref.player_name 
and 		outpost_player.media_product_id = 11  
and			statrev_spot_rates.campaign_no = outpost_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id)
and			revenue_group = 53 
and			spot_status in ('C', 'U', 'N')
and			dandc = 'Y'
and			outpost_spot.spot_id not in (select 	spot_id 
							from 	outpost_delete_charge_spots, 
									outpost_delete_charge
							where	outpost_delete_charge.delete_charge_id = outpost_delete_charge_spots.delete_charge_id
							and		outpost_delete_charge_spots.source_dest = 'S'
							and		outpost_delete_charge.source_campaign = outpost_spot.campaign_no
							and		outpost_delete_charge.confirmed = 'Y')
GROUP BY 	outpost_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail Super Wall D&C spots', 16, 1)
	rollback transaction
	return -1
end

/* 	8a. FILM On Hold Spots */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 38,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates,
			film_campaign	
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			spot_status = 'H'
and			spot_type <> 'R'
and			spot_type <> 'W'
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and			revenue_group = 1
and			business_unit_id = 2
and			campaign_package.campaign_no = film_campaign.campaign_no
GROUP BY 	campaign_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/* 	8b. DMG Oh Hold Spots SPOTS  */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 39,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates	,
			film_campaign
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			spot_status = 'H'
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and			revenue_group = 2
and			business_unit_id = 3
and			campaign_package.campaign_no = film_campaign.campaign_no
GROUP BY 	campaign_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/* 	8c. SHOWCASE Oh Hold Spots SPOTS  */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 51,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates	,
			film_campaign
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			spot_status = 'H'
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and			revenue_group = 3
and			business_unit_id = 5
and			campaign_package.campaign_no = film_campaign.campaign_no
GROUP BY 	campaign_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new SHOWCASE unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/* 	8d. Cinelight On Hold SPOTS  */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = cinelight_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 40,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		cinelight_spot,
			cinelight_package,
			statrev_spot_rates	
where 		cinelight_package.package_id = cinelight_spot.package_id
and			cinelight_spot.campaign_no = @campaign_no 
and			spot_status = 'H'
and			statrev_spot_rates.campaign_no = cinelight_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_cl_redirect_backwards(cinelight_spot.spot_id)
and			revenue_group = 4
and			media_product_id = 3
GROUP BY 	cinelight_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinelight unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/*  8e Cinemarketing On Hold Spots   */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 41,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		inclusion_spot,
			inclusion,
			statrev_spot_rates	
where 		inclusion.inclusion_id = inclusion_spot.inclusion_id
and			inclusion_spot.campaign_no = @campaign_no 
and			spot_status = 'H'
and			statrev_spot_rates.campaign_no = inclusion_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_inc_redirect_backwards(inclusion_spot.spot_id)
and 		inclusion.inclusion_type = 5
and			revenue_group = 5
GROUP BY 	inclusion_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinemarketing unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/* 8f. Retail On Hold Spots */

insert 		#outpost_deferred_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 118,  
			revenue = (convert(numeric(38,16), sum(avg_rate))),
			units = count(*) ,   
			min(avg_rate)
from 		outpost_spot,
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			statrev_spot_rates
where 		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.spot_status != 'P'
and 		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name = outpost_player_xref.player_name 
and 		outpost_player.media_product_id = 9  
and			statrev_spot_rates.campaign_no = outpost_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id)
and			revenue_group = 50 
and			spot_status = 'H'
GROUP BY 	outpost_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/* 8g. Retail Moving Wall On Hold Spots */

insert 		#outpost_deferred_work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 119,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		inclusion_spot,
			statrev_spot_rates,
			inclusion
where 		inclusion_spot.campaign_no = @campaign_no
and  		inclusion.inclusion_id = inclusion_spot.inclusion_id
and			inclusion_spot.spot_status != 'P'
and			spot_status = 'H'
and 		inclusion.inclusion_type = 18
and			revenue_group = 51		
and			statrev_spot_rates.campaign_no = inclusion_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_inc_redirect_backwards(inclusion_spot.spot_id)
GROUP BY 	inclusion_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail Wall unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/* 8h. Retail Super Wall On Hold Spots */

insert 		#outpost_deferred_work_revision
select 		'NEW',
			campaign_no = outpost_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 120,  
			revenue = (convert(numeric(38,16), sum(avg_rate))),
			units = count(*) ,   
			min(avg_rate)
from 		outpost_spot,
			outpost_panel,
			outpost_player_xref,
			outpost_player,
			statrev_spot_rates
where 		outpost_spot.campaign_no = @campaign_no
and 		outpost_spot.spot_status != 'P'
and 		outpost_spot.outpost_panel_id = outpost_panel.outpost_panel_id  
and 		outpost_panel.outpost_panel_id	= outpost_player_xref.outpost_panel_id  
and 		outpost_player.player_name = outpost_player_xref.player_name 
and 		outpost_player.media_product_id = 11  
and			statrev_spot_rates.campaign_no = outpost_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_op_redirect_backwards(outpost_spot.spot_id)
and			revenue_group = 53 
and			spot_status = 'H'
GROUP BY 	outpost_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new Retail Super Wall unallocated spots', 16, 1)
	rollback transaction
	return -1
end

/* 9a. Film Revenue Proxy SPOTS */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 13, /* Film Revenue Proxy SPOTS  */
			cost = sum ( inclusion_spot.charge_rate ),   
			units = count(*),
			avg_rate = avg(inclusion_spot.charge_rate)
from 		inclusion_spot,
			inclusion 
where		inclusion.campaign_no = @campaign_no
and  		inclusion_spot.inclusion_id = inclusion.inclusion_id
and  		inclusion_spot.spot_status != 'P'
and 		inclusion.inclusion_type = 11
GROUP BY 	inclusion_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film revenue proxy', 16, 1)
	rollback transaction
	return -1
end


/* 9b. DMG Revenue Proxy SPOTS */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 17, /* DMG Revenue Proxy SPOTS   */
			cost = sum ( inclusion_spot.charge_rate ),   
			units = count(*),
			avg_rate = avg ( inclusion_spot.charge_rate )
from 		inclusion_spot,
			inclusion,
			film_campaign
where		inclusion.campaign_no = @campaign_no
and			inclusion.campaign_no = film_Campaign.campaign_no
and			film_campaign.business_unit_id = 3
and  		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			inclusion_spot.spot_status != 'P'
and 		inclusion.inclusion_type = 12
GROUP BY 	inclusion_spot.campaign_no,
			inclusion_spot.screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg revenue proxy spots', 16, 1)
	rollback transaction
	return -1
end

/* 9c. SHOWCASE Revenue Proxy SPOTS */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 45, /* SHOWCASE Revenue Proxy SPOTS   */
			cost = sum ( inclusion_spot.charge_rate ),   
			units = count(*),
			avg_rate = avg ( inclusion_spot.charge_rate )
from 		inclusion_spot,
			inclusion,
			film_campaign
where		inclusion.campaign_no = @campaign_no
and			inclusion.campaign_no = film_Campaign.campaign_no
and			film_campaign.business_unit_id = 5
and  		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			inclusion_spot.spot_status != 'P'
and 		inclusion.inclusion_type = 12
GROUP BY 	inclusion_spot.campaign_no,
			inclusion_spot.screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg revenue proxy spots', 16, 1)
	rollback transaction
	return -1
end

/* 9d. Cinelight Revenue Proxy SPOTS */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 20, /* Cinelight Revenue Proxy SPOTS  */
			cost = sum ( inclusion_spot.charge_rate ),   
			units = count(*),
			avg_rate = avg ( inclusion_spot.charge_rate )
from 		inclusion_spot,
			inclusion 
where		inclusion.campaign_no = @campaign_no
and 		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			inclusion_spot.spot_status != 'P'
and 		inclusion.inclusion_type = 13
GROUP BY 	inclusion_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinelight revenue proxy spots', 16, 1)
	rollback transaction
	return -1
end

/* 9e. CineMarketing Revenue Proxy SPOTS*/

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 23, /* CineMarketing Revenue Proxy SPOTS */
			cost = sum ( inclusion_spot.charge_rate ),   
			units = count(*),
			avg_rate = avg ( inclusion_spot.charge_rate )
from 		inclusion_spot,
			inclusion 
where		inclusion.campaign_no = @campaign_no
and  		inclusion_spot.inclusion_id = inclusion.inclusion_id
and			inclusion_spot.spot_status != 'P'
and 		inclusion.inclusion_type = 14
GROUP BY 	inclusion_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cinemarketing revenue proxy spots', 16, 1)
	rollback transaction
	return -1
end


/*
 CINEads
*/

/* 	1ci. CineAds NORMAL SPOTS  */

insert 		#work_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 59,
			revenue_period = ( 	select 	max(benchmark_end) 
								from 	film_screening_date_xref 
								where 	film_screening_date_xref.screening_date = campaign_spot.screening_date ) ,
			screening_date = campaign_spot.screening_date,   
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates,
			film_campaign
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			((spot_status = 'A'
and			spot_type <> 'M'
and			spot_type <> 'V')
or			spot_status in ('X', 'R'))
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and			campaign_package.campaign_no = film_campaign.campaign_no
and			revenue_group = 8
and			business_unit_id = 9
GROUP BY 	campaign_spot.campaign_no,
			campaign_spot.screening_date

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg normal spots', 16, 1)
	rollback transaction
	return -1
end

/* 	8b. DMG Oh Hold Spots SPOTS  */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 65,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates	,
			film_campaign
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			spot_status = 'H'
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and			revenue_group = 8
and			business_unit_id = 9
and			campaign_package.campaign_no = film_campaign.campaign_no
GROUP BY 	campaign_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new cineads  unallocated spots', 16, 1)
	rollback transaction
	return -1
end



/* 2ma. Cineads TakeOut */

insert 		#work_revision
select 		'NEW',
			campaign_no = inclusion_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 60, /* Film Takeout */
			inclusion_spot.revenue_period,
			screening_date = (select 	max(screening_date) 
				from 	film_screening_date_xref fdx, accounting_period acp
				where 	fdx.benchmark_end = acp.benchmark_end and acp.end_date = inclusion_spot.revenue_period),   
			cost = SUM ( inclusion_spot.takeout_rate * - 1),  
			units = count(*),
			0
from 		inclusion_spot, 
			inclusion, 
			film_campaign 
where		inclusion.campaign_no = @campaign_no
and			inclusion.campaign_no = film_campaign.campaign_no
and  		inclusion.inclusion_id = inclusion_spot.inclusion_id
and  		inclusion.include_revenue = 'Y' -- GB
and 		inclusion_spot.spot_status != 'P'
and 		inclusion.inclusion_category in ('F', 'D')
and			business_unit_id = 9
GROUP BY 	inclusion_spot.campaign_no,
			inclusion_spot.revenue_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film takeout spots', 16, 1)
	rollback transaction
	return -1
end

/* 3m. Cineads Billing Credits */

insert 		#work_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 61, /* Billing Credits And Bad Debts */
			revenue_period = benchmark_end ,
			screening_date = (select 	max(screening_date) 
							from 	film_screening_date_xref fdx
							where 	fdx.benchmark_end = accounting_period.benchmark_end ),   
			cost = sum ( spot_liability.spot_amount ),   
			units = 1 ,
			 0
from 		campaign_spot,
			spot_liability,
			accounting_period,
			film_campaign 
where		campaign_spot.campaign_no = @campaign_no
and			accounting_period.end_date = spot_liability.creation_period
and 		campaign_spot.spot_status != 'P'
and 		spot_liability.liability_type = 40
and			business_unit_id = 9
and 		campaign_spot.spot_id  = spot_liability.spot_id
and			film_campaign.campaign_no = campaign_spot.campaign_no
GROUP BY	campaign_spot.campaign_no,
			benchmark_end

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new dmg billing credits', 16, 1)
	rollback transaction
	return -1
end

/* 5m. CineAds Cancelled Spots */

insert 		#work_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 64,
			revenue_period = ( 	select 	max(benchmark_end) 
								from 	film_screening_date_xref 
								where 	film_screening_date_xref.screening_date = campaign_spot.billing_date ) ,
			screening_date = campaign_spot.billing_date,   
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates,
			film_campaign	
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			spot_status in ('C')
and			spot_type <> 'R' 
and 		spot_type <> 'W'
and			dandc = 'N'
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id)
and			campaign_package.campaign_no = film_campaign.campaign_no
and			revenue_group = 8
and			business_unit_id = 9
GROUP BY 	campaign_spot.campaign_no,
			campaign_spot.billing_date

/* 	6m. Cineads Unallocated & Active Makeups SPOTS  */

insert 		#work_deferred_revision
select 		'NEW',
			campaign_no = campaign_spot.campaign_no,   
			confirmation_date = @confirm_date,
			transaction_type = 62,
			revenue = convert(numeric(38,16), sum(avg_rate)),
			units = count(*) ,   
			min(avg_rate)
from 		campaign_spot,
			campaign_package,
			statrev_spot_rates,
			film_campaign	
where 		campaign_package.package_id = campaign_spot.package_id
and			campaign_spot.campaign_no = @campaign_no 
and			((spot_status = 'A'
and			(spot_type = 'M'
or			spot_type = 'V')
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id))
or			(spot_status in ('U', 'N')
and			spot_redirect is null)
and			statrev_spot_rates.spot_id = dbo.f_spot_redirect_backwards(campaign_spot.spot_id))
and			statrev_spot_rates.campaign_no = campaign_spot.campaign_no
and			revenue_group = 8
and			business_unit_id = 9
and			campaign_package.campaign_no = film_campaign.campaign_no
and			dandc = 'N'
GROUP BY 	campaign_spot.campaign_no

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting new film unallocated spots', 16, 1)
	rollback transaction
	return -1
end



/* insert existing compaign transactions as a negative value to figure out the delta */

insert 		#work_revision
select 		flag = 'OLD',   
			statrev_campaign_revision.campaign_no,   
			statrev_campaign_revision.confirmation_date,   
			statrev_cinema_normal_transaction.transaction_type,
			statrev_cinema_normal_transaction.revenue_period,   
			statrev_cinema_normal_transaction.screening_date,   
			cost * -1.000000000000,   
			units * -1.000000000000,   
			0 
from 		statrev_campaign_revision,   
			statrev_cinema_normal_transaction  
where		statrev_cinema_normal_transaction.revision_id = statrev_campaign_revision.revision_id 
and 		statrev_campaign_revision.campaign_no = @campaign_no 

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting old revisions', 16, 1)
	rollback transaction
	return -1
end

insert 		#outpost_work_revision
select 		flag = 'OLD',   
			statrev_campaign_revision.campaign_no,   
			statrev_campaign_revision.confirmation_date,   
			statrev_outpost_normal_transaction.transaction_type,
			statrev_outpost_normal_transaction.revenue_period,   
			statrev_outpost_normal_transaction.screening_date,   
			cost * -1.000000000000,   
			units * -1.000000000000,
			0
from 		statrev_campaign_revision,   
			statrev_outpost_normal_transaction  
where		statrev_outpost_normal_transaction.revision_id = statrev_campaign_revision.revision_id 
and 		statrev_campaign_revision.campaign_no = @campaign_no 

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting old retail revisions', 16, 1)
	rollback transaction
	return -1
end

insert 		#work_deferred_revision
select 		flag = 'OLD',   
			statrev_campaign_revision.campaign_no,   
			statrev_campaign_revision.confirmation_date,   
			statrev_cinema_deferred_transaction.transaction_type,
			cost * -1.000000000000,   
			units * -1.000000000000,   
			0
from 		statrev_campaign_revision,   
			statrev_cinema_deferred_transaction  
where		statrev_cinema_deferred_transaction.revision_id = statrev_campaign_revision.revision_id 
and 		statrev_campaign_revision.campaign_no = @campaign_no 

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting old revisions', 16, 1)
	rollback transaction
	return -1
end

insert 		#outpost_deferred_work_revision
select 		flag = 'OLD',   
			statrev_campaign_revision.campaign_no,   
			statrev_campaign_revision.confirmation_date,   
			statrev_outpost_deferred_transaction.transaction_type,
			cost * -1.000000000000,   
			units * -1.000000000000,   
			0 
from 		statrev_campaign_revision,   
			statrev_outpost_deferred_transaction  
where		statrev_outpost_deferred_transaction.revision_id = statrev_campaign_revision.revision_id 
and 		statrev_campaign_revision.campaign_no = @campaign_no 

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
	transaction_type,	
	revenue_period ,	
	screening_date, 
	cost,
	units,
	avg_rate
)
( 	select 		#work_revision.campaign_no,
				#work_revision.transaction_type,   
				#work_revision.revenue_period,   
				#work_revision.screening_date,   
				sum ( #work_revision.cost) ,   
				sum ( #work_revision.units),   
				max ( #work_revision.avg_rate)  
	from 		#work_revision
	GROUP BY 	#work_revision.campaign_no,
				#work_revision.transaction_type,   
				#work_revision.revenue_period,   
				#work_revision.screening_date
	HAVING   	sum ( #work_revision.cost) <> 0  
	OR			sum ( #work_revision.units) <> 0)

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
	transaction_type,	
	revenue_period ,	
	screening_date, 
	cost,
	units,
	avg_rate
)
( 	select 		#outpost_work_revision.campaign_no,
				#outpost_work_revision.transaction_type,   
				#outpost_work_revision.revenue_period,   
				#outpost_work_revision.screening_date,   
				sum ( #outpost_work_revision.cost) ,   
				sum ( #outpost_work_revision.units),   
				max ( #outpost_work_revision.avg_rate)  
	from 		#outpost_work_revision
	GROUP BY 	#outpost_work_revision.campaign_no,
				#outpost_work_revision.transaction_type,   
				#outpost_work_revision.revenue_period,   
				#outpost_work_revision.screening_date
	HAVING   	sum ( #outpost_work_revision.cost) <> 0  
	OR			sum ( #outpost_work_revision.units) <> 0)

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting into retail delta temp table', 16, 1)
	rollback transaction
	return -1
end

insert INTO #delta_deferred_revision
(
	campaign_no, 
	transaction_type,	
	cost,
	units,
	avg_rate
)
( 	select 		#work_deferred_revision.campaign_no,
				#work_deferred_revision.transaction_type,   
				sum ( #work_deferred_revision.cost) ,   
				sum ( #work_deferred_revision.units),   
				max ( #work_deferred_revision.avg_rate)  
	from 		#work_deferred_revision
	GROUP BY 	#work_deferred_revision.campaign_no,
				#work_deferred_revision.transaction_type
	HAVING   	sum ( #work_deferred_revision.cost) <> 0  
	OR			sum ( #work_deferred_revision.units) <> 0)

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting into delta temp table', 16, 1)
	rollback transaction
	return -1
end

insert INTO #outpost_deferred_delta_revision
(
	campaign_no, 
	transaction_type,	
	cost,
	units,
	avg_rate
)
( 	select 		#outpost_deferred_work_revision.campaign_no,
				#outpost_deferred_work_revision.transaction_type,   
				sum ( #outpost_deferred_work_revision.cost) ,   
				sum ( #outpost_deferred_work_revision.units),   
				max ( #outpost_deferred_work_revision.avg_rate)  
	from 		#outpost_deferred_work_revision
	GROUP BY 	#outpost_deferred_work_revision.campaign_no,
				#outpost_deferred_work_revision.transaction_type
	HAVING   	sum ( #outpost_deferred_work_revision.cost) <> 0  
	OR			sum ( #outpost_deferred_work_revision.units) <> 0)

select @error = @@error
if @error <> 0
begin
	raiserror ('Error inserting into retail delta temp table', 16, 1)
	rollback transaction
	return -1
end

UPDATE 		#delta_revision 
SET    		revenue_period = @accounting_period
where   	revenue_period < @accounting_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error udpdating closed periods in delta table', 16, 1)
	rollback transaction
	return -1
end

UPDATE 		#outpost_delta_revision 
SET    		revenue_period = @accounting_period
where   	revenue_period < @accounting_period

select @error = @@error
if @error <> 0
begin
	raiserror ('Error udpdating closed periods in retail delta table', 16, 1)
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
where   	IsNull( #delta_revision.cost , 0 ) = 0 
and			IsNull( #delta_revision.units, 0 ) = 0

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting from delta table', 16, 1)
	rollback transaction
	return -1
end

DELETE from #delta_deferred_revision 
where   	IsNull( #delta_deferred_revision.cost , 0 ) = 0 
and			IsNull( #delta_deferred_revision.units, 0 ) = 0

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting from deferred delta table', 16, 1)
	rollback transaction
	return -1
end

DELETE from #outpost_delta_revision 
where   	IsNull( #outpost_delta_revision.cost , 0 ) = 0 
and			IsNull( #outpost_delta_revision.units, 0 ) = 0

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting from retail delta table', 16, 1)
	rollback transaction
	return -1
end

DELETE from #outpost_deferred_delta_revision 
where   	IsNull( #outpost_deferred_delta_revision.cost , 0 ) = 0 
and			IsNull( #outpost_deferred_delta_revision.units, 0 ) = 0

select @error = @@error
if @error <> 0
begin
	raiserror ('Error deleting from retail deferred delta table', 16, 1)
	rollback transaction
	return -1
end

/* Add new campaign revision records from temporary table */
IF ( IsNull( @revision_id, 0 ) = 0 )
begin
	insert INTO statrev_campaign_revision  
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
        from    (select 	#delta_revision.campaign_no   
                from 		#delta_revision 
                where 		NOT EXISTS (select 	* 
						                from 	statrev_campaign_revision
						                where 	statrev_campaign_revision.campaign_no = #delta_revision.campaign_no
						                and 	statrev_campaign_revision.revision_no = @revision_no)
                GROUP BY 	#delta_revision.campaign_no
                union
                select      #outpost_delta_revision.campaign_no   
                from 		#outpost_delta_revision 
                where 		NOT EXISTS (select 	* 
						                from 	statrev_campaign_revision
						                where 	statrev_campaign_revision.campaign_no = #outpost_delta_revision.campaign_no
						                and 	statrev_campaign_revision.revision_no = @revision_no)
                GROUP BY 	#outpost_delta_revision.campaign_no
				union
				select 		#delta_deferred_revision.campaign_no   
                from 		#delta_deferred_revision 
                where 		NOT EXISTS (select 	* 
						                from 	statrev_campaign_revision
						                where 	statrev_campaign_revision.campaign_no = #delta_deferred_revision.campaign_no
						                and 	statrev_campaign_revision.revision_no = @revision_no)
                GROUP BY 	#delta_deferred_revision.campaign_no
                union
                select      #outpost_deferred_delta_revision.campaign_no   
                from 		#outpost_deferred_delta_revision 
                where 		NOT EXISTS (select 	* 
						                from 	statrev_campaign_revision
						                where 	statrev_campaign_revision.campaign_no = #outpost_deferred_delta_revision.campaign_no
						                and 	statrev_campaign_revision.revision_no = @revision_no)
                GROUP BY 	#outpost_deferred_delta_revision.campaign_no	) as temp_table         
 

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting into campaign revision B', 16, 1)
		rollback transaction
		return -1
	end

	insert INTO statrev_cinema_normal_transaction  
	( 
	revision_id,   
	transaction_type,   
	revenue_period,   
	screening_date,   
	delta_date,   
	cost,   
	units,   
	avg_rate
	)  
	select		statrev_campaign_revision.revision_id,   
				#delta_revision.transaction_type,   
				#delta_revision.revenue_period,   
				#delta_revision.screening_date,   
				@confirm_date,   
				#delta_revision.cost,   
				#delta_revision.units,   
				#delta_revision.avg_rate
	from 		statrev_campaign_revision,
				#delta_revision
	where  		statrev_campaign_revision.campaign_no = #delta_revision.campaign_no
	and 		statrev_campaign_revision.revision_no = @revision_no

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting revision transaction', 16, 1)
		rollback transaction
		return -1
	end

	insert INTO statrev_outpost_normal_transaction  
	( 
	revision_id,   
	transaction_type,   
	revenue_period,   
	screening_date,   
	delta_date,   
	cost,   
	units,   
	avg_rate
	)  
	select		statrev_campaign_revision.revision_id,   
				#outpost_delta_revision.transaction_type,   
				#outpost_delta_revision.revenue_period,   
				#outpost_delta_revision.screening_date,   
				@confirm_date,   
				#outpost_delta_revision.cost,   
				#outpost_delta_revision.units,   
				#outpost_delta_revision.avg_rate
	from 		statrev_campaign_revision,
				#outpost_delta_revision
	where  		statrev_campaign_revision.campaign_no = #outpost_delta_revision.campaign_no
	and 		statrev_campaign_revision.revision_no = @revision_no

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting revision transaction', 16, 1)
		rollback transaction
		return -1
	end


	insert INTO statrev_cinema_deferred_transaction  
	( 
	revision_id,   
	transaction_type,   
	delta_date,   
	cost,   
	units,   
	avg_rate
	)  
	select		statrev_campaign_revision.revision_id,   
				#delta_deferred_revision.transaction_type,   
				@confirm_date,   
				#delta_deferred_revision.cost,   
				#delta_deferred_revision.units,   
				#delta_deferred_revision.avg_rate
	from 		statrev_campaign_revision,
				#delta_deferred_revision
	where  		statrev_campaign_revision.campaign_no = #delta_deferred_revision.campaign_no
	and 		statrev_campaign_revision.revision_no = @revision_no

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting revision transaction', 16, 1)
		rollback transaction
		return -1
	end

	insert INTO statrev_outpost_deferred_transaction  
	( 
	revision_id,   
	transaction_type,   
	delta_date,   
	cost,   
	units,   
	avg_rate
	)  
	select		statrev_campaign_revision.revision_id,   
				#outpost_deferred_delta_revision.transaction_type,   
				@confirm_date,   
				#outpost_deferred_delta_revision.cost,   
				#outpost_deferred_delta_revision.units,   
				#outpost_deferred_delta_revision.avg_rate
	from 		statrev_campaign_revision,
				#outpost_deferred_delta_revision
	where  		statrev_campaign_revision.campaign_no = #outpost_deferred_delta_revision.campaign_no
	and 		statrev_campaign_revision.revision_no = @revision_no

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting revision transaction', 16, 1)
		rollback transaction
		return -1
	end
end

IF ( IsNull( @revision_id, 0 ) != 0 )
begin
	insert INTO statrev_cinema_normal_transaction  
	( 
	revision_id,   
	transaction_type,   
	revenue_period,   
	screening_date,   
	delta_date,   
	cost,   
	units,   
	avg_rate 
	)  
	select		@revision_id,   
				#delta_revision.transaction_type,   
				#delta_revision.revenue_period,   
				#delta_revision.screening_date,   
				@confirm_date,   
				sum ( #delta_revision.cost ),   
				sum ( #delta_revision.units ),   
				max ( #delta_revision.avg_rate)
	from 		#delta_revision
	GROUP BY    #delta_revision.transaction_type,   
				#delta_revision.revenue_period,   
				#delta_revision.screening_date

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting new revision transactions', 16, 1)
		rollback transaction
		return -1
	end

	insert INTO statrev_outpost_normal_transaction  
	( 
	revision_id,   
	transaction_type,   
	revenue_period,   
	screening_date,   
	delta_date,   
	cost,   
	units,   
	avg_rate 
	)  
	select		@revision_id,   
				#outpost_delta_revision.transaction_type,   
				#outpost_delta_revision.revenue_period,   
				#outpost_delta_revision.screening_date,   
				@confirm_date,   
				sum ( #outpost_delta_revision.cost ),   
				sum ( #outpost_delta_revision.units ),   
				max	( #outpost_delta_revision.avg_rate)
	from 		#outpost_delta_revision
	where		#outpost_delta_revision.transaction_type >= 100
	GROUP BY    #outpost_delta_revision.transaction_type,   
				#outpost_delta_revision.revenue_period,   
				#outpost_delta_revision.screening_date

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting new revision transactions', 16, 1)
		rollback transaction
		return -1
	end

	insert INTO statrev_cinema_deferred_transaction  
	( 
	revision_id,   
	transaction_type,   
	delta_date,   
	cost,   
	units,   
	avg_rate 
	)  
	select		@revision_id,   
				#delta_deferred_revision.transaction_type,   
				@confirm_date,   
				sum ( #delta_deferred_revision.cost ),   
				sum ( #delta_deferred_revision.units ),   
				max ( #delta_deferred_revision.avg_rate)
	from 		#delta_deferred_revision
	GROUP BY    #delta_deferred_revision.transaction_type

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting new revision transactions', 16, 1)
		rollback transaction
		return -1
	end

	insert INTO statrev_outpost_deferred_transaction  
	( 
	revision_id,   
	transaction_type,   
	delta_date,   
	cost,   
	units,   
	avg_rate 
	)  
	select		@revision_id,   
				#outpost_deferred_delta_revision.transaction_type,   
				@confirm_date,   
				sum ( #outpost_deferred_delta_revision.cost ),   
				sum ( #outpost_deferred_delta_revision.units ),   
				max	( #outpost_deferred_delta_revision.avg_rate)
	from 		#outpost_deferred_delta_revision
	where		#outpost_deferred_delta_revision.transaction_type >= 100
	GROUP BY    #outpost_deferred_delta_revision.transaction_type

	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting new revision transactions', 16, 1)
		rollback transaction
		return -1
	end
end

select 	@revision_id = ISNULL(revision_id, 0)
from 	statrev_campaign_revision
where 	statrev_campaign_revision.campaign_no = @campaign_no
and 	statrev_campaign_revision.revision_no = @revision_no

if @revision_id IS NOT NULL
begin
	insert INTO statrev_revision_rep_xref ( 
		revision_id,   
		rep_id,
		revenue_percent
	)
	select	@revision_id,
			rep_id,
			booking_percent
	  from	film_campaign_reps
	where	campaign_no = @campaign_no
	and		booking_percent <> 0 
	
	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting revision Reps Xref', 16, 1)
		rollback transaction
		return -1
	end	
	
	insert INTO statrev_revision_team_xref ( 
		revision_id,   
		team_id,
		revenue_percent
	)
	select	@revision_id,
			team_id,
			booking_percent
	  from	film_campaign_reps, campaign_rep_teams
	  	where	campaign_no = @campaign_no and film_campaign_reps.campaign_reps_id = campaign_rep_teams.campaign_reps_id
	and		booking_percent <> 0 
	group by team_id,
			booking_percent
	
	select @error = @@error
	if @error <> 0
	begin
		raiserror ('Error inserting revision Reps Xref', 16, 1)
		rollback transaction
		return -1
	end	
end


commit transaction
return 0
GO
