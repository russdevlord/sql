/****** Object:  StoredProcedure [dbo].[p_film_prop_figures_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_prop_figures_report]
GO
/****** Object:  StoredProcedure [dbo].[p_film_prop_figures_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_film_prop_figures_report]  	@mode		int,
											@branch_code	char(2),
                                        	@report_period	datetime
as

/*
 * Declare Procedure Variables
 */

declare @error          		    int,
        @rowcount					int,
		@figure_id				    int,
		@last_campaign_no	    	int,
		@nett_contract_value	    money,
        @campaign_no				int,
        @upd						tinyint,
        @npu_stat					char(1),
        @req_count			    	smallint

/*
 * Create Temporary Tables
 */

create table #figures
(
	figure_id							int			    null,
	campaign_no							int			    null,
	branch_code							char(2)			null,
	rep_id								int			    null,
	origin_period						datetime		null,
	creation_period					    datetime		null,
	release_period						datetime		null,
	figure_type							char(1)			null,
	figure_status						char(1)			null,
	figure_category				    	smallint		null,
	gross_amount						money			null,
	nett_amount							money			null,
	comm_amount							money			null,
	figure_reason						varchar(50)		null,
	figure_official					    char(1)			null,
	product_desc						varchar(50)		null,
	nett_contract_value				    money			null,
	first_name							varchar(30)		null,
	last_name							varchar(30)		null,
	report_period_end					datetime		null,
	report_period_no					int			    null,
	status								char(1)			null,
	total_contract_value				money			null,
	area_id								int		    	null,
	team_id								int		    	null,
	contract_received					char(1)			null,
    business_unit_id                     	int		        null
)



/*
 * Select Figures
 */

if @mode = 1 
begin
	insert into #figures
   	     select film_figures.figure_id,
				film_figures.campaign_no,
				film_figures.branch_code,
				film_figures.rep_id,
				film_figures.origin_period,
				film_figures.creation_period,
				film_figures.release_period,
				film_figures.figure_type,
				film_figures.figure_status,
				film_figures.figure_category,
				film_figures.gross_amount,
				film_figures.nett_amount,
				film_figures.comm_amount,
				film_figures.figure_reason,
				film_figures.figure_official,
				film_campaign.product_desc,
				film_campaign.confirmed_cost,
				sales_rep.first_name,
				sales_rep.last_name,
				film_reporting_period.report_period_end,
				film_reporting_period.report_period_no,
				film_reporting_period.status,
				0,
				film_figures.area_id,
				film_figures.team_id,
				film_campaign.contract_received,
                film_campaign.business_unit_id
		   from film_figures,
				film_campaign,
				sales_rep,
				film_reporting_period
		  where film_figures.campaign_no = film_campaign.campaign_no and
				film_figures.rep_id = sales_rep.rep_id and
				film_reporting_period.report_period_end = @report_period and
				( ( film_figures.release_period = film_reporting_period.report_period_end and
				( ( film_figures.figure_type <> 'D' and
				film_figures.figure_type <> 'X' and	
				film_figures.figure_status <> 'P' ) or
				( film_figures.figure_type <> 'D' and
				film_figures.figure_type <> 'X'  ) ) ) or
				( film_figures.creation_period <= film_reporting_period.report_period_end and
				film_figures.release_period > film_reporting_period.report_period_end ) )
end
else if @mode = 2
begin
	insert into #figures
	     select film_figures.figure_id,
				film_figures.campaign_no,
				film_figures.branch_code,
				film_figures.rep_id,
				film_figures.origin_period,
				film_figures.creation_period,
				film_figures.release_period,
				film_figures.figure_type,
				film_figures.figure_status,
				film_figures.figure_category,
				film_figures.gross_amount,
				film_figures.nett_amount,
				film_figures.comm_amount,
				film_figures.figure_reason,
				film_figures.figure_official,
				film_campaign.product_desc,
				film_campaign.confirmed_cost,
				sales_rep.first_name,
				sales_rep.last_name,
				film_reporting_period.report_period_end,
				film_reporting_period.report_period_no,
				film_reporting_period.status,
				0,
				film_figures.area_id,
				film_figures.team_id,
				film_campaign.contract_received,
                film_campaign.business_unit_id
		   from film_figures,
				film_campaign,
				sales_rep,
				film_reporting_period
		  where film_figures.campaign_no = film_campaign.campaign_no and
				film_figures.rep_id = sales_rep.rep_id and
				film_reporting_period.report_period_end = @report_period and
				film_figures.branch_code = @branch_code and
				( ( film_figures.release_period = film_reporting_period.report_period_end and
				( ( film_figures.figure_type <> 'D' and
				film_figures.figure_type <> 'X' and	
				film_figures.figure_status <> 'P' ) or
				( film_figures.figure_type <> 'D' and
				film_figures.figure_type <> 'X'  ) ) ) or
				( film_figures.creation_period <= film_reporting_period.report_period_end and
				film_figures.release_period > film_reporting_period.report_period_end ) )
end

select @last_campaign_no = 0

 declare figures_csr cursor static for
  select figure_id, 
		 campaign_no,
		 nett_contract_value
    from #figures
order by campaign_no

open figures_csr
fetch figures_csr into @figure_id, @campaign_no, @nett_contract_value
while(@@fetch_status = 0)
begin
	
	if @last_campaign_no <> @campaign_no
	begin
		update #figures
		   set total_contract_value = nett_contract_value
		 where figure_id = @figure_id
	end
	
	select @last_campaign_no = @campaign_no

	fetch figures_csr into @figure_id, @campaign_no, @nett_contract_value
end

close figures_csr 
deallocate figures_csr 

/*
 * Return
 */

 select figure_id,
        campaign_no,
        branch_code,
        rep_id,
        origin_period,
        creation_period,
        release_period,
        figure_type,
        figure_status,
        figure_category,
        gross_amount,
        nett_amount,
        comm_amount,
        figure_reason,
        figure_official,
        product_desc,
        nett_contract_value,
        first_name,
        last_name,
        report_period_end,
        report_period_no,
        status,
        total_contract_value,
        area_id,
        team_id,
        contract_received,
        business_unit_id
   from #figures

return 0
GO
