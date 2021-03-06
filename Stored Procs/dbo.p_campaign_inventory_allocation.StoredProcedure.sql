/****** Object:  StoredProcedure [dbo].[p_campaign_inventory_allocation]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_inventory_allocation]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_inventory_allocation]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[p_campaign_inventory_allocation]		@country_code								char(1),                
														@screening_dates							varchar(max),                
														@film_markets								varchar(max),
														@cinetam_reporting_demographics_id			int           
                                                                  
as                
                
declare			@error								int,
				@demo_desc							varchar(50)               
                
set nocount on                

/*
 * Create Temp Tables
 */

create table #screening_dates                
(                
	screening_date         datetime   not null                
)      

create table #film_markets                
(                
	film_market_no         int     not null                
)    

create table #campaign_inventory_allocation_report
(
	screening_date								datetime			null,
	generation_date								datetime			null,
	country_code								char(1)				null,
	film_market_no								int					null,
	film_market_desc							varchar(50)			null,
	complex_id									int					null,
	complex_name								varchar(50)			null,
	exhibitor_id								int					null,
	exhibitor_name								varchar(50)			null,
	campaign_no									int					null,
	product_desc								varchar(100)		null,
	complex_attendance							numeric(20,8)		null,
	complex_campaign_attendance					numeric(20,8)		null,
	complex_revenue								numeric(20,8)		null,
	campaign_attendance							numeric(20,8)		null,
	campaign_revenue							numeric(20,8)		null,
	demo_desc									varchar(50)			null
)

if len(@screening_dates) > 0  
begin              
	insert into #screening_dates                
	select * from dbo.f_multivalue_parameter(@screening_dates,',')
end

if len(@film_markets) > 0  
begin              
	insert into #film_markets                
	select * from dbo.f_multivalue_parameter(@film_markets,',')
end

select			@demo_desc = cinetam_reporting_demographics_desc
from			cinetam_reporting_demographics
where			cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id

if @cinetam_reporting_demographics_id = 0
begin
	insert into		#campaign_inventory_allocation_report
	select			movie_history.screening_date,
					GETDATE(),
					branch.country_code,
					complex.film_market_no,
					film_market_desc,
					movie_history.complex_id,
					complex_name,
					exhibitor.exhibitor_id,
					exhibitor_name,
					film_campaign.campaign_no,
					product_desc,
					(select			isnull(sum(mov.attendance),0)
					from			movie_history mov
					inner join		#screening_dates on mov.screening_date = #screening_dates.screening_date
					inner join		complex on mov.complex_id = complex.complex_id
					inner join		#film_markets on complex.film_market_no = #film_markets.film_market_no
					where			mov.complex_id = movie_history.complex_id
					and				mov.screening_date = movie_history.screening_date) as complex_attendance,
					(select			isnull(sum(mov.attendance),0)
					from			movie_history mov
					inner join		v_certificate_item_distinct on mov.certificate_group = v_certificate_item_distinct.certificate_group
					inner join		#screening_dates on mov.screening_date = #screening_dates.screening_date
					inner join		complex on mov.complex_id = complex.complex_id
					inner join		#film_markets on complex.film_market_no = #film_markets.film_market_no
					where			mov.complex_id = movie_history.complex_id
					and				mov.screening_date = movie_history.screening_date) as complex_campaign_attendance,
					(select			isnull(SUM(cinema_amount),0)
					from			spot_liability
					inner join		v_certificate_item_distinct on spot_liability.spot_id = v_certificate_item_distinct.spot_reference
					inner join		campaign_spot on v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
					inner join		#screening_dates on campaign_spot.screening_date = #screening_dates.screening_date
					inner join		complex on campaign_spot.complex_id = complex.complex_id
					inner join		#film_markets on complex.film_market_no = #film_markets.film_market_no
					where			liability_type in (1, 5, 34)
					and				campaign_spot.complex_id = movie_history.complex_id
					and				campaign_spot.screening_date = movie_history.screening_date) as complex_revenue,
					isnull(sum(attendance),0) as campaign_attendance,
					(select			isnull(SUM(cinema_amount),0)
					from			spot_liability
					inner join		v_certificate_item_distinct on spot_liability.spot_id = v_certificate_item_distinct.spot_reference
					inner join		campaign_spot on v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
					inner join		#screening_dates on campaign_spot.screening_date = #screening_dates.screening_date
					inner join		complex on campaign_spot.complex_id = complex.complex_id
					inner join		#film_markets on complex.film_market_no = #film_markets.film_market_no
					where			liability_type in (1, 5, 34)
					and				campaign_spot.complex_id = movie_history.complex_id
					and				campaign_spot.screening_date = movie_history.screening_date
					and				campaign_spot.campaign_no = film_campaign.campaign_no) as campaign_revenue,
					@demo_desc
	from			v_certificate_item_distinct
	inner join		movie_history on v_certificate_item_distinct.certificate_group = movie_history.certificate_group
	inner join		complex on movie_history.complex_id = complex.complex_id
	inner join		branch on complex.branch_code = branch.branch_code
	inner join		film_market on complex.film_market_no = film_market.film_market_no
	inner join		exhibitor on complex.exhibitor_id = exhibitor.exhibitor_id
	inner join		campaign_spot on v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
	inner join		film_campaign on campaign_spot.campaign_no = film_campaign.campaign_no
	inner join		#screening_dates on movie_history.screening_date = #screening_dates.screening_date                
	inner join		#film_markets on complex.film_market_no= #film_markets.film_market_no
	where			movie_id <> 102           
	group by		movie_history.screening_date,
					branch.country_code,
					complex.film_market_no,
					film_market_desc,
					movie_history.complex_id,
					complex_name,
					exhibitor.exhibitor_id,
					exhibitor_name,
					film_campaign.campaign_no,
					product_desc
