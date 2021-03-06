/****** Object:  StoredProcedure [dbo].[p_cag_invoicing_invoiced_details]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_invoicing_invoiced_details]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_invoicing_invoiced_details]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cag_invoicing_invoiced_details]			@cinema_agreement_id				int,
																						@accounting_period						datetime
																						
as

declare			@error							int,
						@duration						int,
						@no_spots						int,
						@campaign_no				int,
						@complex_id					int,
						@revenue_source			char(1)

set nocount on

create table #results
(
	campaign_no							int,
	product_desc						varchar(100),	 
	accounting_period				datetime, 
	complex_name						varchar(100), 
	complex_id								int,
	cinema_agreement_id			int, 
	revenue_desc							varchar(50), 
	revenue_source						char(1),
	full_revenue							money, 
	agreement_revenue				money, 
	duration									int, 
	no_spots									int
)						

insert into	#results
select			campaign_no, 
					product_desc, 
					accounting_period, 
					complex_name, 
					complex.complex_id,
					cinema_agreement_id, 
					revenue_desc, 
					film_revenue_creation.revenue_source, 
					sum(cinema_amount), 
					sum(cinema_amount * percentage_entitlement), 
					0, 
					0
from			film_revenue_creation, 
					complex, 
					cinema_agreement_policy,
					cinema_revenue_source
where			film_revenue_creation.complex_id = complex.complex_id
and				film_revenue_creation.complex_id = cinema_agreement_policy.complex_id
and				film_revenue_creation.revenue_source = cinema_agreement_policy.revenue_source
and				film_revenue_creation.accounting_period  between isnull(rent_inclusion_start, '1-jan-2000') and isnull(rent_inclusion_end, '31-dec-2050')
and				film_revenue_creation.accounting_period  = @accounting_period
and				cinema_agreement_policy.cinema_agreement_id = @cinema_agreement_id
and				film_revenue_creation.revenue_source = cinema_revenue_source.revenue_source
and				liability_type_id not in (3,10)
group by		campaign_no, 
					product_desc, 
					accounting_period, 
					film_revenue_creation.revenue_source, 
					complex_name, 
					cinema_agreement_id, 
					complex.complex_id,
					revenue_desc
					
declare		revenue_csr cursor forward_only for
select			campaign_no, 
					complex_id,
					revenue_source
from			#results
group by		campaign_no, 
					complex_id,
					revenue_source
for				read only					
							
open revenue_csr
fetch revenue_csr into @campaign_no,  @complex_id, @revenue_source
while(@@fetch_status = 0)
begin

	select			@duration = avg(duration) ,
						@no_spots	= sum(no_spots) 
	from			v_film_revenue_creation
	where			campaign_no = @campaign_no
	and				accounting_period = @accounting_period
	and				complex_id = @complex_id
	and				revenue_source = @revenue_source
	
	update		#results
	set				duration = @duration, 
						no_spots = @no_spots
	where			campaign_no = @campaign_no
	and				accounting_period = @accounting_period
	and				complex_id = @complex_id
	and				revenue_source = @revenue_source						

	fetch revenue_csr into @campaign_no,  @complex_id, @revenue_source
end

select * from #results
GO
