/****** Object:  StoredProcedure [dbo].[p_op_generate_screenings]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_generate_screenings]
GO
/****** Object:  StoredProcedure [dbo].[p_op_generate_screenings]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_op_generate_screenings]		@screening_date		datetime
as

declare		@error			int,
			@package_id		int,
			@outpost_panel_id	int,
			@player_name	varchar(50),
			@showings		int,
			@days			int,
			@records		int,
			@campaign_no	int,
			@package_char	varchar(50),
		    @shell_code     varchar(50),
			@print_id       int
			
set nocount on

/*
 * Begin Transaction
 */

begin transaction

delete outpost_package_showings
where	screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Deleting outpost_panel Campaign Showings', 16, 1)
	rollback transaction
	return -1
end

delete outpost_panel_shell_showings
where	screening_date = @screening_date

select @error = @@error
if @error != 0
begin
	raiserror ('Error: Deleting outpost_panel Shell Showings', 16, 1)
	rollback transaction
	return -1
end


commit transaction

/*
 * Generate outpost_panel Package Showings
 */ 

declare		outpost_panel_showings_csr cursor static forward_only for
select 		distinct package_id,
			outpost_spot.outpost_panel_id,
			outpost_panel_dsn_player_xref.player_name
from		outpost_spot,
			v_outpost_panel_certificate_item_distinct,
			outpost_panel_dsn_player_xref
where		outpost_spot.spot_id = v_outpost_panel_certificate_item_distinct.spot_id
and			screening_date = @screening_date
and			outpost_spot.outpost_panel_id = outpost_panel_dsn_player_xref.outpost_panel_id
group by 	package_id,
			outpost_spot.outpost_panel_id,
			outpost_panel_dsn_player_xref.player_name
order by 	package_id, 
			outpost_spot.outpost_panel_id
for 		read only

open outpost_panel_showings_csr
fetch outpost_panel_showings_csr into @package_id, @outpost_panel_id, @player_name
while(@@fetch_status=0)
begin

	select @package_char = convert(varchar(50), @package_id)

	--call proc on navori server and then if row exists update with showings else insert row with 0 attendance

	exec @error = [172.29.0.13].NavoriDataReportSQL.dbo.p_get_outpost_panels_screenings @screening_date, @package_char, @player_name, @showings OUTPUT, @days OUTPUT

	if @error != 0
	begin
		raiserror ('Error: 7', 16, 1)
--		rollback transaction
		return -1
	end

	if @days < 7 and @days > 0
		select @showings = (@showings / @days) * 7
	
	if @days = 0 or @showings is null
		select @showings = -1

	insert into outpost_package_showings values (
	@screening_date,
	@outpost_panel_id,
	@package_id,
	@showings)

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: 6', 16, 1)
--		rollback transaction
		return -1
	end

	fetch outpost_panel_showings_csr into @package_id, @outpost_panel_id, @player_name
end

deallocate outpost_panel_showings_csr


declare		outpost_panel_shell_showings_csr cursor static forward_only for
select 		distinct cert_view.shell_code,
			cert_view.outpost_panel_id,
			outpost_panel_dsn_player_xref.player_name,
			cert_view.print_id
from		v_outpost_panel_shell_certificate_item_distinct cert_view,
			outpost_panel_dsn_player_xref
where		cert_view.screening_date = @screening_date
and			cert_view.outpost_panel_id = outpost_panel_dsn_player_xref.outpost_panel_id
group by 	cert_view.shell_code,
			cert_view.outpost_panel_id,
			outpost_panel_dsn_player_xref.player_name,
			cert_view.print_id
order by 	cert_view.shell_code,
			cert_view.outpost_panel_id,
			outpost_panel_dsn_player_xref.player_name,
			cert_view.print_id
for 		read only

open outpost_panel_showings_csr
fetch outpost_panel_showings_csr into @shell_code, @outpost_panel_id, @player_name, @print_id
while(@@fetch_status=0)
begin

	--call proc on navori server and then if row exists update with showings else insert row with 0 attendance

	exec @error = [172.29.0.13].NavoriDataReportSQL.dbo.p_get_outpost_panels_screenings @screening_date, @shell_code, @player_name, @showings OUTPUT, @days OUTPUT

	if @error != 0
	begin
		raiserror ('Error: 7', 16, 1)
--		rollback transaction
		return -1
	end

	if @days < 7 and @days > 0
		select @showings = (@showings / @days) * 7
	
	if @days = 0 or @showings is null
		select @showings = -1

	insert into outpost_panel_shell_showings values (
	@screening_date,
	@outpost_panel_id,
	@shell_code,
	@print_id,
	@showings)

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: 5006', 16, 1)
--		rollback transaction
		return -1
	end

	fetch outpost_panel_shell_showings_csr into @shell_code, @outpost_panel_id, @player_name, @print_id
