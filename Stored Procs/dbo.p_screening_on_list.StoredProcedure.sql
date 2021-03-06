/****** Object:  StoredProcedure [dbo].[p_screening_on_list]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_screening_on_list]
GO
/****** Object:  StoredProcedure [dbo].[p_screening_on_list]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  PROC [dbo].[p_screening_on_list] 	@screening_date	datetime
as
set nocount on 
declare 	@campaign_no			int,
			@standby_campaign_no	int,
			@product_desc			varchar(100),
			@rep_id					int,
			@business_unit_id		int,	
			@first_name				varchar(30),
			@last_name				varchar(30),
			@package_code			char(1),
			@package_desc			varchar(100),
			@used_by_date			datetime,
			@package_id				int,
			@email					varchar(255)

create table #screening_campaigns
(
	campaign_no				int  		null,
	product_desc			varchar(100)	null,
	rep_id					int  		null,
	business_unit_id		int		   null,	
	first_name				varchar(30)    null,
	last_name				varchar(30)		null,
	package_code			char(1)			null,
	package_desc			varchar(100)	null,
	used_by_date			datetime			null,
	package_id				int			null,
	print_cert				char(1)			null,
	email					varchar(255)	null,
	email_cert			   char(1)			null
)
						
/*
 * If screening_date not null get screening_information
 */ 
declare     scheduled_campaigns_csr cursor static for
select      fc.campaign_no,
            fc.product_desc,
            fc.rep_id,
            fc.business_unit_id,
            rep.first_name,
            rep.last_name,
            cp.package_code,
            cp.package_desc,
            cp.used_by_date,
            cp.package_id,
            rep.email
from        film_campaign fc ,
            campaign_package cp,
            campaign_spot spot ,
            sales_rep rep     
where       fc.rep_id = rep.rep_id 
and         fc.campaign_no = cp.campaign_no 
and         cp.package_id = spot.package_id
and         spot.spot_status <> 'P'
and         spot.screening_date = @screening_date
and         spot.campaign_no = fc.campaign_no
group by    fc.campaign_no,
            fc.product_desc,
            fc.rep_id,
            fc.business_unit_id,
            rep.first_name,
            rep.last_name,
            cp.package_code,
            cp.package_desc,
            cp.used_by_date,
            cp.package_id,
            rep.email
union
select      fc.campaign_no,
            fc.product_desc,
            fc.rep_id,
            fc.business_unit_id,
            rep.first_name,
            rep.last_name,
            cp.package_code,
            cp.package_desc,
            cp.used_by_date,
            cp.package_id,
            rep.email
from        film_campaign fc ,
            campaign_package cp,
            sales_rep rep     
where       fc.rep_id = rep.rep_id 
and         fc.campaign_no = cp.campaign_no 
and         fc.end_date < @screening_date
and         fc.makeup_deadline >= @screening_date
and         fc.campaign_status = 'L'
and         cp.used_by_date >= @screening_date
and         cp.start_date <= @screening_date
group by    fc.campaign_no,
            fc.product_desc,
            fc.rep_id,
            fc.business_unit_id,
            rep.first_name,
            rep.last_name,
            cp.package_code,
            cp.package_desc,
            cp.used_by_date,
            cp.package_id,
            rep.email
order by    fc.campaign_no,
            fc.product_desc,
            fc.rep_id,
            fc.business_unit_id,
            rep.first_name,
            rep.last_name,
            cp.package_code,
            cp.package_desc,
            cp.used_by_date,
            cp.package_id,
            rep.email

open scheduled_campaigns_csr
fetch scheduled_campaigns_csr into 	@campaign_no,
									@product_desc,
									@rep_id,
									@business_unit_id,	
									@first_name,
									@last_name,
									@package_code,
									@package_desc,
									@used_by_date,
									@package_id,
		   						    @email
while (@@fetch_status = 0)
begin
	insert into #screening_campaigns
		(
		campaign_no,
		product_desc,
		rep_id,
		business_unit_id,	
		first_name,
		last_name,
		package_code,
		package_desc,
		used_by_date,
		package_id,
		print_cert,
		email_cert,
		email
		) values
		(
		@campaign_no,
		@product_desc,
		@rep_id,
		@business_unit_id,	
		@first_name,
		@last_name,
		@package_code,
		@package_desc,
		@used_by_date,
		@package_id,
		'N',
		'N',
		@email
		)

	fetch scheduled_campaigns_csr into 	@campaign_no,
										@product_desc,
										@rep_id,
										@business_unit_id,	
										@first_name,
										@last_name,
										@package_code,
										@package_desc,
										@used_by_date,
										@package_id,
			   						    @email

end
close scheduled_campaigns_csr
deallocate scheduled_campaigns_csr

declare     standby_campaign_csr cursor static for
select      fc.campaign_no,
            fc.product_desc,
            fc.rep_id,
            fc.business_unit_id,
            rep.first_name,
            rep.last_name,
            cp.package_code,
            cp.package_desc,
            cp.used_by_date,
            cp.package_id,
            rep.email
from        film_campaign fc,
            campaign_package cp,
            film_plan fp,
            film_plan_dates fpd,
            film_plan_complex fpc,
            sales_rep rep
where       fc.rep_id = rep.rep_id and
            fc.campaign_no = cp.campaign_no and
            cp.package_id = fp.package_id and
            fpd.screening_date = @screening_date and
            fp.campaign_no = fc.campaign_no and
            fp.film_plan_id = fpd.film_plan_id and
            fp.film_plan_id = fpc.film_plan_id
group by    fc.campaign_no,
            fc.product_desc,
            fc.rep_id,
            fc.business_unit_id,
            rep.first_name,
            rep.last_name,
            cp.package_code,
            cp.package_desc,
            cp.used_by_date,
            cp.package_id,
            rep.email
order by    fc.campaign_no,
            fc.product_desc,
            fc.rep_id,
            fc.business_unit_id,
            rep.first_name,
            rep.last_name,
            cp.package_code,
            cp.package_desc,
            cp.used_by_date,
            cp.package_id,
            rep.email

open standby_campaign_csr
fetch standby_campaign_csr into @campaign_no,
								@product_desc,
								@rep_id,
								@business_unit_id,	
								@first_name,
								@last_name,
								@package_code,
								@package_desc,
								@used_by_date,
								@package_id,
	   							@email
while (@@fetch_status = 0)
begin

select @standby_campaign_no = campaign_no
from #screening_campaigns
where campaign_no = @campaign_no

 	if @standby_campaign_no is null
	begin
	insert into #screening_campaigns
		(
		campaign_no,
		product_desc,
		rep_id,
		business_unit_id,	
		first_name,
		last_name,
		package_code,
		package_desc,
		used_by_date,
		package_id,
		print_cert,
		email_cert,
		email

		) values
		(
		@campaign_no,
		@product_desc,
		@rep_id,
		@business_unit_id,	
		@first_name,
		@last_name,
		@package_code,
		@package_desc,
		@used_by_date,
		@package_id,
		'N',
		'N',
		@email
		)
end

	fetch standby_campaign_csr into @campaign_no,
									@product_desc,
									@rep_id,
									@business_unit_id,	
									@first_name,
									@last_name,
									@package_code,
									@package_desc,
									@used_by_date,
									@package_id,
		   						    @email
end

deallocate standby_campaign_csr

select * from #screening_campaigns

return 0
GO
