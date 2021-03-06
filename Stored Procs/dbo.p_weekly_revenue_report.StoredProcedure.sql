/****** Object:  StoredProcedure [dbo].[p_weekly_revenue_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_weekly_revenue_report]
GO
/****** Object:  StoredProcedure [dbo].[p_weekly_revenue_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc	[dbo].[p_weekly_revenue_report]		@report_date			datetime

as

declare			@current_cy_start_period					datetime,
						@current_cy_end_period					datetime,
						@next_cy_start_period						datetime,
						@next_cy_end_period							datetime,
						@current_qtr_start_period				datetime,
						@current_qtr_end_period					datetime,
						@next_qtr_start_period						datetime,
						@next_qtr_end_period						datetime,
						@delta_start											datetime,
						@delta_end											datetime,
						@delta_end_prev									datetime,
						@prev_current_cy_start_period		datetime,
						@prev_current_cy_end_period			datetime,
						@prev_current_qtr_start_period		datetime,
						@prev_current_qtr_end_period		datetime,
						@prev_next_qtr_start_period			datetime,
						@prev_next_qtr_end_period				datetime,
						@vma_book_cy_rev								money,
						@vmnz_book_cy_rev							money,
						@vmoau_book_cy_rev							money,
						@vmonz_book_cy_rev							money,
						@vma_book_ny_rev								money,
						@vmnz_book_ny_rev							money,
						@vmoau_book_ny_rev							money,
						@vmonz_book_ny_rev							money,
						@vma_book_cy_camps							int,
						@vmnz_book_cy_camps						int,
						@vmoau_book_cy_camps						int,
						@vmonz_book_cy_camps						int,
						@vma_book_ny_camps							int,
						@vmnz_book_ny_camps						int,
						@vmoau_book_ny_camps						int,
						@vmonz_book_ny_camps						int,
						@vma_cq_rev										money,
						@vmnz_cq_rev										money,
						@vmoau_cq_rev									money,
						@vmonz_cq_rev									money,
						@vma_cq_tar										money,
						@vmnz_cq_tar										money,
						@vmoau_cq_tar									money,
						@vmonz_cq_tar									money,
						@vma_stlycq_rev									money,
						@vmnz_stlycq_rev								money,
						@vmoau_stlycq_rev								money,
						@vmonz_stlycq_rev								money,
						@vma_stlycq_tar									money,
						@vmnz_stlycq_tar								money,
						@vmoau_stlycq_tar								money,
						@vmonz_stlycq_tar								money,
						@vma_cy_rev										money,
						@vmnz_cy_rev										money,
						@vmoau_cy_rev									money,
						@vmonz_cy_rev									money,
						@vma_cy_tar										money,
						@vmnz_cy_tar										money,
						@vmoau_cy_tar									money,
						@vmonz_cy_tar									money,
						@vma_stlycy_rev									money,
						@vmnz_stlycy_rev								money,
						@vmoau_stlycy_rev								money,
						@vmonz_stlycy_rev								money,
						@vma_stlycy_tar									money,
						@vmnz_stlycy_tar								money,
						@vmoau_stlycy_tar								money,
						@vmonz_stlycy_tar								money,
						@vma_nq_rev										money,
						@vmnz_nq_rev										money,
						@vmoau_nq_rev									money,
						@vmonz_nq_rev									money,
						@vma_nq_tar										money,
						@vmnz_nq_tar										money,
						@vmoau_nq_tar									money,
						@vmonz_nq_tar									money,
						@vma_stlynq_rev									money,
						@vmnz_stlynq_rev								money,
						@vmoau_stlynq_rev								money,
						@vmonz_stlynq_rev								money,
						@vma_stlynq_tar									money,
						@vmnz_stlynq_tar								money,
						@vmoau_stlynq_tar								money,
						@vmonz_stlynq_tar							money
						
set nocount on

select @delta_start										= dateadd(hh, 20, dateadd(dd, -3, @report_date))
select @delta_end										= dateadd(ss, -1, dateadd(hh, 20, dateadd(dd, 4, @report_date)))
select @delta_end_prev								= DATEADD(DAY, -365, @delta_end)
select @current_cy_start_period				= max(end_date) from accounting_period where start_date < @report_date and period_no = 1
select @current_cy_end_period				= min(end_date) from accounting_period where end_date >= @report_date and period_no = 12
select @next_cy_start_period					= max(end_date) from accounting_period where start_date < dateadd(yy, 1, @report_date) and period_no = 1
select @next_cy_end_period						= min(end_date) from accounting_period where end_date >= dateadd(yy, 1, @report_date) and period_no = 12
select @current_qtr_start_period			= max(end_date) from accounting_period where start_date < @report_date and period_no in (1,4,7,10)
select @current_qtr_end_period				= min(end_date) from accounting_period where end_date >= @report_date and period_no in (3,6,9,12) 
select @next_qtr_start_period					= min(end_date) from accounting_period where end_date > @current_qtr_start_period and period_no in (1,4,7,10)
select @next_qtr_end_period					= min(end_date) from accounting_period where end_date > @current_qtr_end_period and period_no in (3,6,9,12) 
select @prev_current_cy_start_period	= max(end_date) from accounting_period where end_date < @current_cy_start_period and period_no = 1
select @prev_current_cy_end_period		= min(end_date) from accounting_period where end_date >= @prev_current_cy_start_period and period_no = 12
select @prev_current_qtr_start_period	= max(end_date) from accounting_period where end_date < @current_qtr_start_period and period_no in (select period_no from accounting_period where end_date = @current_qtr_start_period)
select @prev_current_qtr_end_period		= min(end_date) from accounting_period where end_date >= @prev_current_qtr_start_period and period_no  in (select period_no from accounting_period where end_date = @current_qtr_end_period)
select @prev_next_qtr_start_period		= max(end_date) from accounting_period where end_date < @next_qtr_start_period and period_no in (select period_no from accounting_period where end_date = @next_qtr_start_period)
select @prev_next_qtr_end_period			= min(end_date) from accounting_period where end_date >= @prev_next_qtr_start_period and period_no  in (select period_no from accounting_period where end_date = @next_qtr_end_period)

create table #weekly_revenue
(
	business_unit_id			int,
	branch_code					char(2),
	revenue_period				datetime,
	revenue							money,
	campaign_no					int,
	revision_id						int
)

create table #yearly_revenue
(
	business_unit_id			int,
	branch_code					char(2),
	revenue_period				datetime,
	revenue							money
)

create table #yearly_revenue_stly
(
	business_unit_id			int,
	branch_code					char(2),
	revenue_period				datetime,
	revenue							money
)

create table #results
(
	delta_start										datetime,
	delta_end											datetime,
	delta_end_prev									datetime,
	current_cy_start_period				datetime,
	current_cy_end_period					datetime,
	next_cy_start_period						datetime,
	next_cy_end_period						datetime,
	current_qtr_start_period				datetime,
	current_qtr_end_period					datetime,
	next_qtr_start_period					datetime,
	next_qtr_end_period						datetime,
	prev_current_cy_start_period		datetime,
	prev_current_cy_end_period			datetime,
	prev_current_qtr_start_period		datetime,
	prev_current_atr_end_period		datetime,
	prev_next_qtr_start_period			datetime,
	prev_next_qtr_end_period				datetime,	
	vma_book_cy_rev								money,
	vmnz_book_cy_rev							money,
	vmoau_book_cy_rev							money,
	vmonz_book_cy_rev							money,
	vma_book_ny_rev								money,
	vmnz_book_ny_rev							money,
	vmoau_book_ny_rev							money,
	vmonz_book_ny_rev							money,
	vma_book_cy_camps						int,
	vmnz_book_cy_camps						int,
	vmoau_book_cy_camps					int,
	vmonz_book_cy_camps					int,
	vma_book_ny_camps						int,
	vmnz_book_ny_camps						int,
	vmoau_book_ny_camps					int,
	vmonz_book_ny_camps					int,
	vma_cq_rev										money,
	vmnz_cq_rev										money,
	vmoau_cq_rev									money,
	vmonz_cq_rev									money,
	vma_cq_tar										money,
	vmnz_cq_tar										money,
	vmoau_cq_tar									money,
	vmonz_cq_tar									money,
	vma_stlycq_rev									money,
	vmnz_stlycq_rev								money,
	vmoau_stlycq_rev								money,
	vmonz_stlycq_rev								money,
	vma_stlycq_tar									money,
	vmnz_stlycq_tar								money,
	vmoau_stlycq_tar								money,
	vmonz_stlycq_tar								money,
	vma_cy_rev										money,
	vmnz_cy_rev										money,
	vmoau_cy_rev									money,
	vmonz_cy_rev									money,
	vma_cy_tar										money,
	vmnz_cy_tar										money,
	vmoau_cy_tar									money,
	vmonz_cy_tar									money,
	vma_stlycy_rev									money,
	vmnz_stlycy_rev								money,
	vmoau_stlycy_rev								money,
	vmonz_stlycy_rev								money,
	vma_stlycy_tar									money,
	vmnz_stlycy_tar								money,
	vmoau_stlycy_tar								money,
	vmonz_stlycy_tar								money,
	vma_nq_rev										money,
	vmnz_nq_rev										money,
	vmoau_nq_rev									money,
	vmonz_nq_rev									money,
	vma_nq_tar										money,
	vmnz_nq_tar										money,
	vmoau_nq_tar									money,
	vmonz_nq_tar									money,
	vma_stlynq_rev									money,
	vmnz_stlynq_rev								money,
	vmoau_stlynq_rev								money,
	vmonz_stlynq_rev								money,
	vma_stlynq_tar									money,
	vmnz_stlynq_tar								money,
	vmoau_stlynq_tar								money,
	vmonz_stlynq_tar								money
)

insert			into #weekly_revenue
select			business_unit_id,
					branch_code,
					revenue_period,
					sum(cost),
					film_campaign.campaign_no,
					statrev_campaign_revision.revision_id
from			statrev_cinema_normal_transaction, 
					statrev_campaign_revision, 
					film_campaign
where			statrev_cinema_normal_transaction.revision_id = statrev_campaign_revision.revision_id
and				statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and				revenue_period between 	@current_cy_start_period	 and @next_cy_end_period
and				delta_date between @delta_start and @delta_end
group by		business_unit_id,
					branch_code,
					revenue_period,
					film_campaign.campaign_no,
					statrev_campaign_revision.revision_id
union all					
select			business_unit_id,
					branch_code,
					revenue_period,
					sum(cost),
					film_campaign.campaign_no,
					statrev_campaign_revision.revision_id	 
from			statrev_outpost_normal_transaction, 
					statrev_campaign_revision, 
					film_campaign
where			statrev_outpost_normal_transaction.revision_id = statrev_campaign_revision.revision_id
and				statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and				revenue_period between 	@current_cy_start_period	 and @next_cy_end_period
and				delta_date between @delta_start and @delta_end
group by		business_unit_id,
					branch_code,
					revenue_period,
					film_campaign.campaign_no,
					statrev_campaign_revision.revision_id

insert			into #yearly_revenue
select			business_unit_id,
					branch_code,
					revenue_period,
					sum(cost)	 
from			statrev_cinema_normal_transaction, 
					statrev_campaign_revision, 
					film_campaign
where			statrev_cinema_normal_transaction.revision_id = statrev_campaign_revision.revision_id
and				statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and				revenue_period between 	@current_cy_start_period	 and @next_cy_end_period
and				delta_date <= @delta_end
group by		business_unit_id,
					branch_code,
					revenue_period
union all					
select			business_unit_id,
					branch_code,
					revenue_period,
					sum(cost)	 
from			statrev_outpost_normal_transaction, 
					statrev_campaign_revision, 
					film_campaign
where			statrev_outpost_normal_transaction.revision_id = statrev_campaign_revision.revision_id
and				statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and				revenue_period between 	@current_cy_start_period	 and @next_cy_end_period
and				delta_date <= @delta_end
group by		business_unit_id,
					branch_code,
					revenue_period

insert			into #yearly_revenue_stly
select			business_unit_id,
					branch_code,
					revenue_period,
					sum(cost)	 
from			v_statrev_report
where			revenue_period between 	@prev_current_cy_start_period	 and @next_cy_end_period
and				delta_date <= @delta_end_prev
group by		business_unit_id,
					branch_code,
					revenue_period

/*insert			into #yearly_revenue_stly
select			business_unit_id,
					branch_code,
					revenue_period,
					sum(cost)	 
from			statrev_cinema_normal_transaction, 
					statrev_campaign_revision, 
					film_campaign
where			statrev_cinema_normal_transaction.revision_id = statrev_campaign_revision.revision_id
and				statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and				revenue_period between 	@prev_current_cy_start_period	 and @next_cy_end_period
and				delta_date <= @delta_end_prev
group by		business_unit_id,
					branch_code,
					revenue_period
union all					
select			business_unit_id,
					branch_code,
					revenue_period,
					sum(cost)	 
from			statrev_outpost_normal_transaction, 
					statrev_campaign_revision, 
					film_campaign
where			statrev_outpost_normal_transaction.revision_id = statrev_campaign_revision.revision_id
and				statrev_campaign_revision.campaign_no = film_campaign.campaign_no
and				revenue_period between 	@prev_current_cy_start_period	 and @next_cy_end_period
and				delta_date <= @delta_end_prev
group by		business_unit_id,
					branch_code,
					revenue_period*/


