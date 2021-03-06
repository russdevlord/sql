/****** Object:  StoredProcedure [dbo].[p_package_instruction_update]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_package_instruction_update]
GO
/****** Object:  StoredProcedure [dbo].[p_package_instruction_update]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_package_instruction_update] @source_pkg_id		int,
                                      	  @target_pkg_id		int
as
set nocount on 
/*
 * Declare Variables
 */

declare @error					int,
        @errorode					int,
		  @scrn_pos 			tinyint,
        @scrn_trailers 		char(1),
        @school_hols 		tinyint,
        @follow_film 		char(1),
		  @movie_mix 			char(1),
		  @movie_bands 		char(1),
		  @cert_priority		smallint,
		  @client_clash		char(1),
		  @movie_brief			varchar(100) 

/*
 * Get the Source Package Details
 */

select @scrn_pos = pack.screening_position,
       @scrn_trailers = pack.screening_trailers,
       @school_hols = pack.school_holidays,
       @follow_film = pack.follow_film,
		 @movie_mix = pack.movie_mix,
		 @movie_bands = pack.movie_bands,
		 @cert_priority = pack.certificate_priority,
		 @client_clash = pack.client_clash,
		 @movie_brief = pack.movie_brief
  from campaign_package pack   
 where pack.package_id = @source_pkg_id

/*
 * Begin Transaction
 */

begin transaction

/*
 * Delete Campaign Audience record for target Package id
 */

delete campaign_audience
 where campaign_audience.package_id = @target_pkg_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'p_package_instruction_update : DB Error %1', 11, 1, @error)
        return -1
end

/*
 * Delete Campaign Category record for target Package id
 */

delete campaign_category
 where campaign_category.package_id = @target_pkg_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'p_package_instruction_update : Delete DB Error %1', 11, 1, @error)
	return -1
end

/*
 * Delete Campaign Classification record for target Package id
 */

delete campaign_classification
 where campaign_classification.package_id = @target_pkg_id


select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'p_package_instruction_update : Delete (2) DB Error %1', 11, 1, @error)
	return -1
end


/*
 * Delete Movie Screening Instructions record for target Package id
 */

delete movie_screening_instructions
 where movie_screening_instructions.package_id = @target_pkg_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'p_package_instruction_update : Delete(3) DB Error %1', 11, 1, @error)
	return -1
end

/*
 * Insert Campaign Audience record for target Package id
 */

insert into campaign_audience (audience_profile_code, 
										 package_id, 
										 instruction_type)
						
								select audience_profile_code,
										 @target_pkg_id,
										 instruction_type
								  from campaign_audience
								 where campaign_audience.package_id = @source_pkg_id
		
								select @error = @@error
								if (@error !=0)
								begin
									rollback transaction
									return -1
								end



/*
 * Insert Campaign Category record for target Package id
 */

insert into campaign_category (movie_category_code,
										 package_id,
										 instruction_type
										)
						
								select movie_category_code,
										 @target_pkg_id,
										 instruction_type
								  from campaign_category
								 where campaign_category.package_id = @source_pkg_id
		
								select @error = @@error
								if (@error !=0)
								begin
									rollback transaction
									return -1
								end



/*
 * Insert Campaign Classification record for target Package id
 */

insert into campaign_classification (classification_id,
										 		 package_id,
										 		 instruction_type
												)
						
								select classification_id,
								 		 @target_pkg_id,
								 		 instruction_type
								  from campaign_classification
								 where campaign_classification.package_id = @source_pkg_id
		
								select @error = @@error
								if (@error !=0)
								begin
									rollback transaction
									return -1
								end

/*
 * Insert Movie Screening Instructions record for target Package id
 */

insert into movie_screening_instructions (movie_id,
										 		 		package_id,
										 		 		instruction_type,
														sequence_no
													  )
						
					 						  select movie_id,
								 		 		      @target_pkg_id,
										            instruction_type,
										            sequence_no
		  								       from movie_screening_instructions
								 				where movie_screening_instructions.package_id = @source_pkg_id
		
											  select @error = @@error
											  if (@error !=0)
											  begin
												  rollback transaction
												  return -1
   										  end



/*
 * Update Campaign Package record for target Package id
 */

update campaign_package
   set screening_position = @scrn_pos,
       screening_trailers = @scrn_trailers,
       school_holidays =  @school_hols,
       follow_film = @follow_film, 		
		 movie_mix =  @movie_mix, 			
		 movie_bands = @movie_bands, 		
		 certificate_priority = @cert_priority,		
		 client_clash = @client_clash,		
		 movie_brief = @movie_brief			
 where package_id = @target_pkg_id

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	return @error
end	

/*
 * Commit and Return
 */

commit transaction
return 0
GO
