/****** Object:  View [dbo].[v_bi_Report_Catalist1]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_bi_Report_Catalist1]
GO
/****** Object:  View [dbo].[v_bi_Report_Catalist1]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[v_bi_Report_Catalist1] AS
(Select * from (
Select fin_year, fin_Qtr, Fin_Month, Business_Unit_Desc, Branch_Name, Buying_Group_Desc, Agency_Group_Name, Agency_Name, Client_Name, RevCurr , prev_rev, (ISNULL(SUM(PREV_REV) / NULLIF(Sum(RevCurr),0),0)) AS VAR_CURR
FROM bi_Agency_report
GROUP BY fin_year, fin_Qtr, Fin_Month, Business_Unit_Desc, Branch_Name, Buying_Group_Desc, Agency_Group_Name, Agency_Name, Client_Name,RevCurr , prev_rev)a)
--UNION ALL
--Select fin_year, fin_Qtr, NULL Fin_Month, Business_Unit_Desc, Branch_Name, Buying_Group_Desc, Agency_Group_Name, Agency_Name, Client_Name, Sum(RevCurr) Rev_Cur, Sum(prev_rev) prev_rev, (ISNULL(SUM(PREV_REV) / NULLIF(Sum(RevCurr),0),0)) AS VAR_CURR
--FROM bi_Agency_report
--GROUP BY fin_year, fin_Qtr, Business_Unit_Desc, Branch_Name, Buying_Group_Desc, Agency_Group_Name, Agency_Name, Client_Name
--UNION ALL
--Select fin_year, NULL fin_Qtr, NULL Fin_Month, Business_Unit_Desc, Branch_Name, Buying_Group_Desc, Agency_Group_Name, Agency_Name, Client_Name, Sum(RevCurr) Rev_Cur, Sum(prev_rev) prev_rev, (ISNULL(SUM(PREV_REV) / NULLIF(Sum(RevCurr),0),0)) AS VAR_CURR
--FROM bi_Agency_report
--GROUP BY fin_year, fin_Qtr, Business_Unit_Desc, Branch_Name, Buying_Group_Desc, Agency_Group_Name, Agency_Name, Client_Name)a)


/*(SELECT VAR_CURR FROM 
(SELECT  
	CASE 
		WHEN RevCurr = 0 THEN 0 END 
		ELSE prev_Rev = 0 THEN 0 END 
		ELSE SUM((PREV_REV/RevCurr)-1)
	END VAR_CURR
FROM bi_Agency_report
group by RevCurr,prev_)a)
*/

--select * from bi_Agency_report
--Where Fin_Year =@Fin_year
GO