select			@vma_book_cy_rev = isnull(sum(revenue),0)
from			#weekly_revenue 
where			datepart(yy, revenue_period) = datepart(yy, @report_date)
and				branch_code <> 'Z'
and				business_unit_id  in (2,3,5,9)

select			@vmnz_book_cy_rev = isnull(sum(revenue),0)
from			#weekly_revenue 
where			datepart(yy, revenue_period) = datepart(yy, @report_date)
and				branch_code = 'Z'
and				business_unit_id  in (2,3,5,9)

select			@vmoau_book_cy_rev = isnull(sum(revenue),0)
from			#weekly_revenue 
where			datepart(yy, revenue_period) = datepart(yy, @report_date)
and				branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vmonz_book_cy_rev = isnull(sum(revenue),0)
from			#weekly_revenue 
where			datepart(yy, revenue_period) = datepart(yy, @report_date)
and				branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vma_book_ny_rev = isnull(sum(revenue),0)
from			#weekly_revenue 
where			datepart(yy, revenue_period) = datepart(yy, @report_date) + 1
and				branch_code <> 'Z'
and				business_unit_id  in (2,3,5,9)

select			@vmnz_book_ny_rev = isnull(sum(revenue),0)
from			#weekly_revenue 
where			datepart(yy, revenue_period) = datepart(yy, @report_date) + 1
and				branch_code = 'Z'
and				business_unit_id  in (2,3,5,9)

