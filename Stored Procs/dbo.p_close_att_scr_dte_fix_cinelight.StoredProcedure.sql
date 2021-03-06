/****** Object:  StoredProcedure [dbo].[p_close_att_scr_dte_fix_cinelight]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_close_att_scr_dte_fix_cinelight]
GO
/****** Object:  StoredProcedure [dbo].[p_close_att_scr_dte_fix_cinelight]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_close_att_scr_dte_fix_cinelight] 	@screening_date		datetime,
														@employee_id		int

as

declare		@error								int,
			@attendance_contributors			int,
			@attendance_processed				int,
			@attendance_status					char(1),
			@regional_indicator					char(1),
			@country_code						char(1),
			@average							numeric(18,6),
			@programmed_average					numeric(18,6),
			@movie_id							int,
			@campaign_no						int,
			@complex_id							int,
			@attendance							int,
			@records							int,
			@cinelight_id						int,
			@showings							int,
			@package_id							int,
			@cinelight_count					int,
			@player_name						varchar(40),
			@days								int,
			@premium_movie_count				numeric(18,6),
			@normal_movie_count					numeric(18,6),			
			@premium_movie_avg					numeric(18,6),
			@normal_movie_avg					numeric(18,6)		


set nocount on

/*
 * Obtain info from screening_dates table
 */

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete existing attendance averages
 */

delete		cinelight_attendance_history
where		screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Generate Cinelight Actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end

delete		cinelight_attendance_actuals
where		screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Generate Cinelight Actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end

delete		cinelight_attendance_digilite_actuals
where		screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Generate Cinelight Actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end

delete		cinelight_shell_attendance
where		screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Generate Cinelight Actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end

declare 	cinelight_csr cursor forward_only static for
select 		cinelight_id,
			complex_id
from		cinelight
where		cinelight_status = 'O'
order by 	cinelight_id
for 		read only


open cinelight_csr
fetch cinelight_csr into @cinelight_id, @complex_id
while(@@fetch_status = 0)
begin

	select	@cinelight_count = 0

	select @attendance = 0

	select 	@cinelight_count = count(cinelight_id)
	from	complex,
			cinelight
	where	cinelight_status = 'O'
	and		cinelight.complex_id = complex.complex_id
	and		cinelight_type = 4
	and		@complex_id = complex.complex_id

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Generate Cinelight Actuals. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	select 	@attendance = sum(attendance)
	from		movie_history
	where	complex_id = @complex_id
	and		screening_date = @screening_date

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: Could Not Generate Cinelight Actuals. Close denied.', 16, 1)
		rollback transaction
		return -1
	end

	if @attendance > 0 and @cinelight_count > 0
	begin
		insert into cinelight_attendance_history values (
		@screening_date,
		@cinelight_id,
		@attendance / @cinelight_count)
	
		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error: Could Not Generate Cinelight Actuals. Close denied.', 16, 1)
			rollback transaction
			return -1
		end
	end


	fetch cinelight_csr into @cinelight_id, @complex_id
end

deallocate cinelight_csr

/*
 * Generate Cinelight Campaign Attendance
 */

insert into cinelight_attendance_actuals
select			campaign_no,
					screening_date,
					@employee_id,
					getdate(),
					sum(attendance),
					0,
					'Y'
from			(select		campaign_no,
										screening_date,
										(select isnull(sum(attendance),0) from movie_history where complex_id = temp_table.complex_id and screening_Date = temp_table.screening_date) as attendance
					from			(select 			film_campaign.campaign_no,
																screening_date,
																complex_id
											from			film_campaign,
																cinelight_spot,
																cinelight
											where			film_campaign.campaign_no = cinelight_spot.campaign_no
											and				cinelight_spot.spot_status = 'X'
											and				cinelight_spot.cinelight_id = cinelight.cinelight_id
											and				cinelight_spot.screening_date = @screening_date
											group by 	film_campaign.campaign_no,
																screening_date,
																complex_id) as temp_table) as temp_table_2
group by 				campaign_no,
					screening_date			

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Generate Cinelight Campaign Actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end

--print 16

insert into cinelight_attendance_digilite_actuals
select 		film_campaign.campaign_no,
			@screening_date,
			cinelight_spot.cinelight_id,
			sum(isnull(attendance,0)),
			0,
			'Y'			
from		film_campaign,
			cinelight_attendance_history,
			v_cinelight_playlist_item_distinct,
			cinelight_spot
where		film_campaign.campaign_no = cinelight_spot.campaign_no
and			cinelight_spot.spot_id = v_cinelight_playlist_item_distinct.spot_id
and			cinelight_spot.cinelight_id = cinelight_attendance_history.cinelight_id
and			attendance is not null
and			attendance > 0 
and         cinelight_spot.screening_date = @screening_date
and         cinelight_attendance_history.screening_date = @screening_date
group by 	film_campaign.campaign_no,
			cinelight_spot.cinelight_id

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Generate Cinelight Panel Campaign Actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end

--print 17

insert into cinelight_shell_attendance
select 		cert_view.shell_code,
			cert_view.print_id,
			@screening_date,
			cert_view.cinelight_id,
			sum(isnull(attendance,0))			
from		cinelight_attendance_history,
			v_cinelight_shell_certificate_item_distinct cert_view
where		cert_view.cinelight_id = cinelight_attendance_history.cinelight_id
and			attendance is not null
and			attendance > 0 
and         cert_view.screening_date = @screening_date
and         cinelight_attendance_history.screening_date = @screening_date
group by 	cert_view.shell_code,
			cert_view.print_id,
			cert_view.cinelight_id

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Could Not Generate Cinelight Shell Actuals. Close denied.', 16, 1)
	rollback transaction
	return -1
end

/*
 * Close Transaction & Return
 */

commit transaction

return 0
GO
