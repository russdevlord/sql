/****** Object:  StoredProcedure [dbo].[p_complex_listing_common]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_listing_common]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_listing_common]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_complex_listing_common] @groupby			integer
as

set nocount on

/*
 * Create the Temporary Loader Table
 */

create table #cinema
(
	complex_id							integer			null,
	cinema_no							integer			null,
	seating_capacity					integer			null,
	projector_type_desc					varchar(20)		null,
	slide_size_code						char(2)			null,
	film_size_code						char(3)			null,
	image_area							varchar(30)		null,
	glass_area							varchar(30)		null,
	media_type							char(1)			null,
	pulse_frequency						char(1)			null,
	start_pulse_ins						char(1)			null,
	clip_pulse_ins						char(1)			null,
	end_pulse_ins						char(1)			null,
	total_cinema_count					int				null, 
	normal_cinema_count					int				null,	
	gold_class_cinema_count				int				null, 
	la_prem_cinema_count				int				null
	
)

create table #complex
(
	complex_id							integer			null,
	complex_name						varchar(50)		null,
	complex_category					char(1)			null,
	complex_region_class				char(1)			null,
	complex_type						char(1)			null,
	address_1							varchar(50)		null,
	address_2							varchar(50)		null,
	town_suburb							char(30)			null,
	postcode							char(5)			null,
	phone								char(20)			null,
	fax									char(20)			null,
	manager								varchar(50)		null,
	projectionist						varchar(50)		null,
	phone_proj							varchar(20)		null,
	campaign_safety_limit	 		    integer			null,
	clash_safety_limit				    integer			null,
	movie_target						integer			null,
	session_target						integer			null,
	max_ads								integer			null,
	max_time								integer			null,
	state_code							char(3)			null,
	branch_code							char(2)			null,
	exhibitor_name						varchar(50)		null,
	opening_date						datetime			null,
	closing_date						datetime			null,
	film_status							char(1)			null,
	market_no							integer			null,
	market_desc							varchar(30)		null,
	certificate_send_method				tinyint			null,
	no_cinemas						    int				null,
	mg_max_ads								integer			null,
	mg_max_time								integer			null,
	cplx_max_ads								integer			null,
	cplx_max_time								integer			null,
	emails								varchar(max)
)

/*
 * Select Cinema Info
 */



  insert into #cinema(complex_id, total_cinema_count, normal_cinema_count, gold_class_cinema_count, la_prem_cinema_count)   
  select complex_id 
	    ,count(complex_id) as  total_count
	    ,sum(case when cinema_category = 'N' then 1
			  else 0
			  end) as normal_cinemas
	    ,sum(case when cinema_category = 'G' then 1
			  else 0
			  end) as gold_class_cinemas
	    ,sum(case when cinema_category = 'L' then 1
			  else 0
			  end) as la_prem_cinemas
	from cinema
	where active_flag = 'Y'
	group by complex_id


/*
 * Select Complex Info
 */


 insert      into #complex(complex_id, complex_name, complex_category, complex_region_class, complex_type, address_1, address_2, town_suburb, postcode,
							  phone, fax, manager, projectionist, phone_proj, campaign_safety_limit, clash_safety_limit, movie_target, session_target,
							  max_ads, max_time, state_code, branch_code, exhibitor_name, opening_date, closing_date, film_status, 
							  market_no, market_desc , certificate_send_method, no_cinemas, mg_max_ads, mg_max_time, cplx_max_ads, cplx_max_time)
    select      complex.complex_id,
                complex.complex_name,   
                complex.complex_category,   
                complex.complex_region_class,   
                complex.complex_type,   
                complex.address_1,   
                complex.address_2,   
                complex.town_suburb,   
                complex.postcode,   
                complex.phone,   
                complex.fax,   
                complex.manager,   
                complex.projectionist,   
                complex.phone_proj,
                complex.campaign_safety_limit,   
                complex.clash_safety_limit,   
                complex.movie_target,   
                complex.session_target,   
                complex.max_ads,   
                complex.max_time,   
                complex.state_code,   
                complex.branch_code,   
                exhibitor.exhibitor_name,   
                complex.opening_date,   
                complex.closing_date,
                complex.film_complex_status,
                film_market.film_market_no,
                film_market.film_market_desc ,
                complex.certificate_send_method,
                complex.no_cinemas,
                complex.mg_max_ads,
                complex.mg_max_time,
                complex.cplx_max_ads,
                complex.cplx_max_time
    from        film_market,   
                complex,   
                exhibitor  
    where       complex.film_market_no = film_market.film_market_no 
    and         complex.exhibitor_id = exhibitor.exhibitor_id 
    and         complex.film_complex_status <> 'C'


declare @complex_id as int
declare @email varchar(max)

set @groupby = 1

DECLARE c CURSOR LOCAL FAST_FORWARD
  FOR SELECT complex_id
  FROM #complex

open c

fetch c into @complex_id

while @@FETCH_STATUS = 0
begin
	
	set @email = null
	
	SELECT 	@email = COALESCE(@email + ', ', '') + email  
	from(select complex.email
		 FROM 		complex
		 WHERE 	complex.complex_id = @complex_id
		 union
		 SELECT 	complex_addresses.email
		 FROM 		complex,   
					complex_addresses  
		 WHERE 	complex_addresses.complex_id = @complex_id ) a
	
	update #complex
	set emails = @email
	where complex_id = @complex_id

	fetch c into @complex_id
	
end 

CLOSE c
DEALLOCATE c


/*
 * Return
 */

  select    3 as mode,   
            @groupby as groupby,   
            #complex.complex_id,
            #complex.complex_name,   
            #complex.complex_category,   
            #complex.complex_region_class,   
            #complex.complex_type,   
            #complex.address_1,   
            #complex.address_2,   
            #complex.town_suburb,   
            #complex.postcode,   
            #complex.phone,   
            #complex.fax,   
            #complex.manager,   
            #complex.projectionist,   
            #complex.phone_proj,
            #complex.campaign_safety_limit,   
            #complex.clash_safety_limit,   
            #complex.movie_target,   
            #complex.session_target,   
            #complex.max_ads,   
            #complex.max_time,   
            #complex.state_code,   
            #complex.branch_code,   
            #complex.exhibitor_name,   
            #complex.opening_date,   
            #complex.closing_date,
            #complex.film_status,
            #complex.market_no,
            #complex.market_desc,
            #cinema.cinema_no,
            #cinema.seating_capacity,
            #cinema.projector_type_desc,
            #cinema.slide_size_code,
            #cinema.film_size_code,
            #cinema.image_area,
            #cinema.glass_area,
            #cinema.media_type,
            #cinema.pulse_frequency,
            #cinema.start_pulse_ins,
            #cinema.clip_pulse_ins,
            #cinema.end_pulse_ins,
            #complex.certificate_send_method,
            #complex.no_cinemas,
            #complex.mg_max_ads,
            #complex.mg_max_time,
            #complex.cplx_max_ads,
            #complex.cplx_max_time,
            #complex.emails
            ,#cinema.total_cinema_count
            ,#cinema.normal_cinema_count
            ,#cinema.la_prem_cinema_count
            ,#cinema.gold_class_cinema_count
from        #complex,
            #cinema
where       ( #complex.complex_id = #cinema.complex_id 
or          #cinema.complex_id is null )
order by    complex_name ASC   

return 0
GO
