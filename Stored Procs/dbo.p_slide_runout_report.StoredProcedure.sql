/****** Object:  StoredProcedure [dbo].[p_slide_runout_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_runout_report]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_runout_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_runout_report] @complex_id				int,
                                  @screening_date_start	    datetime,
                                  @screening_date_end		datetime
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @error          			int,
        @rowcount						int,
        @complex_branch				varchar(50),
        @complex_name				varchar(50),
        @campaign_no					char(7),
        @agency_deal					char(1),
        @client_agency_name		varchar(50),
        @address_1					varchar(50),
        @address_2					varchar(50),
        @town_suburb					varchar(30),
        @state_code					char(3),
        @postcode						char(5),
        @carousel_code				char(1),
        @carousel_codes				varchar(50)


/*
 * Create Temporary Tables
 */

create table #campaigns
(
   campaign_no					char(7)				null,
   screens						int				null,
   screenings					int				null,
   weekly_rate					money					null,
   carousel_codes				varchar(50)			null,
   agency_deal					char(1)				null,
   client_agency_name		varchar(50)			null,
   address_1					varchar(50)			null,
   address_2					varchar(50)			null,
   town_suburb					varchar(30)			null,
   state_code					char(3)				null,
   postcode						char(5)				null
)

select @complex_branch = branch.branch_name,
       @complex_name = complex.complex_name
  from complex,
       branch
 where complex.complex_id = @complex_id and
       complex.branch_code = branch.branch_code

insert into #campaigns (
       campaign_no,
       screens,
       screenings,
       weekly_rate )
select distinct sp.campaign_no,
       0,
       0,
       0.0
  from slide_campaign_screening scr,
       slide_campaign_spot sp,
       slide_campaign sc
 where scr.spot_id = sp.spot_id and
       sp.campaign_no = sc.campaign_no and
       scr.complex_id = @complex_id and
       scr.screening_status <> 'C' and
       (( scr.screening_date is not null and
          scr.screening_date >= @screening_date_start and
          scr.screening_date <= @screening_date_end ) or
        ( scr.screening_date is null and
          sc.campaign_status = 'U' ))

-- Calculate Number of Screens
update #campaigns
   set #campaigns.screens = isnull((select scc.screens
                                      from slide_campaign_complex scc
                                     where #campaigns.campaign_no = scc.campaign_no and
                                           scc.complex_id = @complex_id), 0)

-- Calculate Number of Screenings
update #campaigns
   set #campaigns.screenings = isnull((select count(*)
                                         from slide_campaign_screening scr,
                                              slide_campaign_spot sp,
                                              slide_campaign sc
                                        where scr.spot_id = sp.spot_id and
                                              #campaigns.campaign_no = sp.campaign_no and
                                              sp.campaign_no = sc.campaign_no and
                                              scr.complex_id = @complex_id and
                                              scr.screening_status <> 'C' and
                                              (( scr.screening_date is not null and
                                                 scr.screening_date >= @screening_date_start and
                                                 scr.screening_date <= @screening_date_end ) or
                                               ( scr.screening_date is null and
                                                 sc.campaign_status = 'U' ))), 0)

-- Calculate Weekly Rate at this actual_complex
update #campaigns
   set #campaigns.weekly_rate = isnull((select (sc.nett_contract_value / sc.orig_campaign_period) * (rd.original_allocation / sd.original_alloc)
                                          from slide_campaign sc,
                                               rent_distribution rd,
    slide_distribution sd
                                         where #campaigns.campaign_no = sc.campaign_no
                                         and   sd.campaign_no = sc.campaign_no
                                         and   rd.campaign_no = sc.campaign_no
                                         and   rd.complex_id = @complex_id
                                         and   sd.distribution_type = 'R'
                                         and   sd.original_alloc != 0), 0)


 declare campaign_csr cursor static for
  select campaign_no
    from #campaigns
order by campaign_no
     for read only

