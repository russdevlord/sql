/****** Object:  StoredProcedure [dbo].[p_cinatt_campaign_eval_audit]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_campaign_eval_audit]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_campaign_eval_audit]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_campaign_eval_audit] @campaign_no		integer
as


declare @error        			integer,
        @rowcount     			integer,
        @errorode						integer,
        @errno						integer,
        @spot_csr_open			tinyint,
        @film_market_no			integer,
        @spot_id					integer,
        @complex_id				integer,
        @complex_id_store		integer,
        @package_id				integer,
        @screening_date			datetime,
        @spot_status				char(1),
        @pack_code				char(1),
        @charge_rate				money,
        @start						tinyint,
	     @actual_attendance		integer,
        @estimated_attendance	integer,
	     @location_cost			money,
	     @cancelled_cost			money,
        @attendance				integer,
        @movie_id					integer,
        @actual					char(1),
        @cinatt_weighting       numeric(6,4),
        @product_desc           varchar(100)



 declare spot_csr cursor static for
  select spot.spot_id,
         spot.complex_id,
         spot.package_id,
         spot.screening_date,
         spot.spot_status,
         spot.charge_rate,
         cplx.cinatt_weighting
    from campaign_spot spot,
         campaign_package cpack,
         complex cplx
   where spot.campaign_no = @campaign_no and
         spot.complex_id = cplx.complex_id and
         spot.package_id = cpack.package_id and
         spot.spot_status = 'X'
order by spot.complex_id,
         spot.spot_id
     for read only


create table #audit
(
	screening_date datetime		null,
	complex_id					integer			null,
    movie_id            integer     null,
	attendance			integer			null,
    actual       	char(1)			null,
    cinatt_weighting numeric(6,4) null
)



select @spot_csr_open = 0



select @start = 0,
       @complex_id_store = 0,
	    @actual_attendance = 0,
       @estimated_attendance = 0,
	    @location_cost = 0,
	    @cancelled_cost = 0



open spot_csr
select @spot_csr_open = 1
fetch spot_csr into @spot_id,@complex_id,@package_id,@screening_date,@spot_status,@charge_rate,@cinatt_weighting
while(@@fetch_status = 0)
begin

	select @attendance = 0

	select @movie_id = mh.movie_id
     from certificate_item ci,
          certificate_group cg,
          movie_history mh
    where ci.spot_reference = @spot_id and
          ci.certificate_group = cg.certificate_group_id and
          cg.certificate_group_id = mh.certificate_group
    select @errno = @@error
	if (@errno != 0)
		goto error
        
	if(@screening_date is not null)
	begin
		exec @errorode = p_cinatt_get_movie_attendance @screening_date,
																  @complex_id,
																  @movie_id,
																  @attendance OUTPUT,
																  @actual OUTPUT



        if @actual <> 'Y'
            select @attendance = convert(int,(@attendance * @cinatt_weighting))


insert into #audit(screening_date,
                	complex_id,
                    movie_id,
                	attendance,
                    actual,
                    cinatt_weighting)
             values(@screening_date,
    				  @complex_id,
    				  @movie_id,
    				  @attendance,
    				  @actual,
                      @cinatt_weighting)


	end

	

	fetch spot_csr into @spot_id,@complex_id,@package_id,@screening_date,@spot_status,@charge_rate,@cinatt_weighting

end
close spot_csr
select @spot_csr_open = 0
deallocate spot_csr

select  @product_desc = product_desc
from    film_campaign
where   campaign_no = @campaign_no


select #audit.screening_date,
        #audit.complex_id,
        complex.complex_name,
        #audit.movie_id,
        movie.long_name,
        #audit.attendance,
    	#audit.actual,
        #audit.cinatt_weighting,
        @campaign_no,
        @product_desc
from    #audit, complex, movie
where   #audit.complex_id = complex.complex_id
and     #audit.movie_id = movie.movie_id

drop table #audit

return 0



error:

	 if(@spot_csr_open = 1)
    begin
		 close spot_csr
		 deallocate spot_csr
         drop table #audit
	 end

	 return -1
GO
