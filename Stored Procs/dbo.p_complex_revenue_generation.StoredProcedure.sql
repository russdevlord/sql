/****** Object:  StoredProcedure [dbo].[p_complex_revenue_generation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_revenue_generation]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_revenue_generation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_complex_revenue_generation] 
as
set nocount on  

/* Declare Variables */
declare @error        						int,
        @rowcount     						int,
        @errorode								int,
        @spot_id							int,		
        @complex_id							int,
        @complex_id2						int,        
        @makegood_rate                      numeric(18,4),
        @billing_period                     datetime,
        @ultimate_spot_id                   int,
        @screening_date                     datetime,
        @billing_date                       datetime,        
        @revenue_source						char(1),                        
        @cancelled						    char(1),
        @takeout_rate                       numeric(18,4),
        @cinema_rate                        numeric(18,4),
		@generation_date					datetime


/*******************************************************
 * Create Liability Records *
 *******************************************************/
 
/* Campaign*/
begin transaction

select 	@generation_date = min(end_date)
from	accounting_period

/* delete records with todays date */
delete  from complex_projected_revenue
where   generation_date = @generation_date

select @error = @@error
if (@error !=0)
begin
    raiserror ('Error deleting existing records', 16, 1)
	rollback transaction
	goto error
end                        


/* Create temp complex_projected_revenue table */
create table #temp_complex_projected_revenue
(
    generation_date datetime NULL,
    complex_id      int      NULL,
    campaign_no     int      NULL,
    screening_date  datetime NULL,
    billing_date    datetime NULL,
    billing_period  datetime NULL,
    revenue_source  char(1)  NULL,
    cancelled       char(1)  NULL,
    cinema_rate     money    NULL,
    makegood_rate   money    NULL,
    takeout_rate    money    NULL
)


/* Onscreen Cinema Amount */
insert into #temp_complex_projected_revenue(
        generation_date,
        complex_id,
        campaign_no,
        revenue_source,
        screening_date,
        cancelled, 
        cinema_rate,
        billing_period,
        billing_date,
        takeout_rate,
        makegood_rate)
select  @generation_date,
        spot_redirect.complex_id,
        spot.campaign_no,
        pack.revenue_source,     
        spot_redirect.screening_date,
        (case isnull(spot.spot_status, 'N') when 'C' then 'Y' else 'N' end),
        spot.cinema_rate,                    
        spot.billing_period,
        spot.billing_date,
        0, -- takeout_rate,
        0 -- makegood_rate
from    campaign_spot spot,
		campaign_package pack,
		campaign_spot spot_redirect,
        campaign_spot_redirect_xref spot_xref
where   spot.package_id = pack.package_id
and     spot.spot_type not in ('M','V','D')
and     spot.spot_status <> 'P'
and     spot.charge_rate <> 0
and		spot_redirect.screening_date is not null
and		spot.spot_id = spot_xref.original_spot_id
and     spot_redirect.spot_id = spot_xref.redirect_spot_id
    
select @error = @@error
if (@error !=0)
begin
    raiserror ('Error inserting onscreen cinema amounts' , 16, 1)
    rollback transaction
    goto error
end     

/* Onscreen Cinema Amount */
insert into #temp_complex_projected_revenue(
        generation_date,
        complex_id,
        campaign_no,
        revenue_source,
        screening_date,
        cancelled, 
        cinema_rate,
        billing_period,
        billing_date,
        takeout_rate,
        makegood_rate)
select  @generation_date,
        spot.complex_id,
        spot.campaign_no,
        pack.revenue_source,     
        spot.screening_date,
        (case isnull(spot.spot_status, 'N') when 'C' then 'Y' else 'N' end),
        spot.cinema_rate,                    
        spot.billing_period,
        spot.billing_date,
        0, -- takeout_rate,
        0 -- makegood_rate
from    campaign_spot spot,
		campaign_package pack
where   spot.package_id = pack.package_id
and     spot.spot_type not in ('M','V','D')
and     spot.spot_status <> 'P'
and     spot.charge_rate <> 0
and		spot.spot_redirect is null
and     spot.screening_date is not null
    
select @error = @@error
if (@error !=0)
begin
    raiserror ('Error inserting onscreen cinema amounts' , 16, 1)
    rollback transaction
    goto error
