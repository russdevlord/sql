/****** Object:  StoredProcedure [dbo].[p_propogate_compdate_capacity]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_propogate_compdate_capacity]
GO
/****** Object:  StoredProcedure [dbo].[p_propogate_compdate_capacity]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_propogate_compdate_capacity] 	@a_complex_id				integer,
											@a_movie_target				smallint,
											@a_session_target			smallint,
											@a_session_threshold		integer,
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
											@a_end_date					datetime,
											@a_date_range				tinyint
as

declare @error		integer

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Complex Dates
 */
if @a_date_range = 0 
begin
	if @a_cert_confirmation = 'Z'
	begin
		update 	complex_date  
		set 	campaign_safety_limit = @a_campaign_safety,   
				clash_safety_limit = @a_clash_safety,   
				movie_target = @a_movie_target,   
				session_target = @a_session_target,   
				max_ads = @a_max_ads,   
				max_time = @a_max_time,
				mg_max_ads = @a_mg_max_ads,   
				mg_max_time = @a_mg_max_time,
				cplx_max_ads = @a_cplx_max_ads,   
				cplx_max_time = @a_cplx_max_time,
				session_threshold = @a_session_threshold,
				gold_class_rights = @a_gold_class_rights,
				cinatt_weighting = @a_cinatt_weighting
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
	else
	begin
		update 	complex_date  
		set 	campaign_safety_limit = @a_campaign_safety,   
				clash_safety_limit = @a_clash_safety,   
				movie_target = @a_movie_target,   
				session_target = @a_session_target,   
				max_ads = @a_max_ads,   
				max_time = @a_max_time,
				certificate_confirmation = @a_cert_confirmation,
				mg_max_ads = @a_mg_max_ads,   
				mg_max_time = @a_mg_max_time,
				cplx_max_ads = @a_cplx_max_ads,   
				cplx_max_time = @a_cplx_max_time,
				session_threshold = @a_session_threshold,
				gold_class_rights = @a_gold_class_rights,
				cinatt_weighting = @a_cinatt_weighting
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
end
else if @a_date_range = 1
begin
	if @a_cert_confirmation = 'Z'
	begin
		update 	complex_date  
		set 	campaign_safety_limit = @a_campaign_safety,   
				clash_safety_limit = @a_clash_safety,   
				movie_target = @a_movie_target,   
				session_target = @a_session_target,   
				max_ads = @a_max_ads,   
				max_time = @a_max_time,
				mg_max_ads = @a_mg_max_ads,   
				mg_max_time = @a_mg_max_time,
				cplx_max_ads = @a_cplx_max_ads,   
				cplx_max_time = @a_cplx_max_time,
				session_threshold = @a_session_threshold,
				gold_class_rights = @a_gold_class_rights,
				cinatt_weighting = @a_cinatt_weighting
		from 	film_screening_dates fsd
		where 	complex_date.complex_id = @a_complex_id 
		and  	complex_date.screening_date = fsd.screening_date 
		and		(fsd.screening_date_status = 'O' 
		or		fsd.screening_date_status = 'C')
		
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ( 'Error', 16, 1) 
			return @error
		end	
	end
	else
	begin
		update 	complex_date  
		set 	campaign_safety_limit = @a_campaign_safety,   
				clash_safety_limit = @a_clash_safety,   
				movie_target = @a_movie_target,   
				session_target = @a_session_target,   
				max_ads = @a_max_ads,   
				max_time = @a_max_time,
				certificate_confirmation = @a_cert_confirmation,
				mg_max_ads = @a_mg_max_ads,   
				mg_max_time = @a_mg_max_time,
				cplx_max_ads = @a_cplx_max_ads,   
				cplx_max_time = @a_cplx_max_time,
				session_threshold = @a_session_threshold,
				gold_class_rights = @a_gold_class_rights,
				cinatt_weighting = @a_cinatt_weighting
		from 	film_screening_dates fsd
		where 	complex_date.complex_id = @a_complex_id 
		and  	complex_date.screening_date = fsd.screening_date 
		and		(fsd.screening_date_status = 'O' 
		or		fsd.screening_date_status = 'C')
		
		select @error = @@error
		if ( @error !=0 )
		begin
			rollback transaction
			raiserror ( 'Error', 16, 1) 
			return @error
		end	
	end
end
/*
 * Commit and Return
 */

commit transaction
return 0
GO
