/****** Object:  View [dbo].[v_package_cpm]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP VIEW [dbo].[v_package_cpm]
GO
/****** Object:  View [dbo].[v_package_cpm]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 CREATE VIEW [dbo].[v_package_cpm] AS

SELECT Distinct package_ID, 'All 14+' Cinetam_description, screening_date, used_by_date, package_desc, campaign_no, duration, Revenue, Number_of_Spots,
Total_screen_time, cinetam_reporting_demographics_id, cinetam_reporting_demographics_desc, attendance, rate, CPM, cpm_30,P_Type
FROM
(
SELECT DISTINCT c.package_ID, c.screening_date, a.used_by_date, a.package_desc, a.campaign_no, a.duration, convert(Decimal(10,2),SUM(h.avg_rate)) as revenue, Count(Distinct e.spot_id) As Number_of_spots,
a.duration*Count(e.spot_id) As Total_Screen_Time, d.cinetam_reporting_demographics_id, b.cinetam_reporting_demographics_desc, 
ISNULL(d.attendance,0) attendance, a.rate as rate,
Sum(h.avg_rate/d.attendance)*1000 CPM, 
(Sum(h.avg_rate) * 30 / a.duration)/d.attendance*1000 CPM_30,
CASE WHEN a.follow_film = 'Y' THEN 'FF'
WHEN a.follow_film = 'N' AND a.movie_mix = 'Y' THEN 'MM'
WHEN a.follow_film = 'Y' AND a.movie_mix = 'Y' THEN 'FF MM'
WHEN c.package_id IN (Select distinct package_id from cinetam_inclusion_settings) THEN 'Tap'
END P_Type
FROM campaign_package a
JOIN v_bi_Campaign_Spots c
ON a.campaign_no = c.campaign_no
and a.package_id = c.package_id
JOIN (Select package_ID, SUM(attendance)AS attendance, cinetam_reporting_demographics_ID FROM v_cinetam_campaign_package_reporting_demographics where cinetam_reporting_demographics_ID = 1 Group by package_ID, cinetam_reporting_demographics_ID)  d
ON a.package_id = d.package_id
JOIN cinetam_reporting_demographics b
ON b.cinetam_reporting_demographics_id = d.cinetam_reporting_demographics_ID
JOIN campaign_spot e
ON c.campaign_no = e.campaign_no
AND c.package_id = e.package_id
and c.screening_date = e.screening_date
JOIN statrev_spot_rates h
ON e.spot_id = h.spot_id
Where d.cinetam_reporting_demographics_ID IN (1)
and c.type = 'onscreen'
and d.attendance >=1
and b.cinetam_reporting_demographics_id = 1
GROUP BY 
c.package_Id, a.package_desc, a.campaign_no, a.duration,a.rate, h.avg_rate, a.spot_count,d.cinetam_reporting_demographics_id, 
b.cinetam_reporting_demographics_desc, c.screening_date, a.used_by_date, d.attendance, a.follow_film,a.movie_mix)a
UNION ALL
SELECT Distinct package_ID, 'All 18-39' Cinetam_description, screening_date, used_by_date, package_desc, campaign_no, duration, Revenue, Number_of_Spots,
Total_screen_time, cinetam_reporting_demographics_id, cinetam_reporting_demographics_desc, attendance, rate, CPM, cpm_30,P_Type
FROM
(SELECT DISTINCT c.package_ID, c.screening_date, a.used_by_date, a.package_desc, a.campaign_no, a.duration, 0 revenue, 0 As Number_of_spots,
0 Total_Screen_Time, d.cinetam_reporting_demographics_id, b.cinetam_reporting_demographics_desc, 
ISNULL(d.attendance,0) attendance, a.rate as rate,
Sum(h.avg_rate/d.attendance)*1000 CPM, 
(Sum(h.avg_rate) * 30 / a.duration)/d.attendance*1000 CPM_30,
CASE WHEN a.follow_film = 'Y' THEN 'FF'
WHEN a.follow_film = 'N' AND a.movie_mix = 'Y' THEN 'MM'
WHEN a.follow_film = 'Y' AND a.movie_mix = 'Y' THEN 'FF MM'
WHEN c.package_id IN (Select distinct package_id from cinetam_inclusion_settings) THEN 'Tap'
END P_Type
FROM campaign_package a
JOIN v_bi_Campaign_Spots c
ON a.campaign_no = c.campaign_no
and a.package_id = c.package_id
JOIN (Select package_ID, SUM(attendance)AS attendance, cinetam_reporting_demographics_ID FROM v_cinetam_campaign_package_reporting_demographics where cinetam_reporting_demographics_ID = 3 Group by package_ID, cinetam_reporting_demographics_ID)  d
ON a.package_id = d.package_id
JOIN cinetam_reporting_demographics b
ON b.cinetam_reporting_demographics_id = d.cinetam_reporting_demographics_ID
JOIN campaign_spot e
ON c.campaign_no = e.campaign_no
AND c.package_id = e.package_id
and c.screening_date = e.screening_date
JOIN statrev_spot_rates h
ON e.spot_id = h.spot_id
Where d.cinetam_reporting_demographics_ID IN (3)
and c.type = 'onscreen'
and d.attendance >=1
and b.cinetam_reporting_demographics_id = 3
GROUP BY 
c.package_Id, a.package_desc, a.campaign_no, a.duration,a.rate, h.avg_rate, a.spot_count,d.cinetam_reporting_demographics_id, 
b.cinetam_reporting_demographics_desc, c.screening_date, a.used_by_date, d.attendance, a.follow_film,a.movie_mix) b
UNION ALL
SELECT Distinct package_ID, 'All 25-54' Cinetam_description, screening_date, used_by_date, package_desc, campaign_no, duration, 0 revenue, 0 As Number_of_spots,
0 Total_Screen_Time, cinetam_reporting_demographics_id, cinetam_reporting_demographics_desc, attendance, rate, CPM, cpm_30,P_Type
FROM
(SELECT DISTINCT c.package_ID, c.screening_date, a.used_by_date, a.package_desc, a.campaign_no, a.duration, sum(Distinct h.avg_rate) as revenue, Count(Distinct e.spot_id) As Number_of_spots,
0 As Total_Screen_Time, d.cinetam_reporting_demographics_id, b.cinetam_reporting_demographics_desc, 
ISNULL(d.attendance,0) attendance, a.rate as rate,
Sum(h.avg_rate/d.attendance)*1000 CPM, 
(Sum(h.avg_rate) * 30 / a.duration)/d.attendance*1000 CPM_30,
CASE WHEN a.follow_film = 'Y' THEN 'FF'
WHEN a.follow_film = 'N' AND a.movie_mix = 'Y' THEN 'MM'
WHEN a.follow_film = 'Y' AND a.movie_mix = 'Y' THEN 'FF MM'
WHEN c.package_id IN (Select distinct package_id from cinetam_inclusion_settings) THEN 'Tap'
END P_Type
FROM campaign_package a
JOIN v_bi_Campaign_Spots c
ON a.campaign_no = c.campaign_no
and a.package_id = c.package_id
JOIN (Select package_ID, SUM(attendance)AS attendance, cinetam_reporting_demographics_ID FROM v_cinetam_campaign_package_reporting_demographics where cinetam_reporting_demographics_ID = 5 Group by package_ID, cinetam_reporting_demographics_ID)  d
ON a.package_id = d.package_id
JOIN cinetam_reporting_demographics b
ON b.cinetam_reporting_demographics_id = d.cinetam_reporting_demographics_ID
JOIN campaign_spot e
ON c.campaign_no = e.campaign_no
AND c.package_id = e.package_id
and c.screening_date = e.screening_date
JOIN statrev_spot_rates h
ON e.spot_id = h.spot_id
Where d.cinetam_reporting_demographics_ID IN (5)
and c.type = 'onscreen'
and d.attendance >=1
and b.cinetam_reporting_demographics_id = 5
GROUP BY 
c.package_Id, a.package_desc, a.campaign_no, a.duration,a.rate, h.avg_rate, a.spot_count,d.cinetam_reporting_demographics_id, 
b.cinetam_reporting_demographics_desc, c.screening_date, a.used_by_date, d.attendance, a.follow_film,a.movie_mix) c


GO
