/****** Object:  StoredProcedure [dbo].[p_set_compdate_capacity]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_set_compdate_capacity]
GO
/****** Object:  StoredProcedure [dbo].[p_set_compdate_capacity]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_set_compdate_capacity] @a_complex_id				int,
									@a_movie_target				smallint,
									@a_session_target			smallint,
									@a_session_threshold		int,
									@a_max_ads					smallint,
									@a_max_time					smallint,
									@a_mg_max_ads				smallint,
									@a_mg_max_time				smallint,
									@a_cplx_max_ads				smallint,
									@a_cplx_max_time			smallint,
									@a_campaign_safety			smallint,
									@a_clash_safety				smallint,
	                    			@a_cert_confirmation		char(1),	
									@a_gold_class_rights		char(1),
									@a_cinatt_weighting			numeric(6,4),
									@a_start_date				datetime,
									@a_end_date					datetime
as

declare @error     int

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Campaign Safety Limit
 */

if(@a_campaign_safety is not null)
begin

	update 	complex_date  
	set 	campaign_safety_limit = @a_campaign_safety   
	where 	complex_date.complex_id = @a_complex_id 
	and  	complex_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end

/*
 * Update Clash Safety Limit
 */

if(@a_clash_safety is not null)
begin

	update 	complex_date  
	set 	clash_safety_limit = @a_clash_safety   
	where 	complex_date.complex_id = @a_complex_id 
	and		complex_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end

/*
 * Update Movie Target
 */

if(@a_movie_target is not null)
begin

	update 	complex_date  
	set 	movie_target = @a_movie_target   
	where 	complex_date.complex_id = @a_complex_id 
	and		complex_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end

/*
 * Update Session Target
 */

if(@a_session_target is not null)
begin
	
	update 	complex_date  
	set 	session_target = @a_session_target
	where 	complex_date.complex_id = @a_complex_id 
	and		complex_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end

/*
 * Update Session Threshold
 */

if(@a_session_threshold is not null)
begin

	update 	complex_date  
	set 	session_threshold = @a_session_threshold
	where 	complex_date.complex_id = @a_complex_id 
	and		complex_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end

/*
 * Update Maximum Ads
 */

if(@a_max_ads is not null)
begin

	update 	complex_date  
	set 	max_ads = @a_max_ads   
	where 	complex_date.complex_id = @a_complex_id 
	and		complex_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end

/*
 * Update Maximum Time
 */

if(@a_max_time is not null)
begin

	update 	complex_date  
	set 	max_time = @a_max_time
	where 	complex_date.complex_id = @a_complex_id 
	and		complex_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end

/*
 * Update MG Maximum Ads
 */

if(@a_mg_max_ads is not null)
begin

	update 	complex_date  
	set 	mg_max_ads = @a_mg_max_ads   
	where 	complex_date.complex_id = @a_complex_id 
	and		complex_date.screening_date between @a_start_date and @a_end_date

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

if(@a_mg_max_time is not null)
begin

	update 	complex_date  
	set 	mg_max_time = @a_mg_max_time
	where 	complex_date.complex_id = @a_complex_id 
	and		complex_date.screening_date between @a_start_date and @a_end_date

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

if(@a_cplx_max_ads is not null)
begin

	update 	complex_date  
	set 	cplx_max_ads = @a_cplx_max_ads   
	where 	complex_date.complex_id = @a_complex_id 
	and		complex_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end

/*
 * Update Complex Maximum Time
 */

if(@a_cplx_max_time is not null)
begin

	update 	complex_date  
	set 	cplx_max_time = @a_cplx_max_time
	where 	complex_date.complex_id = @a_complex_id 
	and		complex_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end

/*
 * Update Certificate Confirmation
 */

if(@a_cert_confirmation is not null) and (@a_cert_confirmation <> 'Z')
begin

	update 	complex_date  
	set 	certificate_confirmation = @a_cert_confirmation
	where 	complex_date.complex_id = @a_complex_id 
	and		complex_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end

/*
 * Update Gold Class Rights
 */

if(@a_gold_class_rights is not null) 
begin

	update 	complex_date  
	set 	gold_class_rights = @a_gold_class_rights
	where 	complex_date.complex_id = @a_complex_id 
	and		complex_date.screening_date between @a_start_date and @a_end_date

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		return @error
	end	

end

/*
 * Update Cinatt Weighting
 */

if(@a_cinatt_weighting is not null) 
begin

	update 	complex_date  
	set 	cinatt_weighting = @a_cinatt_weighting
	where 	complex_date.complex_id = @a_complex_id 
	and		complex_date.screening_date between @a_start_date and @a_end_date

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
