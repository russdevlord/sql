/****** Object:  StoredProcedure [dbo].[p_vm_br_new_clients]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_vm_br_new_clients]
GO
/****** Object:  StoredProcedure [dbo].[p_vm_br_new_clients]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

create proc [dbo].[p_vm_br_new_clients]     @start_date         datetime,
                                    @end_date           datetime,
                                    @country_code       char(1),
                                    @amount             money
                                    
as 

declare         @prev_start_date        datetime,
                @prev_end_date          datetime

set nocount on

select @prev_start_date = dateadd(yy, -1, @start_date)
select @prev_end_date = dateadd(yy, -1, @end_date)
                                    
--Month of Sale	Month of Revenue going to screen	Amount (AUD 000's)	Region Sold	Sales Executive	Explanation of campaign

select		client_name as 'Client',
            film_campaign.confirmed_date as 'Month of Sale',
            min(revision_transaction.billing_date) as 'Month of Revenue going to screen',
            sum(cost) as 'Amount (AUD 000s)',
            branch.branch_name as 'Region Sold	',
            (select first_name + ' ' + last_name from sales_rep where rep_id = film_campaign.rep_id) as 'Sales Executive',
            '' as 'Explanation of campaign'
from		film_campaign,
            campaign_revision,
            revision_transaction,
            film_screening_date_xref,
            client,
            client_group,
            branch,
            business_unit,
            film_campaign_reporting_client
where		film_campaign.campaign_no = campaign_revision.campaign_no
and			campaign_revision.revision_id = revision_transaction.revision_id
and			film_screening_date_xref.screening_date =  revision_transaction.billing_date
and			film_screening_date_xref.benchmark_end between @start_date and @end_date
and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
and         film_campaign_reporting_client.client_id = client.client_id
and			client.client_group_id = client_group.client_group_id
and			film_campaign.branch_code = branch.branch_code
and			branch.country_code = @country_code
and			client_group_desc = 'Other'
and			film_campaign.business_unit_id = business_unit.business_unit_id
and         client.client_id not in (select	    film_campaign_reporting_client.client_id 
                                    from		film_campaign,
                                                campaign_revision,
                                                revision_transaction,
                                                film_screening_date_xref,
                                                client,
                                                client_group,
                                                branch,
                                                film_campaign_reporting_client
                                    where		film_campaign.campaign_no = campaign_revision.campaign_no
                                    and			campaign_revision.revision_id = revision_transaction.revision_id
                                    and			film_screening_date_xref.screening_date =  revision_transaction.billing_date
                                    and			film_screening_date_xref.benchmark_end between @prev_start_date and @prev_end_date
                                    and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
                                    and         film_campaign_reporting_client.client_id = client.client_id
                                    and			client.client_group_id = client_group.client_group_id
                                    and			film_campaign.branch_code = branch.branch_code
                                    and			branch.country_code = @country_code
                                    and			client_group_desc = 'Other'
                                    group by 	film_campaign_reporting_client.client_id
                                    having		sum(cost) > 0)
group by 	client_name,
            branch.branch_name,
            film_campaign.confirmed_date,
            film_campaign.rep_id
having		sum(cost) >= @amount
union
select		client_group_desc,
            film_campaign.confirmed_date as 'Month of Sale',
            min(revision_transaction.billing_date) as 'Month of Revenue going to screen',
            sum(cost) as 'Amount (AUD 000s)',
            branch.branch_name as 'Region Sold',
            (select first_name + ' ' + last_name from sales_rep where rep_id = film_campaign.rep_id) as 'Sales Executive',
            '' as 'Explanation of campaign'
from		film_campaign,
            campaign_revision,
            revision_transaction,
            film_screening_date_xref,
            client,
            client_group,
            branch,
            business_unit,
            film_campaign_reporting_client
where		film_campaign.campaign_no = campaign_revision.campaign_no
and			campaign_revision.revision_id = revision_transaction.revision_id
and			film_screening_date_xref.screening_date =  revision_transaction.billing_date
and			film_screening_date_xref.benchmark_end between @start_date and @end_date
and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
and         film_campaign_reporting_client.client_id = client.client_id
and			client.client_group_id = client_group.client_group_id
and			film_campaign.branch_code = branch.branch_code
and			branch.country_code = @country_code
and			client_group_desc != 'Other'
and			film_campaign.business_unit_id = business_unit.business_unit_id
and         client.client_group_id not in (select		client.client_group_id
                                    from		film_campaign,
                                                campaign_revision,
                                                revision_transaction,
                                                film_screening_date_xref,
                                                client,
                                                client_group,
                                                branch,
                                                film_campaign_reporting_client
                                    where		film_campaign.campaign_no = campaign_revision.campaign_no
                                    and			campaign_revision.revision_id = revision_transaction.revision_id
                                    and			film_screening_date_xref.screening_date =  revision_transaction.billing_date
                                    and			film_screening_date_xref.benchmark_end between @prev_start_date and @prev_end_date
                                    and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
                                    and         film_campaign_reporting_client.client_id = client.client_id
                                    and			client.client_group_id = client_group.client_group_id
                                    and			film_campaign.branch_code = branch.branch_code
                                    and			branch.country_code = @country_code
                                    and			client_group_desc != 'Other'
                                    group by 	client.client_group_id
                                    having		sum(cost) > 0)
group by 	client_group_desc,
            branch.branch_name,
            film_campaign.confirmed_date,
            film_campaign.rep_id
having		sum(cost) > @amount
order by    sum(cost) desc

return 0
GO