open campaign_csr
fetch campaign_csr into @campaign_no
while(@@fetch_status = 0)
begin
   select @agency_deal = sc.agency_deal
     from slide_campaign sc
    where sc.campaign_no = @campaign_no

   if @agency_deal = 'Y'
   begin
		select @agency_deal = sc.agency_deal,
				 @client_agency_name = ag.agency_name,
				 @address_1 = ag.address_1,
				 @address_2 = ag.address_2,
				 @town_suburb = ag.town_suburb,
				 @state_code = ag.state_code,
				 @postcode = ag.postcode
		  from slide_campaign sc,
				 agency ag
		 where sc.agency_deal = 'Y' and
				 sc.agency_id = ag.agency_id and
				 sc.campaign_no = @campaign_no
   end
   else
   begin
      select @agency_deal = sc.agency_deal,
             @client_agency_name = cl.client_name,
             @address_1 = cl.address_1,
             @address_2 = cl.address_2,
             @town_suburb = cl.town_suburb,
             @state_code = cl.state_code,
             @postcode = cl.postcode
        from slide_campaign sc,
             client cl
       where sc.agency_deal = 'N' and
             sc.client_id = cl.client_id and
             sc.campaign_no = @campaign_no
   end

  update #campaigns
     set agency_deal = @agency_deal,
         client_agency_name = @client_agency_name,
         address_1 = @address_1,
         address_2 = @address_2,
         town_suburb = @town_suburb,
         state_code = @state_code,
         postcode = @postcode
   where #campaigns.campaign_no = @campaign_no

   select @carousel_codes = ''

	 declare carousel_csr cursor static for
	  select distinct carousel.carousel_code
	    from carousel,
	         slide_campaign_screening scr,
	         slide_campaign_spot sp,
	         slide_campaign sc
	   where scr.carousel_id = carousel.carousel_id and
	         scr.spot_id = sp.spot_id and
	         sp.campaign_no = sc.campaign_no and
	         sp.campaign_no = @campaign_no and
	         scr.complex_id = @complex_id and
	         scr.screening_status <> 'C' and
	         (( scr.screening_date is not null and
	            scr.screening_date >= @screening_date_start and
	            scr.screening_date <= @screening_date_end ) or
	         ( scr.screening_date is null and
	           sc.campaign_status = 'U' ))
	order by carousel.carousel_code
	     for read only

   open carousel_csr
   fetch carousel_csr into @carousel_code
   while(@@fetch_status = 0)
   begin
      if @carousel_codes = ''
         select @carousel_codes = @carousel_code
      else
         select @carousel_codes = @carousel_codes + ', ' + @carousel_code

      fetch carousel_csr into @carousel_code
   end
   close carousel_csr
   deallocate carousel_csr

   if @carousel_codes <> ''
   begin
      update #campaigns
         set carousel_codes = @carousel_codes
       where #campaigns.campaign_no = @campaign_no
   end

	fetch campaign_csr into @campaign_no
end
close campaign_csr
deallocate campaign_csr

/*
 * Return
 */

select @complex_branch as complex_branch,
       @complex_name as complex_name,
       #campaigns.campaign_no,
       sc.name_on_slide,
       sc.campaign_status,
       sc.start_date,
       dateadd(dd, ((sc.min_campaign_period + sc.bonus_period) * 7) - 1, sc.start_date) as end_date,
       #campaigns.screens,
       #campaigns.screenings,
       #campaigns.weekly_rate,
       #campaigns.carousel_codes,
       sc.phone,
       sc.signatory,
       sr.first_name,
  sr.last_name,
       #campaigns.agency_deal,
       #campaigns.client_agency_name,
       #campaigns.address_1,
       #campaigns.address_2,
       #campaigns.town_suburb,
       #campaigns.state_code,
       #campaigns.postcode
  from #campaigns,
       slide_campaign sc,
       sales_rep sr
 where #campaigns.campaign_no = sc.campaign_no and
       sc.service_rep = sr.rep_id
order by #campaigns.campaign_no

return 0
GO