end     

/* Cinelight */
insert into #temp_complex_projected_revenue(
        generation_date,
        complex_id,
        campaign_no,
        revenue_source,
        screening_date,
        cancelled, 
        cinema_rate,
        billing_period,
        billing_date,
        takeout_rate,
        makegood_rate)
select  @generation_date,
        cl.complex_id,
        spot.campaign_no,
        pack.revenue_source,     
        spot.screening_date,
        (case isnull(spot.spot_status, 'N') when 'C' then 'Y' else 'N' end),
        spot.cinema_rate,                    
        spot.billing_period,
        spot.billing_date,
        0, -- takeout_rate,
        0 -- makegood_rate
from    cinelight_spot spot,
		cinelight_package pack,
		cinelight cl
where   spot.package_id = pack.package_id
and     spot.spot_type not in ('M','V','D')
and     spot.spot_status <> 'P'
and     spot.charge_rate <> 0
and		spot.screening_date is not null
and		cl.cinelight_id = spot.cinelight_id

    
select @error = @@error
if (@error !=0)
begin
    raiserror ('Error inserting cinelight cinema amounts', 16, 1)
    rollback transaction
    goto error
end      

/* Inclusion */
insert into #temp_complex_projected_revenue(
        generation_date,
        complex_id,
        campaign_no,
        revenue_source,
        screening_date,
        cancelled, 
        cinema_rate,
        billing_period,
        billing_date,
        takeout_rate,
        makegood_rate)
select  @generation_date,
        spot.complex_id,
        spot.campaign_no,
		'I',     
        spot.screening_date,
        (case isnull(spot.spot_status, 'N') when 'C' then 'Y' else 'N' end),
        spot.cinema_rate,                    
        spot.billing_period,
        spot.billing_date,
        0, -- takeout_rate,
        0 -- makegood_rate
from    inclusion_spot spot,
		inclusion inc
where   spot.spot_type not in ('M','V','D')
and     spot.spot_status <> 'P'
and 	inc.inclusion_id = spot.inclusion_id
and		inc.inclusion_type = 5
and     spot.charge_rate <> 0
and		spot.screening_date is not null
    
select @error = @@error
if (@error !=0)
begin
    raiserror ('Error inserting inclusion cinema amounts', 16, 1)
    rollback transaction
    goto error
end  

/* Onscreen Makegood Amount */
insert into #temp_complex_projected_revenue(
        generation_date,
        complex_id,
        campaign_no,
        revenue_source,
        screening_date,
        cancelled, 
        cinema_rate,
        billing_period,
        billing_date,
        takeout_rate,
        makegood_rate)
select  @generation_date,
        spot_redirect.complex_id,
        spot.campaign_no,
        pack.revenue_source,     
        spot_redirect.screening_date,
        (case isnull(spot.spot_status, 'N') when 'C' then 'Y' else 'N' end),
        0,                    
        spot.billing_period,
        spot.billing_date,
        0, -- takeout_rate,
        spot.cinema_rate -- makegood_rate
from    campaign_spot spot,
		campaign_package pack,
		campaign_spot spot_redirect,
        campaign_spot_redirect_xref spot_xref
where   spot.package_id = pack.package_id
and     spot.spot_type = 'D'
and     spot.spot_status <> 'P'
and     spot.cinema_rate <> 0
and		spot_redirect.screening_date is not null
and		spot.spot_id = spot_xref.original_spot_id
and     spot_redirect.spot_id = spot_xref.redirect_spot_id
    
select @error = @@error
if (@error !=0)
begin
    raiserror ('Error inserting onscreen cinema amounts' , 16, 1)
    rollback transaction
    goto error
end     

/* Onscreen Makegood Amount */
insert into #temp_complex_projected_revenue(
        generation_date,
        complex_id,
        campaign_no,
        revenue_source,
        screening_date,
        cancelled, 
        cinema_rate,
        billing_period,
        billing_date,
        takeout_rate,
        makegood_rate)
