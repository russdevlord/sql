/****** Object:  StoredProcedure [dbo].[p_rep_prospector_list]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rep_prospector_list]
GO
/****** Object:  StoredProcedure [dbo].[p_rep_prospector_list]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_rep_prospector_list]

		--@rep_ids varchar(1000)
		--,@start_date datetime,
		--@end_date datetime


AS
BEGIN

	SET NOCOUNT ON;

	-- drop table #reps
	-- drop table #spots
	-- drop table #questions
	-- drop table #questions_final

	create table #reps(
	rep_id int,
	client_prospect_id int )

	--declare @sql varchar (1000)

	--set @sql =
	-- get list of reps and the prospects associated with them
	insert into #reps
	select rep_id, client_prospect_id
	from client_prospect_rep_xref
	--where rep_id in (' + @rep_ids + ')'

	--exec(@sql)

	select cps.client_prospect_id, SUM(cps.no_screens) as screens , month(screening_date) as period_no,
	YEAR(screening_date) as [year],
	case when month(screening_date) = 1 then 'Q3'
		 when month(screening_date) = 2 then 'Q3'
		 when month(screening_date) = 3 then 'Q3'
		 when month(screening_date) = 4 then 'Q4'
		 when month(screening_date) = 5 then 'Q4'
		 when month(screening_date) = 6 then 'Q4'
		 when month(screening_date) = 7 then 'Q1'
		 when month(screening_date) = 8 then 'Q1'
		 when month(screening_date) = 9 then 'Q1'
		 when month(screening_date) = 10 then 'Q2'
		 when month(screening_date) = 11 then 'Q2'
		 when month(screening_date) = 12 then 'Q2'
		 end as [quarter]
	, (SUM(cps.no_screens) * max(cps.charge_rate)) as total_value -- SUM(total_value)as total_value
	, max(cps.charge_rate) as charge_rate into #spots
	from client_prospect_spots as cps
	inner join client_prospect_package as cpp on cpp.client_prospect_id = cps.client_prospect_id and cpp.package_id = cps.package_id
	where cps.client_prospect_id in (select client_prospect_id from #reps)
	group by cps.client_prospect_id, month(screening_date), YEAR(screening_date)




	select client_prospect_id, client_prospect_question_groups_id, answer, percentage into #questions
	from client_prospect_question_xref as cpqx
	inner join client_prospect_question as cpq on cpq.client_prospect_question_id = cpqx.client_prospect_question_id
	inner join client_prospect_question_group as cpqp on cpqp.client_prospect_question_group_id = cpq.client_prospect_question_groups_id
	where client_prospect_id in (select client_prospect_id from #reps)
	group by client_prospect_id, client_prospect_question_groups_id, answer,percentage



	select client_prospect_id, SUM(percentage) as opportunity_total into #questions_final
	from (
			select client_prospect_id,client_prospect_question_groups_id,
			( case when (count(client_prospect_question_groups_id)) = 1 and max(answer) = 'Y' then sum(percentage)
				   else 0
					end) as percentage
			from #questions
			group by client_prospect_id,client_prospect_question_groups_id
		 ) as a
	group by 	 client_prospect_id


	select rep_id, client_prospect_id, client_id, [year],quarter, agency_id, start_date, end_date,
		  [1] as month1, -- Jan,
		  [2] as month2, --Feb,
		  [3] as month3, --Mar,
		  [4] as month4, --Apr,
		  [5] as month5, --May,
		  [6] as month6, --Jun,
		  [7] as month7, --Jul,
		  [8] as month8, --Aug,
		  [9] as month9, --Sep,
		  [10] as month10, --Oct,
		  [11] as month11, --Nov,
		  [12] as month12, --[Dec]
		  opportunity_total into #final
	from (select r.rep_id, cp.client_id, s.client_prospect_id, s.total_value,[year],period_no, qf.opportunity_total,s.quarter, cp.agency_id, cp.start_date, cp.end_date
		  from #reps as r
		  inner join #spots as s on s.client_prospect_id = r.client_prospect_id
		  inner join #questions_final as qf on qf.client_prospect_id = r.client_prospect_id
		  inner join client_prospect as cp on cp.client_prospect_id = r.client_prospect_id
	--	  where cp.start_date >= @start_date
	--	  and cp.end_date <= @end_date
		  ) piv
	pivot
	(
		max(total_value)
		for period_no in ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
	) as pvt
	order by rep_id, client_prospect_id
 
	select rep_id, client_prospect_id, client_id, year, quarter, 
	month1, month2, month3, month4, month5, month6, month7, month8, month9, month10, month11, month12, opportunity_total ,
	(isnull(month1,0) + isnull(month2,0) + isnull(month3,0) + isnull(month4,0) + isnull(month5,0) + isnull(month6,0) + isnull(month7,0)
	+ isnull(month8,0) + isnull(month9,0) + isnull(month10,0) + isnull(month11,0) + isnull(month12,0)) as total, agency_id, start_date, end_date
	from #final

	END
GO
