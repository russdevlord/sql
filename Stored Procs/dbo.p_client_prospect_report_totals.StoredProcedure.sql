/****** Object:  StoredProcedure [dbo].[p_client_prospect_report_totals]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_client_prospect_report_totals]
GO
/****** Object:  StoredProcedure [dbo].[p_client_prospect_report_totals]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_client_prospect_report_totals]		@client_prospect_id					int

as

declare		@media_cost							money,
					@media_value							money,
					@bundled_inc_cost					money,
					@bundled_inc_value				money,
					@inclusion_cost						money,
					@inclusion_value						money

					
					
select 		@media_cost =isnull( sum(charge_rate * no_screens),0),
					@media_value =isnull( sum(rate * no_screens),0)
from			client_prospect_spots
where		client_prospect_id = @client_prospect_id

select 		@bundled_inc_cost =isnull( sum(total_charge),0),
					@bundled_inc_value =isnull( sum(total_value),0)
from			client_prospect_inclusion
where		client_prospect_id = @client_prospect_id
and				commissionable = 'Y'

select 		@inclusion_cost =isnull( sum(total_charge),0),
					@inclusion_value =isnull( sum(total_value),0)
from			client_prospect_inclusion
where		client_prospect_id = @client_prospect_id
and				commissionable = 'N'


select		@media_cost as media_cost,
					@media_value as media_value,
					@bundled_inc_cost as bundled_inc_cost,
					@bundled_inc_value as bundled_inc_value,
					@inclusion_cost as inclusion_cost,
					@inclusion_value as inclusion_value
					
					
return 0
GO
