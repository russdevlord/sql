/****** Object:  StoredProcedure [dbo].[p_campaign_evaluation_sub]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_evaluation_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_evaluation_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_campaign_evaluation_sub] 	@campaign_no	integer
    
as

declare @product_desc 			varchar(100),
		@long_name				varchar(50),
		@classification_id		integer,
		@new_spot_id			integer,
		@prev_spot_id			integer,
		@screened_1				integer,
		@long_name_1			varchar(50),
		@classification_id_1	integer,
		@screened_2				integer,
		@long_name_2			varchar(50),
		@classification_id_2	integer,
		@screened_3				integer,
		@long_name_3			varchar(50),
		@classification_id_3	integer,
		@screening_date			datetime,
        @start_date             datetime,
        @end_date               datetime,
        @campaign_status        char,
        @agency_name            varchar(50),
        @client_name            varchar(50)

begin

set nocount on
/*
 * Create Temporary Tables
 */ create table #movie_summary
(	long_name		 		varchar(50),
	classification_id		integer,
	screening_week			datetime
)

create table #movie_summary_screened
(	screened				integer,
	long_name		 		varchar(50),
	classification_id		integer,
	screening_week			datetime
)

create table #movie_summary_3_n
(	
	screening_week			datetime,
	long_name_1		 		varchar(50),
	classification_id_1		integer,
	screened_1				integer,
	long_name_2		 		varchar(50),
	classification_id_2		integer,
	screened_2				integer,
	long_name_3		 		varchar(50),
	classification_id_3		integer,
	screened_3				integer,
    product_desc           varchar(100),
    start_date             datetime,
    end_date               datetime,
    campaign_status        char,
    agency_name            varchar(50),
    client_name            varchar(50)
)    
select  @product_desc = fc.product_desc,   
        @start_date = fc.start_date,
        @end_date = fc.end_date,
        @campaign_status = fc.campaign_status,
        @agency_name = agency_name,
        @client_name = client_name
from    film_campaign fc,
        agency,
        client
where   fc.campaign_no = @campaign_no and
        fc.agency_id = agency.agency_id and
        fc.client_id = client.client_id


/*
 * Return Dataset
 */

select @prev_spot_id = 0
/*
 * Declare cursors
 */
declare	scrn_week_csr cursor static for
select distinct cg.screening_date
from	campaign_spot spot,
         certificate_item ci,
         certificate_group cg
where	spot.campaign_no = @campaign_no and
         spot.spot_id = ci.spot_reference and
         ci.certificate_group = cg.certificate_group_id
order by cg.screening_date

open scrn_week_csr
fetch scrn_week_csr into @screening_date
while(@@fetch_status = 0)
	begin

		 declare movie_summary_csr cursor static for
		  select m.long_name,
		 		 mc.classification_id,
				 spot.spot_id
		    from campaign_spot spot,
		         certificate_item ci,
		         certificate_group cg,
				 movie_history mh,
				 movie m,
				 movie_country mc
		   where spot.campaign_no = @campaign_no and
		         spot.spot_id = ci.spot_reference and
		         ci.certificate_group = cg.certificate_group_id and
		         cg.is_movie = 'Y' and
		         cg.screening_date = @screening_date and
		         spot.screening_date = @screening_date and
		         cg.certificate_group_id = mh.certificate_group and
			     mh.movie_id = m.movie_id and
			     mc.movie_id = m.movie_id and
			     mc.movie_id = mh.movie_id and
--		            spot.spot_status != 'N' and
				spot.spot_status in ('X')
		group by m.long_name,
		 	     mc.classification_id,
			 	 spot.spot_id
		union
		  select 'Unknown',
		 		 0,
				 spot.spot_id
		    from campaign_spot spot,
		         certificate_item ci,
		         certificate_group cg
		   where spot.campaign_no = @campaign_no and
		         spot.spot_id = ci.spot_reference and
		         ci.certificate_group = cg.certificate_group_id and
		         cg.is_movie = 'N' and
		         cg.screening_date = @screening_date and
		         spot.screening_date = @screening_date and
--		            spot.spot_status != 'N'  and
				spot.spot_status in ('X')
		group by spot.spot_id
		order by spot.spot_id,
				 m.long_name,
		 		 mc.classification_id
		         
		 
		
		open movie_summary_csr
		fetch movie_summary_csr into @long_name, @classification_id, @new_spot_id		
		while(@@fetch_status = 0)
		begin
			
			if @prev_spot_id <> @new_spot_id
			begin
--				if @classification_id < 100 
--					select @classification_id = @classification_id + 100
		
				insert into #movie_summary
				(long_name, 
				 classification_id,
				 screening_week	) values
				(@long_name,
				 @classification_id,
				 @screening_date)
			end  
		
			select @prev_spot_id = @new_spot_id
		
			fetch movie_summary_csr into @long_name, @classification_id, @new_spot_id		
		end
		
		close movie_summary_csr 
		deallocate movie_summary_csr 

		fetch scrn_week_csr into @screening_date
	end 
	
deallocate scrn_week_csr

			
insert into #movie_summary_screened
select count(long_name)as 'screened', 
		 long_name,
		 classification_id,
		 screening_week
  from #movie_summary
group by long_name,
		 classification_id,
		screening_week
order by 2




-- Split Breakdown by movies to be used as 3-n columns in DW
declare	split_week_csr cursor static for
select distinct screening_week
from	#movie_summary_screened
order by screening_week

open split_week_csr
fetch split_week_csr into @screening_date
while(@@fetch_status = 0)
	begin

 		declare	split_movie_csr cursor static for
 		select screened, long_name, classification_id
 		from	#movie_summary_screened
 		where	screening_week = @screening_date
 
 		open split_movie_csr
 
 		-- fetch_status should be 0 at this point
		while(@@fetch_status = 0)
			begin
				fetch split_movie_csr into @screened_1, @long_name_1, @classification_id_1
				if @@fetch_status <> 0
					break

				fetch split_movie_csr into @screened_2, @long_name_2, @classification_id_2
				if @@fetch_status <> 0
					begin
						select @screened_2 = 0, @long_name_2 = '', @classification_id_2 = 0
						select @screened_3 = 0, @long_name_3 = '', @classification_id_3 = 0
					end
				else
					begin
						fetch split_movie_csr into @screened_3, @long_name_3, @classification_id_3
						if @@fetch_status <> 0
							begin
								select @screened_3 = 0, @long_name_3 = '', @classification_id_3 = 0
							end
					end

					insert into #movie_summary_3_n
					select 	@screening_date,
						   	@long_name_1,
						   	@classification_id_1,
							@screened_1,
							@long_name_2,
							@classification_id_2,
							@screened_2,
							@long_name_3,
							@classification_id_3,
							@screened_3,
                            @product_desc,
                            @start_date,
                            @end_date,
                            @campaign_status,
                            @agency_name,
                            @client_name
			
			end



 		deallocate	split_movie_csr
 
 		fetch split_week_csr into @screening_date
	end

deallocate split_week_csr
 
select * from #movie_summary_3_n

end
GO
