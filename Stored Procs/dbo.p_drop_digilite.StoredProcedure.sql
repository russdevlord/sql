/****** Object:  StoredProcedure [dbo].[p_drop_digilite]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_drop_digilite]
GO
/****** Object:  StoredProcedure [dbo].[p_drop_digilite]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_drop_digilite]	@player_name		varchar(50)

as

declare		@error					int,
			@cinelight_id			int,
			@no_cinelights			numeric(18,14),
			@rate					money,
			@charge_rate			money,
			@cinema_rate			money,
			@makegood_rate			money,
			@rate_calc				money,
			@charge_rate_calc		money,
			@cinema_rate_calc		money,
			@makegood_rate_calc		money,
			@spot_weighting			float,
			@spot_weighting_calc	float,
			@cinema_weighting		float,
			@cinema_weighting_calc	float,
			@attendance				int,
			@showings				int,
			@campaign_no			int,
			@screening_date			datetime,
			@no_cinelights_needed		numeric(18,14),
			@showings_calc			int,
			@attendance_calc		int,
			@package_id				int,
			@shell_code				char(7),
			@print_id				int,
			@spot_amount			money,
			@cinema_amount			money,
			@cinema_rent			money,
			@spot_amount_calc		money,
			@cinema_amount_calc		money,
			@cinema_rent_calc		money,
			@liability_type     	tinyint,
			@allocation_id      	int,
			@creation_period    	datetime,
			@origin_period      	datetime,
			@release_period     	datetime,
			@cancelled          	tinyint,
			@original_liability 	tinyint,
			@spot_type				char(1),
			@spot_status			char(1),
			@billing_date			datetime

set nocount on

create table #cinelights
(
cinelight_id		int		not null
)

insert into #cinelights select cinelight_id from cinelight_dsn_player_xref where player_name = @player_name

select @no_cinelights = count(cinelight_id) from #cinelights

select @no_cinelights_needed = @no_cinelights - 1

select @cinelight_id = max(cinelight_id) from #cinelights 


begin transaction

declare 	cinelight_attendance_digilite_actuals_csr cursor forward_only for
select 		campaign_no,
			screening_date
from		cinelight_attendance_digilite_actuals,
			#cinelights
where		cinelight_attendance_digilite_actuals.cinelight_id = #cinelights.cinelight_id
group by 	campaign_no,
			screening_date
order by 	campaign_no,
			screening_date
for 		read only

open cinelight_attendance_digilite_actuals_csr
fetch cinelight_attendance_digilite_actuals_csr into @campaign_no, @screening_date
while(@@fetch_status = 0)	
begin


	select 	@showings = isnull(sum(showings),0),
			@attendance = isnull(sum(attendance),0)
	from 	cinelight_attendance_digilite_actuals,
			#cinelights
	where	cinelight_attendance_digilite_actuals.cinelight_id = #cinelights.cinelight_id
	and		screening_date = @screening_date
	and		campaign_no = @campaign_no

	if @@error <> 0
		goto error



	select 	@showings_calc = (@showings / @no_cinelights_needed)
	select 	@attendance_calc = (@attendance / @no_cinelights_needed)

	delete 	cinelight_attendance_digilite_actuals
	where	cinelight_id = @cinelight_id
	and		screening_date = @screening_date
	and		campaign_no = @campaign_no

	if @@error <> 0
		goto error

	update 	cinelight_attendance_digilite_actuals
	set		showings = @showings_calc,
			attendance = @attendance_calc
	where	cinelight_id in (select cinelight_id from #cinelights)
	and		screening_date = @screening_date
	and		campaign_no = @campaign_no

	if @@error <> 0
		goto error

	fetch cinelight_attendance_digilite_actuals_csr into @campaign_no, @screening_date
end

deallocate cinelight_attendance_digilite_actuals_csr

declare 	cinelight_attendance_digilite_estimates_csr cursor forward_only for
select 		campaign_no,
			screening_date
from		cinelight_attendance_digilite_estimates,
			#cinelights
where		cinelight_attendance_digilite_estimates.cinelight_id = #cinelights.cinelight_id
group by 	campaign_no,
			screening_date
order by 	campaign_no,
			screening_date
for 		read only

open cinelight_attendance_digilite_estimates_csr
fetch cinelight_attendance_digilite_estimates_csr into @campaign_no, @screening_date
while(@@fetch_status = 0)	
begin


	select 	@showings = isnull(sum(showings),0),
			@attendance = isnull(sum(attendance),0)
	from 	cinelight_attendance_digilite_estimates,
			#cinelights
	where	cinelight_attendance_digilite_estimates.cinelight_id = #cinelights.cinelight_id
	and		screening_date = @screening_date
	and		campaign_no = @campaign_no

	if @@error <> 0
		goto error



	select 	@showings_calc = (@showings / @no_cinelights_needed)
	select 	@attendance_calc = (@attendance / @no_cinelights_needed)

	delete 	cinelight_attendance_digilite_estimates
	where	cinelight_id = @cinelight_id
	and		screening_date = @screening_date
	and		campaign_no = @campaign_no

	if @@error <> 0
		goto error

	update 	cinelight_attendance_digilite_estimates
	set		showings = @showings_calc,
			attendance = @attendance_calc
	where	cinelight_id in (select cinelight_id from #cinelights)
	and		screening_date = @screening_date
	and		campaign_no = @campaign_no

	if @@error <> 0
		goto error

	fetch cinelight_attendance_digilite_estimates_csr into @campaign_no, @screening_date
end

deallocate cinelight_attendance_digilite_estimates_csr

declare 	cinelight_attendance_history_csr cursor forward_only for
select 		screening_date
from		cinelight_attendance_history,
			#cinelights
where		cinelight_attendance_history.cinelight_id = #cinelights.cinelight_id
group by 	screening_date
order by 	screening_date
for 		read only

open cinelight_attendance_history_csr
fetch cinelight_attendance_history_csr into @screening_date
while(@@fetch_status = 0)	
begin


	select 	@attendance = isnull(sum(attendance),0)
	from 	cinelight_attendance_history,
			#cinelights
	where	cinelight_attendance_history.cinelight_id = #cinelights.cinelight_id
	and		screening_date = @screening_date

	if @@error <> 0
		goto error

	select 	@attendance_calc = (@attendance / @no_cinelights_needed)

	delete 	cinelight_attendance_history
	where	cinelight_id = @cinelight_id
	and		screening_date = @screening_date

	if @@error <> 0
		goto error

	update 	cinelight_attendance_history
	set		attendance = @attendance_calc
	where	cinelight_id in (select cinelight_id from #cinelights)
	and		screening_date = @screening_date

	if @@error <> 0
		goto error

	fetch cinelight_attendance_history_csr into @screening_date
end

deallocate cinelight_attendance_history_csr


declare 	cinelight_package_showings_csr cursor forward_only for
select 		screening_date,
			package_id
from		cinelight_package_showings,
			#cinelights
where		cinelight_package_showings.cinelight_id = #cinelights.cinelight_id
group by 	screening_date,
			package_id
order by 	screening_date,
			package_id
for 		read only

open cinelight_package_showings_csr
fetch cinelight_package_showings_csr into @screening_date, @package_id
while(@@fetch_status = 0)	
begin


	select 	@showings = isnull(sum(showings),0)
	from 	cinelight_package_showings,
			#cinelights
	where	cinelight_package_showings.cinelight_id = #cinelights.cinelight_id
	and		screening_date = @screening_date
	and		package_id = @package_id

	if @@error <> 0
		goto error

	select 	@showings_calc = (@showings / @no_cinelights_needed)

	delete 	cinelight_package_showings
	where	cinelight_id = @cinelight_id
	and		screening_date = @screening_date
	and		package_id = @package_id

	if @@error <> 0
		goto error

	update 	cinelight_package_showings
	set		showings = @showings_calc
	where	cinelight_id in (select cinelight_id from #cinelights)
	and		screening_date = @screening_date
	and		package_id = @package_id

	if @@error <> 0
		goto error

	fetch cinelight_package_showings_csr into @screening_date, @package_id
end

deallocate cinelight_package_showings_csr


declare 	cinelight_shell_attendance_csr cursor forward_only for
select 		screening_date,
			shell_code
from		cinelight_shell_attendance,
			#cinelights
where		cinelight_shell_attendance.cinelight_id = #cinelights.cinelight_id
group by 	screening_date,
			shell_code
order by 	screening_date,
			shell_code
for 		read only

open cinelight_shell_attendance_csr
fetch cinelight_shell_attendance_csr into @screening_date, @shell_code
while(@@fetch_status = 0)	
begin


	select 	@attendance = isnull(sum(attendance),0)
	from 	cinelight_shell_attendance,
			#cinelights
	where	cinelight_shell_attendance.cinelight_id = #cinelights.cinelight_id
	and		screening_date = @screening_date
	and		shell_code = @shell_code

	if @@error <> 0
		goto error

	select 	@attendance_calc = (@attendance / @no_cinelights_needed)

	delete 	cinelight_shell_attendance
	where	cinelight_id = @cinelight_id
	and		screening_date = @screening_date
	and		shell_code = @shell_code

	if @@error <> 0
		goto error

	update 	cinelight_shell_attendance
	set		attendance = @attendance_calc
	where	cinelight_id in (select cinelight_id from #cinelights)
	and		screening_date = @screening_date
	and		shell_code = @shell_code

	if @@error <> 0
		goto error

	fetch cinelight_shell_attendance_csr into @campaign_no, @shell_code
end

deallocate cinelight_shell_attendance_csr

declare 	cinelight_shell_showings_csr cursor forward_only for
select 		screening_date,
			shell_code,
			print_id
from		cinelight_shell_showings,
			#cinelights
where		cinelight_shell_showings.cinelight_id = #cinelights.cinelight_id
group by 	screening_date,
			shell_code,
			print_id
order by 	screening_date,
			shell_code,
			print_id
for 		read only

open cinelight_shell_showings_csr
fetch cinelight_shell_showings_csr into @screening_date, @shell_code	, @print_id
while(@@fetch_status = 0)	
begin

	select 	@showings = isnull(sum(showings),0)
	from 	cinelight_shell_showings,
			#cinelights
	where	cinelight_shell_showings.cinelight_id = #cinelights.cinelight_id
	and		screening_date = @screening_date
	and		shell_code = @shell_code
	and		print_id = @print_id

	if @@error <> 0
		goto error

	select 	@showings_calc = (@showings / @no_cinelights_needed)

	delete 	cinelight_shell_showings
	where	cinelight_id = @cinelight_id
	and		screening_date = @screening_date
	and		shell_code = @shell_code
	and		print_id = @print_id

	if @@error <> 0
		goto error

	update 	cinelight_shell_showings
	set		showings = @showings_calc
	where	cinelight_id in (select cinelight_id from #cinelights)
	and		screening_date = @screening_date
	and		shell_code = @shell_code
	and		print_id = @print_id

	if @@error <> 0
		goto error

	fetch cinelight_shell_showings_csr into @campaign_no, @shell_code, @print_id
end

deallocate cinelight_shell_showings_csr

declare 	cinelight_spot_liability_csr cursor forward_only for
select 		liability_type,
			cancelled,
			original_liability,
			screening_date,
			campaign_no,
			package_id
from		cinelight_spot_liability,
			cinelight_spot,
			#cinelights
where		cinelight_spot.cinelight_id = #cinelights.cinelight_id
and			cinelight_spot.spot_id = cinelight_spot_liability.spot_id
group by 	liability_type,
			cancelled,
			original_liability,
			screening_date,
			campaign_no,
			package_id
order by 	liability_type,
			cancelled,
			original_liability,
			screening_date,
			campaign_no,
			package_id
for 		read only

open cinelight_spot_liability_csr
fetch cinelight_spot_liability_csr into @liability_type,
										@cancelled,
										@original_liability,
										@screening_date,
										@campaign_no,
										@package_id
while(@@fetch_status = 0)	
begin

	select 	@spot_amount = isnull(sum(spot_amount),0),
			@cinema_amount = isnull(sum(cinema_amount),0),
			@cinema_rent = isnull(sum(cinema_rent),0)
	from 	cinelight_spot_liability,
			cinelight_spot,
			#cinelights
	where	cinelight_spot.cinelight_id = #cinelights.cinelight_id
	and		cinelight_spot.spot_id = cinelight_spot_liability.spot_id
	and		cinelight_spot_liability.liability_type = @liability_type
	and		cinelight_spot_liability.cancelled = @cancelled
	and		cinelight_spot_liability.original_liability = @original_liability
	and		cinelight_spot.screening_date = @screening_date
	and		cinelight_spot.campaign_no = @campaign_no
	and		cinelight_spot.package_id = @package_id

	if @@error <> 0
		goto error

	select 	@spot_amount_calc = (@spot_amount / @no_cinelights_needed)
	select 	@cinema_amount_calc = (@cinema_amount / @no_cinelights_needed)
	select 	@cinema_rent_calc = (@cinema_rent / @no_cinelights_needed)

	delete 	cinelight_spot_liability
	from	cinelight_spot
	where	cinelight_id = @cinelight_id
	and		cinelight_spot.spot_id = cinelight_spot_liability.spot_id
	and		cinelight_spot_liability.liability_type = @liability_type
	and		cinelight_spot_liability.cancelled = @cancelled
	and		cinelight_spot_liability.original_liability = @original_liability
	and		cinelight_spot.screening_date = @screening_date
	and		cinelight_spot.campaign_no = @campaign_no
	and		cinelight_spot.package_id = @package_id

	if @@error <> 0
		goto error

	update 	cinelight_spot_liability
	set		spot_amount = @spot_amount_calc,
			cinema_amount = @cinema_amount_calc,
			cinema_rent = @cinema_rent_calc
	from	cinelight_spot
	where	cinelight_id in (select cinelight_id from #cinelights)
	and		cinelight_spot.spot_id = cinelight_spot_liability.spot_id
	and		cinelight_spot_liability.liability_type = @liability_type
	and		cinelight_spot_liability.cancelled = @cancelled
	and		cinelight_spot_liability.original_liability = @original_liability
	and		cinelight_spot.screening_date = @screening_date
	and		cinelight_spot.campaign_no = @campaign_no
	and		cinelight_spot.package_id = @package_id

	if @@error <> 0
		goto error

	fetch cinelight_spot_liability_csr into @liability_type,
											@cancelled,
											@original_liability,
											@screening_date,
											@campaign_no,
											@package_id
end

deallocate cinelight_spot_liability_csr

declare 	cinelight_spot_csr cursor forward_only for
select 		campaign_no,
			package_id,
			screening_date,
			billing_date,
			spot_status,
			spot_type
from		cinelight_spot,
			#cinelights
where		cinelight_spot.cinelight_id = #cinelights.cinelight_id
group by 	campaign_no,
			package_id,
			screening_date,
			billing_date,
			spot_status,
			spot_type
order by 	campaign_no,
			package_id,
			screening_date,
			billing_date,
			spot_status,
			spot_type
for 		read only

open cinelight_spot_csr
fetch cinelight_spot_csr into 	@campaign_no,
								@package_id,
								@screening_date,
								@billing_date,
								@spot_status,
								@spot_type
while(@@fetch_status = 0)	
begin

	select 	@rate = isnull(sum(rate),0),
			@charge_rate = isnull(sum(charge_rate),0),
			@makegood_rate = isnull(sum(makegood_rate),0),
			@cinema_rate = isnull(sum(cinema_rate),0),
			@spot_weighting = isnull(sum(spot_weighting),0),
			@cinema_weighting = isnull(sum(cinema_weighting),0)
	from 	cinelight_spot,
			#cinelights
	where	cinelight_spot.cinelight_id = #cinelights.cinelight_id
	and		cinelight_spot.screening_date = @screening_date
	and		cinelight_spot.campaign_no = @campaign_no
	and		cinelight_spot.package_id = @package_id
	and		cinelight_spot.billing_date = @billing_date
	and		cinelight_spot.spot_status = @spot_status
	and		cinelight_spot.spot_type = @spot_type

	if @@error <> 0
		goto error

	select 	@rate_calc = (@rate / @no_cinelights_needed)
	select 	@charge_rate_calc = (@charge_rate / @no_cinelights_needed)
	select 	@makegood_rate_calc = (@makegood_rate / @no_cinelights_needed)
	select 	@cinema_rate_calc = (@cinema_rate / @no_cinelights_needed)
	select 	@spot_weighting_calc = (@spot_weighting / @no_cinelights_needed)
	select 	@cinema_weighting_calc = (@cinema_weighting / @no_cinelights_needed)

	select @rate,@rate_calc, @charge_rate,@charge_rate_calc

	delete 	cinelight_certificate_xref
	where 	spot_id in (select 	spot_id 
						from 	cinelight_spot 
						where 	cinelight_id = @cinelight_id
						and		cinelight_spot.screening_date = @screening_date
						and		cinelight_spot.campaign_no = @campaign_no
						and		cinelight_spot.package_id = @package_id
						and		cinelight_spot.billing_date = @billing_date
						and		cinelight_spot.spot_status = @spot_status
						and		cinelight_spot.spot_type = @spot_type)

	delete	cinelight_spot_xref
	where 	spot_id in (select 	spot_id 
						from 	cinelight_spot 
						where 	cinelight_id = @cinelight_id
						and		cinelight_spot.screening_date = @screening_date
						and		cinelight_spot.campaign_no = @campaign_no
						and		cinelight_spot.package_id = @package_id
						and		cinelight_spot.billing_date = @billing_date
						and		cinelight_spot.spot_status = @spot_status
						and		cinelight_spot.spot_type = @spot_type)
	
	delete	delete_charge_cinelight_spots
	where 	spot_id in (select 	spot_id 
						from 	cinelight_spot 
						where 	cinelight_id = @cinelight_id
						and		cinelight_spot.screening_date = @screening_date
						and		cinelight_spot.campaign_no = @campaign_no
						and		cinelight_spot.package_id = @package_id
						and		cinelight_spot.billing_date = @billing_date
						and		cinelight_spot.spot_status = @spot_status
						and		cinelight_spot.spot_type = @spot_type)

	delete 	cinelight_spot
	where	cinelight_id = @cinelight_id
	and		cinelight_spot.screening_date = @screening_date
	and		cinelight_spot.campaign_no = @campaign_no
	and		cinelight_spot.package_id = @package_id
	and		cinelight_spot.billing_date = @billing_date
	and		cinelight_spot.spot_status = @spot_status
	and		cinelight_spot.spot_type = @spot_type

	if @@error <> 0
		goto error

	update 	cinelight_spot
	set		rate = @rate_calc,
			charge_rate = @charge_rate_calc,
			makegood_rate = @makegood_rate_calc,
			cinema_rate = @cinema_rate_calc,
			spot_weighting = @spot_weighting,
			cinema_weighting = @cinema_weighting_calc
	where	cinelight_id in (select cinelight_id from #cinelights)
	and		cinelight_spot.screening_date = @screening_date
	and		cinelight_spot.campaign_no = @campaign_no
	and		cinelight_spot.package_id = @package_id
	and		cinelight_spot.billing_date = @billing_date
	and		cinelight_spot.spot_status = @spot_status
	and		cinelight_spot.spot_type = @spot_type

	if @@error <> 0
		goto error

	fetch cinelight_spot_csr into 	@campaign_no,
									@package_id,
									@screening_date,
									@billing_date,
									@spot_status,
									@spot_type
end

deallocate cinelight_spot_csr


delete 	cinelight_campaign_complex where cinelight_id = @cinelight_id
	if @@error <> 0
		goto error

delete 	cinelight_date where cinelight_id = @cinelight_id

	if @@error <> 0
		goto error

delete 	cinelight_print_transaction where cinelight_id = @cinelight_id

	if @@error <> 0
		goto error

delete 	cinelight_dsn_player_xref where cinelight_id = @cinelight_id

	if @@error <> 0
		goto error

delete 	cinelight where cinelight_id = @cinelight_id

	if @@error <> 0
		goto error

commit transaction
return 0

error:
	rollback transaction
	return -1
GO
