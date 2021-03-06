/****** Object:  StoredProcedure [dbo].[p_statrev_rep_team_access_list_incl_retail]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_rep_team_access_list_incl_retail]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_rep_team_access_list_incl_retail]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_statrev_rep_team_access_list_incl_retail]	@login_id			varchar(50),
																					@start_date		datetime,
																					@end_date		datetime

as

declare			@error				int

set nocount on

create table #access_list
(
DataName 		varchar(120)			null, 
DataCode			varchar(30)			null,
DataID				integer					null, 
sort_order			integer					null,
control_type		varchar(7)				null,
min_period		datetime				null,
max_period		datetime				null,
status					char(1)					null
)

insert into	#access_list
select 		branch.branch_name as DataName, 
					convert(varchar(1), branch_access.branch_code) as DataCode,
					0 as DataID, 
					branch.sort_order as sort_order,
					'BRANCH' as control_type,
					@start_date as min_period,
					@end_date as max_period,
					'A' as status
from 			branch_access,   
					security_access,   
					security_access_group,
					branch
where 		branch_access.user_id = security_access.user_id
and				branch.branch_code = branch_access.branch_code
and				security_access.user_id = @login_id
and				security_access_group.security_access_group_id = security_access.security_access_group_id
and				security_access_group.security_access_group_desc in ( 	'Head of Sales Dept',
																															'Head of Sales Dept - Retail',
																															'Super User',
																															'Senior Admin User',
																															'Marketing Director',
																															'CEO',
																															'Admin Staff',
																															'Finance Staff')
group by 	branch.branch_name, 
					convert(varchar(1), branch_access.branch_code), 
					branch.sort_order

--Insert Countries - if number branches that user has access to equals the number of branches for the COUNTRY give them COUNTRY access.
insert into	#access_list
select			COUNTRY.country_name,
					COUNTRY.country_code,
					0,
					case COUNTRY.country_code When 'A' Then 1 Else 2 End,
					'COUNTRY' as control_type,
					@start_date as min_period,
					@end_date as max_period,
					'A' as status
from			COUNTRY,
					branch,
					(select 		country_code as country_code, 
										count( distinct branch_access.branch_code) as state_count,
										branch_access.user_id as user_login
					from 			branch_access,   
										security_access,   
										security_access_group,
										branch
					where 		branch_access.user_id = security_access.user_id
					and				branch.branch_code = branch_access.branch_code
					and				security_access.user_id = @login_id
					and				security_access_group.security_access_group_id = security_access.security_access_group_id
					and				security_access_group.security_access_group_desc in ( 	'Head of Sales Dept',
																																				'Head of Sales Dept - Retail',
																																				'Super User',
																																				'Senior Admin User',
																																				'Marketing Director',
																																				'CEO',
																																				'Admin Staff',
																																				'Finance Staff')
					group by 	country_code,
										branch_access.user_id ) as #TEMP
where		COUNTRY.country_code = #TEMP.country_code
and				COUNTRY.country_code = branch.country_code
group by	COUNTRY.country_name,
					COUNTRY.country_code,
					#TEMP.state_count
having		count(branch.branch_code ) = #TEMP.state_count

--insert teams - for users who have access to branches - and only for those branches
insert into	#access_list
select 		distinct sales_team.team_name, 
					'TEAM' + convert(varchar(10), sales_team.team_id), 
					sales_team.team_id,
					8888,
					'TEAM_ID',
					start_date,
					end_date,
					team_status													
	from 		sales_team,
					branch_access,
					security_access,   
					security_access_group
	where	sales_team.team_branch = branch_access.branch_code
	and			branch_access.user_id = security_access.user_id
	and			security_access_group.security_access_group_id = security_access.security_access_group_id
	and			security_access.user_id = @login_id
	and			(start_date <= @end_date or start_date is null)
	and			(end_date >= @start_date or end_date is null)
	and			security_access_group.security_access_group_desc in ( 	'Head of Sales Dept',
																															'Super User',
																															'Senior Admin User',
																															'Marketing Director',
																															'CEO',
																															'Admin Staff',
																															'Finance Staff',
																															'Sales Directors of Various Markets')
																															
																															
--insert teams - for users who have access to branches - and only for those branches - retail
insert into	#access_list
select 		distinct sales_team.team_name, 
					'TEAM' + convert(varchar(10), sales_team.team_id), 
					sales_team.team_id,
					8888,
					'TEAM_ID',
					start_date,
					end_date,
					team_status													
	from 		sales_team,
					branch_access,
					security_access,   
					security_access_group
	where	sales_team.team_branch = branch_access.branch_code
	and			sales_team.business_unit_id = 6
	and			branch_access.user_id = security_access.user_id
	and			security_access_group.security_access_group_id = security_access.security_access_group_id
	and			security_access.user_id = @login_id
	and			(start_date <= @end_date or start_date is null)
	and			(end_date >= @start_date or end_date is null)
	and			security_access_group.security_access_group_desc in ('Head of Sales Dept - Retail')
																															

-- * Select Reps based on branch access
insert into	#access_list
select 		distinct sales_rep.first_name + ' ' + sales_rep.last_name,
					'REPR' + convert(varchar(10), sales_rep.rep_id),
					rep_id,
					9999,
					'REP_ID',
					start_date,
					end_date,
					status
from 			branch_access, 
					sales_rep, 
					security_access,   
					security_access_group 
where 		branch_access.user_id = security_access.user_id
and				security_access_group.security_access_group_id = security_access.security_access_group_id
and				branch_access.branch_code = sales_rep.branch_code
and				security_access.user_id = @login_id
and				(start_date <= @end_date or start_date is null)
and				(end_date >= @start_date or end_date is null)
and				security_access_group.security_access_group_desc in ( 	'Head of Sales Dept',
																															'Super User',
																															'Senior Admin User',
																															'Marketing Director',
																															'CEO',
																															'Admin Staff',
																															'Finance Staff')


-- * Select Reps based on branch access
insert into	#access_list
select 		distinct sales_rep.first_name + ' ' + sales_rep.last_name,
					'REPR' + convert(varchar(10), sales_rep.rep_id),
					rep_id,
					9999,
					'REP_ID',
					start_date,
					end_date,
					status
from 			branch_access, 
					sales_rep, 
					security_access,   
					security_access_group 
where 		branch_access.user_id = security_access.user_id
and				sales_rep.business_unit_id = 6
and				security_access_group.security_access_group_id = security_access.security_access_group_id
and				branch_access.branch_code = sales_rep.branch_code
and				security_access.user_id = @login_id
and			(start_date <= @end_date or start_date is null)
and				(end_date >= @start_date or end_date is null)
and				security_access_group.security_access_group_desc in ( 	'Head of Sales Dept - Retail')
																															
-- * Insert teams for team leaders
insert into	#access_list
select 		distinct sales_team.team_name, 
					'TEAM' + convert(varchar(10), sales_team.team_id), 
					sales_team.team_id,
					8888,
					'TEAM_ID',
					start_date,
					end_date,
					team_status					
from 			employee,
					sales_team
where 		employee.rep_id > 1
and				sales_team.leader_id = employee.rep_id
and				employee.login_id = @login_id
and			(start_date <= @end_date or start_date is null)
and				(end_date >= @start_date or end_date is null)

-- * Insert teams for team members with access to the teams figures
insert into	#access_list
select 		distinct sales_team.team_name, 
					'TEAM' + convert(varchar(10), sales_team.team_id), 
					sales_team.team_id,
					8888,
					'TEAM_ID',
					start_date,
					end_date,
					team_status
from 			employee,
					sales_team,
					sales_team_members
where 		employee.rep_id > 1
and				sales_team.team_id = sales_team_members.team_id
and				sales_team_members.view_team_figures = 'Y'
and				sales_team_members.rep_id = employee.rep_id
and				employee.login_id = @login_id
and			(start_date <= @end_date or start_date is null)
and				(end_date >= @start_date or end_date is null)


-- * Insert reps for team leaders
insert into	#access_list
select 		distinct sales_rep.first_name + ' ' + sales_rep.last_name, 
					'REPR' + convert(varchar(10), sales_rep.rep_id),
					sales_team_members.rep_id,
					9999,
					'REP_ID',
					sales_rep.start_date,
					sales_rep.end_date,
					status
from 			employee,
					sales_team,
					sales_team_members,
					sales_rep
where 		employee.rep_id > 1
and				sales_team.leader_id = employee.rep_id
and				sales_team.team_id = sales_team_members.team_id
and 			sales_team_members.rep_id = sales_rep.rep_id
and				employee.login_id = @login_id
and			(sales_rep.start_date <= @end_date or sales_rep.start_date is null)
and				(sales_rep.end_date >= @start_date or sales_rep.end_date is null)

-- * Insert reps for team members with access to the teams figures
insert into	#access_list
select 		distinct  sales_rep.first_name + ' ' + sales_rep.last_name, 
					'REPR' + convert(varchar(10), sales_rep.rep_id),
					sales_team_members.rep_id,
					9999,
					'REP_ID',
					sales_rep.start_date,
					sales_rep.end_date,
					status
from			employee,
					sales_team,
					sales_team_members,
					sales_rep,
					(select team_id, employee.employee_id from sales_team_members, employee where view_team_figures = 'Y' and sales_team_members.rep_id = employee.rep_id) as temp_table
where 		sales_team.team_id = sales_team_members.team_id
and				sales_team_members.rep_id = sales_rep.rep_id
and				employee.employee_id = temp_table.employee_id
and				sales_team.team_id = temp_table.team_id
and				employee.login_id = @login_id
and			(sales_rep.start_date <= @end_date or sales_rep.start_date is null)
and				(sales_rep.end_date >= @start_date or sales_rep.end_date is null)

-- * Insert reps for sales coordinators
insert into	#access_list
select 		distinct  sales_rep.first_name + ' ' + sales_rep.last_name, 
					'REPR' + convert(varchar(10), sales_rep.rep_id),
					sales_team_members.rep_id,
					9999,
					'REP_ID',
					sales_rep.start_date,
					sales_rep.end_date,
					status
from			employee,
					sales_team_coordinators,
					sales_team_members,
					sales_rep
where 		sales_team_coordinators.team_id = sales_team_members.team_id
and				sales_team_members.rep_id = sales_rep.rep_id
and				employee.employee_id = sales_team_coordinators.employee_id
and				employee.login_id = @login_id
and			(start_date <= @end_date or start_date is null)
and				(sales_rep.end_date >= @start_date or sales_rep.end_date is null)

-- * Insert teams for sales coordinators
insert into	#access_list
select 		distinct sales_team.team_name, 
					'TEAM' + convert(varchar(10), sales_team.team_id), 
					sales_team.team_id,
					8888,
					'TEAM_ID',
					start_date,
					end_date,
					team_status
from			employee,
					sales_team_coordinators,
					sales_team
where 		sales_team_coordinators.team_id = sales_team.team_id
and				employee.employee_id = sales_team_coordinators.employee_id
and				employee.login_id = @login_id
and			(start_date <= @end_date or start_date is null)
and				(end_date >= @start_date or end_date is null)


--  * Insert Reps own record
insert into	#access_list
select 		distinct  sales_rep.first_name + ' ' + sales_rep.last_name, 
					'REPR' + convert(varchar(10), sales_rep.rep_id),
					employee.rep_id,
					9999,
					'REP_ID',
					start_date,
					end_date,
					sales_rep.status
from 			employee  ,
					sales_rep
where 		sales_rep.rep_id = employee.rep_id
and				employee.login_id = @login_id
and			(start_date <= @end_date or start_date is null)
and				(sales_rep.end_date >= @start_date or sales_rep.end_date is null)

insert into	#access_list
select 		'All Campaigns', 
					'ALLC' ,
					0,
					0,
					'ALLC',
					null,
					null,
					'A'
from 			employee 
where 		employee.login_id = @login_id
and				employee.login_id in ('pbutler','mrussell','abrowne', 'rching','ablanch','jfowler', 'mchin', 'apavlovic', 'sakiki', 'cwilson')

set nocount off

select 		DataName, 
					DataCode,
					DataID, 
					sort_order,
					control_type,
					min(min_period) as min_period,
					max(max_period) as max_period,
					status		
from 			#access_list
group by 	DataName, 
					DataCode,
					DataID, 
					sort_order,
					control_type,
					status		
order by 	sort_order,
					dataname
					
return 0
GO
