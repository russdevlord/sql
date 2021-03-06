/****** Object:  StoredProcedure [dbo].[p_vm_br_new_lost_cont_clients_detail]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_vm_br_new_lost_cont_clients_detail]
GO
/****** Object:  StoredProcedure [dbo].[p_vm_br_new_lost_cont_clients_detail]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_vm_br_new_lost_cont_clients_detail]        @start_date				datetime,
																@end_date				datetime,
																@country_code			char(1),
																@years_to_compare		int
                                                    
as

declare         @prev_start_date        datetime,
                @prev_end_date          datetime

set nocount on

select @prev_start_date = dateadd(yy, -@years_to_compare, @start_date)
select @prev_end_date = dateadd(ss, -1, @start_date)

print @start_date
print @end_date
print @prev_start_date
print @prev_end_date

create table #new_lost_cont
(
client_name                 varchar(100),
revenue                     money,
type_of_client              varchar(50),
business_unit_desc          varchar(50),
client_status               varchar(12),
branch_name					varchar(50)
)

insert into #new_lost_cont
select		client_name,
            sum(rev) as revenue,
            'Client' as type,
            business_unit_desc,
            'New' as client_status,
            branch_name
from		v_statrev_agency
where		revenue_period between @start_date and @end_date
and			country_code = @country_code
and         client_id not in (	select	    client_id
								from		v_statrev_agency
								where		revenue_period between @prev_start_date and @prev_end_date
								and			country_code = @country_code
								group by 	client_id
								having		sum(rev) > 0)
group by 	business_unit_desc,
            client_name,
            branch_name
having		sum(rev) > 0    

insert into #new_lost_cont
select		client_name,
            sum(rev) as revenue,
            'Client' as type,
            business_unit_desc,
            'Continuing' as client_status,
            branch_name
from		v_statrev_agency
where		revenue_period between @start_date and @end_date
and			country_code = @country_code
and         client_id in (		select	    client_id
								from		v_statrev_agency
								where		revenue_period between @prev_start_date and @prev_end_date
								and			country_code = @country_code
								group by 	client_id
								having		sum(rev) > 0)
group by 	business_unit_desc,
            client_name,
            branch_name
having		sum(rev) > 0    
    

insert into #new_lost_cont
select		client_name,
            sum(rev) as revenue,
            'Client' as type,
            business_unit_desc,
            'Lost' as client_status,
            branch_name
from		v_statrev_agency
where		revenue_period between @prev_start_date and @prev_end_date
and			country_code = @country_code
and         client_id not in (	select	    client_id
								from		v_statrev_agency
								where		revenue_period between @start_date and @end_date
								and			country_code = @country_code
								group by 	client_id
								having		sum(rev) > 0)
group by 	business_unit_desc, 
            client_name,
            branch_name
having		sum(rev) > 0            

            
select		client_name,
			revenue,
			type_of_client,
			business_unit_desc,
			client_status,
			branch_name
from		#new_lost_cont
order by	client_status, 
			client_name

return 0
GO
