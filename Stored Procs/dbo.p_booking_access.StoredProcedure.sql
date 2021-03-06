/****** Object:  StoredProcedure [dbo].[p_booking_access]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_booking_access]
GO
/****** Object:  StoredProcedure [dbo].[p_booking_access]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROC [dbo].[p_booking_access] 	@s_login 		varchar(30),
								@start_date		datetime,
								@end_date		datetime

with recompile
as


begin

/*
 * Declare Variables
 */

set nocount on

declare 	@error_num              int,
		    @buss_unit              int,
			@no_branches			int


SELECT @buss_unit = 0

CREATE table #tempaccess
(
	name 			varchar(64) 	null,
	rep_id 			integer 		null,
	team_id 		integer 		null,
	branch_code		char(1) 		null,
	sort_order 		int 			null,
	country_code	char(1)			null,
	status			char(1)			null
)

/*
 * Insert Branches for appropriate users
 */

INSERT #tempaccess 
( 
	name, 
	rep_id, 
	team_id, 
	branch_code, 
	sort_order,
	country_code,
	status
) 
SELECT 	branch.branch_name, 
		0,
		0, 
		convert(varchar(1), branch_access.branch_code), 
		branch.sort_order,
		'',
		'A'
FROM 	branch_access,   
		security_access,   
		security_access_group  ,
		branch
WHERE 	branch_access.user_id = security_access.user_id
and		branch.branch_code = branch_access.branch_code
and		security_access_group.security_access_group_id = security_access.security_access_group_id
and		branch_access.user_id = @s_login 
and		security_access_group.security_access_group_desc in ( 	'Head of Sales Dept',
																'Super User',
																'Senior Admin User',
																'Marketing Director',
																'CEO',
																'Admin Staff',
																'Finance Staff',
																'Sales Directors of Various Markets')
group by branch.branch_name, 
		convert(varchar(1), branch_access.branch_code), 
		branch.sort_order

/*
 * Insert Countries - if number branches that user has access to equals the number of branches for the country give them country access.
 */

select @no_branches =  	count(*) 
FROM 	#tempaccess, 
		branch 
where 	#tempaccess.branch_code = convert(varchar(1),branch.branch_code)
and 	branch.country_code = 'A'

IF    (@no_branches
		=
	   (select 	count(*) 
		from 	branch 
		where 	country_code = 'A')) 
begin
	INSERT #tempaccess 
	( 
		name, 
		rep_id, 
		team_id, 
		branch_code,
		sort_order,
		country_code,
		status
	) 
	VALUES  
	( 
		'Australia',
		0,
		0,
		'',
		0,
		'A',
		'A'
	)
end 
		
IF    ((SELECT 	count(*) 
		FROM 	#tempaccess, 
				branch 
		where 	#tempaccess.branch_code = branch.branch_code 
		and 	branch.country_code = 'Z' )
		=
	   (select 	count(*) 
		from 	branch 
		where 	country_code = 'Z')) 
begin
	INSERT #tempaccess 
	( 
		name, 
		rep_id, 
		team_id, 
		branch_code,
		sort_order,
		country_code,
		status
	) 
	VALUES  
	( 
		'New Zealand',
		0,
		0,
		'',
		99,
		'Z',
		'A'
	)	
end 

/*
 * insert teams - for users who have access to branches - and only for those branches
 */

IF ( (SELECT count(*) FROM #tempaccess) > 0) 
begin
	INSERT #tempaccess 
	( 
		name, 
		rep_id, 
		team_id, 
		branch_code,
		sort_order,
		country_code,
		status
	) 
	SELECT 	DISTINCT sales_team.team_name, 
			0, 
			sales_team.team_id, 
			'',
			8888,
			'',
			team_status
	FROM 	sales_team,
			branch_access
	where	sales_team.team_branch = branch_access.branch_code
	and		branch_access.user_id = @s_login
	and 	(team_status = 'A'
	or 		team_id in (	select 		distinct team_id
							from 		booking_figure_team_xref, 
										booking_figures 
							where 		booking_figure_team_xref.figure_id = booking_figures.figure_id
							and			booking_period between dateadd(yy, -1, @start_date) and @end_date))
end

/*
 * Select Reps based on branch access
 */

INSERT #tempaccess 
( 
	name, 
	rep_id, 
	team_id, 
	branch_code, 
	sort_order,
	country_code,
	status
) 
SELECT 	DISTINCT sales_rep.first_name + ' ' + sales_rep.last_name,
		rep_id,
		0,
		'',
		9999,
		'',
		status
FROM 	sales_rep
WHERE 	branch_code in (	SELECT 	ba.branch_code
							FROM 	branch_access ba,
									security_access sa,   
									security_access_group sag
							WHERE 	ba.user_id = sa.user_id
							and		sag.security_access_group_id = sa.security_access_group_id
							and		ba.user_id = @s_login
							and		sag.security_access_group_desc in (	'Head of Sales Dept',
																		'Super User',
																		'Senior Admin User',
																		'Marketing Director',
																		'CEO',
																		'Finance Staff'))
and		(status = 'A'
or		rep_id in (	select 	distinct rep_id
					from	booking_figures
					where	booking_period between dateadd(yy, -1, @start_date) and @end_date))



/*
 * Insert teams for team leaders
 */

INSERT #tempaccess 
( 
	name, 
	rep_id, 
	team_id, 
	branch_code, 
	sort_order,
	country_code,
	status
) 
SELECT 	DISTINCT sales_team.team_name, 
		0, 
		sales_team.team_id, 
		'', 
		8888,
		'',
		team_status
FROM 	employee,
		sales_team
WHERE 	employee.rep_id > 1
and		sales_team.leader_id = employee.rep_id
and 	employee.login_id = @s_login

/*
 * Insert teams for team members with access to the teams figures
 */

INSERT #tempaccess 
( 
	name, 
	rep_id, 
	team_id, 
	branch_code, 
	sort_order,
	country_code,
	status
) 
SELECT 	DISTINCT sales_team.team_name, 
		0, 
		sales_team.team_id, 
		'', 
		8888,
		'',
		team_status
FROM 	employee,
		sales_team,
		sales_team_members
WHERE 	employee.rep_id > 1
and		sales_team.team_id = sales_team_members.team_id
and		sales_team_members.view_team_figures = 'Y'
and		sales_team_members.rep_id = employee.rep_id
and 	employee.login_id = @s_login


/*
 * Insert Reps own record
 */

INSERT #tempaccess 
( 
	name, 
	rep_id, 
	team_id, 
	branch_code, 
	sort_order,
	country_code,
	status
) 
SELECT 	DISTINCT employee.employee_name, 
		employee.rep_id,
		0,
		'',
		9999,
		'',
		employee_status
FROM 	branch_access,   
		employee  ,
		security_access,   
		security_access_group
WHERE 	branch_access.user_id = employee.login_id
and  	branch_access.user_id = security_access.user_id
and		security_access_group.security_access_group_id = security_access.security_access_group_id
and		employee.rep_id > 1
and		branch_access.user_id = @s_login
and		security_access_group.security_access_group_desc in (	'Head of Sales Dept',
																'Sales Directors of Various Markets',
																'Sales Managers of Various Teams',
																'Sales Rep',
																'Marketing Staff',
																'Marketing Director',
																'CEO')


SELECT distinct name, 
				rep_id, 
				team_id, 
				branch_code, 
				sort_order,
				country_code,
				status
 from #tempaccess
		


end
GO
