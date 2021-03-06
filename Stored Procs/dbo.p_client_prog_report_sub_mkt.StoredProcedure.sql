/****** Object:  StoredProcedure [dbo].[p_client_prog_report_sub_mkt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_client_prog_report_sub_mkt]
GO
/****** Object:  StoredProcedure [dbo].[p_client_prog_report_sub_mkt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_client_prog_report_sub_mkt] 	@campaign_no			integer,
                                            @screening_date			datetime,
                                            @package_id				int,
                                            @film_market_no         int                                        
as

declare @product_desc 			varchar(100),
		@long_name				varchar(50),
		@classification_id 		integer,
		@movie_count			integer,
		@prev_spot_id			integer,
		@n_up					int,
		@row_ident				int

set nocount on
/*
 * Create Temporary Tables
 */ 

create table #movie_summary
(	
	row_ident				int					null,
	long_name_1		 		varchar(50)			null,
	classification_id_1		integer				null,
	movie_count_1			integer				null,
	long_name_2		 		varchar(50)			null,
	classification_id_2		integer				null,
	movie_count_2			integer				null,
	long_name_3		 		varchar(50)			null,
	classification_id_3		integer				null,
	movie_count_3			integer				null
)

/*
 * Return Dataset
 */

select @prev_spot_id = 0

/*
 * Declare cursors
 */

 declare movie_summary_csr cursor static for
  select m.long_name,
 		 mc.classification_id,
		 count(distinct spot.spot_id)
    from campaign_spot spot,
         certificate_item ci,
         certificate_group cg,
		 movie_history mh,
		 movie m,
		 movie_country mc,
		 complex c,
		 branch b
   where spot.campaign_no = @campaign_no and
		 (spot.package_id = @package_id or
		 @package_id = -1) and
         spot.spot_id = ci.spot_reference and
         ci.certificate_group = cg.certificate_group_id and
         cg.is_movie = 'Y' and
         cg.screening_date = @screening_date and
         spot.screening_date = @screening_date and
         cg.certificate_group_id = mh.certificate_group and
	     mh.movie_id = m.movie_id and
	     mc.movie_id = m.movie_id and
	     mc.movie_id = mh.movie_id and
            spot.spot_status != 'N' and
		c.complex_id = mh.complex_id and
		c.complex_id = spot.complex_id and
		c.branch_code = b.branch_code and
		b.country_code = mc.country_code and
        c.film_market_no = @film_market_no
group by m.long_name,
 	     mc.classification_id
union
  select 'Unknown',
 		 0,
		 count(distinct spot.spot_id)
    from campaign_spot spot,
         certificate_item ci,
         certificate_group cg,
         complex c
   where spot.campaign_no = @campaign_no and
		 (spot.package_id = @package_id or
		 @package_id = -1) and
         spot.spot_id = ci.spot_reference and
         ci.certificate_group = cg.certificate_group_id and
         cg.is_movie = 'N' and
         cg.screening_date = @screening_date and
         spot.screening_date = @screening_date and
         spot.spot_status != 'N' and
         c.complex_id = cg.complex_id and
         c.film_market_no = @film_market_no
order by count(distinct spot.spot_id) DESC,
		 m.long_name,
 		 mc.classification_id
         
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
				movie_count_1 = @movie_count
		where 	row_ident = @row_ident

		select @n_up = @n_up + 1
	end
	else if @n_up = 2 and @movie_count > 0 
	begin	
		update 	#movie_summary
		set 	long_name_2 = @long_name,
				classification_id_2 = @classification_id,
				movie_count_2 = @movie_count 
		where 	row_ident = @row_ident

		select @n_up = @n_up + 1
	end
	else if @n_up = 3 and @movie_count > 0 
	begin	
		update 	#movie_summary
		set 	long_name_3 = @long_name,
				classification_id_3 = @classification_id,
				movie_count_3 = @movie_count 
		where 	row_ident = @row_ident

		select @n_up = 1
		select @row_ident = @row_ident + 1
	end

	fetch movie_summary_csr into @long_name, @classification_id, @movie_count		
end

close movie_summary_csr 
deallocate movie_summary_csr 

select 	movie_count_1, 
		long_name_1,
		classification_id_1,
		movie_count_2, 
		long_name_2,
		classification_id_2,
		movie_count_3, 
		long_name_3,
		classification_id_3,
		1
  from 	#movie_summary
GO
