/****** Object:  StoredProcedure [dbo].[p_op_propogate_compdate_capacity]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_propogate_compdate_capacity]
GO
/****** Object:  StoredProcedure [dbo].[p_op_propogate_compdate_capacity]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_op_propogate_compdate_capacity] 	@a_player_name				varchar(100),
																											@a_max_ads						smallint,
																											@a_max_time					smallint,
																											@a_max_ads_trailers		smallint,
																											@a_max_time_trailers		smallint,
																											@a_min_ads						smallint,
																											@a_start_date					datetime,
																											@a_end_date					datetime,
																											@a_date_range					tinyint
as

declare @error		integer

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Player Dates
 */
 
if @a_date_range = 0 
begin
	update 	outpost_player_date
	set 			max_ads = @a_max_ads,   
					max_time = @a_max_time,
					max_ads_trailers = @a_max_ads_trailers,   
					max_time_trailers = @a_max_time_trailers,
					min_ads = @a_min_ads
	where 		outpost_player_date.player_name = @a_player_name
	and  		outpost_player_date.screening_date between @a_start_date and @a_end_date
	
	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	
end
else if @a_date_range = 1
begin
	update 	outpost_player_date
	set 			max_ads = @a_max_ads,   
					max_time = @a_max_time,
					max_ads_trailers = @a_max_ads_trailers,   
					max_time_trailers = @a_max_time_trailers,
					min_ads = @a_min_ads
	from 		outpost_screening_dates osd
	where 		outpost_player_date.player_name = @a_player_name
	and  		outpost_player_date.screening_date = osd.screening_date 
	and			(osd.screening_date_status = 'O' 
	or				osd.screening_date_status = 'C')
		
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
