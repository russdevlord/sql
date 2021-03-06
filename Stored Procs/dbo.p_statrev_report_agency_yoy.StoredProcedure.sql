/****** Object:  StoredProcedure [dbo].[p_statrev_report_agency_yoy]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_report_agency_yoy]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_report_agency_yoy]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_statrev_report_agency_yoy]			@report_date							datetime,
																					@delta_date								datetime,
																					@period_start							datetime,
																					@period_end								datetime,
																					@mode										integer, -- 3 - Budget, 4 - Forecast
																					@branch_code							varchar(1),
																					@country_code							varchar(1),
																					@business_unit_id					int,
																					@revenue_group						int,
																					@master_revenue_group			int,
																					@report_type							varchar(1), -- 'C' - cinema, 'O' - outpost/retail, '' - All
																					@company									varchar(1), --'V' = Val Morgan, 'A' = all, 'C' = CineAds
																					@buying_group_id					int --0 for all groups actual number 
with recompile

as

set nocount on

declare		@ultimate_start_date			datetime,
					@prev_report_date				datetime,
					@prev_final_date					datetime,
					@ultimate_start					datetime,
					@startexec							datetime,
					@prev_period_start				datetime,
					@prev_period_end				datetime

SELECT		@startexec							= GetDate(),
					@ultimate_start					= @startexec,
					@ultimate_start_date			= '1-JAN-1900',
					@prev_report_date				= DATEADD(DAY, -365, @report_date),
					@prev_final_date					= CONVERT(DATETIME, CONVERT(VARCHAR(4), DATEPART(YEAR, @report_date) - 1) + '-12-31 23:59:59.000')
					
select			@prev_period_start				= max(end_date) from accounting_period where period_no = (select period_no from accounting_period where end_date = @period_start) and end_date < @period_start
select			@prev_period_end				= max(end_date) from accounting_period where period_no = (select period_no from accounting_period where end_date = @period_end) and end_date < @period_end
		

create	table #report
(
	row_type_desc				varchar(200)				null,
	row_type_subrow			varchar(200)				null,
	row_type_sort				int								null,
	buying_group_desc		varchar(100)				null,
	agency_group_desc		varchar(100)				null,
	agency_desc					varchar(100)				null,
	revenue							money							null
)

insert	into	#report
(
	row_type_desc,
	row_type_subrow,
	row_type_sort,
	buying_group_desc,
	agency_group_desc,
	agency_desc,
	revenue
)
select			'Current Revenue',
					'as at ' + convert(varchar(25), @report_date, 106) + ' '+ convert(varchar(25), @report_date, 108),
					10,
					buying_group_desc,
					agency_group_name,
					agency_name,
					sum(cost)
from			v_statrev_report,
					agency,
					agency_groups,
					agency_buying_groups
where			delta_date <= @report_date 
and				revenue_period between @period_start and @period_end
and				cost <> 0  
and				type2 = 'N'
and				v_statrev_report.agency_id = agency.agency_id
and				agency.agency_group_id = agency_groups.agency_group_id
and				agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and				(agency_buying_groups.buying_group_id = @buying_group_id or @buying_group_id = 0)
and				( type1 = @report_type OR @report_type = '' )
and				( branch_code = @branch_code or @branch_code = '')
and				( country_code =  @country_code or @country_code = '')
and				( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and				( revenue_group = @revenue_group or @revenue_group = 0)
and				( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and				(@company = 'A'
or					(@company = 'V' and business_unit_id in (2,3,5))
or					(@company = 'C' and business_unit_id in (9))
or					(@company = 'O' and business_unit_id in (6,7,8)))
group by		buying_group_desc,
					agency_group_name,
					agency_name
					
insert	into	#report
(
	row_type_desc,
	row_type_subrow,
	row_type_sort,
	buying_group_desc,
	agency_group_desc,
	agency_desc,
	revenue
)
select			'Prior Year Revenue',
					'as at ' + convert(varchar(25), @prev_report_date, 106) + ' '+ convert(varchar(25), @prev_report_date, 108),
					20,
					buying_group_desc,
					agency_group_name,
					agency_name,
					sum(cost)
from			v_statrev_report,
					agency,
					agency_groups,
					agency_buying_groups
where			delta_date <= @prev_report_date 
and				revenue_period between @prev_period_start and @prev_period_end
and				cost <> 0  
and				type2 = 'N'
and				v_statrev_report.agency_id = agency.agency_id
and				agency.agency_group_id = agency_groups.agency_group_id
and				agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and				(agency_buying_groups.buying_group_id = @buying_group_id or @buying_group_id = 0)
and				( type1 = @report_type OR @report_type = '' )
and				( branch_code = @branch_code or @branch_code = '')
and				( country_code =  @country_code or @country_code = '')
and				( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and				( revenue_group = @revenue_group or @revenue_group = 0)
and				( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and				(@company = 'A'
or					(@company = 'V' and business_unit_id in (2,3,5))
or					(@company = 'C' and business_unit_id in (9))
or					(@company = 'O' and business_unit_id in (6,7,8)))
group by		buying_group_desc,
					agency_group_name,
					agency_name

insert	into	#report
(
	row_type_desc,
	row_type_subrow,
	row_type_sort,
	buying_group_desc,
	agency_group_desc,
	agency_desc,
	revenue
)
select			'Prior Year Revenue',
					'Final',
					40,
					buying_group_desc,
					agency_group_name,
					agency_name,
					sum(cost)
from			v_statrev_report,
					agency,
					agency_groups,
					agency_buying_groups
where			delta_date <= @prev_final_date 
and				revenue_period between @prev_period_start and @prev_period_end
and				cost <> 0  
and				type2 = 'N'
and				v_statrev_report.agency_id = agency.agency_id
and				agency.agency_group_id = agency_groups.agency_group_id
and				agency_groups.buying_group_id = agency_buying_groups.buying_group_id
and				(agency_buying_groups.buying_group_id = @buying_group_id or @buying_group_id = 0)
and				( type1 = @report_type OR @report_type = '' )
and				( branch_code = @branch_code or @branch_code = '')
and				( country_code =  @country_code or @country_code = '')
and				( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and				( revenue_group = @revenue_group or @revenue_group = 0)
and				( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
and				(@company = 'A'
or					(@company = 'V' and business_unit_id in (2,3,5))
or					(@company = 'C' and business_unit_id in (9))
or					(@company = 'O' and business_unit_id in (6,7,8)))
group by		buying_group_desc,
					agency_group_name,
					agency_name
					
insert into 	#report
(
	row_type_desc,
	row_type_subrow,
	row_type_sort,
	buying_group_desc,
	agency_group_desc,
	agency_desc,
	revenue
)
select			'Variance %',
					'(Pace)',
					31,
					#report.buying_group_desc,
					#report.agency_group_desc,
					#report.agency_desc,
					case when sum(isnull(prior_revenue.revenue, 0)) = 0 then 1 else (sum(isnull(current_revenue.revenue, 0)) - sum(isnull(prior_revenue.revenue, 0))) / sum(isnull(prior_revenue.revenue, 0)) end
from			#report
left outer join	(select			buying_group_desc,
													agency_group_desc,
													agency_desc,
													sum(revenue) as revenue
								from			#report
								where			row_type_sort	= 10
								group by		buying_group_desc,
													agency_group_desc,
													agency_desc) as current_revenue
on				#report.buying_group_desc = current_revenue.buying_group_desc
and				#report.agency_group_desc = current_revenue.agency_group_desc
and				#report.agency_desc = current_revenue.agency_desc
left outer join	(select			buying_group_desc,
													agency_group_desc,
													agency_desc,
													sum(revenue) as revenue
								from			#report
								where			row_type_sort	= 20
								group by		buying_group_desc,
													agency_group_desc,
													agency_desc) as prior_revenue
on				#report.buying_group_desc = prior_revenue.buying_group_desc
and				#report.agency_group_desc = prior_revenue.agency_group_desc
and				#report.agency_desc = prior_revenue.agency_desc
where			(#report.row_type_sort = 10 
or					#report.row_type_sort = 20)	
group by		#report.buying_group_desc,
					#report.agency_group_desc,
					#report.agency_desc

insert into 	#report
(
	row_type_desc,
	row_type_subrow,
	row_type_sort,
	buying_group_desc,
	agency_group_desc,
	agency_desc,
	revenue
)
select			'Variance %',
					'(Pace)',
					41,
					#report.buying_group_desc,
					#report.agency_group_desc,
					#report.agency_desc,
					case when sum(isnull(prior_revenue.revenue, 0)) = 0 then 1 else (sum(isnull(current_revenue.revenue, 0)) - sum(isnull(prior_revenue.revenue, 0))) / sum(isnull(prior_revenue.revenue, 0)) end
from			#report
left outer join	(select			buying_group_desc,
													agency_group_desc,
													agency_desc,
													sum(revenue) as revenue
								from			#report
								where			row_type_sort	= 10
								group by		buying_group_desc,
													agency_group_desc,
													agency_desc) as current_revenue
on				#report.buying_group_desc = current_revenue.buying_group_desc
and				#report.agency_group_desc = current_revenue.agency_group_desc
and				#report.agency_desc = current_revenue.agency_desc
left outer join	(select			buying_group_desc,
													agency_group_desc,
													agency_desc,
													sum(revenue) as revenue
								from			#report
								where			row_type_sort	= 40
								group by		buying_group_desc,
													agency_group_desc,
													agency_desc) as prior_revenue
on				#report.buying_group_desc = prior_revenue.buying_group_desc
and				#report.agency_group_desc = prior_revenue.agency_group_desc
and				#report.agency_desc = prior_revenue.agency_desc
where			(#report.row_type_sort = 10 
or					#report.row_type_sort = 40)	
group by		#report.buying_group_desc,
					#report.agency_group_desc,
					#report.agency_desc

select			row_type_desc,
					row_type_subrow,
					row_type_sort,
					buying_group_desc,
					agency_group_desc,
					agency_desc,
					revenue,
					@report_date as report_date, 
					@ultimate_start_date as ultimate_start_date,
					@revenue_group as revenue_group,	
					@master_revenue_group as master_revenue_group,
					@business_unit_id as business_unit_id, 
					@country_code as country_code, 
					@branch_code as branch_code,
					@period_start as period_start,
					@period_end as period_end
from			#report				

return 0
GO
