/****** Object:  StoredProcedure [dbo].[p_arc_film_campaign_movie]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_arc_film_campaign_movie]
GO
/****** Object:  StoredProcedure [dbo].[p_arc_film_campaign_movie]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_arc_film_campaign_movie] 	@campaign_no		integer

as

declare		@error              	integer,
			@movie_id				integer,
			@sessions_held			integer,
			@session_target			integer,
			@package_id				integer,
			@spot_type				char(1),
			@scheduled_count		integer,
			@makeup_count			integer,
			@country_code			char(1),
			@record_exists			integer,
			@campaign_status		char(1)

/*
 * Get Country Code from Film Campaign
 */
select @country_code = branch.country_code
  from film_campaign, branch
 where campaign_no = @campaign_no
   and film_campaign.branch_code = branch.branch_code

select @error = @@error
if(@error != 0)
begin
	return -1
end


begin transaction
/*
 * Remove Old History
 */
delete film_campaign_movie_archive
 where campaign_no = @campaign_no

select @error = @@error
if(@error != 0)
begin
	rollback transaction
	return -1
end

/*
 * Loop Records
 */
	declare movie_archive_csr cursor static for 
	SELECT	ISNULL(mh.movie_id, 0),
			COUNT(DISTINCT spot.spot_id),
			cpack.package_id, 
			spot.spot_type, 
			ISNULL(mh.country, @country_code)
	FROM	campaign_package AS cpack INNER JOIN
			campaign_spot AS spot ON cpack.package_id = spot.package_id INNER JOIN
			certificate_item AS ci ON spot.spot_id = ci.spot_reference INNER JOIN
			certificate_group AS cg ON ci.certificate_group = cg.certificate_group_id LEFT OUTER JOIN
			movie_history AS mh ON cg.certificate_group_id = mh.certificate_group INNER JOIN
			complex_date AS cd ON spot.screening_date = cd.screening_date AND spot.complex_id = cd.complex_id INNER JOIN
			complex AS cplx ON cd.complex_id = cplx.complex_id
	WHERE	(cpack.campaign_no = @campaign_no) 
	AND		(spot.campaign_no = @campaign_no) 
	AND		(spot.spot_status = 'X')
	GROUP BY mh.movie_id, cpack.package_id, spot.spot_type, mh.country
	ORDER BY cpack.package_id, mh.movie_id, spot.spot_type, mh.country
	for read only

open movie_archive_csr
fetch movie_archive_csr into @movie_id, @sessions_held, @package_id, @spot_type, @country_code
while(@@fetch_status = 0)
begin

		if @spot_type = 'M'
		begin
			select @scheduled_count = 0
			select @makeup_count = @sessions_held
		end
		else 
		begin
			select @scheduled_count = @sessions_held
			select @makeup_count = 0
		end

		select @record_exists = count(campaign_no)
		  from film_campaign_movie_archive
		 where campaign_no = @campaign_no and
				 package_id = @package_id and 
				 movie_id = @movie_id and
				 country_code = @country_code
	
		if @record_exists = 0 
		begin
			insert into film_campaign_movie_archive (
			campaign_no,
			movie_id,
			package_id,
			country_code,
			scheduled_count,
			makeup_count ) 
			values (
			@campaign_no,
			@movie_id,
			@package_id,
			@country_code,
			@scheduled_count,
			@makeup_count )
		end
		else
		begin
			update	film_campaign_movie_archive
			set		scheduled_count = scheduled_count + @scheduled_count,
					makeup_count = makeup_count + @makeup_count
			 where	campaign_no = @campaign_no and
					package_id = @package_id and 
					movie_id = @movie_id and
					country_code = @country_code
		end
		
		select @error = @@error
		if(@error != 0)
		begin
			goto error
		end

	fetch movie_archive_csr into @movie_id, @sessions_held, @package_id, @spot_type, @country_code
end
close movie_archive_csr
deallocate movie_archive_csr

/*
 * Commit Transaction
 */
commit transaction
return 0

/*
 * Error Handler
 */
error:
	raiserror ('Failed to generate archive movies', 16, 1)
	rollback transaction
 	close movie_archive_csr
	deallocate movie_archive_csr
	return -1
GO