select			@vmoau_book_ny_rev = isnull(sum(revenue),0)
from			#weekly_revenue 
where			datepart(yy, revenue_period) = datepart(yy, @report_date) + 1 
and				branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vmonz_book_ny_rev = isnull(sum(revenue),0)
from			#weekly_revenue 
where			datepart(yy, revenue_period) = datepart(yy, @report_date) + 1 
and				branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vma_book_cy_camps = count(distinct campaign_no) 
from			#weekly_revenue 
where			branch_code <> 'Z'
and				business_unit_id  in (2,3,5,9)
and				revision_id in (select revision_id from statrev_campaign_revision where revision_no = 1)

select			@vmnz_book_cy_camps = count(distinct campaign_no)
from			#weekly_revenue 
where			branch_code = 'Z'
and				business_unit_id  in (2,3,5,9)
and				revision_id in (select revision_id from statrev_campaign_revision where revision_no = 1)

select			@vmoau_book_cy_camps = count(distinct campaign_no)
from			#weekly_revenue 
where			branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)
and				revision_id in (select revision_id from statrev_campaign_revision where revision_no = 1)

select			@vmonz_book_cy_camps = count(distinct campaign_no)
from			#weekly_revenue 
where			branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)
and				revision_id in (select revision_id from statrev_campaign_revision where revision_no = 1)

