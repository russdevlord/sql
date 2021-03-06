/****** Object:  View [dbo].[v_spots_allocated_by_type]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_spots_allocated_by_type]
GO
/****** Object:  View [dbo].[v_spots_allocated_by_type]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO




CREATE VIEW [dbo].[v_spots_allocated_by_type]
AS

select			allocated.spot_id,
					allocated.campaign_no,
					allocated.package_id,
					allocated.complex_id,
					allocated.screening_date,
					allocated.billing_date,
					allocated.spot_status,
					allocated.spot_type,
					allocated.tran_id,
					allocated.rate,
					allocated.charge_rate,
					allocated.makegood_rate,
					allocated.cinema_rate,
					allocated.spot_instruction,
					allocated.schedule_auto_create,
					allocated.billing_period,
					allocated.spot_weighting,
					allocated.cinema_weighting,
					allocated.certificate_score,
					allocated.dandc,
					allocated.onscreen,
					allocated.spot_redirect
from				campaign_spot allocated
where			allocated.spot_status = 'X'
and				allocated.spot_id not in (select spot_redirect from campaign_spot where campaign_no = allocated.campaign_no and spot_redirect is not null)
and				allocated.spot_type not in ('F', 'K', 'T')
union all
select			allocated.spot_id,
					allocated.campaign_no,
					allocated.package_id,
					allocated.complex_id,
					allocated.screening_date,
					allocated.billing_date,
					allocated.spot_status,
					allocated.spot_type,
					allocated.tran_id,
					unallocated.rate,
					unallocated.charge_rate,
					unallocated.makegood_rate,
					unallocated.cinema_rate,
					allocated.spot_instruction,
					allocated.schedule_auto_create,
					allocated.billing_period,
					allocated.spot_weighting,
					allocated.cinema_weighting,
					allocated.certificate_score,
					allocated.dandc,
					allocated.onscreen,
					allocated.spot_redirect
from				campaign_spot allocated,
					campaign_spot unallocated
where			allocated.spot_status = 'X'
and				allocated.spot_id = unallocated.spot_redirect
and				allocated.spot_type not in ('F', 'K', 'T')
union all		
select			allocated.spot_id,
					allocated.campaign_no,
					allocated.package_id,
					allocated.complex_id,
					allocated.screening_date,
					allocated.billing_date,
					allocated.spot_status,
					allocated.spot_type,
					allocated.tran_id,
					allocated.rate,
					(select sum(spot_amount) from spot_liability where spot_id = allocated.spot_id and liability_type in (1,5, 34)),
					allocated.makegood_rate,
					(select sum(cinema_amount) from spot_liability where spot_id = allocated.spot_id and liability_type in (1,5,34)),
					allocated.spot_instruction,
					allocated.schedule_auto_create,
					allocated.billing_period,
					allocated.spot_weighting,
					allocated.cinema_weighting,
					allocated.certificate_score,
					allocated.dandc,
					allocated.onscreen,
					allocated.spot_redirect
from				campaign_spot allocated
where			allocated.spot_status = 'X'
and				allocated.spot_id not in (select spot_redirect from campaign_spot where campaign_no = allocated.campaign_no and spot_redirect is not null)
and				allocated.spot_type in ('F', 'K', 'T')
union all
select			allocated.spot_id,
					allocated.campaign_no,
					allocated.package_id,
					allocated.complex_id,
					allocated.screening_date,
					allocated.billing_date,
					allocated.spot_status,
					allocated.spot_type,
					allocated.tran_id,
					unallocated.rate,
					(select sum(spot_amount) from spot_liability where spot_id = allocated.spot_id and liability_type in (1,5, 34)),
					unallocated.makegood_rate,
					(select sum(cinema_amount) from spot_liability where spot_id = allocated.spot_id and liability_type in (1,5,34)),
					allocated.spot_instruction,
					allocated.schedule_auto_create,
					allocated.billing_period,
					allocated.spot_weighting,
					allocated.cinema_weighting,
					allocated.certificate_score,
					allocated.dandc,
					allocated.onscreen,
					allocated.spot_redirect
from				campaign_spot allocated,
					campaign_spot unallocated
where			allocated.spot_status = 'X'
and				allocated.spot_id = unallocated.spot_redirect
and				allocated.spot_type in ('F', 'K', 'T')


GO
