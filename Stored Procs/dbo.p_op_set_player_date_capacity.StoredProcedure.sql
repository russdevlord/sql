/****** Object:  StoredProcedure [dbo].[p_op_set_player_date_capacity]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_set_player_date_capacity]
GO
/****** Object:  StoredProcedure [dbo].[p_op_set_player_date_capacity]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create  PROC [dbo].[p_op_set_player_date_capacity]	@player_name				varchar(40),
																								@generation_status		char(1),
																								@generation_user			varchar(30),
																								@generation					datetime,
																								@lock_user					varchar(30),
																								@locked							char(1),
																								@revision						int,
																								@max_time					int,
																								@max_ads						int,
																								@max_time_trailers		int,
																								@max_ads_trailers		int,
																								@min_ads						int,
																								@a_start_date				datetime,
																								@a_end_date				datetime
as

declare @error     int


/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Maximum Ads
 */

if(@max_ads is not null)
begin

	update		outpost_player_date  
	set 				max_ads = @max_ads   
	where 		outpost_player_date.player_name = @player_name 
	and				outpost_player_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ('Error updating player max ads', 16, 1)
		return @error
	end	
end

/*
 * Update Maximum Time
 */

if(@max_time is not null)
begin

	update 		outpost_player_date  
	set 				max_time = @max_time
	where 		outpost_player_date.player_name = @player_name 
	and				outpost_player_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror  ('Error updating panel max ads', 16, 1)
		return @error
	end	
end

/*
 * Update MG Maximum Ads
 */

if(@max_time_trailers is not null)
begin

	update 	outpost_player_date  
	set 	max_time_trailers = @max_time_trailers   
	where 	outpost_player_date.player_name = @player_name 
	and		outpost_player_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	
end

/*
 * Update MG Maximum Time
 */

if(@max_ads_trailers is not null)
begin

	update 	outpost_player_date  
	set 	max_ads_trailers = @max_ads_trailers
	where 	outpost_player_date.player_name = @player_name 
	and		outpost_player_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	
end

/*
 * Update Complex Maximum Ads
 */

if(@min_ads is not null)
begin

	update 	outpost_player_date  
	set 	min_ads = @min_ads   
	where 	outpost_player_date.player_name = @player_name 
	and		outpost_player_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end



/*
 * Commit and Return
 */

commit transaction
return 0
GO