end
else
begin
	insert into		#campaign_inventory_allocation_report
	select			cinetam_movie_history.screening_date,
					GETDATE(),
					branch.country_code,
					complex.film_market_no,
					film_market_desc,
					cinetam_movie_history.complex_id,
					complex_name,
					exhibitor.exhibitor_id,
					exhibitor_name,
					film_campaign.campaign_no,
					product_desc,
					(select			isnull(sum(mov.attendance),0)
					from			cinetam_movie_history mov
					inner join		cinetam_reporting_demographics_xref demo_xref on mov.cinetam_demographics_id = demo_xref.cinetam_demographics_id
					inner join		#screening_dates on mov.screening_date = #screening_dates.screening_date
					inner join		complex on mov.complex_id = complex.complex_id
					inner join		#film_markets on complex.film_market_no = #film_markets.film_market_no
					where			mov.complex_id = cinetam_movie_history.complex_id
					and				mov.screening_date = cinetam_movie_history.screening_date
					and				demo_xref.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id) as complex_attendance,
					(select			isnull(sum(mov.attendance),0)
					from			cinetam_movie_history mov
					inner join		cinetam_reporting_demographics_xref demo_xref on mov.cinetam_demographics_id = demo_xref.cinetam_demographics_id
					inner join		v_certificate_item_distinct on mov.certificate_group_id = v_certificate_item_distinct.certificate_group
					inner join		#screening_dates on mov.screening_date = #screening_dates.screening_date
					inner join		complex on mov.complex_id = complex.complex_id
					inner join		#film_markets on complex.film_market_no = #film_markets.film_market_no
					where			mov.complex_id = cinetam_movie_history.complex_id
					and				mov.screening_date = cinetam_movie_history.screening_date
					and				demo_xref.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id) as complex_campaign_attendance,
					(select			isnull(SUM(cinema_amount),0)
					from			spot_liability
					inner join		v_certificate_item_distinct on spot_liability.spot_id = v_certificate_item_distinct.spot_reference
					inner join		campaign_spot on v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
					inner join		#screening_dates on campaign_spot.screening_date = #screening_dates.screening_date
					inner join		complex on campaign_spot.complex_id = complex.complex_id
					inner join		#film_markets on complex.film_market_no = #film_markets.film_market_no
					where			liability_type in (1, 5, 34)
					and				campaign_spot.complex_id = cinetam_movie_history.complex_id
					and				campaign_spot.screening_date = cinetam_movie_history.screening_date) as complex_revenue,
					isnull(sum(attendance),0) as campaign_attendance,
					(select			isnull(SUM(cinema_amount),0)
					from			spot_liability
					inner join		v_certificate_item_distinct on spot_liability.spot_id = v_certificate_item_distinct.spot_reference
					inner join		campaign_spot on v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
					inner join		#screening_dates on campaign_spot.screening_date = #screening_dates.screening_date
					inner join		complex on campaign_spot.complex_id = complex.complex_id
					inner join		#film_markets on complex.film_market_no = #film_markets.film_market_no
					where			liability_type in (1, 5, 34)
					and				campaign_spot.complex_id = cinetam_movie_history.complex_id
					and				campaign_spot.screening_date = cinetam_movie_history.screening_date
					and				campaign_spot.campaign_no = film_campaign.campaign_no) as campaign_revenue,
					@demo_desc
	from			v_certificate_item_distinct
	inner join		cinetam_movie_history on v_certificate_item_distinct.certificate_group = cinetam_movie_history.certificate_group_id
	inner join		cinetam_reporting_demographics_xref on cinetam_movie_history.cinetam_demographics_id = cinetam_reporting_demographics_xref.cinetam_demographics_id
	inner join		complex on cinetam_movie_history.complex_id = complex.complex_id
	inner join		branch on complex.branch_code = branch.branch_code
	inner join		film_market on complex.film_market_no = film_market.film_market_no
	inner join		exhibitor on complex.exhibitor_id = exhibitor.exhibitor_id
	inner join		campaign_spot on v_certificate_item_distinct.spot_reference = campaign_spot.spot_id
	inner join		film_campaign on campaign_spot.campaign_no = film_campaign.campaign_no
	inner join		#screening_dates on cinetam_movie_history.screening_date = #screening_dates.screening_date                
	inner join		#film_markets on complex.film_market_no= #film_markets.film_market_no                
	where			cinetam_reporting_demographics_xref.cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
	and				movie_id <> 102           
	group by		cinetam_movie_history.screening_date,
					branch.country_code,
					complex.film_market_no,
					film_market_desc,
					cinetam_movie_history.complex_id,
					complex_name,
					exhibitor.exhibitor_id,
					exhibitor_name,
					film_campaign.campaign_no,
					product_desc
end


/*                
 * Return                
 */    
 
select			*
from			#campaign_inventory_allocation_report
order by		screening_date,
				film_market_no,
				complex_id,
				exhibitor_id,
				campaign_no	        

return 0
GO
