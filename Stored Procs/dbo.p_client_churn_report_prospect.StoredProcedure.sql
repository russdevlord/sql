/****** Object:  StoredProcedure [dbo].[p_client_churn_report_prospect]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_client_churn_report_prospect]
GO
/****** Object:  StoredProcedure [dbo].[p_client_churn_report_prospect]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_client_churn_report_prospect]	@report_date			datetime,
											@prev_report_date		datetime,
											@country_code			char(1),
											@start_period			datetime,
											@end_period				datetime,
											@business_unit			integer

as 

declare		@prev_amount				money,
			@prev_amount_now			money,
			@current_amount				money,
			@new_adv_amount				money,
			@prev_adv_amount			money,
			@prior_adv_amount			money,
			@prev_adv_amount_store		money,
			@prior_adv_amount_store		money,
			@client_name				varchar(50),
			@client_group_desc			varchar(50),
			@client_id					int,
			@start_month				int,
			@end_month					int,
			@prev_start_period			datetime,
			@prev_end_period			datetime,
			@start_period_no			int,
			@end_period_no				int,
			@prev_year_end				datetime,
			@client						char(1),
			@new_adv					char(1),
			@prev_adv					char(1),
			@prior_adv					char(1),
			@comments					varchar(1000)

set nocount on

create table #results
(
	report_date				datetime		null,
	prev_report_date		datetime		null,
	country_code			char(1)			null,
	prev_amount				money			null,
	prev_amount_now			money			null,
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
	prev_end_period			datetime		null,
	client					char(1)			null,
	prev_year_end			datetime		null,
	new_adv					char(1)			null,
	prev_adv				char(1)			null,
	prior_adv				char(1)			null,
	comments			varchar(1000)	null
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

select 	@prev_year_end = max(end_date)
from	accounting_period	
where	end_date < @start_period

declare 	client_csr cursor forward_only for
select		client.client_id,
			client_name,
			client_group_desc,
			mode,
			revenue,
			comments
from		client_prospects,
			client,
			client_group
where		client_prospects.client_id = client.client_id
and			client.client_group_id = client_group.client_group_id
and			client_prospects.country_code = @country_code
and			mode = 'C'
and			((@business_unit = 1 
and			business_unit_id = 2)
or 			(@business_unit = 2 
and			business_unit_id in (3,5)))
group by 	client.client_id,
			client_name,
			client_group_desc,
			revenue,
			comments,
			mode
union
select		client_group.client_group_id,
			'',
			client_group_desc,
			mode,
			revenue,
			comments
from		client_prospects,
			client_group
where		client_prospects.client_group_id = client_group.client_group_id
and			client_prospects.country_code = @country_code
and			mode = 'G'
and			((@business_unit = 1 
and			business_unit_id = 2)
or 			(@business_unit = 2 
and			business_unit_id in (3,5)))
group by 	client_group.client_group_id,
			client_group_desc,
			revenue,
			comments,
			mode	
order by 	client.client_id

open client_csr
fetch client_csr into @client_id, @client_name, @client_group_desc, @client, @current_amount, @comments
while(@@fetch_status = 0)
begin

	select 	@prev_amount = 0,
			@prev_amount_now = 0,
			@new_adv_amount = 0,
			@prev_adv_amount = 0,	
			@prior_adv_amount = 0,
			@prev_adv_amount_store = 0,	
			@prior_adv_amount_store = 0,
			@new_adv = 'N',
			@prev_adv = 'N',
			@prior_adv = 'N'

	select 	@prev_amount = isnull(sum(cost),0)
	from	film_campaign,
			campaign_revision,
			revision_transaction,
			film_screening_date_xref,
			client,
			branch
	where	film_campaign.campaign_no = campaign_revision.campaign_no
	and		campaign_revision.revision_id = revision_transaction.revision_id
	and		film_screening_date_xref.screening_date =  revision_transaction.billing_date
	and		film_screening_date_xref.benchmark_end between @prev_start_period and @prev_end_period
	and		delta_date <= @prev_report_date
	and		film_campaign.branch_code = branch.branch_code
	and		branch.country_code = @country_code
	and		((@business_unit = 1 
	and		business_unit_id = 2)
	or 		(@business_unit = 2 
	and		business_unit_id in (3,5)))
	and		film_campaign.client_id = client.client_id
	and		((film_campaign.client_id = @client_id
	and		@client = 'C')
	or		(client.client_group_id = @client_id
	and		@client = 'G'))

	select 	@prev_amount_now = isnull(sum(cost),0)
	from	film_campaign,
			campaign_revision,
			revision_transaction,
			film_screening_date_xref,
			client,
			branch
	where	film_campaign.campaign_no = campaign_revision.campaign_no
	and		campaign_revision.revision_id = revision_transaction.revision_id
	and		film_screening_date_xref.screening_date =  revision_transaction.billing_date
	and		film_screening_date_xref.benchmark_end between @prev_start_period and @prev_end_period
	and		delta_date <= @report_date
	and		film_campaign.branch_code = branch.branch_code
	and		branch.country_code = @country_code
	and		((@business_unit = 1 
	and		business_unit_id = 2)
	or 		(@business_unit = 2 
	and		business_unit_id in (3,5)))
	and		film_campaign.client_id = client.client_id
	and		((film_campaign.client_id = @client_id
	and		@client = 'C')
	or		(client.client_group_id = @client_id
	and		@client = 'G'))

	select 	@prev_adv_amount_store = isnull(sum(cost),0)
	from	film_campaign,
			campaign_revision,
			revision_transaction,
			film_screening_date_xref,
			client,
			branch
	where	film_campaign.campaign_no = campaign_revision.campaign_no
	and		campaign_revision.revision_id = revision_transaction.revision_id
	and		film_screening_date_xref.screening_date =  revision_transaction.billing_date
	and		film_screening_date_xref.benchmark_end between @prev_start_period and @prev_year_end
	and		((@business_unit = 1 
	and		business_unit_id = 2)
	or 		(@business_unit = 2 
	and		business_unit_id in (3,5)))
	and		delta_date <= @report_date
	and		film_campaign.branch_code = branch.branch_code
	and		branch.country_code = @country_code
	and		film_campaign.client_id = client.client_id
	and		((film_campaign.client_id = @client_id
	and		@client = 'C')
	or		(client.client_group_id = @client_id
	and		@client = 'G'))

	select 	@prior_adv_amount_store = isnull(sum(cost),0)
	from	film_campaign,
			campaign_revision,
			revision_transaction,
			film_screening_date_xref,
			client,
			branch
	where	film_campaign.campaign_no = campaign_revision.campaign_no
	and		campaign_revision.revision_id = revision_transaction.revision_id
	and		film_screening_date_xref.screening_date =  revision_transaction.billing_date
	and		((@business_unit = 1 
	and		business_unit_id = 2)
	or 		(@business_unit = 2 
	and		business_unit_id in (3,5)))
	and		film_screening_date_xref.benchmark_end < @prev_start_period
	and		delta_date <= @report_date
	and		film_campaign.branch_code = branch.branch_code
	and		branch.country_code = @country_code
	and		film_campaign.client_id = client.client_id
	and		((film_campaign.client_id = @client_id
	and		@client = 'C')
	or		(client.client_group_id = @client_id
	and		@client = 'G'))

	if @prior_adv_amount_store > 0 
	begin
		select @prior_adv = 'Y'
	end

	if @prev_adv_amount_store > 0 
	begin
		select @prev_adv = 'Y'
	end

	if @prev_adv = 'N' and @prior_adv = 'N'
	begin
		select @new_adv = 'Y'
	end
	
	if @prev_adv_amount_store > 0 
	begin

		select @prev_adv_amount = @current_amount
	end
	else
	begin
		if @prior_adv_amount_store > 0
		begin
			select @prior_adv_amount = @current_amount
		end
		else
		begin
			select @new_adv_amount = @current_amount
		end
	end	
	
	insert into #results
	(
		report_date,
		prev_report_date,
		country_code,
		prev_amount,
		prev_amount_now,
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
		prev_end_period,
		client,
		prev_year_end,
		new_adv,
		prev_adv,
		prior_adv,
		comments
	) values
	(	
		@report_date,
		@prev_report_date,
		@country_code,
		@prev_amount,
		@prev_amount_now,
		@current_amount,
		@new_adv_amount,
		@prev_adv_amount,
		@prior_adv_amount,
		@client_name,
		@client_group_desc,
		@client_id,
		@start_period,
		@end_period,
		@prev_start_period,
		@prev_end_period,
		@client,
		@prev_year_end,
		@new_adv,
		@prev_adv,
		@prior_adv,
		@comments
	)


	fetch client_csr into @client_id, @client_name, @client_group_desc, @client, @current_amount, @comments
end

select 		report_date,
			prev_report_date,
			country_code,
			prev_amount,
			prev_amount_now,
			current_amount,
			new_amount,
			prior_amount,
			not_new_amount,
			client_name,
			client_group_desc,
			start_period,
			end_period,
			prev_start_period,
			prev_end_period,
			client,
			prev_year_end,
			new_adv,
			prev_adv,
			prior_adv,
			comments
from 		#results
where		client = 'C'
union
select 		report_date,
			prev_report_date,
			country_code,
			prev_amount,
			prev_amount_now,
			current_amount,
			new_amount,
			prior_amount,
			not_new_amount,
			client_group_desc,
			client_group_desc,
			start_period,
			end_period,
			prev_start_period,
			prev_end_period,
			client,
			prev_year_end,
			new_adv,
			prev_adv,
			prior_adv,
			comments
from 		#results
where 		client = 'G'
order by 	client_name, client_group_desc

return 0
GO
