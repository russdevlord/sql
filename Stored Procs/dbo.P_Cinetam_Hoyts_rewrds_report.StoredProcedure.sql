/****** Object:  StoredProcedure [dbo].[P_Cinetam_Hoyts_rewrds_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[P_Cinetam_Hoyts_rewrds_report]
GO
/****** Object:  StoredProcedure [dbo].[P_Cinetam_Hoyts_rewrds_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Frances
-- Create date: 3-12-2013
-- Description: For the Hoyts Qtrly rewards Report
-- =============================================
--Drop Proc P_Cinetam_Hoyts_rewrds_report

CREATE PROCEDURE [dbo].[P_Cinetam_Hoyts_rewrds_report]


																			@Date				datetime
																			/*@Detail						varchar(max), 
																			@YY							int,
																			@QQ	         				datetime,
																			@screening_date				datetime,
																			@Mnth						int,
																			@Unique_members				int,
																			@tot_trans					int,
																			@tot_adult_tickets			int,
																			@tot_child_tickets			int,
																			@cinetam_demographics_desc	Varchar(max),	
																			@cinetam_demographics_id	int*/
	
AS

--Declare
--																			@Date				datetime
																			
																			
BEGIN

create table #Hoyts_qtr_Rewards_report
(
																			Detail						varchar(max), 
																			YY							int,
																			QQ	         				varchar(2),
																			screening_date				datetime,
																			Mnth						int,
																			Unique_members				int,
																			tot_trans					int,
																			tot_adult_tickets			int,
																			tot_child_tickets			int,
																			cinetam_demographics_desc	Varchar(max),
																			cinetam_demographics_id		int
)
	SET NOCOUNT ON;
--SET @Date = @Date	

    -- Insert statements for procedure here

insert into  #Hoyts_qtr_Rewards_report
(Detail, YY,QQ ,screening_date, Mnth,Unique_members,tot_trans,tot_adult_tickets,tot_child_tickets,cinetam_demographics_desc, cinetam_demographics_id)


Select 'Current_Qtr' As Detail, YY,QQ ,Benchmark_end, Mnth, Unique_members,tot_trans,tot_adult_tickets,tot_child_tickets,cinetam_demographics_desc, cinetam_demographics_id
FROM
(SELECT        
DATEPART(Year, Benchmark_end) AS YY, 
case month(Benchmark_end) 
when 1 then 'Q3' 
when 2 then 'Q3'
when 3 then 'Q3'
when 4 then 'Q4' 
when 5 then 'Q4' 
when 6 then 'Q4' 
when 7 then 'Q1' 
when 8 then 'Q1' 
when 9 then 'Q1' 
when 10 then 'Q2'
when 11 then 'Q2'
when 12 then 'Q2' end as QQ, 
Benchmark_end,
DATEPART(Month, Benchmark_end) AS Mnth, 
COUNT(DISTINCT membership_id) AS Unique_members, SUM(unique_transactions) AS tot_trans, SUM(adult_tickets) AS tot_adult_tickets, SUM(child_tickets) AS tot_child_tickets, 
cinetam_demographics_desc, cinetam_demographics_id
FROM  v_movio_data_demo_fsd, film_screening_date_xref
WHERE v_movio_data_demo_fsd.screening_date = film_screening_date_xref.screening_date
GROUP BY DATEPART(Year, Benchmark_end), DATEPART(Quarter, Benchmark_end), DATEPART(Month, Benchmark_end), cinetam_demographics_desc, 
cinetam_demographics_id, Benchmark_end) b
WHERE QQ = 
case MONTH(@Date)
when 1 then 'Q3' 
when 2 then 'Q3'
when 3 then 'Q3'
when 4 then 'Q4' 
when 5 then 'Q4' 
when 6 then 'Q4' 
when 7 then 'Q1' 
when 8 then 'Q1' 
when 9 then 'Q1' 
when 10 then 'Q2'
when 11 then 'Q2'
when 12 then 'Q2'
END
AND YEAR(Benchmark_end) = YEAR(@Date)
UNION ALL
Select 'Prior_Qtr' As Detail, YY,QQ As Prior_Qtr,Benchmark_end, Mnth, Unique_members,tot_trans,tot_adult_tickets,tot_child_tickets,cinetam_demographics_desc, cinetam_demographics_id
FROM
(SELECT        
DATEPART(Year, Benchmark_end) AS YY, 
case month(Benchmark_end) 
when 1 then 'Q3' 
when 2 then 'Q3'
when 3 then 'Q3'
when 4 then 'Q4' 
when 5 then 'Q4' 
when 6 then 'Q4' 
when 7 then 'Q1' 
when 8 then 'Q1' 
when 9 then 'Q1' 
when 10 then 'Q2'
when 11 then 'Q2'
when 12 then 'Q2' end as QQ, 
Benchmark_end,
DATEPART(Month, benchmark_end) AS Mnth, 
COUNT(DISTINCT membership_id) AS Unique_members, SUM(unique_transactions) AS tot_trans, SUM(adult_tickets) AS tot_adult_tickets, SUM(child_tickets) 
AS tot_child_tickets, cinetam_demographics_desc, cinetam_demographics_id
FROM  v_movio_data_demo_fsd, film_screening_date_xref
WHERE v_movio_data_demo_fsd.screening_date = film_screening_date_xref.screening_date
GROUP BY DATEPART(Year, Benchmark_end), DATEPART(Quarter, Benchmark_end), DATEPART(Month, Benchmark_end), cinetam_demographics_desc, 
cinetam_demographics_id, Benchmark_end) b
WHERE QQ = 
case MONTH(DATEADD(MONTH,-3,@Date))
when 1 then 'Q3' 
when 2 then 'Q3'
when 3 then 'Q3'
when 4 then 'Q4' 
when 5 then 'Q4' 
when 6 then 'Q4' 
when 7 then 'Q1' 
when 8 then 'Q1' 
when 9 then 'Q1' 
when 10 then 'Q2'
when 11 then 'Q2'
when 12 then 'Q2'
END
AND YEAR(Benchmark_end) = 
CASE WHEN Month(@Date) IN (1,2,3) THEN YEAR(DATEADD(YEAR,-1,@Date))
	 ELSE YEAR(@Date) 
	 END
