/****** Object:  StoredProcedure [dbo].[p_vm_br_new_lost_continuing_clients]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_vm_br_new_lost_continuing_clients]
GO
/****** Object:  StoredProcedure [dbo].[p_vm_br_new_lost_continuing_clients]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE proc [dbo].[p_vm_br_new_lost_continuing_clients]     @start_date         datetime,
															@end_date           datetime,
															@country_code       char(1),
															@amount             money      
as

declare         @prev_start_date        datetime,
                @prev_end_date          datetime

set nocount on

select @prev_start_date = dateadd(yy, -1, @start_date)
select @prev_end_date = dateadd(yy, -1, @end_date)

create table #new_lost_cont (
		no_clients                  int,
		revenue                     money,
		type_of_client              char(1),
		business_unit_desc          varchar(50),
		status                      varchar(12),
		product_report_group_desc   varchar(50)
)

create table #report_groups (
	sort_order                  int,
	product_report_group_desc   varchar(50),
	status                      varchar(12)
)

insert into #new_lost_cont
select  count( distinct client_name),
        sum(revenue),
        type,
        business_unit_desc,
        status,
        product_report_group_desc
from    (select		client_name,
                    sum(cost) as revenue,
                    'C' as type,
                    business_unit_desc,
                    'New' as status,
                    product_report_group_desc
        from		film_campaign,
                    campaign_revision,
                    revision_transaction,
                    film_screening_date_xref,
                    client,
                    client_group,
                    branch,
                    business_unit,
                    product_report_groups,
                    product_report_group_client_xref,
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
        and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
        and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
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
        group by 	business_unit_desc,
                    client_name,
                    product_report_group_desc
        having		sum(cost) >= @amount
        union
        select		client_group_desc,
                    sum(cost),
                    'G',
                    business_unit_desc,
                    'New',
                    product_report_group_desc
        from		film_campaign,
                    campaign_revision,
                    revision_transaction,
                    film_screening_date_xref,
                    client,
                    client_group,
                    branch,
                    business_unit,
                    product_report_groups,
                    product_report_group_client_xref,
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
        and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
        and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
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
        group by 	business_unit_desc,
                    client_group_desc,
                    product_report_group_desc
        having		sum(cost) >= @amount) as temp_table
group by    type,
            business_unit_desc,
            status,
        product_report_group_desc


insert into #new_lost_cont
select  count( distinct client_name),
        sum(revenue),
        type,
        business_unit_desc,
        status,
        product_report_group_desc
from    (select		client_name,
                    sum(cost) as revenue,
                    'C' as type,
                    business_unit_desc,
                    'Continuing' as status,
                    product_report_group_desc
        from		film_campaign,
                    campaign_revision,
                    revision_transaction,
                    film_screening_date_xref,
                    client,
                    client_group,
                    branch,
                    business_unit,
                    product_report_groups,
                    product_report_group_client_xref,
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
        and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
        and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
        and			film_campaign.business_unit_id = business_unit.business_unit_id
        and         client.client_id in (select	    film_campaign_reporting_client.client_id
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
        group by 	business_unit_desc, 
                    client_name,
                    product_report_group_desc
        having		sum(cost) >= @amount
        union
        select		client_group_desc,
                    sum(cost),
                    'G',
                    business_unit_desc,
                    'Continuing',
                    product_report_group_desc
        from		film_campaign,
                    campaign_revision,
                    revision_transaction,
                    film_screening_date_xref,
                    client,
                    client_group,
                    branch,
                    business_unit,
                    product_report_groups,
                    product_report_group_client_xref,
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
        and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
        and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
        and			film_campaign.business_unit_id = business_unit.business_unit_id
        and         client.client_group_id in (select		client.client_group_id
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
        group by 	business_unit_desc, 
                    client_group_desc,
                    product_report_group_desc
        having		sum(cost) >= @amount) as temp_table
group by    type,
            business_unit_desc,
            status,
            product_report_group_desc

insert into #new_lost_cont
select  count( distinct client_name),
        sum(revenue),
        type,
        business_unit_desc,
        status,
        product_report_group_desc
from    (select		client_name,
                    sum(cost) as revenue,
                    'C' as type,
                    business_unit_desc,
                    'Lost' as status,
        product_report_group_desc
        from		film_campaign,
                    campaign_revision,
                    revision_transaction,
                    film_screening_date_xref,
                    client,
                    client_group,
                    branch,
                    business_unit,
                    product_report_groups,
                    product_report_group_client_xref,
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
        and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
        and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
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
                                            and			film_screening_date_xref.benchmark_end between @start_date and @end_date
                                            and			film_campaign.client_id = client.client_id
                                            and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
                                            and         film_campaign_reporting_client.client_id = client.client_id
                                            and			film_campaign.branch_code = branch.branch_code
                                            and			branch.country_code = @country_code
                                            and			client_group_desc = 'Other'
                                            group by 	film_campaign_reporting_client.client_id
                                            having		sum(cost) > 0)
        group by 	business_unit_desc, client_name,
        product_report_group_desc
        having		sum(cost) >= @amount
        union
        select		client_group_desc,
                    sum(cost),
                    'G',
                    business_unit_desc,
                    'Lost',
        product_report_group_desc
        from		film_campaign,
                    campaign_revision,
                    revision_transaction,
                    film_screening_date_xref,
                    client,
                    client_group,
                    branch,
                    business_unit,
                    product_report_groups,
                    product_report_group_client_xref,
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
        and         film_campaign.client_product_id = product_report_group_client_xref.client_product_id
        and         product_report_group_client_xref.product_report_group_id = product_report_groups.product_report_group_id
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
                                            and			film_screening_date_xref.benchmark_end between @start_date and @end_date
                                            and			film_campaign.campaign_no = film_campaign_reporting_client.campaign_no
                                            and         film_campaign_reporting_client.client_id = client.client_id
                                            and			client.client_group_id = client_group.client_group_id
                                            and			film_campaign.branch_code = branch.branch_code
                                            and			branch.country_code = @country_code
                                            and			client_group_desc != 'Other'
                                            group by 	client.client_group_id
                                            having		sum(cost) > 0)
        group by 	business_unit_desc, client_group_desc,
        product_report_group_desc
        having		sum(cost) >= @amount
        ) as temp_table
group by    type,
            business_unit_desc,
            status,
         product_report_group_desc
            
            
insert into #report_groups
values (1,'Automotive','New')

insert into #report_groups
values (2,'Alcohol','New')

insert into #report_groups
values (3,'Packaged Goods','New')

insert into #report_groups
values (4,'Electronic Games','New')

insert into #report_groups
values (5,'Fast Food','New')

insert into #report_groups
values (6,'Financial','New')

insert into #report_groups
values (7,'Government','New')

insert into #report_groups
values (8,'Telco','New')

insert into #report_groups
values (1,'Automotive','Lost')

insert into #report_groups
values (2,'Alcohol','Lost')

insert into #report_groups
values (3,'Packaged Goods','Lost')

insert into #report_groups
values (4,'Electronic Games','Lost')

insert into #report_groups
values (5,'Fast Food','Lost')

insert into #report_groups
values (6,'Financial','Lost')

insert into #report_groups
values (7,'Government','Lost')

insert into #report_groups
values (8,'Telco','Lost')

insert into #report_groups
values (1,'Automotive','Continuing')

insert into #report_groups
values (2,'Alcohol','Continuing')

insert into #report_groups
values (3,'Packaged Goods','Continuing')

insert into #report_groups
values (4,'Electronic Games','Continuing')

insert into #report_groups
values (5,'Fast Food','Continuing')

insert into #report_groups
values (6,'Financial','Continuing')

insert into #report_groups
values (7,'Government','Continuing')

insert into #report_groups
values (8,'Telco','Continuing')
            
select  #report_groups.sort_order,
        #report_groups.product_report_group_desc,
        #report_groups.status,
        isnull(revenue,0) as revenue,
        isnull(no_clients,0) as no_spots
--from    #new_lost_cont,
--        #report_groups
--where   #new_lost_cont.product_report_group_desc =* #report_groups.product_report_group_desc
--and     #new_lost_cont.status =* #report_groups.status
FROM	#new_lost_cont  LEFT OUTER JOIN
		#report_groups ON #new_lost_cont.product_report_group_desc = #report_groups.product_report_group_desc
		AND  #new_lost_cont.status = #report_groups.status

return 0
GO
