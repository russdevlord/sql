/****** Object:  StoredProcedure [dbo].[p_country_monthly_film_figures]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_country_monthly_film_figures]
GO
/****** Object:  StoredProcedure [dbo].[p_country_monthly_film_figures]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_country_monthly_film_figures]   @report_period_end	    datetime,
											 @country_code			char(1),
											 @mode					int,
											 @include_reps			char(1)
as

/*
 * Declare Procedure Variables
 */

declare @error          			int,
        @report_period_no			int,
        @year_start				datetime,
        @report_period_status	    char(1),
        @report_period				datetime,	
        @first_name					varchar(30),
        @last_name					varchar(30),
        @film_target				money,
        @film_target_ytd			money,
        @prev_year_nett		    	money,
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
        @branch_code				char(2),
        @open_rep_csr 				int,
        @report_heading			    varchar(100),
        @page_heading				varchar(100),
        @adjustments				money,
        @year_end				datetime,
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
	report_period			int				        null,
	country_code			char(1)				    null,
	report_heading			varchar(100)		    null,
	page_heading			varchar(100)		    null,
	monthly_target			money					null,	
	yearly_target			money					null
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
		where       (film_reporting_period.finyear_end = financial_year.finyear_end)  
		and         ((film_reporting_period.report_period_end = @report_period_end))
		
		select @error = @@error
		if ( @error !=0 )
		begin
			return -1
		end

		select @year_type = 'F'

	end
else
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
	

/*
 * Open cursor and fill get values
 */

