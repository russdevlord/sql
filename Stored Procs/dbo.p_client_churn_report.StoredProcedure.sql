/****** Object:  StoredProcedure [dbo].[p_client_churn_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_client_churn_report]
GO
/****** Object:  StoredProcedure [dbo].[p_client_churn_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_client_churn_report]	@report_date			datetime,
									@prev_report_date		datetime,
									@country_code			char(1),
									@start_period			datetime,
									@end_period				datetime

as 

declare		@prev_amount			money,
			@current_amount			money,
			@new_amount				money,
			@prior_amount			money,
			@not_new_amount			money,
			@client_name			varchar(50),
			@client_group_desc		varchar(50),
			@client_id				int,
			@start_month			int,
			@end_month				int,
			@prev_start_period		datetime,
			@prev_end_period		datetime,
			@start_period_no		int,
			@end_period_no			int

set nocount on

create table #results
(
	report_date				datetime		null,
	prev_report_date		datetime		null,
	country_code			char(1)			null,
	prev_amount				money			null,
	current_amount			money			null,
	new_amount				money			null,
	prior_amount			money			null,
	not_new_amount			money			null,
	client_name				varchar(50)		null,
	client_group_desc		varchar(50)		null,
	client_id				int				null,
	start_period			datetime		null,
	end_period				datetime		null,
	prev_start_period		datetime		null,
	prev_end_period			datetime		null
)


select @start_period_no = period_no from accounting_period where end_date = @start_period 

select @end_period_no = period_no from accounting_period where end_date = @end_period 

select 	@prev_start_period = max(end_date)
from	accounting_period	
where	period_no = @start_period_no
and		end_date < @start_period

select 	@prev_end_period = max(end_date)
from	accounting_period	
where	period_no = @end_period_no
and		end_date < @end_period

declare 	client_csr cursor forward_only for
select		client.client_id,
			client_name,
			client_group_desc
from		film_campaign,
			campaign_revision,
			revision_transaction,
			film_screening_date_xref,
			client,
			client_group,
			branch
where		film_campaign.campaign_no = campaign_revision.campaign_no
and			campaign_revision.revision_id = revision_transaction.revision_id
and			film_screening_date_xref.screening_date =  revision_transaction.billing_date
and			film_screening_date_xref.benchmark_end between @start_period and @end_period
and			film_campaign.client_id = client.client_id
and			client.client_group_id = client_group.client_group_id
and			film_campaign.branch_code = branch.branch_code
and			branch.country_code = @country_code
and			delta_date <= @report_date
group by 	client.client_id,
			client_name,
			client_group_desc
having		sum(cost) > 0
union
select		client.client_id,
			client_name,
			client_group_desc
from		film_campaign,
			campaign_revision,
			revision_transaction,
			film_screening_date_xref,
			client,
			client_group,
			branch
where		film_campaign.campaign_no = campaign_revision.campaign_no
and			campaign_revision.revision_id = revision_transaction.revision_id
and			film_screening_date_xref.screening_date =  revision_transaction.billing_date
and			film_screening_date_xref.benchmark_end between @prev_start_period and @prev_end_period
and			film_campaign.client_id = client.client_id
and			client.client_group_id = client_group.client_group_id
and			film_campaign.branch_code = branch.branch_code
and			branch.country_code = @country_code
and			delta_date <= @prev_report_date
group by 	client.client_id,
			client_name,
			client_group_desc
having		sum(cost) > 0
order by 	client.client_id

open client_csr
fetch client_csr into @client_id, @client_name, @client_group_desc
while(@@fetch_status = 0)
begin

	select 	@current_amount = 0,
			@prev_amount = 0,
			@new_amount = 0,
			@prior_amount = 0,	
			@new_amount = 0

	select 	@current_amount = isnull(sum(cost),0)
	from	film_campaign,
			campaign_revision,
			revision_transaction,
			film_screening_date_xref
	where	film_campaign.campaign_no = campaign_revision.campaign_no
	and		campaign_revision.revision_id = revision_transaction.revision_id
	and		film_screening_date_xref.screening_date =  revision_transaction.billing_date
	and		film_screening_date_xref.benchmark_end between @start_period and @end_period
	and		delta_date <= @report_date
	and		film_campaign.client_id = @client_id
	and		film_campaign.branch_code <> 'Z'

	select 	@prev_amount = isnull(sum(cost),0)
	from	film_campaign,
			campaign_revision,
			revision_transaction,
			film_screening_date_xref
	where	film_campaign.campaign_no = campaign_revision.campaign_no
	and		campaign_revision.revision_id = revision_transaction.revision_id
	and		film_screening_date_xref.screening_date =  revision_transaction.billing_date
	and		film_screening_date_xref.benchmark_end between @prev_start_period and @prev_end_period
	and		delta_date <= @prev_report_date
	and		film_campaign.client_id = @client_id
	and		film_campaign.branch_code <> 'Z'

	select 	@new_amount = isnull(sum(cost),0)
	from	film_campaign,
			campaign_revision,
			revision_transaction,
			film_screening_date_xref
	where	film_campaign.campaign_no = campaign_revision.campaign_no
	and		campaign_revision.revision_id = revision_transaction.revision_id
	and		film_screening_date_xref.screening_date =  revision_transaction.billing_date
	and		film_screening_date_xref.benchmark_end between @start_period and @end_period
	and		delta_date <= @report_date
	and		film_campaign.client_id = @client_id
	and		film_campaign.branch_code <> 'Z'
	and		film_campaign.client_id not in (select 	distinct client_id 
											from 	film_campaign,
													campaign_revision,
													revision_transaction,
													film_screening_date_xref
											where	film_campaign.campaign_no = campaign_revision.campaign_no
											and		campaign_revision.revision_id = revision_transaction.revision_id
											and		film_screening_date_xref.screening_date =  revision_transaction.billing_date
											and		film_screening_date_xref.benchmark_end < @prev_end_period
											and		delta_date <= @report_date
											and		film_campaign.branch_code <> 'Z'
											and		film_campaign.client_id = @client_id)

	if @new_amount = 0
	begin
	
		if @prev_amount > 0 
			select @prior_amount = @current_amount

		if @prior_amount = 0 
		begin

	
			select 	@not_new_amount = isnull(sum(cost),0)
			from	film_campaign,
					campaign_revision,
					revision_transaction,
					film_screening_date_xref
			where	film_campaign.campaign_no = campaign_revision.campaign_no
			and		campaign_revision.revision_id = revision_transaction.revision_id
			and		film_screening_date_xref.screening_date =  revision_transaction.billing_date
			and		film_screening_date_xref.benchmark_end in (select benchmark_end from accounting_period where period_no between @start_period_no and @end_period_no )
			and		delta_date <= @report_date
			and		film_campaign.branch_code <> 'Z'
			and		film_campaign.client_id = @client_id
			and		film_campaign.client_id in 		(select distinct client_id 
													from 	film_campaign,
															campaign_revision,
															revision_transaction,
															film_screening_date_xref
													where	film_campaign.campaign_no = campaign_revision.campaign_no
													and		film_campaign.branch_code <> 'Z'
													and		campaign_revision.revision_id = revision_transaction.revision_id
													and		film_screening_date_xref.screening_date =  revision_transaction.billing_date
													and		film_screening_date_xref.benchmark_end between @start_period and @end_period
													and		delta_date <= @report_date
													and		film_campaign.client_id = @client_id)
			and		film_campaign.client_id not in (select 	distinct client_id 
													from 	film_campaign,
															campaign_revision,
															revision_transaction,
															film_screening_date_xref
													where	film_campaign.campaign_no = campaign_revision.campaign_no
													and		campaign_revision.revision_id = revision_transaction.revision_id
													and		film_campaign.branch_code <> 'Z'
													and		film_screening_date_xref.screening_date =  revision_transaction.billing_date
													and		film_screening_date_xref.benchmark_end between @prev_start_period and @prev_end_period
													and		delta_date <= @prev_report_date
													and		film_campaign.client_id = @client_id)

		if @not_new_amount > 0
			select @not_new_amount = isnull(@current_amount,0)
		end	
	end

	insert into #results
	(
		report_date,
		prev_report_date,
		country_code,
		prev_amount,
		current_amount,
		new_amount,
		prior_amount,
		not_new_amount,
		client_name,
		client_group_desc,
		client_id,
		start_period,
		end_period,
		prev_start_period,
		prev_end_period
	) values
	(	
		@report_date,
		@prev_report_date,
		@country_code,
		@prev_amount,
		@current_amount,
		@new_amount,
		@prior_amount,
		@not_new_amount,
		@client_name,
		@client_group_desc,
		@client_id,
		@start_period,
		@end_period,
		@prev_start_period,
		@prev_end_period
	)


	fetch client_csr into @client_id, @client_name, @client_group_desc
end

select 		report_date,
			prev_report_date,
			country_code,
			prev_amount,
			current_amount,
			new_amount,
			prior_amount,
			not_new_amount,
			client_name,
			client_group_desc,
			start_period,
			end_period,
			prev_start_period,
			prev_end_period
from 		#results
where		client_group_desc = 'Other'
union
select 		report_date,
			prev_report_date,
			country_code,
			sum(prev_amount),
			sum(current_amount),
			sum(new_amount),
			sum(prior_amount),
			sum(not_new_amount),
			client_group_desc,
			client_group_desc,
			start_period,
			end_period,
			prev_start_period,
			prev_end_period
from 		#results
where		client_group_desc != 'Other'
group by 	report_date,
			prev_report_date,
			country_code,
			client_group_desc,
			client_group_desc,
			start_period,
			end_period,
			prev_start_period,
			prev_end_period
order by 	client_name, client_group_desc

return 0
GO
