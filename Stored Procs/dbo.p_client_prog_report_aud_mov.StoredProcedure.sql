/****** Object:  StoredProcedure [dbo].[p_client_prog_report_aud_mov]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_client_prog_report_aud_mov]
GO
/****** Object:  StoredProcedure [dbo].[p_client_prog_report_aud_mov]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_client_prog_report_aud_mov] 	@campaign_no				integer,
        																			@screening_date			datetime,
																					@package_id				int
    
as

declare		@product_desc 				varchar(100),
				@market_name				varchar(50),
				@movie_count					numeric(30,15),
				@prev_spot_id					int,
				@n_up								int,
				@row_ident						int,
				@total_achievement		numeric(30,15),
				@long_name						varchar(50),
				@classification_id	 		integer

set nocount on

/*
 * Create Temporary Tables
 */ 


create table #movie_summary
(	
	row_ident						int								null,
	long_name_1		 			varchar(50)					null,
	classification_id_1		integer							null,
	movie_count_1				numeric(30,15)				null,
	long_name_2		 		varchar(50)					null,
	classification_id_2		integer							null,
	movie_count_2				numeric(30,15)				null,
	long_name_3		 		varchar(50)					null,
	classification_id_3		integer							null,
	movie_count_3				numeric(30,15)				null
)

create table #movie_details
(
	long_name					varchar(50)					null,
	classification_id			integer						null,
	movie_count					numeric(30,15)				null,
)
/*
 * Return Dataset
 */

select @prev_spot_id = 0

/*
 * Declare cursors
 */

select			@total_achievement = sum(achieved_attendance)
from			(select			sum(cinetam_movie_complex_estimates.attendance) as achieved_attendance
				from			inclusion_spot
				inner join		inclusion_campaign_spot_xref on inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id and  inclusion_spot.inclusion_id = inclusion_campaign_spot_xref.inclusion_id
				inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
				inner join		campaign_spot on inclusion_campaign_spot_xref.spot_id = campaign_spot.spot_id
				inner join		v_certificate_item_distinct on inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
				inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
				inner join		cinetam_movie_complex_estimates on movie_history.movie_id = cinetam_movie_complex_estimates.movie_id 
									and				movie_history.complex_id = cinetam_movie_complex_estimates.complex_id 
									and				movie_history.screening_date = cinetam_movie_complex_estimates.screening_date
				where			campaign_spot.campaign_no = @campaign_no 
				and				(campaign_spot.package_id = @package_id 
				or				@package_id = -1) 
				and				movie_history.screening_date = @screening_date 
				and				cinetam_movie_complex_estimates.screening_date = @screening_date
				and				cinetam_movie_complex_estimates.cinetam_reporting_demographics_id = 0) as sub_table


insert into		#movie_details
select			long_name, 
				classification_id,
				sum(achieved_attendance)
from			(select			movie_history.movie_id,
								sum(cinetam_movie_complex_estimates.attendance) as achieved_attendance,
								movie_history.country
				from			inclusion_spot
				inner join		inclusion_campaign_spot_xref on inclusion_spot.spot_id = inclusion_campaign_spot_xref.inclusion_spot_id and  inclusion_spot.inclusion_id = inclusion_campaign_spot_xref.inclusion_id
				inner join		inclusion on inclusion_spot.inclusion_id = inclusion.inclusion_id
				inner join		campaign_spot on inclusion_campaign_spot_xref.spot_id = campaign_spot.spot_id
				inner join		v_certificate_item_distinct on inclusion_campaign_spot_xref.spot_id = v_certificate_item_distinct.spot_reference
				inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
				inner join		cinetam_movie_complex_estimates on movie_history.movie_id = cinetam_movie_complex_estimates.movie_id 
				and				movie_history.complex_id = cinetam_movie_complex_estimates.complex_id 
				and				movie_history.screening_date = cinetam_movie_complex_estimates.screening_date
				where			campaign_spot.campaign_no = @campaign_no 
				and				(campaign_spot.package_id = @package_id 
				or				@package_id = -1) 
				and				movie_history.screening_date = @screening_date 
				and				cinetam_movie_complex_estimates.screening_date = @screening_date
				and				cinetam_movie_complex_estimates.cinetam_reporting_demographics_id = 0
				group by		movie_history.movie_id,
								movie_history.country) as sub_table
inner join		movie on sub_table.movie_id = movie.movie_id
inner join		movie_country on sub_table.country = movie_country.country_code and sub_table.movie_id = movie_country.movie_id
group by		long_name, 
				classification_id
order by		sum(achieved_attendance) desc

declare			movie_summary_csr cursor static for
select			long_name,
				classification_id,
				movie_count		 
from			#movie_details
order by		movie_count desc
	        
select	@n_up = 1,
			@row_ident = 1

open movie_summary_csr
fetch movie_summary_csr into @long_name, @classification_id, @movie_count		
while(@@fetch_status = 0)
begin

	if @n_up = 1 and @movie_count > 0 
	begin	
		insert into #movie_summary
		(row_ident) values
		(@row_ident)

		update 	#movie_summary
		set 	long_name_1 = @long_name,
				classification_id_1 = @classification_id,
				movie_count_1 = @movie_count / @total_achievement
		where 	row_ident = @row_ident

		select @n_up = @n_up + 1
	end
	else if @n_up = 2 and @movie_count > 0 
	begin	
		update 	#movie_summary
		set 	long_name_2 = @long_name,
				classification_id_2 = @classification_id,
				movie_count_2 = @movie_count / @total_achievement
		where 	row_ident = @row_ident

		select @n_up = @n_up + 1
	end
	else if @n_up = 3 and @movie_count > 0 
	begin	
		update 	#movie_summary
		set 	long_name_3 = @long_name,
				classification_id_3 = @classification_id,
				movie_count_3 = @movie_count / @total_achievement
		where 	row_ident = @row_ident

		select @n_up = 1
		select @row_ident = @row_ident + 1
	end

	fetch movie_summary_csr into @long_name, @classification_id, @movie_count		
end

close movie_summary_csr 
deallocate movie_summary_csr 

select 		movie_count_1, 
				long_name_1,
				classification_id_1,
				movie_count_2, 
				long_name_2,
				classification_id_2,
				movie_count_3, 
				long_name_3,
				classification_id_3,
				1
from 		#movie_summary
GO
