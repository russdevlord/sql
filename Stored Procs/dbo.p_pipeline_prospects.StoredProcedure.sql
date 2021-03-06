/****** Object:  StoredProcedure [dbo].[p_pipeline_prospects]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_pipeline_prospects]
GO
/****** Object:  StoredProcedure [dbo].[p_pipeline_prospects]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_pipeline_prospects]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 ---- Drop temp Tables

	 --drop table #output
	 --drop table #sales
	 --drop table #reps
	 --drop table #questions
	 --drop table #question_total


	select cp.client_prospect_id
		   ,cp.business_unit_id
		   ,cp.agency_id
		   ,client_id
		   ,client_product_id
		   ,vapwq.quarter
		   ,year(cps.screening_date) as year
  		   ,sum(no_screens) as no_screens
		   ,max(charge_rate) as charge_rate
		   ,(sum(no_screens) * max(charge_rate)) as total_value
			,country_code
			,cp.start_date
			,cp.end_date
		   into #sales
	from client_prospect_spots as cps
	inner join v_accounting_period_wth_qtr as vapwq on vapwq.start_date = screening_date
	inner join client_prospect as cp on cp.client_prospect_id = cps.client_prospect_id
		 where year(vapwq.start_date) = year(getdate())
		  or (year(vapwq.end_date) =  year(dateadd(yy, 1, getdate())) and vapwq.period_no in (1,2,3,4,5,6))
		  or (year(vapwq.end_date) =  year(dateadd(yy, -1 , getdate())) and vapwq.period_no in (7,8,9,10,11,12) )
	group by   cp.client_prospect_id
			  ,cp.business_unit_id
			  ,cp.agency_id
			  ,client_id
			  ,client_product_id
			  ,vapwq.quarter
			  ,year(screening_date)
			  ,country_code
			  ,cp.start_date
			  ,cp.end_date
	order by year(cps.screening_date), vapwq.quarter



	-- get reps by prospect
	select  s.client_prospect_id, cprx.rep_id, first_name + ' ' + last_name as rep_name, branch_code
	into #reps
	from client_prospect_rep_xref as cprx
	inner join sales_rep as sr on sr.rep_id = cprx.rep_id
	inner join #sales as s on s.client_prospect_id = cprx.client_prospect_id

	-- get Question Percentage

	select s.client_prospect_id, client_prospect_question_groups_id, answer, percentage
	into #questions
	from client_prospect_question_xref as cpqx
	inner join client_prospect_question as cpq on cpq.client_prospect_question_id = cpqx.client_prospect_question_id
	inner join client_prospect_question_group as cpqp on cpqp.client_prospect_question_group_id = cpq.client_prospect_question_groups_id
	inner join #sales as s on s.client_prospect_id = cpqx.client_prospect_id
	group by s.client_prospect_id, client_prospect_question_groups_id, answer,percentage

	select client_prospect_id, SUM(percentage) as opportunity_total into #question_total
	from (
			select client_prospect_id,client_prospect_question_groups_id,
			( case when (count(client_prospect_question_groups_id)) = 1 and max(answer) = 'Y' then sum(percentage)
					 else 0
					end) as percentage
			from #questions
			group by client_prospect_id,client_prospect_question_groups_id
		 ) as a
	group by 	 client_prospect_id


	select distinct s.client_prospect_id
		   ,s.start_date
		   ,s.end_date
		   ,country_code
		   ,s.business_unit_id
		   ,bu.business_unit_desc
		   ,s.agency_id
		   ,a.agency_name
		   ,c.client_id
		   ,c.client_name
		   ,cp.client_product_id
		   ,cp.client_product_desc
		   ,r.rep_id
		   ,r.rep_name
		   ,st.team_id
		   ,st.team_name
		   ,r.branch_code
		   ,s.quarter
		   ,s.year
		   ,s.no_screens
		   ,s.charge_rate
		   ,s.total_value
		   ,case when qt.opportunity_total <> 0 then qt.opportunity_total / 100
				 else 0
				 end as opportunity_total
	from #sales as s
	inner join #question_total as qt on qt.client_prospect_id = s.client_prospect_id
	inner join #reps as r on r.client_prospect_id = s.client_prospect_id
	inner join business_unit as bu on bu.business_unit_id = s.business_unit_id
	inner join agency as a on a.agency_id = s.agency_id
	inner join client as c on c.client_id = s.client_id
	inner join client_product as cp on cp.client_product_id = s.client_product_id
	left join sales_team_members as stm on stm.rep_id = r.rep_id
	left join sales_team as st on st.team_id = stm.team_id

    
    
END
GO