select			@vma_book_ny_camps = count(distinct campaign_no)
from			#weekly_revenue 
where			branch_code <> 'Z'
and				business_unit_id  in (2,3,5,9)
and				revision_id in (select revision_id from statrev_campaign_revision where revision_no = 1)

select			@vmnz_book_ny_camps = count(distinct campaign_no)
from			#weekly_revenue 
where			branch_code = 'Z'
and				business_unit_id  in (2,3,5,9)
and				revision_id in (select revision_id from statrev_campaign_revision where revision_no = 1)

select			@vmoau_book_ny_camps = count(distinct campaign_no)
from			#weekly_revenue 
where			branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)
and				revision_id in (select revision_id from statrev_campaign_revision where revision_no = 1)

select			@vmonz_book_ny_camps = count(distinct campaign_no)
from			#weekly_revenue 
where			branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)
and				revision_id in (select revision_id from statrev_campaign_revision where revision_no = 1)

select			@vma_cq_rev = isnull(sum(revenue),0)
from			#yearly_revenue
where			revenue_period between @current_qtr_start_period and @current_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmnz_cq_rev = isnull(sum(revenue),0)
from			#yearly_revenue
where			revenue_period between @current_qtr_start_period and @current_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmoau_cq_rev = isnull(sum(revenue),0)
from			#yearly_revenue
where			revenue_period between @current_qtr_start_period and @current_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vmonz_cq_rev = isnull(sum(revenue),0)
from			#yearly_revenue
where			revenue_period between @current_qtr_start_period and @current_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vma_stlycq_rev = isnull(sum(revenue),0)
from			#yearly_revenue_stly
where			revenue_period between @prev_current_qtr_start_period and @prev_current_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmnz_stlycq_rev = isnull(sum(revenue),0)
from			#yearly_revenue_stly
where			revenue_period between @prev_current_qtr_start_period and @prev_current_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmoau_stlycq_rev = isnull(sum(revenue),0)
from			#yearly_revenue_stly
where			revenue_period between @prev_current_qtr_start_period and @prev_current_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vmonz_stlycq_rev = isnull(sum(revenue),0)
from			#yearly_revenue_stly
where			revenue_period between @prev_current_qtr_start_period and @prev_current_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vma_cy_rev = isnull(sum(revenue),0)
from			#yearly_revenue
where			revenue_period between @current_cy_start_period and @current_cy_end_period
and				branch_code <> 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmnz_cy_rev = isnull(sum(revenue),0)
from			#yearly_revenue
where			revenue_period between @current_cy_start_period and @current_cy_end_period
and				branch_code = 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmoau_cy_rev = isnull(sum(revenue),0)
from			#yearly_revenue
where			revenue_period between @current_cy_start_period and @current_cy_end_period
and				branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vmonz_cy_rev = isnull(sum(revenue),0)
from			#yearly_revenue
where			revenue_period between @current_cy_start_period and @current_cy_end_period
and				branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vma_stlycy_rev = isnull(sum(revenue),0)
from			#yearly_revenue_stly
where			revenue_period between @prev_current_cy_start_period and @prev_current_cy_end_period
and				branch_code <> 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmnz_stlycy_rev = isnull(sum(revenue),0)
from			#yearly_revenue_stly
where			revenue_period between @prev_current_cy_start_period and @prev_current_cy_end_period
and				branch_code = 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmoau_stlycy_rev = isnull(sum(revenue),0)
from			#yearly_revenue_stly
where			revenue_period between @prev_current_cy_start_period and @prev_current_cy_end_period
and				branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vmonz_stlycy_rev = isnull(sum(revenue),0)
from			#yearly_revenue_stly
where			revenue_period between @prev_current_cy_start_period and @prev_current_cy_end_period
and				branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vma_nq_rev = isnull(sum(revenue),0)
from			#yearly_revenue
where			revenue_period between @next_qtr_start_period and @next_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmnz_nq_rev = isnull(sum(revenue),0)
from			#yearly_revenue
where			revenue_period between @next_qtr_start_period and @next_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmoau_nq_rev = isnull(sum(revenue),0)
from			#yearly_revenue
where			revenue_period between @next_qtr_start_period and @next_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vmonz_nq_rev = isnull(sum(revenue),0)
from			#yearly_revenue
where			revenue_period between @next_qtr_start_period and @next_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vma_stlynq_rev = isnull(sum(revenue),0)
from			#yearly_revenue_stly
where			revenue_period between @prev_next_qtr_start_period and @prev_next_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmnz_stlynq_rev = isnull(sum(revenue),0)
from			#yearly_revenue_stly
where			revenue_period between @prev_next_qtr_start_period and @prev_next_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmoau_stlynq_rev = isnull(sum(revenue),0)
from			#yearly_revenue_stly
where			revenue_period between @prev_next_qtr_start_period and @prev_next_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vmonz_stlynq_rev = isnull(sum(revenue),0)
from			#yearly_revenue_stly
where			revenue_period between @prev_next_qtr_start_period and @prev_next_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vma_cq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @current_qtr_start_period and @current_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmnz_cq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @current_qtr_start_period and @current_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmoau_cq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @current_qtr_start_period and @current_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vmonz_cq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @current_qtr_start_period and @current_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vma_cy_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @current_cy_start_period and @current_cy_end_period
and				branch_code <> 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmnz_cy_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @current_cy_start_period and @current_cy_end_period
and				branch_code = 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmoau_cy_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @current_cy_start_period and @current_cy_end_period
and				branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vmonz_cy_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @current_cy_start_period and @current_cy_end_period
and				branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vma_nq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @next_qtr_start_period and @next_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmnz_nq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @next_qtr_start_period and @next_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmoau_nq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @next_qtr_start_period and @next_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vmonz_nq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @next_qtr_start_period and @next_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vma_stlycq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @prev_current_qtr_start_period and @prev_current_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmnz_stlycq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @prev_current_qtr_start_period and @prev_current_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmoau_stlycq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @prev_current_qtr_start_period and @prev_current_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vmonz_stlycq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @prev_current_qtr_start_period and @prev_current_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vma_stlycy_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @prev_current_cy_start_period and @prev_current_cy_end_period
and				branch_code <> 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmnz_stlycy_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @prev_current_cy_start_period and @prev_current_cy_end_period
and				branch_code = 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmoau_stlycy_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @prev_current_cy_start_period and @prev_current_cy_end_period
and				branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vmonz_stlycy_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @prev_current_cy_start_period and @prev_current_cy_end_period
and				branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vma_stlynq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @prev_next_qtr_start_period and @prev_next_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmnz_stlynq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @prev_next_qtr_start_period and @prev_next_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id in (2,3,5,9)

