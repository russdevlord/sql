/****** Object:  StoredProcedure [dbo].[p_client_prog_report_sub_rep]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_client_prog_report_sub_rep]
GO
/****** Object:  StoredProcedure [dbo].[p_client_prog_report_sub_rep]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_client_prog_report_sub_rep] 	@campaign_no			integer,
											@screening_date			datetime,
											@package_id				int
    
as

declare 	@product_desc 		varchar(100),
		  	@long_name			varchar(50),
		  	@classification_id 	integer,
		 	@new_spot_id		integer,
		  	@prev_spot_id		integer

/*
 * Create Temporary Tables
 */ 

create table #movie_summary
(	
	long_name		 		varchar(50),
	classification_id		integer
)

/*
 * Return Dataset
 */

select @prev_spot_id = 0 

/*
 * Declare cursors
 */

declare 	movie_summary_csr cursor static for
select 		m.long_name,
			mc.classification_id,
			spot.spot_id
from 		campaign_spot spot,
			certificate_item ci,
			certificate_group cg,
			movie_history mh,
			movie m,
			movie_country mc,
			complex c,
			branch b
where 		spot.campaign_no = @campaign_no
and			(spot.package_id = @package_id 
or			@package_id = -1)
and			spot.spot_id = ci.spot_reference 
and			ci.certificate_group = cg.certificate_group_id 
and			cg.is_movie = 'Y' 
and			cg.screening_date = @screening_date 
and			spot.screening_date = @screening_date 
and			cg.certificate_group_id = mh.certificate_group 
and			mh.movie_id = m.movie_id 
and			mc.movie_id = m.movie_id 
and			mc.movie_id = mh.movie_id 
and			spot.spot_status != 'N' 
and			c.complex_id = mh.complex_id 
and			c.complex_id = spot.complex_id 
and			c.branch_code = b.branch_code 
and			b.country_code = mc.country_code
group by 	m.long_name,
			mc.classification_id,
			spot.spot_id
union
select 		'Unknown',
			0,
			spot.spot_id
from 		campaign_spot spot,
			certificate_item ci,
			certificate_group cg
where 		spot.campaign_no = @campaign_no
and			(spot.package_id = @package_id 
or			@package_id = -1)
and			spot.spot_id = ci.spot_reference 
and			ci.certificate_group = cg.certificate_group_id 
and			cg.is_movie = 'N' 
and			cg.screening_date = @screening_date 
and			spot.screening_date = @screening_date 
and			spot.spot_status != 'N'
order by 	spot.spot_id,
			m.long_name,
			mc.classification_id

open movie_summary_csr
fetch movie_summary_csr into @long_name, @classification_id, @new_spot_id		
while(@@fetch_status = 0)
begin
	
	if @prev_spot_id <> @new_spot_id
	begin
/*		if @classification_id < 100 
			select @classification_id = @classification_id + 105
*/
		insert into #movie_summary
		(long_name, 
		 classification_id) values
		(@long_name,
		 @classification_id)
	end  

	select @prev_spot_id = @new_spot_id

	fetch movie_summary_csr into @long_name, @classification_id, @new_spot_id		
end
close movie_summary_csr 
deallocate movie_summary_csr 

select 		count(long_name), 
			long_name,
			classification_id
from 		#movie_summary
group by 	long_name,
			classification_id
GO
