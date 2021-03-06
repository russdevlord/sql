/****** Object:  StoredProcedure [dbo].[p_statrev_report_campaign_team_assignment]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_statrev_report_campaign_team_assignment]
GO
/****** Object:  StoredProcedure [dbo].[p_statrev_report_campaign_team_assignment]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE proc [dbo].[p_statrev_report_campaign_team_assignment]
	@report_date			datetime,
	@delta_date				datetime,
	@PERIOD_START			datetime,
	@PERIOD_END				datetime,
	@mode					integer, -- 3 - Budget, 4 - Forecast
	@branch_code			varchar(1),
	@country_code			varchar(1),
	@business_unit_id		int,
	@revenue_group			int,
	@master_revenue_group	int,
	@report_type			varchar(1) -- 'C' - cinema, 'O' - outpost/retail, '' - All
AS

DECLARE @ultimate_start_date		datetime
DECLARE @prev_report_date			datetime
DECLARE @prev_final_date			datetime

DECLARE	@ultimate_start				datetime
DECLARE @startexec					datetime
SELECT	@startexec = GetDate()
SELECT	@ultimate_start = @startexec

-- Set dates unless specified
SELECT	@ultimate_start_date = '1-JAN-1900';
SELECT	@prev_report_date = DATEADD(DAY, -365, @report_date);
SELECT	@prev_final_date = CONVERT(DATETIME, CONVERT(VARCHAR(4), DATEPART(YEAR, @report_date) - 1) + '-12-31 23:59:59.000');

-- Set dates unless specified
SELECT	@ultimate_start_date = '1-JAN-1900';
SELECT	@prev_report_date = DATEADD(DAY, -365, @report_date);
SELECT	@prev_final_date = CONVERT(DATETIME, CONVERT(VARCHAR(4), DATEPART(YEAR, @report_date) - 1) + '-12-31 23:59:59.000');

create table	#campaigns
(
	campaign_no				int					not null,
	product_desc			varchar(100)		not null,
	branch_code				char(2)				not null,
	branch_name				varchar(50)			not null,
	business_unit_id		int					not null,
	business_unit_desc		varchar(30)			not null,
	revenue_type			int					not null,
	revenue_desc			varchar(100)		not null,
	revenue					money				not null,
	base_revenue			money				not null,
	in_error				int					not null
)

-- Insert Total Actual Revenue
insert into		#campaigns
select			campaign_no, 
				product_desc,
				branch_code,
				branch_name,
				business_unit_id,
				business_unit_desc,
				1,
				'Base Campaign Revenue',
				sum(cost),
				sum(cost),
				0
from			v_statrev_report
where			delta_date <= @report_date 
and				revenue_period BETWEEN @PERIOD_START AND @PERIOD_END
and				cost <> 0  
and				( type1 = @report_type OR @report_type = '' )
and				( branch_code = @branch_code or @branch_code = '')
and				( country_code =  @country_code or @country_code = '')
and				( business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and				( revenue_group = @revenue_group or @revenue_group = 0)
and				( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
group by		campaign_no, 
				product_desc,
				branch_code,
				branch_name,
				business_unit_id,
				business_unit_desc

insert into		#campaigns
select			campaign_no, 
				product_desc,
				v_statrev_report_rep.branch_code,
				branch_name,
				v_statrev_report_rep.business_unit_id,
				business_unit_desc,
				2,
				first_name + ' ' + last_name,
				sum(cost),
				(select			sum(revenue)
				from			#campaigns
				where			revenue_type = 1
				and				campaign_no = v_statrev_report_rep.campaign_no),
				0
from			v_statrev_report_rep
inner join		sales_rep on v_statrev_report_rep.rep_id = sales_rep.rep_id
where			delta_date <= @report_date 
and				revenue_period BETWEEN @PERIOD_START AND @PERIOD_END
and				cost <> 0  
and				( type1 = @report_type OR @report_type = '' )
and				( v_statrev_report_rep.branch_code = @branch_code or @branch_code = '')
and				( country_code =  @country_code or @country_code = '')
and				( v_statrev_report_rep.business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and				( revenue_group = @revenue_group or @revenue_group = 0)
and				( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
group by		campaign_no, 
				product_desc,
				v_statrev_report_rep.branch_code,
				branch_name,
				v_statrev_report_rep.business_unit_id,
				business_unit_desc,
				first_name + ' ' + last_name

insert into		#campaigns
select			campaign_no, 
				product_desc,
				v_statrev_report_team.branch_code,
				branch_name,
				v_statrev_report_team.business_unit_id,
				business_unit_desc,
				3,
				team_name,
				sum(cost),
				(select			sum(revenue)
				from			#campaigns
				where			revenue_type = 1
				and				campaign_no = v_statrev_report_team.campaign_no),

				0
from			v_statrev_report_team
inner join		sales_team on v_statrev_report_team.team_id = sales_team.team_id
where			delta_date <= @report_date 
and				revenue_period BETWEEN @PERIOD_START AND @PERIOD_END
and				cost <> 0  
and				( type1 = @report_type OR @report_type = '' )
and				( v_statrev_report_team.branch_code = @branch_code or @branch_code = '')
and				( country_code =  @country_code or @country_code = '')
and				( v_statrev_report_team.business_unit_id = @business_unit_id or @business_unit_id = 0 ) 
and				( revenue_group = @revenue_group or @revenue_group = 0)
and				( master_revenue_group = @master_revenue_group or @master_revenue_group = 0)
group by		campaign_no, 
				product_desc,
				v_statrev_report_team.branch_code,
				branch_name,
				v_statrev_report_team.business_unit_id,
				business_unit_desc,
				team_name

update #campaigns set in_error = 1 where revenue <> base_revenue

select * from #campaigns
where revenue <> 0
order by campaign_no

GO
