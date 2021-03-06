/****** Object:  StoredProcedure [dbo].[p_campaign_evaluation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_evaluation]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_evaluation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_campaign_evaluation]  @campaign_no 	int
as

/*
 * Decalare Variables
 */

declare @agency_name			varchar(100),
        @client_name			varchar(100),
		  @campaign_status 	char(1),
        @product_desc 		varchar(255),
		  @start_date			datetime,
        @end_date				datetime,
        @attendance_analysis    char(1),
        @cinatt_data_valid      char(1)

/*
 * Return Campaign Evaluation
 */

select @cinatt_data_valid = 'N'

  select @product_desc = fc.product_desc,   
		   @start_date = fc.start_date,
		   @end_date = fc.end_date,
			@campaign_status = fc.campaign_status,
         @agency_name = agency_name,
         @client_name = client_name,
         @attendance_analysis = fc.attendance_analysis
    from film_campaign fc,
         agency,
         client
   where fc.campaign_no = @campaign_no and
         fc.agency_id = agency.agency_id and
 		   fc.client_id = client.client_id


if @attendance_analysis = 'Y'
begin
    if not exists(
        SELECT  1
        FROM    attendance_campaign_Actuals
        where   campaign_no = @campaign_no
        and     data_valid = 'N')
            if exists(
                SELECT  1
                FROM    attendance_campaign_Actuals
                where   campaign_no = @campaign_no
                and     data_valid = 'Y')
                    select @cinatt_data_valid = 'Y'
end


  select @campaign_no,  
         @product_desc,   
			@campaign_status,
		   @start_date,
		   @end_date, 
         @client_name,   
         @agency_name,
		   mc.classification_id,
	      mc.movie_name,
	      c.country_name,
		   mc.country_code,
			cpack.package_code,
			cpack.package_desc,
			fcma.scheduled_count,
			fcma.makeup_count,
            @attendance_analysis 'attendance_analysis',
            @cinatt_data_valid 'cinatt_data_valid'
    from campaign_package cpack,   
			movie_country mc,
			country c,
			film_campaign_movie_archive fcma
   where cpack.campaign_no = @campaign_no and
			mc.movie_id = fcma.movie_id and
			fcma.movie_id <> 0 and
			fcma.campaign_no = cpack.campaign_no and
			fcma.country_code = mc.country_code and 
			mc.country_code = c.country_code and 
			fcma.package_id = cpack.package_id
UNION
  select @campaign_no,  
         @product_desc,   
			@campaign_status,
		   @start_date,
		   @end_date, 
         @client_name,   
         @agency_name,
		   999,
	      'Unknown',
	      c.country_name,
		   c.country_code,
			cpack.package_code,
			cpack.package_desc,
			fcma.scheduled_count,
			fcma.makeup_count,
            @attendance_analysis 'attendance_analysis',
            @cinatt_data_valid 'cinatt_data_valid'
    from campaign_package cpack,   
			country c,
			film_campaign_movie_archive fcma
   where cpack.campaign_no = @campaign_no and
			fcma.movie_id = 0 and
			fcma.campaign_no = cpack.campaign_no and
			fcma.country_code = c.country_code and 
			fcma.package_id = cpack.package_id

/*
 * Return Success
 */

return 0
GO