select      @film_target_ytd = 0,
		    @prev_year_nett_ytd = 0,
		    @prev_year_gross_ytd = 0,
		    @slide_figures_ytd = 0,
		    @nett_ytd = 0,
		    @writebacks_ytd = 0,
		    @gross_ytd = 0

    declare     country_csr cursor static for 
    select      country_code
    from        country
    where        country_code = (case when @mode = 0 then @country_code else country_code end)
    order by    country_code asc
    for         read only

    open country_csr 
    fetch country_csr into @country_code
    while(@@fetch_status = 0)
    begin

        select  @film_target_ytd = 0,
                @prev_year_nett_ytd = 0,
                @prev_year_gross_ytd = 0,
                @slide_figures_ytd = 0,
                @nett_ytd = 0,
                @writebacks_ytd = 0,
                @gross_ytd = 0

		declare     report_period_csr cursor static for 
		select      report_period_end, 
		            report_period_no,
		            status
		from        film_reporting_period 
		where       report_period_end <= @report_period_end and 
		            dbo.f_is_date_within_year(report_period_end, @year_end) = 1
		order by    report_period_end asc
		for         read only

	    open report_period_csr
	    fetch report_period_csr into @report_period, @report_period_no, @report_period_status
	    while (@@fetch_status = 0)
	    begin
	
                select  @film_target = sum(target_amount)
                from    branch_film_targets
                where   report_period = @report_period and
                        branch_code in (select branch_code from branch where country_code = @country_code) 
	
			    select  @film_target_ytd = isnull(@film_target, 0) + isnull(@film_target_ytd, 0)
	
                select  @prev_year_nett = sum(nett_amount)
                from    film_figures,
                        film_campaign
                where   release_period = dateadd(mm, -12, @report_period) and
                        film_campaign.branch_code in (select branch_code from branch where country_code = @country_code) 
                and     film_figures.campaign_no = film_campaign.campaign_no 

                select  @prev_year_nett_ytd = isnull(@prev_year_nett,0) + isnull(@prev_year_nett_ytd,0)

                select  @prev_year_gross = sum(gross_amount)
                from    film_figures,
                        film_campaign
                where   release_period = dateadd(mm, -12, @report_period) and
                        film_campaign.branch_code in (select branch_code from branch where country_code = @country_code) 
                and     film_figures.campaign_no = film_campaign.campaign_no 

                select  @prev_year_gross_ytd = isnull(@prev_year_gross,0) + isnull(@prev_year_gross_ytd,0)

                select  @slide_figures = null
                select  @slide_figures_ytd = null

                select  @nett = sum(nett_amount)
                from    film_figures,
                        film_campaign
                where   figure_type = 'C' and
                        release_period = @report_period and
                        film_campaign.branch_code in (select branch_code from branch where country_code = @country_code) 
                and     film_figures.campaign_no = film_campaign.campaign_no 

                select  @adjustments = sum(nett_amount)
                from    film_figures,
                        film_campaign
                where   figure_type <> 'C' and
                        release_period = @report_period and
                        nett_amount > 0 and 
                        film_campaign.branch_code in (select branch_code from branch where country_code = @country_code) 
                and     film_figures.campaign_no = film_campaign.campaign_no 

                select  @writebacks = sum(nett_amount)
                from    film_figures,
                        film_campaign
                where   figure_type <> 'C' and
                        release_period = @report_period and
                        nett_amount < 0 and
                        film_campaign.branch_code in (select branch_code from branch where country_code = @country_code) 
                and     film_figures.campaign_no = film_campaign.campaign_no 

                SELECT  @monthly_target = null
                SELECT  @yearly_target = null

				if @year_type = 'F'
	                select  @monthly_target = sum(monthly_target),
	                        @yearly_target = sum(annual_target)
	                from    film_branch_year
	                where   finyear_end = @year_end and
	                        branch_code in (select branch_code from branch where country_code = @country_code)
				else
					begin
						select	@yearly_target = isnull(sum(target_amount), 0)
						from	branch_film_targets, film_reporting_period
						where	branch_film_targets.report_period = film_reporting_period.report_period_end
						and		branch_film_targets.branch_code in (select branch_code from branch where country_code = @country_code)
						and		film_reporting_period.calendar_end = @year_end															
						
	
						select	@cnt = count(distinct branch_film_targets.report_period)	
						from	branch_film_targets, film_reporting_period
						where	branch_film_targets.report_period = film_reporting_period.report_period_end
						and		branch_film_targets.branch_code in (select branch_code from branch where country_code = @country_code)
						and		film_reporting_period.calendar_end = @year_end															
						and		isnull(branch_film_targets.target_amount, 0) <> 0
						
						if @cnt > 0 
							select	@monthly_target = @yearly_target / @cnt 
	
					end

                select  @nett_ytd = isnull(@nett,0) + isnull(@adjustments, 0) + isnull(@writebacks, 0) + isnull(@nett_ytd,0)

                select  @report_heading = 'Monthly Film Figures - Country'

                select  @page_heading = country_name
                from    country
                where   country_code = @country_code
	
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
					    null,--isnull(@slide_figures,0),
					    null,--isnull(@slide_figures_ytd,0),
					    @rep_id,
					    @first_name,
					    @last_name,
					    isnull(@nett,0),
					    isnull(@nett_ytd,0),
					    isnull(@gross,0),
					    isnull(@gross_ytd,0),
					    isnull(@writebacks,0),
					    isnull(@writebacks_ytd,0),
					    'aa',
					    @country_code,
					    @report_period_no,
					    @report_heading,
					    @page_heading,
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
					    'aa',
					    @country_code,
					    @report_period_no,
					    @report_heading,
					    @page_heading,
					    isnull(@monthly_target,0),
					    isnull(@yearly_target,0)
					    )
			    end
	
		    fetch report_period_csr into @report_period, @report_period_no, @report_period_status
	    end
	    close report_period_csr
		deallocate report_period_csr

	    select @rep_id = null
       select @first_name = null
	    select @last_name = null

	    if @include_reps = 'Y'
	    begin

   		 	declare     branch_csr cursor static for 
		    select      branch_code
		    from        branch
		    where       country_code = @country_code
		    order by    branch_code asc
		    for         read only

		    open branch_csr
		    fetch branch_csr into @branch_code
		    while (@@fetch_status = 0)
		    begin
				    select  @film_target_ytd = 0,
						    @prev_year_nett_ytd = 0,
						    @prev_year_gross_ytd = 0,
						    @slide_figures_ytd = 0,
						    @nett_ytd = 0,
						    @writebacks_ytd = 0,
						    @gross_ytd = 0
				declare     report_period_csr cursor static for 
				select      report_period_end, 
				            report_period_no,
				            status
				from        film_reporting_period 
				where       report_period_end <= @report_period_end and 
				            dbo.f_is_date_within_year(report_period_end, @year_end) = 1
				order by    report_period_end asc
				for         read only

			    open report_period_csr
			    fetch report_period_csr into @report_period, @report_period_no, @report_period_status
			    while (@@fetch_status = 0)
			    begin
		
                    select  @film_target = sum(target_amount)
                    from    branch_film_targets
                    where   report_period = @report_period and
                            branch_code = @branch_code

                    select  @film_target_ytd = isnull(@film_target, 0) + isnull(@film_target_ytd, 0)

                    select  @prev_year_nett = sum(nett_amount)
                    from    film_figures,
                            film_campaign
                    where   release_period = dateadd(mm, -12, @report_period) and
                            film_campaign.branch_code = @branch_code
                    and     film_figures.campaign_no = film_campaign.campaign_no 

                    select  @prev_year_nett_ytd = isnull(@prev_year_nett,0) + isnull(@prev_year_nett_ytd,0)

                    select  @prev_year_gross = sum(gross_amount)
                    from    film_figures,
                            film_campaign
                    where   release_period = dateadd(mm, -12, @report_period) and
                            film_campaign.branch_code = @branch_code
                    and     film_figures.campaign_no = film_campaign.campaign_no 

                    select  @prev_year_gross_ytd = isnull(@prev_year_gross,0) + isnull(@prev_year_gross_ytd,0)

                    select  @nett = sum(nett_amount)
                    from    film_figures,
                            film_campaign
                    where   figure_type = 'C' and
                            release_period = @report_period and
                            film_campaign.branch_code = @branch_code
                    and     film_figures.campaign_no = film_campaign.campaign_no 

                    select  @adjustments = sum(nett_amount)
                    from    film_figures,
                            film_campaign
                    where   figure_type <> 'C' and
                            release_period = @report_period and
                            film_campaign.branch_code = @branch_code and
                            nett_amount > 0 
                    and     film_figures.campaign_no = film_campaign.campaign_no 

                    select  @writebacks = sum(nett_amount)
                    from    film_figures,
                            film_campaign
                    where   figure_type <> 'C' and
                            release_period = @report_period and
                            film_campaign.branch_code = @branch_code and
                            nett_amount < 0 
                    and     film_figures.campaign_no = film_campaign.campaign_no 

                    SELECT  @monthly_target = null
                    SELECT  @yearly_target = null

				if @year_type = 'F'
                    select  @monthly_target = sum(monthly_target),
                            @yearly_target = sum(annual_target)
                    from    film_branch_year
                    where   finyear_end = @year_end and
                            branch_code = @branch_code
				else
					begin
						select	@yearly_target = isnull(sum(target_amount), 0)
						from	branch_film_targets, film_reporting_period
						where	branch_film_targets.report_period = film_reporting_period.report_period_end
						and		branch_film_targets.branch_code = @branch_code
						and		film_reporting_period.calendar_end = @year_end															
						
	
						select	@cnt = count(target_amount)	
						from	branch_film_targets, film_reporting_period
						where	branch_film_targets.report_period = film_reporting_period.report_period_end
						and		branch_film_targets.branch_code = @branch_code
						and		film_reporting_period.calendar_end = @year_end															
						and		isnull(branch_film_targets.target_amount, 0) <> 0
						
						if @cnt > 0 
							select	@monthly_target = @yearly_target / @cnt 
	
					end

                    select  @nett_ytd = isnull(@nett,0) + isnull(@adjustments, 0) + isnull(@writebacks, 0) + isnull(@nett_ytd,0)

                    select  @report_heading = 'Monthly Film Figures - Country'

                    select  @page_heading = branch_name
                    from    branch
                    where   branch_code = @branch_code

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
						    null,--isnull(@slide_figures,0),
						    null,--isnull(@slide_figures_ytd,0),
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
						    isnull(@monthly_target,0),
						    isnull(@yearly_target,0)
						    )
				    end
	
				    fetch report_period_csr into @report_period, @report_period_no, @report_period_status
			    end
			    close report_period_csr
				deallocate report_period_csr
			    fetch branch_csr into @branch_code
		    end
		
		    close branch_csr
			deallocate branch_csr
	    end
	    fetch country_csr into @country_code
    end

    close country_csr
	deallocate country_csr
    

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
		 report_period,
		 country_code,
		 report_heading,
		 page_heading,
		 monthly_target,
		 yearly_target
  from #monthly_figures
order by country_code,
		 first_name,
		 last_name,
		 release_date
            
return 0
GO
