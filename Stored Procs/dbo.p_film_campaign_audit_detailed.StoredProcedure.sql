/****** Object:  StoredProcedure [dbo].[p_film_campaign_audit_detailed]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_audit_detailed]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_audit_detailed]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_film_campaign_audit_detailed]		@allocation_id				int,
												@cinema_agreement_id		int,
												@tran_id					int

as
 
declare		@error						int,
			@release_date				datetime,
			@campaign_no				int, 
			@product_desc				varchar(100),
			@liability_type_id			int,
			@revenue_source				varchar(50),
			@complex_name				varchar(50),
			@spot_amount				money,
			@cinema_amount				money,
			@cinema_rent				money,
			@release_period				datetime,
			@cancelled					char(1),
			@complex_id					int,
			@complex_count				int,
			@spot_count					int

create table #transactions
(
	campaign_no					int				null,   
	product_desc				varchar(100)	null,
	liability_type_id			int				null,
	revenue_source				varchar(50)		null,
	complex_name				varchar(50)		null,
	spot_amount					money			null,
	cinema_amount				money			null,
	cinema_rent					money			null,
	release_period				datetime		null,
	cancelled					char(1)			null
)

create table #complexes
(
	complex_id					int				null
)

select @release_date = isnull(max(release_period), getdate()) from spot_liability where allocation_id = @allocation_id

insert 	into #complexes
select 	complex_id 
from 	cinema_agreement_policy 
where	cinema_agreement_id = @cinema_agreement_id
and    	processing_start_date <= @release_date
and    	isnull(processing_end_date,'1-jan-2050') >= @release_date

if @cinema_agreement_id = 404
begin
    insert 	into #complexes
    select 	complex_id 
    from 	cinema_agreement_policy 
    where	cinema_agreement_id = 405
    and    	processing_start_date <= @release_date
    and    	isnull(processing_end_date,'1-jan-2050') >= @release_date
end


/*insert into #complexes
select      distinct spot_liability.complex_id 
from        spot_liability,
			campaign_spot
where 		spot_liability.allocation_id = @allocation_id 
and			spot_liability.spot_id = campaign_spot.spot_id
*/
declare		liability_csr cursor for
select 		spot_liability.complex_id,
			sum(spot_amount),
			sum(cinema_amount),
			sum(cinema_rent),
			release_period,
			cancelled,
			liability_type,
			campaign_no
from		spot_liability,
			campaign_spot
where 		spot_liability.allocation_id = @allocation_id 
and			spot_liability.spot_id = campaign_spot.spot_id
and         spot_liability.liability_type = 3
and			spot_liability.allocation_id is not null
group by 	spot_liability.complex_id,
			release_period,
			cancelled,
			liability_type,
			campaign_no
union
select 		spot_liability.complex_id,
			sum(spot_amount),
			sum(cinema_amount),
			sum(cinema_rent),
			release_period,
			cancelled,
			liability_type,
			campaign_no
from		spot_liability,
			campaign_spot
where 		spot_liability.spot_id in (select dbo.f_spot_redirect(spot_id) from film_spot_xref where tran_id = @tran_id)
and         liability_type != 3
and			spot_liability.spot_id = campaign_spot.spot_id
and			cinema_amount != 0
group by 	spot_liability.complex_id,
			release_period,
			cancelled,
			liability_type,
			campaign_no

open liability_csr
fetch liability_csr into @complex_id, @spot_amount, @cinema_amount, @cinema_rent, @release_period, @cancelled, @liability_type_id, @campaign_no
while(@@fetch_status = 0)
begin

	select @complex_count = count(complex_id) from #complexes where complex_id = @complex_id

	if @complex_count > 0
		select @complex_name = complex_name from complex where complex_id = @complex_id
	else
	begin
		select @complex_count = count(complex_id) from complex where complex_id = @complex_id and exhibitor_category_code = 'U'
		if @complex_count > 0
			select @complex_name = 'Other Majors'
		else
			select @complex_name = 'Other Independants'
	end

	select @complex_count = count(complex_name) from #transactions where complex_name = @complex_name and release_period = @release_period and cancelled = @cancelled and liability_type_id = @liability_type_id and campaign_no = @campaign_no

	select @product_desc = product_desc from film_campaign where campaign_no = @campaign_no
 
	if @complex_count = 0
	begin
		insert into #transactions (
		campaign_no,
		product_desc,
		liability_type_id,
		revenue_source,
		complex_name,
		spot_amount,
		cinema_amount,
		cinema_rent,
		release_period,
		cancelled
		) values
		(
		@campaign_no,
		@product_desc,
		@liability_type_id,
		'',
		@complex_name,
		@spot_amount,
		@cinema_amount,
		@cinema_rent,
		@release_period,
		@cancelled
		)

	end
	else
	begin 
		update 	#transactions
		set		spot_amount = spot_amount + @spot_amount,
				cinema_amount = cinema_amount + @cinema_amount,
				cinema_rent = cinema_rent + @cinema_rent
		where	complex_name = @complex_name 
		and 	release_period = @release_period 
		and 	cancelled = @cancelled 
		and 	liability_type_id = @liability_type_id 
		and 	campaign_no = @campaign_no
	end

	fetch liability_csr into @complex_id, @spot_amount, @cinema_amount, @cinema_rent, @release_period, @cancelled, @liability_type_id, @campaign_no
end


select * from #transactions
return 0
GO