end

deallocate outpost_panel_showings_csr

begin transaction

/*
 * get averages for outpost_panels that have no screening information
 */

declare 	incomplete_showing_csr cursor forward_only static for
select		distinct package_id
from	 	outpost_package_showings
where		screening_date = @screening_date
and			showings = -1
order by 	package_id
for			read only

open incomplete_showing_csr
fetch incomplete_showing_csr into @package_id 
while(@@fetch_status = 0)
begin

	select 	@showings = avg(showings)
	from	outpost_package_showings
	where	screening_date = @screening_date
	and		showings <> -1
	and		package_id = @package_id

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: 5', 16, 1)
		rollback transaction
		return -1
	end

	update 	outpost_package_showings
	set		showings = @showings
	where	showings = -1
	and		screening_date = @screening_date 
	and		package_id = @package_id

	select @error = @@error
	if @error != 0
	begin
		raiserror ('Error: 4', 16, 1)
		rollback transaction
		return -1
	end

	fetch incomplete_showing_csr into @package_id 
end

deallocate incomplete_showing_csr 

/*
 * Generate outpost_panel Campaign Showings
 */ 

declare		outpost_panel_campaign_showings_csr cursor static forward_only for
select 		distinct campaign_no,
			outpost_panel_id
from		outpost_spot,
			v_outpost_panel_certificate_item_distinct
where		outpost_spot.spot_id = v_outpost_panel_certificate_item_distinct.spot_id
and			screening_date = @screening_date
order by 	campaign_no, 
			outpost_panel_id
for 		read only

open outpost_panel_campaign_showings_csr
fetch outpost_panel_campaign_showings_csr into @campaign_no, @outpost_panel_id
while(@@fetch_status=0)
begin

	select 	@showings = isnull(sum(showings),0)
	from	outpost_package_showings,
			outpost_package
	where	outpost_panel_id = @outpost_panel_id
	and		screening_date = @screening_date
	and		outpost_package_showings.package_id = outpost_package.package_id
	and		outpost_package.campaign_no = @campaign_no

	--if row exists update showings else insert row with 0 attendance
	select 	@records = count(campaign_no)
	from	outpost_panel_attendance_digilite_actuals
	where	campaign_no = @campaign_no
	and		outpost_panel_id = @outpost_panel_id
	and		screening_date = @screening_date

	if @records > 0
	begin
		update 	outpost_panel_attendance_digilite_actuals
		set		showings = @showings
		where	campaign_no = @campaign_no
		and		screening_date = @screening_date
		and 	outpost_panel_id = @outpost_panel_id
		
		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error: 4', 16, 1)
			rollback transaction
			return -1
		end
	end
	else
	begin
		insert into outpost_panel_attendance_digilite_actuals values (@campaign_no, @screening_date, @outpost_panel_id,0, @showings, 'Y')

		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error: 3', 16, 1)
			rollback transaction
			return -1
		end
	end


	fetch outpost_panel_campaign_showings_csr into @campaign_no, @outpost_panel_id
end

deallocate outpost_panel_campaign_showings_csr

declare		outpost_panel_campaign_showings_csr cursor static forward_only for
select 		distinct campaign_no
from		outpost_spot,
			v_outpost_panel_certificate_item_distinct
where		outpost_spot.spot_id = v_outpost_panel_certificate_item_distinct.spot_id
and			screening_date = @screening_date
order by 	campaign_no
for 		read only

open outpost_panel_campaign_showings_csr
fetch outpost_panel_campaign_showings_csr into @campaign_no
while(@@fetch_status=0)
begin

	select 	@showings = isnull(sum(showings),0)
	from	outpost_package_showings,
			outpost_package
	where	screening_date = @screening_date
	and		outpost_package_showings.package_id = outpost_package.package_id
	and		outpost_package.campaign_no = @campaign_no

	--if row exists update showings else insert row with 0 attendance
	select 	@records = count(campaign_no)
	from	outpost_panel_attendance_actuals
	where	campaign_no = @campaign_no
	and		screening_date = @screening_date

	if @records > 0
	begin
		update 	outpost_panel_attendance_actuals
		set		showings = @showings
		where	campaign_no = @campaign_no
		and		screening_date = @screening_date
		
		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error: 2', 16, 1)
			rollback transaction
			return -1
		end
	end
	else
	begin
		insert into outpost_panel_attendance_actuals values (@campaign_no, @screening_date, 193, getdate(), 0, @showings, 'Y')

		select @error = @@error
		if @error != 0
		begin
			raiserror ('Error: 1', 16, 1)
			rollback transaction
			return -1
		end
	end
	fetch outpost_panel_campaign_showings_csr into @campaign_no
end

deallocate outpost_panel_campaign_showings_csr

/*
 * Generate outpost_panel Shell Showing
 */



commit transaction
return 0
GO
