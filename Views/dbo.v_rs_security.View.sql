/****** Object:  View [dbo].[v_rs_security]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_rs_security]
GO
/****** Object:  View [dbo].[v_rs_security]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE view [dbo].[v_rs_security]

as

-- Insert Branches for appropriate users
select 		branch.branch_name as DataName, 
					convert(varchar(1), branch_access.branch_code) as DataCode,
					0 as DataID, 
					branch.sort_order as sort_order,
					'BRANCH' as control_type,
					branch_access.user_id as user_login,
					'1-jan-1900' as min_period,
					'31-dec-3000' as max_period,
					'A' as status
from 			branch_access,   
					security_access,   
					security_access_group,
					branch
where 		branch_access.user_id = security_access.user_id
and				branch.branch_code = branch_access.branch_code
and				security_access_group.security_access_group_id = security_access.security_access_group_id
and				security_access_group.security_access_group_desc in ( 	'Head of Sales Dept',
																															'IT Staff',
																															'Senior Admin Staff',
																															'Marketing Director',
																															'CEO',
																															'Admin Staff',
																															'Finance Staff',
																															'Sales Directors of Various Markets')
group by 	branch.branch_name, 
					convert(varchar(1), branch_access.branch_code), 
					branch.sort_order,
					branch_access.user_id

--Insert Countries - if number branches that user has access to equals the number of branches for the COUNTRY give them COUNTRY access.
union all

select			COUNTRY.country_name,
					COUNTRY.country_code,
					0,
					case COUNTRY.country_code When 'A' Then 1 Else 2 End,
					'COUNTRY' as control_type,
					#TEMP.user_login as user_login,
					'1-jan-1900' as min_period,
					'31-dec-3000' as max_period,
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
					and				security_access_group.security_access_group_id = security_access.security_access_group_id
					and				security_access_group.security_access_group_desc in ( 	'Head of Sales Dept',
																																				'IT Staff',
																																				'Senior Admin Staff',
																																				'Marketing Director',
																																				'CEO',
																																				'Admin Staff',
																																				'Finance Staff',
																																				'Sales Directors of Various Markets')
					group by 	country_code,
										branch_access.user_id ) as #TEMP
where		COUNTRY.country_code = #TEMP.country_code
and				COUNTRY.country_code = branch.country_code
group by	COUNTRY.country_name,
					COUNTRY.country_code,
					#TEMP.user_login,
					#TEMP.state_count
having		count(branch.branch_code ) = #TEMP.state_count

--insert teams - for users who have access to branches - and only for those branches
union
select 		distinct sales_team.team_name, 
					'TEAM' + convert(varchar(10), sales_team.team_id), 
					sales_team.team_id,
					8888,
					'TEAM_ID',
					branch_access.user_id,
					(select min(revenue_period) from v_statrev_team where team_id = sales_team.team_id) as first_period,
					(select max(revenue_period) from v_statrev_team where team_id = sales_team.team_id) as last_period,
					team_status													
	from 		sales_team,
					branch_access,
					security_access,   
					security_access_group
	where	sales_team.team_branch = branch_access.branch_code
	and			branch_access.user_id = security_access.user_id
	and			security_access_group.security_access_group_id = security_access.security_access_group_id
	and			security_access_group.security_access_group_desc in ( 	'Head of Sales Dept',
																															'IT Staff',
																															'Senior Admin Staff',
																															'Marketing Director',
																															'CEO',
																															'Admin Staff',
																															'Finance Staff',
																															'Sales Directors of Various Markets')
union

-- * Select Reps based on branch access
select 		distinct sales_rep.first_name + ' ' + sales_rep.last_name,
					'REPR' + convert(varchar(10), sales_rep.rep_id),
					rep_id,
					9999,
					'REP_ID',
					security_access.user_id,
					(select min(revenue_period) from v_statrev_rep where rep_id = sales_rep.rep_id) as first_period,
					(select max(revenue_period) from v_statrev_rep where rep_id = sales_rep.rep_id) as last_period,
					status
from 			branch_access, 
					sales_rep, 
					security_access,   
					security_access_group 
where 		branch_access.user_id = security_access.user_id
and				security_access_group.security_access_group_id = security_access.security_access_group_id
and				branch_access.branch_code = sales_rep.branch_code
and				security_access_group.security_access_group_desc in ( 	'Head of Sales Dept',
																															'IT Staff',
																															'Senior Admin Staff',
																															'Marketing Director',
																															'CEO',
																															'Admin Staff',
																															'Finance Staff',
																															'Sales Directors of Various Markets')
union

-- * Insert teams for team leaders
select 		distinct sales_team.team_name, 
					'TEAM' + convert(varchar(10), sales_team.team_id), 
					sales_team.team_id,
					8888,
					'TEAM_ID',
					employee.login_id,
					(select min(revenue_period) from v_statrev_team where team_id = sales_team.team_id) as first_period,
					(select max(revenue_period) from v_statrev_team where team_id = sales_team.team_id) as last_period,
					team_status					
from 			employee,
					sales_team
where 		employee.rep_id > 1
and				sales_team.leader_id = employee.rep_id

-- * Insert teams for team members with access to the teams figures
union
select 		distinct sales_team.team_name, 
					'TEAM' + convert(varchar(10), sales_team.team_id), 
					sales_team.team_id,
					8888,
					'TEAM_ID',
					employee.login_id,
					(select min(revenue_period) from v_statrev_team where team_id = sales_team.team_id) as first_period,
					(select max(revenue_period) from v_statrev_team where team_id = sales_team.team_id) as last_period,
					team_status
from 			employee,
					sales_team,
					sales_team_members
where 		employee.rep_id > 1
and				sales_team.team_id = sales_team_members.team_id
and				sales_team_members.view_team_figures = 'Y'
and				sales_team_members.rep_id = employee.rep_id


-- * Insert reps for team leaders
union
select 		distinct sales_rep.first_name + ' ' + sales_rep.last_name, 
					'REPR' + convert(varchar(10), sales_rep.rep_id),
					sales_team_members.rep_id,
					9999,
					'REP_ID',
					employee.login_id,
					(select min(revenue_period) from v_statrev_rep where rep_id = sales_rep.rep_id) as first_period,
					(select max(revenue_period) from v_statrev_rep where rep_id = sales_rep.rep_id) as last_period,
					status
from 			employee,
					sales_team,
					sales_team_members,
					sales_rep
where 		employee.rep_id > 1
and				sales_team.leader_id = employee.rep_id
and				sales_team.team_id = sales_team_members.team_id
and 			sales_team_members.rep_id = sales_rep.rep_id

-- * Insert reps for team members with access to the teams figures
union
select 		distinct  sales_rep.first_name + ' ' + sales_rep.last_name, 
					'REPR' + convert(varchar(10), sales_rep.rep_id),
					sales_team_members.rep_id,
					9999,
					'REP_ID',
					employee.login_id,
					(select min(revenue_period) from v_statrev_rep where rep_id = sales_rep.rep_id) as first_period,
					(select max(revenue_period) from v_statrev_rep where rep_id = sales_rep.rep_id) as last_period,
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


--  * Insert Reps own record
union
select 		distinct  sales_rep.first_name + ' ' + sales_rep.last_name, 
					'REPR' + convert(varchar(10), sales_rep.rep_id),
					employee.rep_id,
					9999,
					'REP_ID',
					employee.login_id,
					'1-jan-1900',
					'31-dec-3000',
					'A'
from 			employee  ,
					sales_rep
where 		sales_rep.rep_id = employee.rep_id
GO
