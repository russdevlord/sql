/****** Object:  StoredProcedure [dbo].[p_team_monthly_film_figures]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_team_monthly_film_figures]
GO
/****** Object:  StoredProcedure [dbo].[p_team_monthly_film_figures]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[p_team_monthly_film_figures]	    @report_period_end	        datetime,
											@branch_code			    char(2),
											@mode						int,
											@include_reps			    char(1),
											@team_id					int
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @error          			int,
        @report_period_no			int,
        @year_start					datetime,
        @report_period_status	    char(1),
        @report_period				datetime,	
        @first_name					varchar(30),
        @last_name					varchar(30),
        @film_target				money,
        @film_target_ytd			money,
        @prev_year_nett			    money,
        @prev_year_nett_ytd		    money,
        @prev_year_gross			money,
        @prev_year_gross_ytd		money,
        @release_date				datetime,
        @slide_figures				money,
        @slide_figures_ytd		    money,
        @nett						money,
        @nett_ytd					money,
        @gross						money,
        @gross_ytd					money,
        @writebacks					money,
        @writebacks_ytd			    money,
        @rep_id						int,
        @open_rep_csr 				int,
        @report_heading			    varchar(100),
        @page_heading				varchar(100),
        @team_branch				char(2),
        @team_name					varchar(50),
        @adjustments				money,
        @country_code				char(2),
        @rep_status					char(1),
        @team_code					char(3),
        @area_code					char(3),
        @leader_id					int,
        @year_end					datetime,
        @monthly_target			    money,
        @yearly_target				money,
		@year_type					char(1),
		@cnt						integer




/*
 * Create Temporary Tables
 */

create table #monthly_figures
(
	film_target				money					null,
	film_target_ytd			money					null,
	prev_year_nett			money					null,
	prev_year_nett_ytd		money					null,
	prev_year_gross			money					null,
	prev_year_gross_ytd		money					null,
	release_date			datetime				null,
	slide_figures			money					null,
	slide_figures_ytd		money					null,
	rep_id					int				        null,
	first_name				varchar(30)			    null,
	last_name				varchar(30)			    null,
	nett					money					null,
	nett_ytd				money					null,
	gross					money					null,
	gross_ytd				money					null,
	writebacks				money					null,
	writebacks_ytd			money					null,
	branch_code				char(2)				    null,
	country_code			char(2)				    null,
	report_period			int				        null,
	report_heading			varchar(100)		    null,
	page_heading			varchar(100)		    null,
	team_id					int				        null,
	team_name				varchar(50)			    null,
	team_code				varchar(3)			    null,
	area_code				varchar(3)			    null,
	leader_id				int				        null,
	monthly_target			money					null,
	yearly_target			money					null
)

create table #reps
(
	rep_id		int		null
)

/*
 *  Iniatialise values for reporting periods
 */

if datepart(month, @report_period_end) = 6
	begin
		select      @year_start = financial_year.finyear_start,
		            @year_end = financial_year.finyear_end
		from        film_reporting_period,
		            financial_year
		where       film_reporting_period.finyear_end = financial_year.finyear_end and  
		            film_reporting_period.report_period_end = @report_period_end
		
		select @error = @@error
		if ( @error !=0 )
		begin
			return -1
		end

		select @year_type = 'F'
	end
else  -- otherwise work off calendar year
	begin
		select      @year_start = calendar_start,
		            @year_end = calendar_end
		from        calendar_year
		where       dbo.f_is_date_within_year(@report_period_end, calendar_end) = 1
		
		select @error = @@error
		if ( @error !=0 )
			return -1

		select @year_type = 'C'
	end 


if @mode = 2
begin
    select      @team_branch = team_branch 
    from        film_sales_team
    where       team_id = @team_id
