/****** Object:  StoredProcedure [dbo].[p_cag_aged_trial_balance]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_aged_trial_balance]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_aged_trial_balance]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc	[dbo].[p_cag_aged_trial_balance]		@cinema_agreement_id			int,
											@accounting_period				datetime

as	

declare		@error							int,
			@cinema_agreement_id_sniff		int,
			@accounting_period_sniff		datetime

select			@cinema_agreement_id_sniff = @cinema_agreement_id,
				@accounting_period_sniff = @accounting_period

select			fc.campaign_no, 
				fc.product_desc,
				complex_name, 
				cap.revenue_source,
				sl.creation_period,
				case datediff(mm, sl.creation_period, @accounting_period)
					when 0 then 0
					when 1 then 1
					when 2 then 2
					when 3 then 3
					when 4 then 4
					else 5
				end as credit_age,
				case datediff(mm, sl.creation_period, @accounting_period)
					when 0 then 'Current'
					when 1 then '30 Days'
					when 2 then '60 Days'
					when 3 then '90 Days'
					when 4 then '120 Days'
					else '120+ Days'
				end as credit_age_desc,
				crc.revenue_desc,
				sum(cinema_amount_sum * percentage_entitlement) as liability_amount
from			cinema_agreement_policy cap
inner join		complex cplx on cap.complex_id = cplx.complex_id
inner join		v_campaign_spot_liability_aged sl on cap.complex_id = sl.complex_id
and				cap.revenue_source = sl.revenue_source
inner join		film_campaign fc on sl.campaign_no = fc.campaign_no
inner join		cinema_revenue_source crc on sl.revenue_source = crc.revenue_source
where			cinema_agreement_id = @cinema_agreement_id
and				cap.active_flag = 'Y'
and				policy_status_code in ('A', 'N')
and				fc.campaign_status in ('L', 'F')
and				cinema_amount_sum <> 0
group by		fc.campaign_no, 
				fc.product_desc,
				complex_name, 
				cap.revenue_source,
				crc.revenue_desc,
				creation_period
having			sum(cinema_amount_sum) <> 0
				
return 0
GO
