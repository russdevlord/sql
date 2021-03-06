/****** Object:  StoredProcedure [dbo].[p_kpi_branch_tracker]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_kpi_branch_tracker]
GO
/****** Object:  StoredProcedure [dbo].[p_kpi_branch_tracker]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE proc	[dbo].[p_kpi_branch_tracker]		@country_code				char(1),
												@start_period					datetime,
												@end_period					datetime,
												@delta_date					datetime
																
as

declare			@prev_start_period			datetime,
				@prev_end_period				datetime,
				@start_period_no				int,
				@end_period_no				int


set nocount on
						
create table #branch_data (
			sort_order					int IDENTITY(1, 1)		not null,
			branch_code					varchar(2)						null,
			branch_name					varchar(100)					null,
			mth 						money							null,
			mth_prev					money							null,
			fy_ytd 						money							null,
			fy_prev_ytd					money							null,
			fy_prev_final				money							null
)

/*
 * Initialse Variables
 */
 
select 	@start_period_no = period_no
from	accounting_period 
where	end_date = @start_period 

select 	@end_period_no = period_no
from	accounting_period 
where	end_date = @end_period 

select 	@prev_start_period = max(end_date)
from	accounting_period
where	period_no = @start_period_no
and		end_date < @start_period

select 	@prev_end_period = max(end_date)
from	accounting_period
where	period_no = @end_period_no
and		end_date < @end_period

insert into 	#branch_data (
			--sort_order, SQL SERVER 2008
			v_statrev.branch_code,
			v_statrev.branch_name,
			mth
					)
select 		--ROW_NUMBER() over (order by 	isnull(sum(cost),0) desc), SQL SERVER 2008
					v_statrev.branch_code,
					v_statrev.branch_name,
					isnull(sum(cost),0)
from   		v_statrev,
					branch
where     	v_statrev.branch_code = branch.branch_code
and				v_statrev.revenue_period between @start_period and @end_period
and				v_statrev.delta_date <= @delta_date
and 			v_statrev.country_code = @country_code
group by 	v_statrev.branch_code, 
					v_statrev.branch_name,
					branch.sort_order
order by 	branch.sort_order					

update 		#branch_data 
set 		mth_prev = revenue
from   		(select 		v_statrev.branch_code,
										isnull(sum(cost),0) as revenue
					from   		v_statrev
					where     	v_statrev.revenue_period between @prev_end_period and @prev_end_period
					and				v_statrev.delta_date <= @delta_date
					group by 	v_statrev.branch_code
					) as revenue_data
where		revenue_data.branch_code  = #branch_data.branch_code
	
update 		#branch_data 
set 				fy_ytd = revenue
from   		(select 		branch_code,
										isnull(sum(cost),0) as revenue
					from   		v_statrev
					where     	v_statrev.revenue_period between @start_period and @end_period
					and				v_statrev.delta_date <= @delta_date
					group by 	branch_code
					) as revenue_data
where		revenue_data.branch_code  = #branch_data.branch_code
	
update 		#branch_data 
set 				fy_prev_ytd = revenue
from   		(select 		branch_code,
										isnull(sum(cost),0) as revenue
					from   		v_statrev
					where     	v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= dateadd(yy, -1, @delta_date)
					group by 	branch_code
					) as revenue_data
where		revenue_data.branch_code  = #branch_data.branch_code
	
update 		#branch_data 
set 				fy_prev_final = revenue
from   		(select 		branch_code,
										isnull(sum(cost),0) as revenue
					from   		v_statrev
					where     	v_statrev.revenue_period between @prev_start_period and @prev_end_period
					and				v_statrev.delta_date <= @delta_date
					group by 	branch_code
					) as revenue_data
where		revenue_data.branch_code  = #branch_data.branch_code
	
select	sort_order,
		branch_code,
		branch_name,
		mth,
		mth_prev,
		fy_ytd,
		fy_prev_ytd,
		fy_prev_final,
		@country_code as country_code,
		@start_period as start_period, 
		@end_period	as end_period, 
		@delta_date as delta_date
from #branch_data 
order by sort_order

return 0
GO