select			@vmoau_stlynq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @prev_next_qtr_start_period and @prev_next_qtr_end_period
and				branch_code <> 'Z'
and				business_unit_id not in (2,3,5,9)

select			@vmonz_stlynq_tar = isnull(sum(budget),0)
from			statrev_budgets
where			revenue_period between @prev_next_qtr_start_period and @prev_next_qtr_end_period
and				branch_code = 'Z'
and				business_unit_id not in (2,3,5,9)

insert into #results
values (
 	@delta_start,
	@delta_end,
	@delta_end_prev,
	@current_cy_start_period,
	@current_cy_end_period,
	@next_cy_start_period,
	@next_cy_end_period,
	@current_qtr_start_period,
	@current_qtr_end_period,
	@next_qtr_start_period,
	@next_qtr_end_period,
	@prev_current_cy_start_period,
	@prev_current_cy_end_period,
	@prev_current_qtr_start_period,
	@prev_current_qtr_end_period,
	@prev_next_qtr_start_period,
	@prev_next_qtr_end_period,
	@vma_book_cy_rev,
	@vmnz_book_cy_rev,
	@vmoau_book_cy_rev,
	@vmonz_book_cy_rev,
	@vma_book_ny_rev,
	@vmnz_book_ny_rev,
	@vmoau_book_ny_rev,
	@vmonz_book_ny_rev,
	@vma_book_cy_camps,
	@vmnz_book_cy_camps,
	@vmoau_book_cy_camps,
	@vmonz_book_cy_camps	,
	@vma_book_ny_camps,
	@vmnz_book_ny_camps,
	@vmoau_book_ny_camps,
	@vmonz_book_ny_camps	,
	@vma_cq_rev,
	@vmnz_cq_rev,
	@vmoau_cq_rev,
	@vmonz_cq_rev,
	@vma_cq_tar,
	@vmnz_cq_tar,
	@vmoau_cq_tar,
	@vmonz_cq_tar,
	@vma_stlycq_rev,
	@vmnz_stlycq_rev,
	@vmoau_stlycq_rev,
	@vmonz_stlycq_rev,
	@vma_stlycq_tar,
	@vmnz_stlycq_tar,
	@vmoau_stlycq_tar,
	@vmonz_stlycq_tar,
	@vma_cy_rev,
	@vmnz_cy_rev,
	@vmoau_cy_rev,
	@vmonz_cy_rev,
	@vma_cy_tar,
	@vmnz_cy_tar,
	@vmoau_cy_tar,
	@vmonz_cy_tar,
	@vma_stlycy_rev,
	@vmnz_stlycy_rev,
	@vmoau_stlycy_rev,
	@vmonz_stlycy_rev,
	@vma_stlycy_tar,
	@vmnz_stlycy_tar,
	@vmoau_stlycy_tar,
	@vmonz_stlycy_tar,
	@vma_nq_rev,
	@vmnz_nq_rev,
	@vmoau_nq_rev,
	@vmonz_nq_rev,
	@vma_nq_tar,
	@vmnz_nq_tar,
	@vmoau_nq_tar,
	@vmonz_nq_tar,
	@vma_stlynq_rev,
	@vmnz_stlynq_rev,
	@vmoau_stlynq_rev,
	@vmonz_stlynq_rev,
	@vma_stlynq_tar,
	@vmnz_stlynq_tar,
	@vmoau_stlynq_tar,
	@vmonz_stlynq_tar
)

select * from #results

return 0
GO