UNION ALL
Select 'Last 12 Months' As Detail, YY,QQ As Prior_Qtr,Benchmark_end, Mnth, Unique_members,tot_trans,tot_adult_tickets,tot_child_tickets,cinetam_demographics_desc, cinetam_demographics_id
FROM
(SELECT        
DATEPART(Year, Benchmark_end) AS YY, 
case month(Benchmark_end) 
when 1 then 'Q3' 
when 2 then 'Q3'
when 3 then 'Q3'
when 4 then 'Q4' 
when 5 then 'Q4' 
when 6 then 'Q4' 
when 7 then 'Q1' 
when 8 then 'Q1' 
when 9 then 'Q1' 
when 10 then 'Q2'
when 11 then 'Q2'
when 12 then 'Q2' end as QQ, 
Benchmark_end,
DATEPART(Month, Benchmark_end) AS Mnth, 
COUNT(DISTINCT membership_id) AS Unique_members, SUM(unique_transactions) AS tot_trans, SUM(adult_tickets) AS tot_adult_tickets, SUM(child_tickets) 
AS tot_child_tickets, cinetam_demographics_desc, cinetam_demographics_id
FROM  v_movio_data_demo_fsd, film_screening_date_xref
WHERE v_movio_data_demo_fsd.screening_date = film_screening_date_xref.screening_date
GROUP BY DATEPART(Year, Benchmark_end), DATEPART(Quarter, Benchmark_end), DATEPART(Month, Benchmark_end), cinetam_demographics_desc, 
cinetam_demographics_id, Benchmark_end) b
WHERE Benchmark_end <= @Date 
AND  Benchmark_end >= DATEADD(WEEK,-52,@Date)
UNION ALL	 
Select 'Same Quarter Last Year' As Detail, YY,QQ ,Benchmark_end, Mnth, Unique_members,tot_trans,tot_adult_tickets,tot_child_tickets,cinetam_demographics_desc, cinetam_demographics_id
FROM
(SELECT        
DATEPART(Year, Benchmark_end) AS YY, 
case month(Benchmark_end) 
when 1 then 'Q3' 
when 2 then 'Q3'
when 3 then 'Q3'
when 4 then 'Q4' 
when 5 then 'Q4' 
when 6 then 'Q4' 
when 7 then 'Q1' 
when 8 then 'Q1' 
when 9 then 'Q1' 
when 10 then 'Q2'
when 11 then 'Q2'
when 12 then 'Q2' end as QQ, 
Benchmark_end,
DATEPART(Month, Benchmark_end) AS Mnth, 
COUNT(DISTINCT membership_id) AS Unique_members, SUM(unique_transactions) AS tot_trans, SUM(adult_tickets) AS tot_adult_tickets, SUM(child_tickets) 
AS tot_child_tickets, cinetam_demographics_desc, cinetam_demographics_id
FROM  v_movio_data_demo_fsd, film_screening_date_xref
WHERE v_movio_data_demo_fsd.screening_date = film_screening_date_xref.screening_date
GROUP BY Benchmark_end, cinetam_demographics_desc, 
cinetam_demographics_id, Benchmark_end) b
WHERE QQ =
case MONTH(@Date)
when 1 then 'Q3' 
when 2 then 'Q3'
when 3 then 'Q3'
when 4 then 'Q4' 
when 5 then 'Q4' 
when 6 then 'Q4' 
when 7 then 'Q1' 
when 8 then 'Q1' 
when 9 then 'Q1' 
when 10 then 'Q2'
when 11 then 'Q2'
when 12 then 'Q2'
END
AND
YEAR(benchmark_end) = Year(DATEADD(YEAR,-1,@Date))

END

Select * from #Hoyts_qtr_Rewards_report
GO
