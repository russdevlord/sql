/****** Object:  StoredProcedure [dbo].[p_move_campaign_options]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_move_campaign_options]
GO
/****** Object:  StoredProcedure [dbo].[p_move_campaign_options]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create proc [dbo].[p_move_campaign_options]	@campaign_no			int

as

declare			@error								int,
				@current_screening_date				datetime,
				@current_accounting_period			datetime

set nocount on

/*
 * Create temp table for options
 */

create table #campaign_options
(
	option_desc		varchar(100)		null,
	option_id		int					null,
	option_type		int					null,
	start_date		datetime			null,
	end_date		datetime			null,
	move_yes_no		char(1)				null,
	no_weeks		int					null,
	new_start_date	datetime			null
)


/*
 * insert onscreen
 */

insert into		#campaign_options
(	
				option_desc,
				option_id,
				option_type,
				start_date,
				end_date,
				move_yes_no
)
select			'Onscreen Package: ' + package_code + ' - ' + package_desc,
				campaign_package.package_id,
				1,
				min(start_date),
				max(campaign_spot.screening_date),
				'Y'
from			campaign_package
inner join		campaign_spot on campaign_package.package_id = campaign_spot.package_id
where			campaign_package.campaign_no = @campaign_no
and				spot_type not in ('F', 'A', 'K', 'T')
group by		package_code,
				package_desc,
				campaign_package.package_id


/*
 * insert cinelights
 */

insert into		#campaign_options
(	
				option_desc,
				option_id,
				option_type,
				start_date,
				end_date,
				move_yes_no
)
select			'Digilite Package: ' + package_code + ' - ' + package_desc,
				cinelight_package.package_id,
				2,
				min(screening_date),
				max(screening_date),
				'Y'
from			cinelight_package
inner join		cinelight_spot on cinelight_package.package_id = cinelight_spot.package_id
where			cinelight_package.campaign_no = @campaign_no
group by		package_code,
				package_desc,
				cinelight_package.package_id

/*
 * insert inclusions with spots (non takeout) non follow film
 */

insert into		#campaign_options
(	
				option_desc,
				option_id,
				option_type,
				start_date,
				end_date,
				move_yes_no
)
select			inclusion_type_desc + ' Inclusion: ' + convert(varchar(10), inclusion.inclusion_id) + ' - ' + inclusion_desc,
				inclusion.inclusion_id,
				3,
				min(screening_date),
				max(screening_date),
				'Y'
from			inclusion
inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
inner join		inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
where			inclusion.campaign_no = @campaign_no
and				inclusion_format in ('C', 'T')
and				inclusion.inclusion_type <> 29
group by		inclusion_type_desc,
				inclusion.inclusion_id,
				inclusion_desc

/*
 * insert inclusions without spots
 */

insert into		#campaign_options
(	
				option_desc,
				option_id,
				option_type,
				start_date,
				end_date,
				move_yes_no
)
select			inclusion_type_desc + ' Inclusion: ' + convert(varchar(10), inclusion.inclusion_id) + ' - ' + inclusion_desc,
				inclusion.inclusion_id,
				4,
				billing_period,
				billing_period,
				'Y'
from			inclusion
inner join		inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
where			inclusion.campaign_no = @campaign_no
and				billing_period is not null
and				inclusion_id not in (select			inclusion_id
									from			inclusion_spot
									where			campaign_no = @campaign_no)
group by		inclusion_type_desc,
				inclusion.inclusion_id,
				inclusion_desc,
				billing_period

/*
 * insert inclusions with spots
 */

insert into		#campaign_options
(	
				option_desc,
				option_id,
				option_type,
				start_date,
				end_date,
				move_yes_no
)
select			inclusion_type_desc + ' Inclusion: ' + convert(varchar(10), inclusion.inclusion_id) + ' - ' + inclusion_desc,
				inclusion.inclusion_id,
				5,
				min(inclusion_spot.billing_period),
				max(inclusion_spot.billing_period),
				'Y'
from			inclusion
inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
inner join		inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
where			inclusion.campaign_no = @campaign_no
and				inclusion_format in ('A', 'I', 'M')
group by		inclusion_type_desc,
				inclusion.inclusion_id,
				inclusion_desc

/*
 * insert inclusions with spots (non takeout)
 */

insert into		#campaign_options
(	
				option_desc,
				option_id,
				option_type,
				start_date,
				end_date,
				move_yes_no
)
select			inclusion_type_desc + ' Inclusion: ' + convert(varchar(10), inclusion.inclusion_id) + ' - ' + inclusion_desc,
				inclusion.inclusion_id,
				6,
				min(screening_date),
				max(screening_date),
				'N'
from			inclusion
inner join		inclusion_spot on inclusion.inclusion_id = inclusion_spot.inclusion_id
inner join		inclusion_type on inclusion.inclusion_type = inclusion_type.inclusion_type
where			inclusion.campaign_no = @campaign_no
and				inclusion_format in ('C', 'T')
and				inclusion.inclusion_type = 29
group by		inclusion_type_desc,
				inclusion.inclusion_id,
				inclusion_desc,
				start_date,
				used_by_date

select			@current_screening_date = min(screening_date)
from			film_screening_dates
where			screening_date_status = 'C'

select			@current_accounting_period = min(end_date)
from			accounting_period
where			status = 'O'

update			#campaign_options
set				move_yes_no = 'N'
where			option_type in (1,2,3)
and				end_date < @current_screening_date

update 			#campaign_options
set				move_yes_no = 'N'
where			option_type in (4, 5)
and				end_date < @current_accounting_period

 /*
  * Select And Return
  */

select			option_desc,
				option_id,
				option_type,
				start_date,
				end_date,
				move_yes_no,
				no_weeks,
				new_start_date,
				@current_screening_date,
				@current_accounting_period	
from			#campaign_options

return 0
GO
