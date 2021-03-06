/****** Object:  View [dbo].[v_rs_security_all]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_rs_security_all]
GO
/****** Object:  View [dbo].[v_rs_security_all]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE view [dbo].[v_rs_security_all] as

SELECT 		DataName, 
						DataCode,
						DataID, 
						sort_order,
						control_type,
						user_login,
						min_period,
						max_period,
						status
FROM			v_rs_security
UNION
SELECT 		'(All Countries)','',0,0, 'COUNTRY',V.user_login,'1-jan-1900','31-dec-3000','A'
FROM			v_rs_security AS V,
						(SELECT 		user_login AS user_login,
												COUNT(*) AS country_count
						FROM 			v_rs_security 
						WHERE 		control_type = 'COUNTRY'
						GROUP BY 	user_login) AS #TEMP
WHERE 		V.user_login = #TEMP.user_login
GROUP BY 	V.user_login,#TEMP.country_count
having 			(SELECT count(country.country_code) FROM country) = #TEMP.country_count
UNION
SELECT 		'(All Branches)','',0,0, 'BRANCH',V.user_login,'1-jan-1900','31-dec-3000','A'
FROM			v_rs_security AS V,
						(SELECT 		user_login AS user_login,
												COUNT(*) AS branch_count
						FROM 			v_rs_security 
						WHERE 		control_type = 'BRANCH'
						GROUP BY 	user_login) AS #TEMP
WHERE 		V.user_login = #TEMP.user_login
GROUP BY 	V.user_login, #TEMP.branch_count
having 			(SELECT count(branch.branch_code) FROM branch) = #TEMP.branch_count
UNION
SELECT 		'(All Teams)','',0,8880, 'TEAM_ID', V.user_login,'1-jan-1900','31-dec-3000','A'
FROM			v_rs_security AS V,
						(SELECT 		user_login AS user_login,
												COUNT(DISTINCT DataID) AS team_count
						FROM 			v_rs_security 
						WHERE 		control_type = 'TEAM_ID'
						GROUP BY 	user_login) AS #TEMP
WHERE 		V.user_login = #TEMP.user_login
GROUP BY 	V.user_login, #TEMP.team_count
having 			(SELECT count(team_id) FROM sales_team WHERE team_status = 'A') = #TEMP.team_count
UNION
SELECT 		'(All Reps)','',0,9990, 'REP_ID', V.user_login,'1-jan-1900','31-dec-3000','A'
FROM			v_rs_security AS V,
						(SELECT 		user_login AS user_login,
												COUNT(DISTINCT DataID) AS rep_count
						FROM 			v_rs_security 
						WHERE 		control_type = 'REP_ID'
						GROUP BY 	user_login) AS #TEMP
WHERE 		V.user_login = #TEMP.user_login
GROUP BY 	V.user_login, #TEMP.rep_count
having 			(SELECT count(rep_id) FROM sales_rep WHERE status = 'A') = #TEMP.rep_count
GO
