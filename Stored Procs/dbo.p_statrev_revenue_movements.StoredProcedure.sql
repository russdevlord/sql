/****** Object:  StoredProcedure [dbo].[p_statrev_revenue_movements]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_revenue_movements]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_revenue_movements]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create proc [dbo].[p_statrev_revenue_movements]			@start_date			datetime,
														@end_date			datetime,
														@business_units		varchar(max),
														@branches			varchar(max),
														@countries			varchar(max)

as

declare			@error			int

create table #business_units
(	
	business_unit_id			int
)

create table #branches
(	
	branch_code					char(1)
)

create table #countries
(	
	country_code				char(1)
)

if len(@business_units) > 0                
	insert into #business_units                
	select * from dbo.f_multivalue_parameter(@business_units,',')     

if len(@branches) > 0                
	insert into #branches                
	select * from dbo.f_multivalue_parameter(@branches,',')     

if len(@countries) > 0                
	insert into #countries                
	select * from dbo.f_multivalue_parameter(@countries,',')     

select			campaign_no,
				product_desc,
				case when v_srr.campaign_status = 'P' then 'Removed Revenue' when revision_type = 1 then 'Confirmed Campaign' else 'All Other Movements' end as movement_type ,
				v_srr.business_unit_id,
				business_unit_desc,
				sum(cost) as revenue,
				revenue_period, 
				statrev_transaction_type,
				statrev_transaction_type_desc,
				revenue_group,
				revenue_group_desc,
				master_revenue_group,
				master_revenue_group_desc,
				v_srr.branch_code, 
				branch_name,
				v_srr.country_code,
				country_name,
				branch_sort_order,
				revision_type,
				revision_type_desc,
				revision_category_desc,
				v_srr.reporting_agency,
				v_srr.client_id,
				v_srr.rep_id,
				v_srr.agency_id,
				v_srr.reporting_agency_name,
				v_srr.client_name,
				v_srr.rep_name,
				v_srr.agency_name
from			v_statrev_report_cinema v_srr
inner join		#business_units on v_srr.business_unit_id = #business_units.business_unit_id
inner join		#branches on v_srr.branch_code = #branches.branch_code
inner join		#countries on v_srr.country_code = #countries.country_code
where			delta_date between @start_date and @end_date
group by		case when v_srr.campaign_status = 'P' then 'Removed Revenue' when revision_type = 1 then 'Confirmed Campaign' else 'All Other Movements' end ,
				campaign_no,
				product_desc,
				v_srr.business_unit_id,
				business_unit_desc,
				revenue_period, 
				statrev_transaction_type,
				statrev_transaction_type_desc,
				revenue_group,
				revenue_group_desc,
				master_revenue_group,
				master_revenue_group_desc,
				v_srr.branch_code, 
				branch_name,
				v_srr.country_code,
				country_name,
				branch_sort_order,
				revision_type,
				revision_type_desc,
				revision_category_desc,
				v_srr.reporting_agency,
				v_srr.client_id,
				v_srr.rep_id,
				v_srr.agency_id,
				v_srr.reporting_agency_name,
				v_srr.client_name,
				v_srr.rep_name,
				v_srr.agency_name
having			sum(cost) <> 0


return 0
GO
