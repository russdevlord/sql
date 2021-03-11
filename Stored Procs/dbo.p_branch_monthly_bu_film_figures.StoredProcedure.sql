USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_branch_monthly_bu_film_figures]    Script Date: 11/03/2021 2:30:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_branch_monthly_bu_film_figures]   @report_period_end	        datetime,
											@branch_code			    char(2),
											@mode						int,
											@include_reps			    char(1)
as

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
        @adjustments				money,
        @rep_status					char(1),
        @country_code				char(2),
        @year_end					datetime,
        @monthly_target		    	money,
        @yearly_target				money,
        @business_unit_id           int,
        @business_unit_desc         varchar(100),
		@year_type					char(1)


select      @open_rep_csr = 0


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
	country_code			char(2)			    	null,
	report_period			int				        null,
	report_heading			varchar(100)		    null,
	page_heading			varchar(100)		    null,
	monthly_target			money					null,
	yearly_target			money					null,
    business_unit_id        int                     null,
    business_unit_desc      varchar(100)            null
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
			return -1

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

/*
 * Open cursor and fill get values
 */

declare     business_unit_csr cursor static for
select      business_unit_id,
            business_unit_desc
from        business_unit 
where       system_use_only = 'N'
order by    business_unit_desc
for         read only  

open business_unit_csr
fetch business_unit_csr into @business_unit_id, @business_unit_desc
while(@@fetch_status=0)
begin

    declare     branch_csr cursor static for 
    select      branch_code
    from        branch
    where       branch_code = (case when @mode = 0 then @branch_code else branch_code end)
    order by    branch_code asc
    for         read only

    open branch_csr
    fetch branch_csr into @branch_code
    while(@@fetch_status = 0)
    begin


        select      @country_code = country_code
        from        branch 
        where       branch_code = @branch_code

        select      @film_target_ytd = 0,
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
		            report_period_end >= @year_start
		order by    report_period_end asc
		for         read only

	    open report_period_csr
	    fetch report_period_csr into @report_period, @report_period_no, @report_period_status
	    while (@@fetch_status = 0)
	    begin		
            select      @film_target = 0/*sum(target_amount)
            from        branch_film_targets
            where       report_period = @report_period and
                        branch_code = @branch_code*/

            select      @film_target_ytd = isnull(@film_target, 0) + isnull(@film_target_ytd, 0)

            select      @prev_year_nett = sum(nett_amount)
            from        film_figures,
                        film_campaign
            where       release_period = dateadd(mm, -12, @report_period) and
                        film_figures.branch_code = @branch_code and
                        figure_official = 'Y'
            and         film_figures.campaign_no = film_campaign.campaign_no 
            and         film_campaign.business_unit_id = @business_unit_id

            select      @prev_year_nett_ytd = isnull(@prev_year_nett,0) + isnull(@prev_year_nett_ytd,0)

            select      @prev_year_gross = sum(gross_amount)
            from        film_figures,
                        film_campaign
            where       release_period = dateadd(mm, -12, @report_period) and
                        film_figures.branch_code = @branch_code and
                        figure_official = 'Y'
            and         film_figures.campaign_no = film_campaign.campaign_no 
            and         film_campaign.business_unit_id = @business_unit_id

            select      @prev_year_gross_ytd = isnull(@prev_year_gross,0) + isnull(@prev_year_gross_ytd,0)

            select      @nett = sum(nett_amount)
            from        film_figures,
                        film_campaign
            where       figure_type = 'C' and
                        release_period = @report_period and
                        film_figures.branch_code = @branch_code and
                        figure_official = 'Y'
            and         film_figures.campaign_no = film_campaign.campaign_no 
            and         film_campaign.business_unit_id = @business_unit_id

            select      @adjustments = sum(nett_amount)
            from        film_figures,
                        film_campaign
            where       figure_type <> 'C' and
                        release_period = @report_period and
                        film_figures.branch_code = @branch_code and 
                        nett_amount > 0 and
                        figure_official = 'Y'
            and         film_figures.campaign_no = film_campaign.campaign_no 
            and         film_campaign.business_unit_id = @business_unit_id

            select      @writebacks = sum(nett_amount)
            from        film_figures,
                        film_campaign
            where       figure_type <> 'C' and
                        release_period = @report_period and
                        film_figures.branch_code = @branch_code and 
                        nett_amount < 0 and
                        figure_official = 'Y'
            and         film_figures.campaign_no = film_campaign.campaign_no 
            and         film_campaign.business_unit_id = @business_unit_id

            SELECT      @monthly_target = null
            SELECT      @yearly_target = null

            select      @monthly_target = 0,--monthly_target,
                        @yearly_target = 0/*annual_target
            from        film_branch_year
            where       branch_code = @branch_code and
                        finyear_end = @year_end*/

            select      @nett_ytd = isnull(@nett,0) + isnull(@adjustments, 0) + isnull(@writebacks,0) +isnull(@nett_ytd,0)

            select      @report_heading = 'Monthly Film Figures - Branch'

            select      @page_heading = null

            select      @page_heading = branch_name
            from        branch
            where       branch_code = @branch_code

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
				    yearly_target,
					business_unit_id,
                    business_unit_desc			
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
				    0,
				    'aaaaa',
				    'aaaaa',
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
				    isnull(@yearly_target,0),
					@business_unit_id,
                    @business_unit_desc
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
				    yearly_target,
					business_unit_id,
                    business_unit_desc				
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
				    0,
				    'aaaaa',
				    'aaaaa',
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
				    isnull(@yearly_target,0),
					@business_unit_id,
                    @business_unit_desc
				    )	
		    end

		    fetch report_period_csr into @report_period, @report_period_no, @report_period_status
	    end
	    deallocate report_period_csr

	    if @include_reps = 'Y'
	    begin

		    declare     sales_rep_csr cursor static for 
		    select      sr.rep_id,
		                sr.first_name,
		                sr.last_name,
		                ff.branch_code,
		                sr.status
		    from        sales_rep sr,
		                film_figures ff
		    where       ff.rep_id = sr.rep_id and
		                ff.release_period <= @report_period_end and 
		                ff.release_period >= @year_start and
		                ff.branch_code = @branch_code
		    group by    sr.rep_id,
		                sr.first_name,
		                sr.last_name,
		                ff.branch_code,
		                sr.status
		    union
		    select      sr.rep_id,
		                sr.first_name,
		                sr.last_name,
		                ff.branch_code,
		                sr.status
		    from        sales_rep sr,
		                rep_film_targets ff
		    where       ff.rep_id = sr.rep_id and
		                ff.report_period <= @report_period_end and 
		                ff.report_period >= @year_start and
		                ff.target_amount > 0 and
		                ff.branch_code = @branch_code
		    group by    sr.rep_id,
		                sr.first_name,
		                sr.last_name,
		                ff.branch_code,
		                sr.status
		    order by    sr.first_name,
		                sr.last_name
	
			select      @open_rep_csr = 1

		    open sales_rep_csr
		    fetch sales_rep_csr into @rep_id, @first_name, @last_name, @branch_code, @rep_status
		    while (@@fetch_status = 0)
		    begin
                select      @film_target_ytd = 0,
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
		            report_period_end >= @year_start
		order by    report_period_end asc
		for         read only

			    open report_period_csr
			    fetch report_period_csr into @report_period, @report_period_no, @report_period_status
			    while (@@fetch_status = 0)
			    begin
		
                    select      @film_target = 0/*sum(target_amount)
                    from        rep_film_targets
                    where       rep_id = @rep_id and
                                report_period = @report_period and
                                branch_code = @branch_code*/

                    select      @film_target_ytd = isnull(@film_target, 0) + isnull(@film_target_ytd, 0)

                    select      @prev_year_nett = sum(nett_amount)
                    from        film_figures,
                                film_campaign
                    where       film_figures.rep_id = @rep_id and
                                release_period = dateadd(mm, -12, @report_period) and
                                film_figures.branch_code = @branch_code and
                                figure_official = 'Y'
                    and         film_figures.campaign_no = film_campaign.campaign_no 
                    and         film_campaign.business_unit_id = @business_unit_id

                    select      @prev_year_nett_ytd = isnull(@prev_year_nett,0) + isnull(@prev_year_nett_ytd,0)

                    select      @prev_year_gross = sum(gross_amount)
                    from        film_figures,
                                film_campaign
                    where       film_figures.rep_id = @rep_id and
                                release_period = dateadd(mm, -12, @report_period) and
                                film_figures.branch_code = @branch_code and
                                figure_official = 'Y'
                    and         film_figures.campaign_no = film_campaign.campaign_no 
                    and         film_campaign.business_unit_id = @business_unit_id

                    select      @prev_year_gross_ytd = isnull(@prev_year_gross,0) + isnull(@prev_year_gross_ytd,0)

                    select      @slide_figures = sum(nett_amount)
                    from        slide_figures
                    where       rep_id = @rep_id and
                                release_period <= @report_period and
                                release_period >= dateadd(mm, -1, @report_period) and
                                branch_code = @branch_code and
                                figure_official = 'Y' and
                                rep_id in ( select      distinct rep_id 
                                            from        rep_film_targets
                    where       report_period = @report_period and
		                        rep_id = @rep_id)

                    select      @nett = sum(nett_amount)
                    from        film_figures,
                                film_campaign
                    where       film_figures.rep_id = @rep_id and
                                figure_type = 'C' and
                                release_period = @report_period and
                                film_figures.branch_code = @branch_code and
                                figure_official = 'Y'
                    and         film_figures.campaign_no = film_campaign.campaign_no 
                    and         film_campaign.business_unit_id = @business_unit_id

                    select      @adjustments = sum(nett_amount)
                    from        film_figures,
                                film_campaign
                    where       film_figures.rep_id = @rep_id and
                                figure_type <> 'C' and
                                release_period = @report_period and
                                film_figures.branch_code = @branch_code and
                                nett_amount > 0 and
                                figure_official = 'Y'
                    and         film_figures.campaign_no = film_campaign.campaign_no 
                    and         film_campaign.business_unit_id = @business_unit_id

                    select      @writebacks = sum(nett_amount)
                    from        film_figures,
                                film_campaign
                    where       film_figures.rep_id = @rep_id and
                                figure_type <> 'C' and
                                release_period = @report_period and
                                film_figures.branch_code = @branch_code and
                                nett_amount < 0 and
                                figure_official = 'Y'
                    and         film_figures.campaign_no = film_campaign.campaign_no 
                    and         film_campaign.business_unit_id = @business_unit_id

                    SELECT      @monthly_target = null
                    SELECT      @yearly_target = null

                    select      @monthly_target = 0,--monthly_target,
                                @yearly_target = 0/*annual_target
                    from        film_rep_year
                    where       rep_id = @rep_id and
                                finyear_end = @year_end and
                                branch_code = @branch_code*/

                    select      @nett_ytd = isnull(@nett,0) + isnull(@adjustments, 0) + isnull(@writebacks,0) +isnull(@nett_ytd,0)

                    select      @report_heading = 'Monthly Film Figures - Branch'

                    select      @page_heading = null

                    if @rep_status = 'X'
                        select      @page_heading = '(Terminated) ' + rtrim(@first_name) + ' ' + rtrim(@last_name) + ' - ' 
                    else
                        select      @page_heading = @page_heading + rtrim(@first_name) + ' ' + rtrim(@last_name) + ' - ' 

                    select      @page_heading = @page_heading + branch_name
                    from        branch
                    where       branch_code = @branch_code

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
						    yearly_target,
						    business_unit_id,
                            business_unit_desc				
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
						    isnull(@monthly_target,0),
						    isnull(@yearly_target,0),
						    @business_unit_id,
                            @business_unit_desc
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
						    yearly_target,
						    business_unit_id,
                            business_unit_desc
						    ) values
						    (null,--@adjustments,
						    isnull(@film_target_ytd,0),
						    isnull(@prev_year_nett,0),
						    isnull(@prev_year_nett_ytd,0),
						    isnull(@prev_year_gross,0),
						    isnull(@prev_year_gross_ytd,0),
						    @report_period,
						    null,--@slide_figures,
						    @slide_figures_ytd,
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
						    isnull(@yearly_target,0),
						    @business_unit_id,
                            @business_unit_desc
						    )	
				    end

				    fetch report_period_csr into @report_period, @report_period_no, @report_period_status
			    end
			    deallocate report_period_csr
		    end
		
		    deallocate sales_rep_csr 
	    end
	    fetch branch_csr into @branch_code
    end
    
    deallocate branch_csr
    fetch business_unit_csr into @business_unit_id, @business_unit_desc
end

deallocate business_unit_csr


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
		 monthly_target,
		 yearly_target,
	     business_unit_id,
         business_unit_desc
  from #monthly_figures
order by branch_code,
			first_name,
			last_name,
			release_date
			

return 0
GO
