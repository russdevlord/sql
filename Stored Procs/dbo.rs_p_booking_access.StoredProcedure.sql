/****** Object:  StoredProcedure [dbo].[rs_p_booking_access]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[rs_p_booking_access]
GO
/****** Object:  StoredProcedure [dbo].[rs_p_booking_access]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE PROC [dbo].[rs_p_booking_access] 	@s_login varchar(30)--, @control_type VARCHAR(10)--, @start_date		datetime, @end_date		datetime

as

declare 	@error_num              int,
		    @buss_unit              int,
			@no_branches			int,
			@domain_strip			INT

SELECT @buss_unit = 0

SELECT @domain_strip = CHARINDEX ( '\' , @s_login  )

IF @domain_strip > 0
BEGIN
	SELECT @s_login  =  SUBSTRING ( @s_login , @domain_strip + 1 , LEN(@s_login) - @domain_strip)
END

--SELECT @s_login = 'divailovski'

CREATE table #tempaccess (
	name 			varchar(100) 	null,
	rep_id 			integer 		null,
	rep_name		varchar(50)		null,
	team_id 		integer 		null,
	team_name		varchar(50)		null,
	branch_code		char(1) 		null,
	branch_name		varchar(50)		null,
	country_code	char(1)			null,
	country_name	varchar(50)		null,
	sort_order 		int 			null,
	status			char(1)			null,
	control_type	VARCHAR(7)		NULL )

/*
 * Insert Branches for appropriate users
 */
INSERT #tempaccess ( 
	name, 
	rep_id, 
	team_id, 
	branch_code, branch_name,
	sort_order,
	country_code,
	status , control_type ) 
SELECT 	branch.branch_name, 
		0,
		0, 
		convert(varchar(1), branch_access.branch_code), branch.branch_name,
		branch.sort_order,
		'',
		'A',
		'BRANCH'
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
SELECT	@no_branches = count(*) 
FROM 	#tempaccess, 
		branch 
WHERE 	#tempaccess.branch_code = convert(varchar(1),branch.branch_code)
and 	branch.country_code = 'A'

IF    (@no_branches = (select 	count(*) 
						from 	branch 
						where 	country_code = 'A')) 
begin
	INSERT #tempaccess ( 
		name, 
		rep_id, 
		team_id, 
		branch_code,
		sort_order,
		country_code, country_name,
		status, control_type	) 
	VALUES ( 
		'Australia',
		0,
		0,
		'',
		0,
		'A', 'Australia',
		'A' ,
		'COUNTRY')
end 
		
IF    ((SELECT 	count(*) 
		FROM 	#tempaccess, 
				branch 
		where 	#tempaccess.branch_code = branch.branch_code 
		and 	branch.country_code = 'Z' )
		=
	   (select 	count(*) 
		from 	branch 
		where 	branch.country_code = 'Z')) 
begin
	INSERT #tempaccess ( 
		name, 
		rep_id, 
		team_id, 
		branch_code,
		sort_order,
		country_code, country_name,
		status, control_type ) 
	VALUES ( 
		'New Zealand',
		0,
		0,
		'',
		1,--99,
		'Z', 'New Zealand',
		'A',
		'COUNTRY' )	
end 

/*
 * insert teams - for users who have access to branches - and only for those branches
 */

IF ( (SELECT count(*) FROM #tempaccess) > 0) 
begin
	INSERT #tempaccess ( 
		name, 
		rep_id, 
		team_id, team_name,
		branch_code,
		sort_order,
		country_code,
		status, control_type ) 
	SELECT 	DISTINCT sales_team.team_name, 
			0, 
			sales_team.team_id, sales_team.team_name,
			'',
			8888,
			'',
			team_status,
			'TEAM_ID'
	FROM 	sales_team,
			branch_access
	where	sales_team.team_branch = branch_access.branch_code
	and		branch_access.user_id = @s_login
	and 	(team_status = 'A'
--	or 		team_id in (	select 		distinct team_id
--							from 		booking_figure_team_xref, 
--										booking_figures 
--							where 		booking_figure_team_xref.figure_id = booking_figures.figure_id
--							and			booking_period between dateadd(yy, -1, @start_date) and @end_date)
)
end

/*
 * Select Reps based on branch access
 */
INSERT #tempaccess ( 
		name, 
		rep_id, rep_name,
		team_id, 
		branch_code, 
		sort_order,
		country_code,
		status, control_type ) 
SELECT 	DISTINCT sales_rep.first_name + ' ' + sales_rep.last_name,
		rep_id, sales_rep.first_name + ' ' + sales_rep.last_name,
		0,
		'',
		9999,
		'',
		status,
		'REP_ID'
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
																		'CEO'))