end

	/*
	 * Declare Cursor to loop over all branches is mode = 1
	 */ 
	if @mode = 0 
	begin
	    declare     branch_csr cursor static for 
	    select      branch_code
	    from        branch
	    where       branch_code = @branch_code
	    order by    branch_code asc
	    for         read only
	end
	else if @mode = 1
	begin
	    declare     branch_csr cursor static for 
	    select      branch_code
	    from        branch
	    order by    branch_code asc
	    for         read only
	end
	else if @mode = 2
	begin
	    declare     branch_csr cursor static for 
	    select      branch_code
	    from        branch
	    where       branch_code = @team_branch
	    order by    branch_code asc
	    for         read only
	end

    open branch_csr
    fetch branch_csr into @branch_code
    while(@@fetch_status = 0)
    begin

        select      @country_code = country_code
        from        branch
        where       branch_code = @branch_code

		/*
		 * Declare Cursor to loop over all branches is mode = 1
		 */ 
		if @mode = 0 
		begin
		    declare     team_csr cursor static for 
		    select      team_id,
		                team_name
		    from        film_sales_team
		    where       team_branch = @branch_code
		    order by    team_id asc
		    for         read only
		end
		else if @mode = 1
		begin
		    declare     team_csr cursor static for 
		    select      team_id,
		                team_name
		    from        film_sales_team
		    where       team_branch = @branch_code
		    order by    team_id asc
		    for         read only
		end
		else if @mode = 2
		begin
		    declare     team_csr cursor static for 
		    select      team_id,
		                team_name
		    from        film_sales_team
		    where       team_id = @team_id and
		                team_branch = @branch_code
		    order by    team_id asc
		    for         read only
		end

	    open team_csr
	    fetch team_csr into @team_id, @team_name
	    while(@@fetch_status = 0)
	    begin
		    select   @film_target_ytd = 0,
			         @prev_year_nett_ytd = 0,
			         @prev_year_gross_ytd = 0,
			         @slide_figures_ytd = 0,
			         @nett_ytd = 0,
			         @writebacks_ytd = 0,
			         @gross_ytd = 0
	
			/*
			 * Declare Cursor to loop over report_periods to date for the year
			 */ 
			declare     report_period_csr cursor static for 
			select      report_period_end,
			            report_period_no,
			            status
			from        film_reporting_period 
			where       report_period_end <= @report_period_end and 
			            report_period_end >= @year_start
			order by    report_period_end asc
			for         read only

		    open report_period_csr
		    fetch report_period_csr into @report_period, @report_period_no, @report_period_status
		    while (@@fetch_status = 0)
		    begin		
                select      @film_target = sum(target_amount)
                from        film_team_targets
                where       sales_period = @report_period and
                            team_id = @team_id

                select      @leader_id = min(leader_id)
                from        film_team_targets
                where       sales_period = @report_period and
                            team_id = @team_id

                select      @film_target_ytd = isnull(@film_target, 0) + isnull(@film_target_ytd, 0)

                select      @prev_year_nett = sum(nett_amount)
                from        film_figures,
                            film_campaign
                where       release_period = dateadd(mm, -12, @report_period)
                and            team_id = @team_id
				and		 	film_campaign.campaign_no = film_figures.campaign_no
				and         figure_official = 'Y'

                select      @prev_year_nett_ytd = isnull(@prev_year_nett,0) + isnull(@prev_year_nett_ytd,0)

                select      @prev_year_gross = sum(gross_amount)
                from        film_figures,
                            film_campaign
                where       release_period = dateadd(mm, -12, @report_period) and
                            team_id = @team_id and
                            figure_official = 'Y'

                select      @prev_year_gross_ytd = isnull(@prev_year_gross,0) + isnull(@prev_year_gross_ytd,0)

                SELECT      @monthly_target = null
                SELECT      @yearly_target = null

				if @year_type = 'F'
					begin
		                select      @monthly_target = monthly_target,
		                            @yearly_target = annual_target
		                from        film_team_year
		                where       team_id = @team_id and
		                            finyear_end = @year_end
					end
				else
					begin
						select	@yearly_target = isnull(sum(target_amount), 0)
						from	film_team_targets, film_reporting_period
						where	film_team_targets.report_period_end = film_reporting_period.report_period_end
						and		film_team_targets.team_id = @team_id
						and		film_reporting_period.calendar_end = @year_end															
						
	
						select	@cnt = count(target_amount)	
						from	film_team_targets, film_reporting_period
						where	film_team_targets.report_period_end = film_reporting_period.report_period_end
						and		film_team_targets.team_id = @team_id
						and		film_reporting_period.calendar_end = @year_end															
						and		isnull(film_team_targets.target_amount, 0) <> 0
						
						if @cnt > 0 
							select	@monthly_target = @yearly_target / @cnt 
					end

                delete      #reps

                insert into #reps
                select      sr.rep_id
                from        sales_rep sr,
                            film_figures ff,
                            film_campaign
                where       ff.rep_id = sr.rep_id and
                            ff.release_period = @report_period and 
                            ff.team_id = @team_id
                and         FF.campaign_no = film_campaign.campaign_no 
                union
                select      sr.rep_id
                from        sales_rep sr,
                            rep_film_targets ff
                where       ff.rep_id = sr.rep_id and
                            ff.report_period = @report_period and 
                            ff.target_amount > 0 and
                            ff.team_id = @team_id


                select      @slide_figures = sum(nett_amount)
                from        slide_figures
                where       release_period <= @report_period and
                            release_period >= dateadd(mm, -1, @report_period) and
                            figure_official = 'Y' and
                            rep_id in ( select  rep_id 
                                        from    #reps  )

                select      @slide_figures_ytd = isnull(@slide_figures, 0) + isnull(@slide_figures_ytd,0)

                select      @nett = sum(nett_amount)
                from        film_figures,
                            film_campaign
                where       figure_type = 'C' and
                            release_period = @report_period and
                            team_id = @team_id and
                            figure_official = 'Y'
                and         film_figures.campaign_no = film_campaign.campaign_no 

                select      @adjustments = sum(nett_amount)
                from        film_figures,
                            film_campaign
                where       figure_type <> 'C' and
                            release_period = @report_period and
                            team_id = @team_id and
                            nett_amount > 0 and
                            figure_official = 'Y'
                and         film_figures.campaign_no = film_campaign.campaign_no 

                select      @writebacks = sum(nett_amount)
                from        film_figures,
                            film_campaign
                where       figure_type <> 'C' and
                            release_period = @report_period and
                            team_id = @team_id and
                            nett_amount < 0 and
                            figure_official = 'Y'
                and         film_figures.campaign_no = film_campaign.campaign_no 

                select      @nett_ytd = isnull(@nett,0) + isnull(@adjustments, 0) + isnull(@writebacks, 0) + isnull(@nett_ytd,0)

                select      @report_heading = 'Monthly Film Figures - Supervisor'

                select      @page_heading = null

                select      @page_heading = @team_name
		
			    if @report_period_status = 'X'
			    begin
				    insert into #monthly_figures
					    (film_target,
					    film_target_ytd,
					    prev_year_nett,
					    prev_year_nett_ytd,
					    prev_year_gross,
					    prev_year_gross_ytd,
					    release_date,
					    slide_figures,
					    slide_figures_ytd,
					    rep_id,
					    first_name,
					    last_name,
					    nett,
					    nett_ytd,
					    gross,
					    gross_ytd,
					    writebacks,
					    writebacks_ytd,
					    branch_code,
					    country_code,
					    report_period,
					    report_heading,
					    page_heading,
					    team_id,
					    team_name,
					    team_code,
					    area_code,
					    leader_id,
					    monthly_target,
					    yearly_target
					    ) values
					    (isnull(@adjustments,0),
					    isnull(@film_target_ytd,0),
					    isnull(@prev_year_nett,0),
					    isnull(@prev_year_nett_ytd,0),
					    isnull(@prev_year_gross,0),
					    isnull(@prev_year_gross_ytd,0),
					    @report_period,
					    isnull(@slide_figures,0),
					    isnull(@slide_figures_ytd,0),
					    @rep_id,
					    'aaaaaa',
					    'aaaaaa',
					    isnull(@nett,0),
					    isnull(@nett_ytd,0),
					    isnull(@gross,0),
					    isnull(@gross_ytd,0),
					    isnull(@writebacks,0),
					    isnull(@writebacks_ytd,0),
					    @branch_code,	
					    @country_code,
					    @report_period_no,
					    @report_heading,
					    @page_heading,
					    @team_id,
					    @team_name,
					    @team_code,
					    @area_code,
					    @leader_id,
					    isnull(@monthly_target,0),
					    isnull(@yearly_target,0)
					    )
			    end
			    else
			    begin
				    insert into #monthly_figures
					    (film_target,
					    film_target_ytd,
					    prev_year_nett,
					    prev_year_nett_ytd,
					    prev_year_gross,
					    prev_year_gross_ytd,
					    release_date,
					    slide_figures,
					    slide_figures_ytd,
					    rep_id,
					    first_name,
					    last_name,
					    nett,
					    nett_ytd,
					    gross,
					    gross_ytd,
					    writebacks,
					    writebacks_ytd,
					    branch_code,
					    country_code,
					    report_period,
					    report_heading,
					    page_heading,
					    team_id,
					    team_name,
					    team_code,
					    area_code,
					    leader_id,
					    monthly_target,
					    yearly_target
					    ) values
					    (null,--@adjustments,
					    isnull(@film_target_ytd,0),
					    isnull(@prev_year_nett,0),
					    isnull(@prev_year_nett_ytd,0),
					    isnull(@prev_year_gross,0),
					    isnull(@prev_year_gross_ytd,0),
					    @report_period,
					    null,--@slide_figures,
					    null,--@slide_figures_ytd,
					    @rep_id,
					    'aaaaaa',
					    'aaaaaa',
					    null,--@nett,
					    null,--@nett_ytd,
					    null,--@gross,
					    null,--@gross_ytd,
					    null,--@writebacks,
					    null,--@writebacks_ytd,
					    @branch_code,
					    @country_code,
					    @report_period_no,
					    @report_heading,
					    @page_heading,
					    @team_id,
					    @team_name,
					    @team_code,
					    @area_code,
					    @leader_id,
					    isnull(@monthly_target,0),
					    isnull(@yearly_target,0)
					    )
			    end

			    fetch report_period_csr into @report_period, @report_period_no, @report_period_status
		    end
		    close report_period_csr
		    deallocate report_period_csr
	
		    if @include_reps = 'Y'
		    begin

/*
 * Declare Rep cursor static for include_reps = 0
 */
				if @include_reps = 'Y'
				begin
				    declare         sales_rep_csr cursor static for 
				    select          sr.rep_id,
				                    sr.first_name,
				                    sr.last_name,
				                    sr.status
				    from            sales_rep sr,
				                    film_figures ff
				    where           ff.rep_id = sr.rep_id and
				                    ff.release_period <= @report_period_end and 
				                    ff.release_period >= @year_start and
				                    ff.team_id = @team_id
				    group by        sr.rep_id,
				                    sr.first_name,
				                    sr.last_name,
				                    sr.status,
				                    ff.branch_code
				    union
				    select          sr.rep_id,
				                    sr.first_name,
				                    sr.last_name,
				                    sr.status
				    from            sales_rep sr,
				                    rep_film_targets ff
				    where           ff.rep_id = sr.rep_id and
				                    ff.report_period <= @report_period_end and 
				                    ff.report_period >= @year_start and
				                    ff.target_amount > 0 and
				                    ff.team_id = @team_id
				    group by        sr.rep_id,
				                    sr.first_name,
				                    sr.last_name,
				                    sr.status,
				                    ff.branch_code
				    order by        sr.first_name,
				                    sr.last_name
				
				    select @open_rep_csr = 1
				end
				else
				begin
					select @open_rep_csr = 0
				end

			    open sales_rep_csr
			    fetch sales_rep_csr into @rep_id, @first_name, @last_name, @rep_status
			    while (@@fetch_status = 0)
			    begin
					    select  @film_target_ytd = 0,
							    @prev_year_nett_ytd = 0,
							    @prev_year_gross_ytd = 0,
							    @slide_figures_ytd = 0,
							    @nett_ytd = 0,
							    @writebacks_ytd = 0,
							    @gross_ytd = 0
			
					/*
					 * Declare Cursor to loop over report_periods to date for the year
					 */ 
					declare     report_period_csr cursor static for 
					select      report_period_end,
					            report_period_no,
					            status
					from        film_reporting_period 
					where       report_period_end <= @report_period_end and 
					            report_period_end >= @year_start
					order by    report_period_end asc
					for         read only

				    open report_period_csr
				    fetch report_period_csr into @report_period, @report_period_no, @report_period_status
				    while (@@fetch_status = 0)
				    begin
			
                        select      @film_target = sum(target_amount)
                        from        rep_film_targets
                        where       rep_id = @rep_id and
                                    report_period = @report_period and
                                    team_id = @team_id

                        select      @film_target_ytd = isnull(@film_target, 0) + isnull(@film_target_ytd, 0)

                        select      @leader_id = min(leader_id)
                        from        film_team_targets
                        where       sales_period = @report_period and
                                    team_id = @team_id

                        select      @team_code = null

                        select      @team_code = film_sales_team.team_code
                        from        rep_film_targets,
                                    film_sales_team
                        where       rep_film_targets.rep_id = @rep_id and
                                    rep_film_targets.report_period = @report_period and
                                    rep_film_targets.team_id = @team_id and
                                    rep_film_targets.team_id = film_sales_team.team_id

                        select      @area_code = null

                        select      @area_code = film_sales_area.area_code
                        from        rep_film_targets,
                                    film_sales_area
                        where       rep_film_targets.rep_id = @rep_id and
                                    rep_film_targets.report_period = @report_period and
                                    rep_film_targets.area_id = film_sales_area.area_id

                        select      @prev_year_nett = sum(nett_amount)
                        from        film_figures,
                                    film_campaign
                        where       film_figures.rep_id = @rep_id and
                                    release_period = dateadd(mm, -12, @report_period) and
                                    team_id = @team_id and
                                    figure_official = 'Y'
                        and         film_figures.campaign_no = film_campaign.campaign_no 

                        select      @prev_year_nett_ytd = isnull(@prev_year_nett,0) + isnull(@prev_year_nett_ytd,0)

                        select      @prev_year_gross = sum(gross_amount)
                        from        film_figures,
                                    film_campaign
                        where       film_figures.rep_id = @rep_id and
                                    release_period = dateadd(mm, -12, @report_period) and
                                    team_id = @team_id and
                                    figure_official = 'Y'
                        and         film_figures.campaign_no = film_campaign.campaign_no 

                        select      @prev_year_gross_ytd = isnull(@prev_year_gross,0) + isnull(@prev_year_gross_ytd,0)

                        select      @slide_figures = sum(nett_amount)
                        from        slide_figures
                        where       rep_id = @rep_id and
                                    release_period <= @report_period and
                                    figure_official = 'Y' and
                                    release_period >= dateadd(mm, -1, @report_period) 

                        select      @slide_figures_ytd = isnull(@slide_figures, 0) + isnull(@slide_figures_ytd,0)

                        select      @nett = sum(nett_amount)
                        from        film_figures,
                                    film_campaign
                        where       film_figures.rep_id = @rep_id and
                                    figure_type = 'C' and
                                    release_period = @report_period and
                                    team_id = @team_id and
                                    figure_official = 'Y'
                        and         film_figures.campaign_no = film_campaign.campaign_no 

                        select      @adjustments = sum(nett_amount)
                        from        film_figures,
                                    film_campaign
                        where       film_figures.rep_id = @rep_id and
                                    figure_type <> 'C' and
                                    release_period = @report_period and
                                    team_id = @team_id and
                                    nett_amount > 0 and
                                    figure_official = 'Y'
                        and         film_figures.campaign_no = film_campaign.campaign_no 

                        select      @writebacks = sum(nett_amount)
                        from        film_figures,
                                    film_campaign
                        where       film_figures.rep_id = @rep_id and
                                    figure_type <> 'C' and
                                    release_period = @report_period and
                                    team_id = @team_id and
                                    nett_amount < 0 and
                                    figure_official = 'Y'
                        and         film_figures.campaign_no = film_campaign.campaign_no 

                        SELECT      @monthly_target = null
                        SELECT      @yearly_target = null
						
						if @year_type = 'F'
							begin
		                        select      @monthly_target = monthly_target,
		                                    @yearly_target = annual_target
		                        from        film_rep_year
		                        where       rep_id = @rep_id and
		                                    finyear_end = @year_end
							end
						else
							begin
								select	@yearly_target = isnull(sum(target_amount), 0)
								from	rep_film_targets, film_reporting_period
								where	rep_film_targets.report_period = film_reporting_period.report_period_end
								and		rep_film_targets.rep_id = @rep_id
								and		film_reporting_period.calendar_end = @year_end															
								
			
								select	@cnt = count(target_amount)	
								from	rep_film_targets, film_reporting_period
								where	rep_film_targets.report_period = film_reporting_period.report_period_end
								and		rep_film_targets.rep_id = @rep_id
								and		film_reporting_period.calendar_end = @year_end															
								and		isnull(rep_film_targets.target_amount, 0) <> 0
								
								if @cnt > 0 
									select	@monthly_target = @yearly_target / @cnt 
							end

                        select      @nett_ytd = isnull(@nett,0) + isnull(@adjustments, 0) + isnull(@writebacks, 0) + isnull(@nett_ytd,0)

                        select      @report_heading = 'Monthly Film Figures - Supervisor'

                        select      @page_heading = null

					    if @rep_status = 'X'
						    select @page_heading = '(Terminated) ' + rtrim(@first_name) + ' ' + rtrim(@last_name) + ' - ' + rtrim(@team_name)
					    else
						    select @page_heading = @page_heading + rtrim(@first_name) + ' ' + rtrim(@last_name) + ' - ' + rtrim(@team_name)
	
				    if @report_period_status = 'X'
				    begin
					    insert into #monthly_figures
						    (film_target,
						    film_target_ytd,
						    prev_year_nett,
						    prev_year_nett_ytd,
						    prev_year_gross,
						    prev_year_gross_ytd,
						    release_date,
						    slide_figures,
						    slide_figures_ytd,
						    rep_id,
						    first_name,
						    last_name,
						    nett,
						    nett_ytd,
						    gross,
						    gross_ytd,
						    writebacks,
						    writebacks_ytd,
						    branch_code,
						    country_code,
						    report_period,
						    report_heading,
						    page_heading,
						    team_id,
						    team_name,
						    team_code,
						    area_code,
						    leader_id,
						    monthly_target,
						    yearly_target
                            
						    ) values
						    (isnull(@adjustments,0),
						    isnull(@film_target_ytd,0),
						    isnull(@prev_year_nett,0),
						    isnull(@prev_year_nett_ytd,0),
						    isnull(@prev_year_gross,0),
						    isnull(@prev_year_gross_ytd,0),
						    @report_period,
						    isnull(@slide_figures,0),
						    isnull(@slide_figures_ytd,0),
						    @rep_id,
						    @first_name,
						    @last_name,
						    isnull(@nett,0),
						    isnull(@nett_ytd,0),
						    isnull(@gross,0),
						    isnull(@gross_ytd,0),
						    isnull(@writebacks,0),
						    isnull(@writebacks_ytd,0),
						    @branch_code,
						    @country_code,
						    @report_period_no,
						    @report_heading,
						    @page_heading,
						    @team_id,
						    @team_name,
						    @team_code,
						    @area_code,
						    @leader_id,
						    isnull(@monthly_target,0),
						    isnull(@yearly_target,0)
						    )
				    end
				    else
				    begin
					    insert into #monthly_figures
						    (film_target,
						    film_target_ytd,
						    prev_year_nett,
						    prev_year_nett_ytd,
						    prev_year_gross,
						    prev_year_gross_ytd,
						    release_date,
						    slide_figures,
						    slide_figures_ytd,
						    rep_id,
						    first_name,
						    last_name,
						    nett,
						    nett_ytd,
						    gross,
						    gross_ytd,
						    writebacks,
						    writebacks_ytd,
						    branch_code,
						    country_code,
						    report_period,
						    report_heading,
						    page_heading,
						    team_id,
						    team_name,
						    team_code,
						    area_code,
						    leader_id,
						    monthly_target,
						    yearly_target
						    ) values
						    (null,--@adjustments,
						    isnull(@film_target_ytd,0),
						    isnull(@prev_year_nett,0),
						    isnull(@prev_year_nett_ytd,0),
						    isnull(@prev_year_gross,0),
						    isnull(@prev_year_gross_ytd,0),
						    @report_period,
						    null,--@slide_figures,
						    null,--@slide_figures_ytd,
						    @rep_id,
						    @first_name,
						    @last_name,
						    null,--@nett,
						    null,--@nett_ytd,
						    null,--@gross,
						    null,--@gross_ytd,
						    null,--@writebacks,
						    null,--@writebacks_ytd,
						    @branch_code,
						    @country_code,
						    @report_period_no,
						    @report_heading,
						    @page_heading,
						    @team_id,
						    @team_name,
						    @team_code,
						    @area_code,
						    @leader_id,
						    isnull(@monthly_target,0),
						    isnull(@yearly_target,0)
						    )
				    end

			     
					    fetch report_period_csr into @report_period, @report_period_no, @report_period_status
				    end
				    close report_period_csr
				    deallocate report_period_csr
				    fetch sales_rep_csr into @rep_id, @first_name, @last_name, @rep_status
			    end
			
			    close sales_rep_csr 
			    deallocate sales_rep_csr 
		    end
		    fetch team_csr into @team_id, @team_name
	    end
	    close team_csr
	    deallocate team_csr
	    fetch branch_csr into @branch_code
    end
    
    close branch_csr
    deallocate branch_csr

/*
 * Return
 */

select film_target,
		 film_target_ytd,
		 prev_year_nett,
		 prev_year_nett_ytd,
		 prev_year_gross,
		 prev_year_gross_ytd,
		 release_date,
		 slide_figures,
		 slide_figures_ytd,
		 rep_id,
		 first_name,
		 last_name,
		 nett,
		 nett_ytd,
		 gross,
		 gross_ytd,
		 writebacks,
		 writebacks_ytd,
		 branch_code,
		 country_code,
		 report_period,
		 report_heading,
		 page_heading,
		 team_id,
		 team_name,
		 team_code,
		 area_code,
		 leader_id,
		 monthly_target,
		 yearly_target
  from #monthly_figures
order by team_id,
			first_name,
			last_name,
			release_date
			
return 0
GO