select  @generation_date,
        spot.complex_id,
        spot.campaign_no,
        pack.revenue_source,     
        spot.screening_date,
        (case isnull(spot.spot_status, 'N') when 'C' then 'Y' else 'N' end),
        0,                    
        spot.billing_period,
        spot.billing_date,
        0, -- takeout_rate,
        spot.cinema_rate -- makegood_rate
from    campaign_spot spot,
		campaign_package pack
where   spot.package_id = pack.package_id
and     spot.spot_type = 'D'
and     spot.spot_status <> 'P'
and     spot.cinema_rate <> 0
and		spot.spot_redirect is null
and     spot.screening_date is not null

   
select @error = @@error
if (@error !=0)
begin
    raiserror ('Error inserting onscreen cinema amounts' , 16, 1)
    rollback transaction
    goto error
end     
/* Cinelight Makegood */
insert into #temp_complex_projected_revenue(
        generation_date,
        complex_id,
        campaign_no,
        revenue_source,
        screening_date,
        cancelled, 
        cinema_rate,
        billing_period,
        billing_date,
        takeout_rate,
        makegood_rate)
select  @generation_date,
        cl.complex_id,
        spot.campaign_no,
        pack.revenue_source,     
        spot.screening_date,
        (case isnull(spot.spot_status, 'N') when 'C' then 'Y' else 'N' end),
        0,                    
        spot.billing_period,
        spot.billing_date,
        0, -- takeout_rate,
        spot.cinema_rate -- makegood_rate
from    cinelight_spot spot,
		cinelight_package pack,
		cinelight cl
where   spot.package_id = pack.package_id
and     spot.spot_type in ('D')
and     spot.spot_status <> 'P'
and     spot.charge_rate <> 0
and		cl.cinelight_id = spot.cinelight_id
and		spot.screening_date is not null
    
select @error = @@error
if (@error !=0)
begin
    raiserror ('Error inserting cinelight makegood cinema amounts', 16, 1)
    rollback transaction
    goto error
end      
         
/* Inclusion -  Makegood*/
insert into #temp_complex_projected_revenue(
        generation_date,
        complex_id,
        campaign_no,
        revenue_source,
        screening_date,
        cancelled, 
        cinema_rate,
        billing_period,
        billing_date,
        takeout_rate,
        makegood_rate)
select  @generation_date,
        spot.complex_id,
        spot.campaign_no,
        'I',     
        spot.screening_date,
        (case isnull(spot.spot_status, 'N') when 'C' then 'Y' else 'N' end),
        0,                    
        spot.billing_period,
        spot.billing_date,
        0, -- takeout_rate,
        spot.cinema_rate -- makegood_rate
from    inclusion_spot spot,
		inclusion inc
where   spot.spot_type in ('D')
and     spot.spot_status <> 'P'
and     spot.charge_rate <> 0
and		inc.inclusion_id = spot.inclusion_id
and		inc.inclusion_type = 5
and		spot.screening_date is not null
    
select @error = @@error
if (@error !=0)
begin
    raiserror ('Error inserting cinemarketing makegood cinema amounts', 16, 1)
    rollback transaction
    goto error
end  

/* Insert into Complex Projected Revenue */ 
 
insert into complex_projected_revenue (
			generation_date,
			complex_id,
			campaign_no,
			screening_date,
			billing_date,
			billing_period,
			revenue_source,
			cancelled,
			cinema_rate,
			makegood_rate,
			takeout_rate) 
			select generation_date,
			complex_id,
			campaign_no,
			screening_date,
			billing_date,
			billing_period,
			revenue_source,
			cancelled,
			sum(isnull(cinema_rate,0)),
			sum(isnull(makegood_rate,0)),
			sum(isnull(takeout_rate,0))
from 		#temp_complex_projected_revenue
group by 	generation_date,
			complex_id,
			campaign_no,
			screening_date,
			billing_date,
			billing_period,
			revenue_source,
			cancelled
having      (sum(isnull(cinema_rate,0)) + sum(isnull(makegood_rate,0))) > 0

select @error = @@error
if (@error !=0)
begin
    print @error
	raiserror ('Error consoldiating records', 16, 1)
	rollback transaction
	goto error
end                     
     
/* Return */
commit transaction
return 0

/* Error Handler */
error:

    raiserror ( 'Error: Failed to Generate Revenue for Projection', 16, 1)
    return -100
GO