and		(status = 'A'
--or		rep_id in (	select 	distinct rep_id
--						from	booking_figures
--						where	booking_period between dateadd(yy, -1, @start_date) and @end_date)
					)

/*
 * Insert teams for team leaders
 */
INSERT #tempaccess ( 
		name, 
		rep_id, 
		team_id, team_name,
		branch_code, 
		sort_order,
		country_code,
		status, control_type ) 
SELECT 	DISTINCT sales_team.team_name, 
		0, 
		sales_team.team_id, sales_team.team_name, 
		'', 
		8888,
		'',
		team_status,
		'TEAM_ID'
FROM 	employee,
		sales_team
WHERE 	employee.rep_id > 1
and		sales_team.leader_id = employee.rep_id
and 	employee.login_id = @s_login

/*
 * Insert teams for team members with access to the teams figures
 */
INSERT #tempaccess ( 
		name, 
		rep_id, 
		team_id, team_name,
		branch_code, 
		sort_order,
		country_code,
		status, control_type ) 
SELECT 	DISTINCT sales_team.team_name, 
		0, 
		sales_team.team_id, sales_team.team_name, 
		'', 
		8888,
		'',
		team_status,
		'TEAM_ID'
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
INSERT #tempaccess ( 
		name, 
		rep_id, rep_name,
		team_id, 
		branch_code, 
		sort_order,
		country_code,
		status, control_type ) 
SELECT 	DISTINCT employee.employee_name, 
		employee.rep_id, employee.employee_name, 
		0,
		'',
		9999,
		'',
		employee_status,
		'REP_ID'
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
-- Adding (All) to each control type

-- Country
IF ( (SELECT COUNT(*) FROM country) = (SELECT COUNT(*) FROM #tempaccess WHERE control_type = 'COUNTRY') ) 
begin
	INSERT #tempaccess ( name, rep_id, team_id, branch_code, sort_order, country_code, country_name, status, control_type ) 
	VALUES ('(All Countries)', 0, 0, null, 0, '', '(All Countries)', 'A', 'COUNTRY')
end

-- Branch
IF ( (SELECT COUNT(*) FROM branch) = (SELECT COUNT(*) FROM #tempaccess WHERE control_type = 'BRANCH') ) 
begin
	INSERT #tempaccess ( name, rep_id, team_id, branch_code, branch_name, sort_order, country_code, status, control_type ) 
	VALUES ('(All Branches)', 0, 0, '', '(All Branches)', 9, NULL, 'A', 'BRANCH')
end

-- Team
IF ( (SELECT COUNT(team_id) FROM sales_team WHERE team_status = 'A') = (SELECT COUNT(DISTINCT team_id) FROM #tempaccess WHERE control_type = 'TEAM_ID') ) 
begin
	INSERT #tempaccess ( name, rep_id, team_id, team_name, branch_code, sort_order, country_code, status, control_type ) 
	VALUES ('(All Teams)', NULL, 0, '(All Teams)', null, 8880, NULL, 'A', 'TEAM_ID')
end

-- Sales Rep
IF ( (SELECT COUNT(rep_id) FROM sales_rep WHERE status = 'A') <= (SELECT COUNT(DISTINCT rep_id) FROM #tempaccess WHERE control_type = 'REP_ID') ) 
begin
	INSERT #tempaccess ( name, rep_id, rep_name, team_id, branch_code, sort_order, country_code, status, control_type ) 
	VALUES ('(All Reps)', 0, '(All Reps)', NULL, null, 9990, NULL, 'A', 'REP_ID')
end

SET FMTONLY OFF

SELECT	DISTINCT name AS DataName, 
		--CASE @control_type When 'REP_ID' Then CONVERT(VARCHAR(4), rep_id)
		--WHEN  'TEAM_ID' Then CONVERT(VARCHAR(4), team_id)
		--WHEN  'BRANCH' Then branch_code
		--WHEN  'COUNTRY' Then country_code
		--ELSE ( CASE country_code When '' Then ( 
		--	 CASE branch_code When '' Then (
		--	 CASE team_id When 0 Then CONVERT(VARCHAR(4), rep_id) 
		--			ELSE CONVERT(VARCHAR(4), team_id) END)
		--			ELSE branch_code END)
		--			ELSE country_code END )
		--			end AS DataID,
		country_code,
		country_name,
		branch_code, 
		branch_name,
		team_id,
		team_name,
		rep_id, 
		rep_name, 
		status,
		sort_order,
		CONTROL_TYPE
FROM	#tempaccess
--WHERE	CONTROL_TYPE = @control_type OR @control_type = ''
--order by 10, 2, 4, 6, 8
ORDER BY sort_order, country_name, branch_name, team_name, rep_name
GO
