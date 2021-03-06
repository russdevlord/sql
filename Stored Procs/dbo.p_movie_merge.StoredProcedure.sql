/****** Object:  StoredProcedure [dbo].[p_movie_merge]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_movie_merge]
GO
/****** Object:  StoredProcedure [dbo].[p_movie_merge]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO





create proc [dbo].[p_movie_merge] @arg_parent_movie_id int,
				    @arg_child_movie_id int,
                    @arg_start_date datetime,
				    @arg_end_date datetime,
                    @arg_movie_translation_flag char(1)

as

set nocount on 

declare     @error									int,
            @screening_date							datetime,
            @parent_reccnt							int,
            @child_reccnt							int,
            @movie_id								int,
            @data_provider_id						int,
            @movie_code								varchar(30),
            @shell_code								char(7),
            @instruction_type						tinyint,
            @audience_profile_code					char(2),
            @movie_category_code					char(2),
            @revision_no							int,
            @package_id								int,
            @provider_id							int,
            @campaign_no							int, 
            @complex_id								int,
            @country_code							char(1),
            @regional_indicator						char(1),
            @occurence								smallint,
            @attendance								int,
            @average								numeric(18,6),
            @average_programmed						numeric(18,6),
            @scheduled_count						int,
            @makeup_count							int,
			@session_time							datetime,
            @bonus_no_charge_count					int,
            @makegood_count							int,
            @sessions_scheduled						smallint,
            @sessions_held							smallint,
            @del_movie_master						smallint,
			@cinetam_demographics_id				int,
			@unique_transactions					numeric(20,12),
			@unique_people							numeric(20,12),
			@original_estimate						int,
			@original_attendance					int,
			@cinetam_reporting_demographics_id		int,
			@print_medium							char(1),
			@three_d_type							int,
			@calculated_weighting					numeric(38, 30),
			@raw_weighting							numeric (38, 30),
			@demo_population						int ,
			@total_movio_population					int ,
			@total_exp_population					int,
			@total_movie_calc_wgt					numeric(38, 30),
			@weighting								numeric(38, 30),
			@adult_tickets							numeric(16,0),
			@child_tickets							numeric(16,0),
			@movie_weighting						numeric(38,30),
			@uuid									nvarchar(100),
			@inclusion_id							int

/*NULL start and end date will surely delete child movie master files*/
IF IsNull(@arg_start_date,'1-jan-1900') = '1-jan-1900' AND IsNull(@arg_end_date,'31-Dec-2099') = '31-Dec-2099'
begin
    select @del_movie_master = 1
end
ELSE
    select @del_movie_master = 0

IF IsNull(@arg_start_date,'1-jan-1900') = '1-jan-1900'
    select @arg_start_date = '1-jan-1900'

/*IF IsNull(@arg_start_date,'1-jan-1900') = '1-jan-1900'
    goto dummyreturn
*/

IF IsNull(@arg_end_date,'31-Dec-2099') = '31-Dec-2099'
    select @arg_end_date = '31-Dec-2099'

/*
 * Begin Processing
 */

begin transaction

/*jump process if attendance translation only*/
if @arg_movie_translation_flag = 'Y'
    goto movietranslation


declare     open_csr cursor static for 
select      movie_id, complex_id, screening_date, country_code, adult_tickets, child_tickets, movie_weighting
from        movie_weekly_ticket_complex_split
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id, @complex_id, @screening_date, @country_code, @adult_tickets, @child_tickets, @movie_weighting
while(@@fetch_status = 0) 
begin
    if (select count(*) from movie_weekly_ticket_complex_split where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and country_code = @country_code ) > 0
    begin
        update movie_weekly_ticket_complex_split set adult_tickets = adult_tickets + @adult_tickets, child_tickets = child_tickets + @child_tickets, movie_weighting = @movie_weighting  where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
        
        delete movie_weekly_ticket_complex_split where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update movie_weekly_ticket_complex_split set movie_id = @arg_parent_movie_id where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and country_code = @country_code
    
        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @movie_id, @complex_id, @screening_date, @country_code, @adult_tickets, @child_tickets, @movie_weighting
end

close open_csr
deallocate open_csr

declare     open_csr cursor static for 
select      movie_id, complex_id, screening_date, country_code, adult_tickets, child_tickets, movie_weighting
from        movie_weekly_ticket_complex_split_weekend
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id, @complex_id, @screening_date, @country_code, @adult_tickets, @child_tickets, @movie_weighting
while(@@fetch_status = 0) 
begin
    if (select count(*) from movie_weekly_ticket_complex_split_weekend where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and country_code = @country_code ) > 0
    begin
        update movie_weekly_ticket_complex_split_weekend set adult_tickets = adult_tickets + @adult_tickets, child_tickets = child_tickets + @child_tickets, movie_weighting = @movie_weighting  where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
        
        delete movie_weekly_ticket_complex_split_weekend where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update movie_weekly_ticket_complex_split_weekend set movie_id = @arg_parent_movie_id where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and country_code = @country_code
    
        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @movie_id, @complex_id, @screening_date, @country_code, @adult_tickets, @child_tickets, @movie_weighting
end

close open_csr
deallocate open_csr


declare     open_csr cursor static for 
select      movie_id,  screening_date, country_code, adult_tickets, child_tickets, movie_weighting
from        movie_weekly_ticket_split
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id,  @screening_date, @country_code, @adult_tickets, @child_tickets, @movie_weighting
while(@@fetch_status = 0) 
begin
    if (select count(*) from movie_weekly_ticket_split where movie_id = @arg_parent_movie_id and screening_date = @screening_date and country_code = @country_code ) > 0
    begin
        update movie_weekly_ticket_split set adult_tickets = adult_tickets + @adult_tickets, child_tickets = child_tickets + @child_tickets, movie_weighting = @movie_weighting  where movie_id = @arg_parent_movie_id  and screening_date = @screening_date and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
        
        delete movie_weekly_ticket_split where movie_id = @movie_id  and screening_date = @screening_date and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update movie_weekly_ticket_split set movie_id = @arg_parent_movie_id where movie_id = @movie_id  and screening_date = @screening_date and country_code = @country_code
    
        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @movie_id,  @screening_date, @country_code, @adult_tickets, @child_tickets, @movie_weighting
end

close open_csr
deallocate open_csr

declare     open_csr cursor static for 
select      movie_id,  screening_date, country_code, adult_tickets, child_tickets, movie_weighting
from        movie_weekly_ticket_split_weekend
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id,  @screening_date, @country_code, @adult_tickets, @child_tickets, @movie_weighting
while(@@fetch_status = 0) 
begin
    if (select count(*) from movie_weekly_ticket_split_weekend where movie_id = @arg_parent_movie_id and screening_date = @screening_date and country_code = @country_code ) > 0
    begin
        update movie_weekly_ticket_split_weekend set adult_tickets = adult_tickets + @adult_tickets, child_tickets = child_tickets + @child_tickets, movie_weighting = @movie_weighting  where movie_id = @arg_parent_movie_id  and screening_date = @screening_date and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
        
        delete movie_weekly_ticket_split_weekend where movie_id = @movie_id  and screening_date = @screening_date and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update movie_weekly_ticket_split_weekend set movie_id = @arg_parent_movie_id where movie_id = @movie_id  and screening_date = @screening_date and country_code = @country_code
    
        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @movie_id,  @screening_date, @country_code, @adult_tickets, @child_tickets, @movie_weighting
end

close open_csr
deallocate open_csr


declare     open_csr cursor static for 
select      movie_id,  screening_date, country_code, adult_tickets, child_tickets, movie_weighting
from        movie_wkend_ticket_split
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id,  @screening_date, @country_code, @adult_tickets, @child_tickets, @movie_weighting
while(@@fetch_status = 0) 
begin
    if (select count(*) from movie_wkend_ticket_split where movie_id = @arg_parent_movie_id and screening_date = @screening_date and country_code = @country_code ) > 0
    begin
        update movie_wkend_ticket_split set adult_tickets = adult_tickets + @adult_tickets, child_tickets = child_tickets + @child_tickets, movie_weighting = @movie_weighting  where movie_id = @arg_parent_movie_id  and screening_date = @screening_date and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
        
        delete movie_wkend_ticket_split where movie_id = @movie_id  and screening_date = @screening_date and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update movie_wkend_ticket_split set movie_id = @arg_parent_movie_id where movie_id = @movie_id  and screening_date = @screening_date and country_code = @country_code
    
        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @movie_id,  @screening_date, @country_code, @adult_tickets, @child_tickets, @movie_weighting
end

close open_csr
deallocate open_csr


declare     open_csr cursor static for 
select      movie_id, complex_id, screening_date, cinetam_demographics_id, country_code, calculated_weighting	, raw_weighting, demo_population, total_movio_population ,total_exp_population ,total_movie_calc_wgt, weighting
from        cinetam_movio_complex_data
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id, @complex_id, @screening_date, @cinetam_demographics_id, @country_code, @calculated_weighting	, @raw_weighting, @demo_population, @total_movio_population ,@total_exp_population ,@total_movie_calc_wgt, @weighting
while(@@fetch_status = 0) 
begin
    if (select count(*) from cinetam_movio_complex_data where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and cinetam_demographics_id = @cinetam_demographics_id and country_code = @country_code) > 0
    begin
        
        delete cinetam_movio_complex_data where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and cinetam_demographics_id = @cinetam_demographics_id  and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update cinetam_movio_complex_data set movie_id = @arg_parent_movie_id where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and cinetam_demographics_id = @cinetam_demographics_id  and country_code = @country_code
    
        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @movie_id, @complex_id, @screening_date, @cinetam_demographics_id, @country_code, @calculated_weighting	, @raw_weighting, @demo_population, @total_movio_population ,@total_exp_population ,@total_movie_calc_wgt, @weighting
end

close open_csr
deallocate open_csr


declare     open_csr cursor static for 
select      movie_id, complex_id, screening_date, cinetam_demographics_id, country_code, calculated_weighting	, raw_weighting, demo_population, total_movio_population ,total_exp_population ,total_movie_calc_wgt, weighting
from        cinetam_movio_complex_data_weekend
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id, @complex_id, @screening_date, @cinetam_demographics_id, @country_code, @calculated_weighting	, @raw_weighting, @demo_population, @total_movio_population ,@total_exp_population ,@total_movie_calc_wgt, @weighting
while(@@fetch_status = 0) 
begin
    if (select count(*) from cinetam_movio_complex_data_weekend where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and cinetam_demographics_id = @cinetam_demographics_id and country_code = @country_code) > 0
    begin
        
        delete cinetam_movio_complex_data_weekend where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and cinetam_demographics_id = @cinetam_demographics_id  and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update cinetam_movio_complex_data_weekend set movie_id = @arg_parent_movie_id where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and cinetam_demographics_id = @cinetam_demographics_id  and country_code = @country_code
    
        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @movie_id, @complex_id, @screening_date, @cinetam_demographics_id, @country_code, @calculated_weighting	, @raw_weighting, @demo_population, @total_movio_population ,@total_exp_population ,@total_movie_calc_wgt, @weighting
end

close open_csr
deallocate open_csr

declare     open_csr cursor static for 
select      movie_id,  screening_date, cinetam_demographics_id, country_code, calculated_weighting	, raw_weighting, demo_population, total_movio_population ,total_exp_population ,total_movie_calc_wgt, weighting
from        cinetam_movio_data
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id,  @screening_date, @cinetam_demographics_id, @country_code, @calculated_weighting	, @raw_weighting, @demo_population, @total_movio_population ,@total_exp_population ,@total_movie_calc_wgt, @weighting
while(@@fetch_status = 0) 
begin
    if (select count(*) from cinetam_movio_data where movie_id = @arg_parent_movie_id  and screening_date = @screening_date and cinetam_demographics_id = @cinetam_demographics_id and country_code = @country_code) > 0
    begin
        
        delete cinetam_movio_data where movie_id = @movie_id  and screening_date = @screening_date and cinetam_demographics_id = @cinetam_demographics_id  and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update cinetam_movio_data set movie_id = @arg_parent_movie_id where movie_id = @movie_id  and screening_date = @screening_date and cinetam_demographics_id = @cinetam_demographics_id  and country_code = @country_code
    
        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @movie_id,  @screening_date, @cinetam_demographics_id, @country_code, @calculated_weighting	, @raw_weighting, @demo_population, @total_movio_population ,@total_exp_population ,@total_movie_calc_wgt, @weighting
end

close open_csr
deallocate open_csr

declare     open_csr cursor static for 
select      movie_id,  screening_date, cinetam_demographics_id, country_code, calculated_weighting	, raw_weighting, demo_population, total_movio_population ,total_exp_population ,total_movie_calc_wgt, weighting
from        cinetam_movio_data_weekend
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id,  @screening_date, @cinetam_demographics_id, @country_code, @calculated_weighting	, @raw_weighting, @demo_population, @total_movio_population ,@total_exp_population ,@total_movie_calc_wgt, @weighting
while(@@fetch_status = 0) 
begin
    if (select count(*) from cinetam_movio_data_weekend where movie_id = @arg_parent_movie_id  and screening_date = @screening_date and cinetam_demographics_id = @cinetam_demographics_id and country_code = @country_code) > 0
    begin
        
        delete cinetam_movio_data_weekend where movie_id = @movie_id  and screening_date = @screening_date and cinetam_demographics_id = @cinetam_demographics_id  and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update cinetam_movio_data_weekend set movie_id = @arg_parent_movie_id where movie_id = @movie_id  and screening_date = @screening_date and cinetam_demographics_id = @cinetam_demographics_id  and country_code = @country_code
    
        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @movie_id,  @screening_date, @cinetam_demographics_id, @country_code, @calculated_weighting	, @raw_weighting, @demo_population, @total_movio_population ,@total_exp_population ,@total_movie_calc_wgt, @weighting
end

close open_csr
deallocate open_csr


declare     open_csr cursor static for 
select  	 screening_date, complex_id, movie_id, attendance, cinetam_reporting_demographics_id, original_estimate
from        cinetam_movie_complex_estimates
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @screening_date, @complex_id, @movie_id, @attendance, @cinetam_reporting_demographics_id, @original_estimate
while(@@fetch_status = 0) 
begin
    if (select count(*) from cinetam_movie_complex_estimates where screening_date = @screening_date and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id and complex_id = @complex_id and movie_id = @arg_parent_movie_id) > 0
    begin
        update cinetam_movie_complex_estimates set attendance = attendance + @attendance, original_estimate = original_estimate + @original_estimate where screening_date = @screening_date and complex_id = @complex_id and movie_id = @arg_parent_movie_id  and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id 
        
        select @error = @@error
		if @error != 0
            goto error   
        
        delete cinetam_movie_complex_estimates where screening_date = @screening_date and complex_id = @complex_id and movie_id = @movie_id and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id 

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update cinetam_movie_complex_estimates set movie_id = @arg_parent_movie_id where  screening_date = @screening_date and complex_id = @complex_id and movie_id = @movie_id and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id 
    
        select @error = @@error
		if @error != 0
			goto error   
	end    
    fetch open_csr into @screening_date, @complex_id, @movie_id, @attendance, @cinetam_reporting_demographics_id, @original_estimate
end

close open_csr
deallocate open_csr


declare     open_csr cursor static for 
select  	 screening_date, country_code, movie_id, attendance, cinetam_reporting_demographics_id, original_attendance
from        cinetam_movie_estimates
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @screening_date, @country_code, @movie_id, @attendance, @cinetam_reporting_demographics_id, @original_attendance
while(@@fetch_status = 0) 
begin
    if (select count(*) from cinetam_movie_estimates where screening_date = @screening_date and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id and country_code = @country_code and movie_id = @arg_parent_movie_id) > 0
    begin
        update cinetam_movie_estimates set attendance = attendance + @attendance, original_attendance = original_attendance + @original_attendance where screening_date = @screening_date and country_code = @country_code and movie_id = @arg_parent_movie_id  and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id 
        
        select @error = @@error
		if @error != 0
            goto error   
        
        delete cinetam_movie_estimates where screening_date = @screening_date and country_code = @country_code and movie_id = @movie_id and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id 

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update cinetam_movie_estimates set movie_id = @arg_parent_movie_id where  screening_date = @screening_date and country_code = @country_code and movie_id = @movie_id and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id 
    
        select @error = @@error
		if @error != 0
			goto error   
	end    
    fetch open_csr into @screening_date, @country_code, @movie_id, @attendance, @cinetam_reporting_demographics_id, @original_attendance
end

close open_csr
deallocate open_csr


declare     open_csr cursor static for 
select  	inclusion_id, campaign_no, screening_date, complex_id, cinetam_reporting_demographics_id, movie_id, attendance
from        inclusion_cinetam_complex_attendance
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @inclusion_id, @campaign_no, @screening_date, @complex_id, @cinetam_reporting_demographics_id, @movie_id, @attendance
while(@@fetch_status = 0) 
begin
    if (select count(*) from inclusion_cinetam_complex_attendance where campaign_no = @campaign_no and screening_date = @screening_date and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id and complex_id = @complex_id and movie_id = @arg_parent_movie_id) > 0
    begin
        update inclusion_cinetam_complex_attendance set attendance = attendance + @attendance where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @arg_parent_movie_id and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id 
        
        select @error = @@error
		if @error != 0
            goto error   
        
        delete inclusion_cinetam_complex_attendance where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @movie_id and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id 

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update inclusion_cinetam_complex_attendance set movie_id = @arg_parent_movie_id where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @movie_id and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id  
    
        select @error = @@error
		if @error != 0
			goto error   
	end    
	fetch open_csr into @inclusion_id, @campaign_no, @screening_date, @complex_id, @cinetam_reporting_demographics_id, @movie_id, @attendance
end

close open_csr
deallocate open_csr

declare     open_csr cursor static for 
select  	campaign_no, screening_date, complex_id, movie_id, attendance, cinetam_demographics_id, unique_transactions, unique_people
from        cinetam_campaign_complex_actuals
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @campaign_no, @screening_date, @complex_id, @movie_id, @attendance, @cinetam_demographics_id, @unique_transactions, @unique_people
while(@@fetch_status = 0) 
begin
    if (select count(*) from cinetam_campaign_complex_actuals where campaign_no = @campaign_no and screening_date = @screening_date and cinetam_demographics_id = @cinetam_demographics_id and complex_id = @complex_id and movie_id = @arg_parent_movie_id) > 0
    begin
        update cinetam_campaign_complex_actuals set attendance = attendance + @attendance, unique_people = unique_people + @unique_people, unique_transactions = unique_transactions + @unique_transactions  where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @arg_parent_movie_id  and cinetam_demographics_id = @cinetam_demographics_id 
        
        select @error = @@error
		if @error != 0
            goto error   
        
        delete cinetam_campaign_complex_actuals where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @movie_id and cinetam_demographics_id = @cinetam_demographics_id 

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update cinetam_campaign_complex_actuals set movie_id = @arg_parent_movie_id where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @movie_id and cinetam_demographics_id = @cinetam_demographics_id 
    
        select @error = @@error
		if @error != 0
			goto error   
	end    
    fetch open_csr into @campaign_no, @screening_date, @complex_id, @movie_id, @attendance, @cinetam_demographics_id, @unique_transactions, @unique_people
end

close open_csr
deallocate open_csr

declare     open_csr cursor static for 
select  	campaign_no, screening_date, complex_id, movie_id, attendance, cinetam_demographics_id, unique_transactions, unique_people
from        cinetam_campaign_complex_actuals_weekend
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @campaign_no, @screening_date, @complex_id, @movie_id, @attendance, @cinetam_demographics_id, @unique_transactions, @unique_people
while(@@fetch_status = 0) 
begin
    if (select count(*) from cinetam_campaign_complex_actuals_weekend where campaign_no = @campaign_no and screening_date = @screening_date and cinetam_demographics_id = @cinetam_demographics_id and complex_id = @complex_id and movie_id = @arg_parent_movie_id) > 0
    begin
        update cinetam_campaign_complex_actuals_weekend set attendance = attendance + @attendance, unique_people = unique_people + @unique_people, unique_transactions = unique_transactions + @unique_transactions  where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @arg_parent_movie_id  and cinetam_demographics_id = @cinetam_demographics_id 
        
        select @error = @@error
		if @error != 0
            goto error   
        
        delete cinetam_campaign_complex_actuals_weekend where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @movie_id and cinetam_demographics_id = @cinetam_demographics_id 

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update cinetam_campaign_complex_actuals_weekend set movie_id = @arg_parent_movie_id where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @movie_id and cinetam_demographics_id = @cinetam_demographics_id 
    
        select @error = @@error
		if @error != 0
			goto error   
	end    
    fetch open_csr into @campaign_no, @screening_date, @complex_id, @movie_id, @attendance, @cinetam_demographics_id, @unique_transactions, @unique_people
end

close open_csr
deallocate open_csr

declare     open_csr cursor static for 
select  	inclusion_id, campaign_no, screening_date, movie_id, attendance, cinetam_reporting_demographics_id
from        inclusion_cinetam_attendance
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @inclusion_id, @campaign_no, @screening_date, @movie_id, @attendance, @cinetam_reporting_demographics_id
while(@@fetch_status = 0) 
begin
    if (select count(*) from inclusion_cinetam_attendance where campaign_no = @campaign_no and screening_date = @screening_date and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id and movie_id = @arg_parent_movie_id) > 0
    begin
        update inclusion_cinetam_attendance set attendance = attendance + @attendance where inclusion_id = @inclusion_id and campaign_no = @campaign_no and screening_date = @screening_date and movie_id = @arg_parent_movie_id  and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id 
        
        select @error = @@error
		if @error != 0
            goto error   
        
        delete inclusion_cinetam_attendance where inclusion_id = @inclusion_id and campaign_no = @campaign_no and screening_date = @screening_date and  movie_id = @movie_id and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
		if @error != 0
            goto error   
    end    
    else
	begin
        update inclusion_cinetam_attendance set movie_id = @arg_parent_movie_id where inclusion_id = @inclusion_id and campaign_no = @campaign_no and screening_date = @screening_date  and movie_id = @movie_id and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
    
        select @error = @@error
		if @error != 0
			goto error   
	end    
	fetch open_csr into @inclusion_id, @campaign_no, @screening_date, @movie_id, @attendance, @cinetam_reporting_demographics_id
end

close open_csr
deallocate open_csr

declare     open_csr cursor static for 
select  	inclusion_id, campaign_no, screening_date, movie_id, attendance, cinetam_reporting_demographics_id
from        inclusion_cinetam_attendance_weekend
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @inclusion_id, @campaign_no, @screening_date, @movie_id, @attendance, @cinetam_reporting_demographics_id
while(@@fetch_status = 0) 
begin
    if (select count(*) from inclusion_cinetam_attendance_weekend where campaign_no = @campaign_no and screening_date = @screening_date and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id and movie_id = @arg_parent_movie_id) > 0
    begin
        update inclusion_cinetam_attendance_weekend set attendance = attendance + @attendance where inclusion_id = @inclusion_id and campaign_no = @campaign_no and screening_date = @screening_date and movie_id = @arg_parent_movie_id  and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id 
        
        select @error = @@error
		if @error != 0
            goto error   
        
        delete inclusion_cinetam_attendance_weekend where inclusion_id = @inclusion_id and campaign_no = @campaign_no and screening_date = @screening_date and  movie_id = @movie_id and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
		if @error != 0
            goto error   
    end    
    else
	begin
        update inclusion_cinetam_attendance_weekend set movie_id = @arg_parent_movie_id where inclusion_id = @inclusion_id and campaign_no = @campaign_no and screening_date = @screening_date  and movie_id = @movie_id and cinetam_reporting_demographics_id = @cinetam_reporting_demographics_id
    
        select @error = @@error
		if @error != 0
			goto error   
	end    
	fetch open_csr into @inclusion_id, @campaign_no, @screening_date, @movie_id, @attendance, @cinetam_reporting_demographics_id
end

close open_csr
deallocate open_csr

/******************************************
* attendance_campaign_complex_actuals Update   *
******************************************/	
declare     open_csr cursor static for 
select  	campaign_no, screening_date, complex_id, movie_id, attendance
from        attendance_campaign_complex_actuals
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @campaign_no, @screening_date, @complex_id, @movie_id, @attendance
while(@@fetch_status = 0) 
begin
    if (select count(*) from attendance_campaign_complex_actuals where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @arg_parent_movie_id) > 0
    begin
        update attendance_campaign_complex_actuals set attendance = attendance + @attendance where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @arg_parent_movie_id
        
        select @error = @@error
		if @error != 0
            goto error   
        
        delete attendance_campaign_complex_actuals where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @movie_id

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update attendance_campaign_complex_actuals set movie_id = @arg_parent_movie_id where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @movie_id
    
        select @error = @@error
		if @error != 0
			goto error   
	end    
    fetch open_csr into @campaign_no, @screening_date, @complex_id, @movie_id, @attendance
end

close open_csr
deallocate open_csr

/*Minimizing attempt of sql count to optimize process*/
if @del_movie_master = 1
begin
    if (select count(*) from attendance_campaign_complex_actuals where movie_id = @arg_child_movie_id) > 0
        select @del_movie_master = 0
end



/******************************************
* attendance_campaign_complex_actuals_weekend Update   *
******************************************/	
declare     open_csr cursor static for 
select  	campaign_no, screening_date, complex_id, movie_id, attendance
from        attendance_campaign_complex_actuals_weekend
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @campaign_no, @screening_date, @complex_id, @movie_id, @attendance
while(@@fetch_status = 0) 
begin
    if (select count(*) from attendance_campaign_complex_actuals_weekend where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @arg_parent_movie_id) > 0
    begin
        update attendance_campaign_complex_actuals_weekend set attendance = attendance + @attendance where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @arg_parent_movie_id
        
        select @error = @@error
		if @error != 0
            goto error   
        
        delete attendance_campaign_complex_actuals_weekend where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @movie_id

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update attendance_campaign_complex_actuals_weekend set movie_id = @arg_parent_movie_id where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @movie_id
    
        select @error = @@error
		if @error != 0
			goto error   
	end    
    fetch open_csr into @campaign_no, @screening_date, @complex_id, @movie_id, @attendance
end

close open_csr
deallocate open_csr


/******************************************
* attendance_movie_averages Update   *
******************************************/	
declare     open_csr cursor static for 
select      screening_date, country_code, movie_id, regional_indicator, average, average_programmed
from        attendance_movie_averages
where       movie_id = @arg_child_movie_id 
and 		screening_date >= @arg_start_date 
and 		screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @screening_date, @country_code, @movie_id, @regional_indicator, @average, @average_programmed
while(@@fetch_status = 0) 
begin
    if (select count(*) from attendance_movie_averages where screening_date = @screening_date and country_code = @country_code and movie_id = @arg_parent_movie_id and regional_indicator = @regional_indicator) > 0
        begin           
            update attendance_movie_averages set average = (average + @average) / 2, average_programmed = (average_programmed + @average_programmed) / 2 where screening_date = @screening_date and country_code = @country_code and movie_id = @arg_parent_movie_id and regional_indicator = @regional_indicator
            
            select @error = @@error
			if @error != 0
                goto error   
            
            delete attendance_movie_averages where screening_date = @screening_date and country_code = @country_code and movie_id = @movie_id and regional_indicator = @regional_indicator

            select @error = @@error
			if @error != 0
                goto error   

        end
    else
	begin
        update attendance_movie_averages set movie_id = @arg_parent_movie_id where screening_date = @screening_date and country_code = @country_code and movie_id = @movie_id and regional_indicator = @regional_indicator
    
        select @error = @@error
		if @error != 0
			goto error   
    end
    
    fetch open_csr into @screening_date, @country_code, @movie_id, @regional_indicator, @average, @average_programmed
end

close open_csr
deallocate open_csr

/*Minimizing attempt of sql count to optimize process*/
if @del_movie_master = 1
begin
    if (select count(*) from attendance_movie_averages where movie_id = @arg_child_movie_id) > 0
        select @del_movie_master = 0
end

/******************************************
* attendance_movie_averages_weekend Update   *
******************************************/	
declare     open_csr cursor static for 
select      screening_date, country_code, movie_id, regional_indicator, average, average_programmed
from        attendance_movie_averages_weekend
where       movie_id = @arg_child_movie_id 
and 		screening_date >= @arg_start_date 
and 		screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @screening_date, @country_code, @movie_id, @regional_indicator, @average, @average_programmed
while(@@fetch_status = 0) 
begin
    if (select count(*) from attendance_movie_averages_weekend where screening_date = @screening_date and country_code = @country_code and movie_id = @arg_parent_movie_id and regional_indicator = @regional_indicator) > 0
        begin           
            update attendance_movie_averages_weekend set average = (average + @average) / 2, average_programmed = (average_programmed + @average_programmed) / 2 where screening_date = @screening_date and country_code = @country_code and movie_id = @arg_parent_movie_id and regional_indicator = @regional_indicator
            
            select @error = @@error
			if @error != 0
                goto error   
            
            delete attendance_movie_averages_weekend where screening_date = @screening_date and country_code = @country_code and movie_id = @movie_id and regional_indicator = @regional_indicator

            select @error = @@error
			if @error != 0
                goto error   

        end
    else
	begin
        update attendance_movie_averages_weekend set movie_id = @arg_parent_movie_id where screening_date = @screening_date and country_code = @country_code and movie_id = @movie_id and regional_indicator = @regional_indicator
    
        select @error = @@error
		if @error != 0
			goto error   
    end
    
    fetch open_csr into @screening_date, @country_code, @movie_id, @regional_indicator, @average, @average_programmed
end

close open_csr
deallocate open_csr

/*Minimizing attempt of sql count to optimize process*/
if @del_movie_master = 1
begin
    if (select count(*) from attendance_movie_averages_weekend where movie_id = @arg_child_movie_id) > 0
        select @del_movie_master = 0
end

/******************************************
* attendnace_raw Update   *
******************************************/	
declare     open_csr cursor static for 
select      data_provider_id, screening_date, complex_id, movie_code, movie_id, attendance
from        attendance_raw
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @data_provider_id, @screening_date, @complex_id, @movie_code, @movie_id, @attendance
while(@@fetch_status = 0) 
begin
    if (select count(*) from attendance_raw where data_provider_id = @data_provider_id and screening_date = @screening_date and complex_id = @complex_id and movie_code = @movie_code and movie_id = @arg_parent_movie_id) > 0
        begin
            update attendance_raw set attendance = attendance + @attendance where data_provider_id = @data_provider_id and screening_date = @screening_date and complex_id = @complex_id and movie_code = @movie_code and movie_id = @arg_parent_movie_id
            
            select @error = @@error
			if @error != 0
                goto error   
            
            delete attendance_raw where data_provider_id = @data_provider_id and screening_date = @screening_date and complex_id = @complex_id and movie_code = @movie_code and movie_id = @movie_id

            select @error = @@error
			if @error != 0
                goto error   
        end    
    else
	begin        
        update attendance_raw set movie_id = @arg_parent_movie_id where data_provider_id = @data_provider_id and screening_date = @screening_date and complex_id = @complex_id and movie_code = @movie_code and movie_id = @movie_id

        select @error = @@error
		if @error != 0
			goto error   
	end
        
    fetch open_csr into @data_provider_id, @screening_date, @complex_id, @movie_code, @movie_id, @attendance
end

close open_csr
deallocate open_csr

/*Minimizing attempt of sql count to optimize process*/
if @del_movie_master = 1
begin
    if (select count(*) from attendance_raw where movie_id = @arg_child_movie_id) > 0
        select @del_movie_master = 0
end


/******************************************
* attendnace_raw Update   *
******************************************/	
declare     open_csr cursor static for 
select      data_provider_id, screening_date, complex_id, movie_code, movie_id, attendance
from        attendance_raw_weekend
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @data_provider_id, @screening_date, @complex_id, @movie_code, @movie_id, @attendance
while(@@fetch_status = 0) 
begin
    if (select count(*) from attendance_raw_weekend where data_provider_id = @data_provider_id and screening_date = @screening_date and complex_id = @complex_id and movie_code = @movie_code and movie_id = @arg_parent_movie_id) > 0
        begin
            update attendance_raw_weekend set attendance = attendance + @attendance where data_provider_id = @data_provider_id and screening_date = @screening_date and complex_id = @complex_id and movie_code = @movie_code and movie_id = @arg_parent_movie_id
            
            select @error = @@error
			if @error != 0
                goto error   
            
            delete attendance_raw_weekend where data_provider_id = @data_provider_id and screening_date = @screening_date and complex_id = @complex_id and movie_code = @movie_code and movie_id = @movie_id

            select @error = @@error
			if @error != 0
                goto error   
        end    
    else
	begin        
        update attendance_raw_weekend set movie_id = @arg_parent_movie_id where data_provider_id = @data_provider_id and screening_date = @screening_date and complex_id = @complex_id and movie_code = @movie_code and movie_id = @movie_id

        select @error = @@error
		if @error != 0
			goto error   
	end
        
    fetch open_csr into @data_provider_id, @screening_date, @complex_id, @movie_code, @movie_id, @attendance
end

close open_csr
deallocate open_csr

/*Minimizing attempt of sql count to optimize process*/
if @del_movie_master = 1
begin
    if (select count(*) from attendance_raw_weekend where movie_id = @arg_child_movie_id) > 0
        select @del_movie_master = 0
end

/******************************************
* cinema_attendnace Update   *
******************************************/	
declare     open_csr cursor static for 
select      movie_id, complex_id, screening_date, attendance
from        cinema_attendance
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id, @complex_id, @screening_date, @attendance
while(@@fetch_status = 0) 
begin
    if (select count(*) from cinema_attendance where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date) > 0
        begin
            update cinema_attendance set attendance = attendance + @attendance where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date
            
            select @error = @@error
			if @error != 0
                goto error   
            
            delete cinema_attendance where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date

            select @error = @@error
			if @error != 0
                goto error   
        end    
    else
	begin
        update cinema_attendance set movie_id = @arg_parent_movie_id where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date
    
        select @error = @@error
		if @error != 0
            goto error   
	end

    fetch open_csr into @movie_id, @complex_id, @screening_date, @attendance
end

close open_csr
deallocate open_csr

/*Minimizing attempt of sql count to optimize process*/

if @del_movie_master = 1
begin
    if (select count(*) from cinema_attendance where movie_id = @arg_child_movie_id) > 0
        select @del_movie_master = 0
end

/******************************************
* film_cinatt_actuals_cplx Update   *
******************************************/	
declare     open_csr cursor static for 
select      campaign_no, screening_date, complex_id, movie_id, attendance
from        film_cinatt_actuals_cplx
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @campaign_no, @screening_date, @complex_id, @movie_id, @attendance
while(@@fetch_status = 0) 
begin
    if (select count(*) from film_cinatt_actuals_cplx where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @arg_parent_movie_id) > 0
        begin
            update film_cinatt_actuals_cplx set attendance = attendance + @attendance where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @arg_parent_movie_id
            
            select @error = @@error
			if @error != 0
                goto error   
            
            delete film_cinatt_actuals_cplx where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @movie_id

            select @error = @@error
			if @error != 0
                goto error   
        end    
    else
	begin
        update film_cinatt_actuals_cplx set movie_id = @arg_parent_movie_id where campaign_no = @campaign_no and screening_date = @screening_date and complex_id = @complex_id and movie_id = @movie_id
    
        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @campaign_no, @screening_date, @complex_id, @movie_id, @attendance
end

close open_csr
deallocate open_csr

/*Minimizing attempt of sql count to optimize process*/
if @del_movie_master = 1
begin
    if (select count(*) from film_cinatt_actuals_cplx where movie_id = @arg_child_movie_id) > 0
        select @del_movie_master = 0
end

/******************************************
* movie_history Update   *
******************************************/	
declare     open_csr cursor static for 
select      movie_id, complex_id, screening_date, occurence,print_medium, three_d_type, attendance
from        movie_history
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id, @complex_id, @screening_date, @occurence, @print_medium, @three_d_type, @attendance
while(@@fetch_status = 0) 
begin
    if (select count(*) from movie_history where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type) > 0
    begin
        update movie_history set attendance = attendance + @attendance where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type

        select @error = @@error
		if @error != 0
            goto error   

        update cinetam_movie_history 
		set attendance = cinetam_movie_history.attendance + cmh_sub.attendance 
		from (select attendance from cinetam_movie_history where movie_id = @movie_id and cinetam_movie_history.complex_id = @complex_id and cinetam_movie_history.screening_date = @screening_date and cinetam_movie_history.occurence = @occurence and cinetam_movie_history.print_medium = @print_medium and cinetam_movie_history.three_d_type = @three_d_type ) as cmh_sub
		where cinetam_movie_history.movie_id = @arg_parent_movie_id and cinetam_movie_history.complex_id = @complex_id and cinetam_movie_history.screening_date = @screening_date and cinetam_movie_history.occurence = @occurence and cinetam_movie_history.print_medium = @print_medium and cinetam_movie_history.three_d_type = @three_d_type

        select @error = @@error
		if @error != 0
            goto error   

        delete cinetam_movie_history where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type

        select @error = @@error
		if @error != 0
            goto error   

        delete movie_history where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type

        select @error = @@error
		if @error != 0
            goto error   
        
    end    
    else
	begin
		insert into movie_history (movie_id, 	complex_id,	screening_date,	occurence,	altered,	advertising_open,	source,	start_date,	premium_cinema,	show_category,	certificate_group,	print_medium,	three_d_type,	movie_print_medium,	confirmed,	sessions_scheduled,	sessions_held,	attendance,	attendance_type,	country,	status)
		select @arg_parent_movie_id, complex_id,	screening_date,	occurence,	altered,	advertising_open,	source,	start_date,	premium_cinema,	show_category,	certificate_group,	print_medium,	three_d_type,	movie_print_medium,	confirmed,	sessions_scheduled,	sessions_held,	attendance,	attendance_type,	country,	status
		from movie_history where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type
		
        select @error = @@error
		if @error != 0
            goto error   

		insert into cinetam_movie_history select @arg_parent_movie_id, complex_id, screening_date, occurence, print_medium, three_d_type, cinetam_demographics_id, country_code, certificate_group_id, attendance, weighting
		from cinetam_movie_history where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type
		
        select @error = @@error
		if @error != 0
            goto error   

        delete cinetam_movie_history where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type

        select @error = @@error
		if @error != 0
            goto error   

        delete movie_history where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type

        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @movie_id, @complex_id, @screening_date, @occurence, @print_medium, @three_d_type, @attendance
end

close open_csr
deallocate open_csr

/******************************************
* movie_history_weekend Update   *
******************************************/	
declare     open_csr cursor static for 
select      movie_id, complex_id, screening_date, occurence,print_medium, three_d_type, attendance
from        movie_history_weekend
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id, @complex_id, @screening_date, @occurence, @print_medium, @three_d_type, @attendance
while(@@fetch_status = 0) 
begin
    if (select count(*) from movie_history_weekend where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type) > 0
    begin
        update movie_history_weekend set attendance = attendance + @attendance where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type

        select @error = @@error
		if @error != 0
            goto error   

        update cinetam_movie_history_weekend 
		set attendance = cinetam_movie_history_weekend.attendance + cmh_sub.attendance 
		from (select attendance from cinetam_movie_history_weekend where movie_id = @movie_id and cinetam_movie_history_weekend.complex_id = @complex_id and cinetam_movie_history_weekend.screening_date = @screening_date and cinetam_movie_history_weekend.occurence = @occurence and cinetam_movie_history_weekend.print_medium = @print_medium and cinetam_movie_history_weekend.three_d_type = @three_d_type ) as cmh_sub
		where cinetam_movie_history_weekend.movie_id = @arg_parent_movie_id and cinetam_movie_history_weekend.complex_id = @complex_id and cinetam_movie_history_weekend.screening_date = @screening_date and cinetam_movie_history_weekend.occurence = @occurence and cinetam_movie_history_weekend.print_medium = @print_medium and cinetam_movie_history_weekend.three_d_type = @three_d_type

        select @error = @@error
		if @error != 0
            goto error   

        delete cinetam_movie_history_weekend where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type

        select @error = @@error
		if @error != 0
            goto error   

        delete movie_history_weekend where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type

        select @error = @@error
		if @error != 0
            goto error   
        
    end    
    else
	begin
		insert into movie_history_weekend (movie_id, 	complex_id,	screening_date,	occurence,	altered,	advertising_open,	source,	start_date,	premium_cinema,	show_category,	certificate_group,	print_medium,	three_d_type,	movie_print_medium,	confirmed,	sessions_scheduled,	sessions_held,	attendance,	attendance_type,	country,	status)
		select @arg_parent_movie_id, complex_id,	screening_date,	occurence,	altered,	advertising_open,	source,	start_date,	premium_cinema,	show_category,	certificate_group,	print_medium,	three_d_type,	movie_print_medium,	confirmed,	sessions_scheduled,	sessions_held,	attendance,	attendance_type,	country,	status
		from movie_history_weekend where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type
		
        select @error = @@error
		if @error != 0
            goto error   

		insert into cinetam_movie_history_weekend select @arg_parent_movie_id, complex_id, screening_date, occurence, print_medium, three_d_type, cinetam_demographics_id, country_code, certificate_group_id, attendance, full_attendance, weighting
		from cinetam_movie_history_weekend where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type
		
        select @error = @@error
		if @error != 0
            goto error   

        delete cinetam_movie_history_weekend where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type

        select @error = @@error
		if @error != 0
            goto error   

        delete movie_history_weekend where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type

        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @movie_id, @complex_id, @screening_date, @occurence, @print_medium, @three_d_type, @attendance
end

close open_csr
deallocate open_csr


/*declare     open_csr cursor static for 
select      movie_id, complex_id, screening_date, occurence,print_medium, three_d_type, attendance, cinetam_demographics_id, country_code
from        cinetam_movie_history
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id, @complex_id, @screening_date, @occurence, @print_medium, @three_d_type, @attendance, @cinetam_demographics_id, @country_code
while(@@fetch_status = 0) 
begin
    if (select count(*) from cinetam_movie_history where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type and cinetam_demographics_id = @cinetam_demographics_id and country_code = @country_code) > 0
    begin
        update cinetam_movie_history set attendance = attendance + @attendance where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type and cinetam_demographics_id = @cinetam_demographics_id and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   
        
        delete cinetam_movie_history where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type and cinetam_demographics_id = @cinetam_demographics_id and country_code = @country_code

        select @error = @@error
		if @error != 0
            goto error   

        delete movie_history where  movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type and country = @country_code

        select @error = @@error
		if @error != 0
            goto error   

    end    
    else
	begin
        update cinetam_movie_history set movie_id = @arg_parent_movie_id where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type and cinetam_demographics_id = @cinetam_demographics_id
    
        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @movie_id, @complex_id, @screening_date, @occurence, @print_medium, @three_d_type, @attendance, @cinetam_demographics_id
end

close open_csr
deallocate open_csr


declare     open_csr cursor static for 
select      movie_id, complex_id, screening_date, occurence, print_medium, three_d_type, attendance, cinetam_demographics_id
from        cinetam_movie_history_weekend
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id, @complex_id, @screening_date, @occurence, @print_medium, @three_d_type, @attendance, @cinetam_demographics_id
while(@@fetch_status = 0) 
begin
    if (select count(*) from cinetam_movie_history_weekend where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type and cinetam_demographics_id = @cinetam_demographics_id) > 0
    begin
        update cinetam_movie_history_weekend set attendance = attendance + @attendance where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type and cinetam_demographics_id = @cinetam_demographics_id

        select @error = @@error
		if @error != 0
            goto error   
        
        delete cinetam_movie_history_weekend where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type and cinetam_demographics_id = @cinetam_demographics_id

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update cinetam_movie_history_weekend set movie_id = @arg_parent_movie_id where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type and cinetam_demographics_id = @cinetam_demographics_id
    
        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @movie_id, @complex_id, @screening_date, @occurence, @print_medium, @three_d_type, @attendance, @cinetam_demographics_id
end

close open_csr
deallocate open_csr
*/

declare     open_csr cursor static for 
select      movie_id, complex_id, screening_date, occurence,print_medium, three_d_type, attendance, cinetam_demographics_id
from        cinetam_wkend_movie_history
where       movie_id = @arg_child_movie_id and screening_date >= @arg_start_date and screening_date <= @arg_end_date
for         read only

open open_csr 
fetch open_csr into @movie_id, @complex_id, @screening_date, @occurence, @print_medium, @three_d_type, @attendance, @cinetam_demographics_id
while(@@fetch_status = 0) 
begin
    if (select count(*) from cinetam_wkend_movie_history where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type and cinetam_demographics_id = @cinetam_demographics_id) > 0
    begin
        update cinetam_wkend_movie_history set attendance = attendance + @attendance where movie_id = @arg_parent_movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type and cinetam_demographics_id = @cinetam_demographics_id

        select @error = @@error
		if @error != 0
            goto error   
        
        delete cinetam_wkend_movie_history where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type and cinetam_demographics_id = @cinetam_demographics_id

        select @error = @@error
		if @error != 0
            goto error   
    end    
    else
	begin
        update cinetam_wkend_movie_history set movie_id = @arg_parent_movie_id where movie_id = @movie_id and complex_id = @complex_id and screening_date = @screening_date and occurence = @occurence and print_medium = @print_medium and three_d_type = @three_d_type and cinetam_demographics_id = @cinetam_demographics_id
    
        select @error = @@error
		if @error != 0
            goto error   
	end        

    fetch open_csr into @movie_id, @complex_id, @screening_date, @occurence, @print_medium, @three_d_type, @attendance, @cinetam_demographics_id
end

close open_csr
deallocate open_csr



/*Minimizing attempt of sql count to optimize process*/
if @del_movie_master = 1
begin
    if (select count(*) from movie_history where movie_id = @arg_child_movie_id) > 0
        select @del_movie_master = 0
end

if @del_movie_master = 1
begin
movietranslation:
    begin
        /******************************************
        * data_translate_movie Update *
        ******************************************/	
        declare     open_csr cursor static for 
        select      movie_id, data_provider_id, movie_code
        from        data_translate_movie
        where       movie_id = @arg_child_movie_id
        for         read only
        
        open open_csr 
        fetch open_csr into @movie_id, @data_provider_id, @movie_code
        while(@@fetch_status = 0) 
        begin
            if (select count(*) from data_translate_movie where movie_id = @arg_parent_movie_id and data_provider_id = @data_provider_id and movie_code = @movie_code) > 0
			begin
                delete data_translate_movie where movie_id = @movie_id and data_provider_id = @data_provider_id and movie_code = @movie_code

	            select @error = @@error
				if @error != 0
	                goto error   
			end
            else
			begin
                update data_translate_movie set movie_id = @arg_parent_movie_id where movie_id = @movie_id and data_provider_id = @data_provider_id and movie_code = @movie_code
                    
	            select @error = @@error
				if @error != 0
	                goto error   
            end

            fetch open_csr into @movie_id, @data_provider_id, @movie_code
        end
        
        close open_csr
        deallocate open_csr
        
        /******************************************
        * translate_movie Update   *
        ******************************************/	
        declare     open_csr cursor static for 
        select      movie_id, provider_id, movie_code
        from        translate_movie
        where       movie_id = @arg_child_movie_id
        for         read only
        
        open open_csr 
        fetch open_csr into @movie_id, @provider_id, @movie_code
        while(@@fetch_status = 0) 
        begin
            if (select count(*) from translate_movie where movie_id = @arg_parent_movie_id and provider_id = @provider_id and movie_code = @movie_code) > 0
			begin
                delete translate_movie where movie_id = @movie_id and provider_id = provider_id and movie_code = @movie_code

	            select @error = @@error
				if @error != 0
	                goto error   
			end
            else
			begin
                update translate_movie set movie_id = @arg_parent_movie_id where movie_id = @movie_id and provider_id = @provider_id and movie_code = @movie_code
            
		        select @error = @@error
				if @error != 0
		            goto error   
			end	
		   	fetch open_csr into @movie_id, @provider_id, @movie_code
        end
        
        close open_csr
        deallocate open_csr
        
        /*
         * Terminate process if merging is for Movie Translation Only
         */

        if @arg_movie_translation_flag = 'Y'
            goto success
    end
        
    /******************************************
    * film_shell_movie_instructions Update   *
    ******************************************/	
    declare     open_csr cursor static for 
    select      movie_id,shell_code,instruction_type
    from        film_shell_movie_instructions
    where       movie_id = @arg_child_movie_id
    for         read only
    
    open open_csr 
    fetch open_csr into @movie_id, @shell_code, @instruction_type
    while(@@fetch_status = 0) 
    begin
        if (select count(*) from film_shell_movie_instructions 
                   where movie_id = @arg_parent_movie_id and shell_code = @shell_code and instruction_type = @instruction_type) > 0
		begin
            delete film_shell_movie_instructions where movie_id = @movie_id  and shell_code = @shell_code and instruction_type = @instruction_type

            select @error = @@error
			if @error != 0
                goto error   

		end
        else
		begin
            update film_shell_movie_instructions set movie_id = @arg_parent_movie_id where movie_id = @movie_id  and shell_code = @shell_code and instruction_type = @instruction_type
            
            select @error = @@error
			if @error != 0
                goto error   
		end
            
        fetch open_csr into @movie_id, @shell_code, @instruction_type
    end
    
    close open_csr
    deallocate open_csr
    
    /******************************************
    * movie_screening_ins_rev Update   *
    ******************************************/	
    declare     open_csr cursor static for 
    select      revision_no, movie_id, package_id, instruction_type
    from        movie_screening_ins_rev
    where       movie_id = @arg_child_movie_id
    for         read only
    
    open open_csr 
    fetch open_csr into @revision_no, @movie_id, @package_id, @instruction_type
    while(@@fetch_status = 0) 
    begin
        if (select count(*) from movie_screening_ins_rev 
                   where revision_no = @revision_no and movie_id = @arg_parent_movie_id and package_id = @package_id and instruction_type = @instruction_type) > 0
		begin
            delete movie_screening_ins_rev where revision_no = @revision_no and movie_id = @movie_id and package_id = @package_id and instruction_type = @instruction_type

            select @error = @@error
			if @error != 0
                goto error   
		end
        else
		begin
            update movie_screening_ins_rev set movie_id = @arg_parent_movie_id where revision_no = @revision_no and movie_id = @movie_id and package_id = @package_id and instruction_type = @instruction_type
        
            select @error = @@error
			if @error != 0
                goto error   
		end                
        fetch open_csr into @revision_no, @movie_id, @package_id, @instruction_type
    end
    
    close open_csr
    deallocate open_csr
    
    /******************************************
    * movie_screening_instructions Update   *
    ******************************************/	
    declare     open_csr cursor static for 
    select      movie_id, package_id, instruction_type
    from        movie_screening_instructions
    where       movie_id = @arg_child_movie_id
    for         read only
    
    open open_csr 
    fetch open_csr into @movie_id, @package_id, @instruction_type
    while(@@fetch_status = 0) 
    begin
        if (select count(*) from movie_screening_instructions 
                   where movie_id = @arg_parent_movie_id and package_id = @package_id and instruction_type = @instruction_type) > 0
		begin
            delete movie_screening_instructions where movie_id = @movie_id and package_id = @package_id and instruction_type = @instruction_type

            select @error = @@error
			if @error != 0
                goto error   
		end
        else
		begin
            update movie_screening_instructions set movie_id = @arg_parent_movie_id where movie_id = @movie_id and package_id = @package_id and instruction_type = @instruction_type
        
            select @error = @@error
			if @error != 0
                goto error   
		end
            
        fetch open_csr into @movie_id, @package_id, @instruction_type
    end
    
    close open_csr
    deallocate open_csr
    
    /******************************************
    * film_campaign_movie_archive Update   *
    ******************************************/	
    declare     open_csr cursor static for 
    select      campaign_no, movie_id, package_id, country_code, scheduled_count, makeup_count
    from        film_campaign_movie_archive
    where       movie_id = @arg_child_movie_id
    for         read only
    
    open open_csr 
    fetch open_csr into @campaign_no, @movie_id, @package_id, @country_code,@scheduled_count, @makeup_count
    while(@@fetch_status = 0) 
    begin
        if (select count(*) from film_campaign_movie_archive where campaign_no = @campaign_no and movie_id = @arg_parent_movie_id and package_id = @package_id and @country_code = @country_code) > 0
        begin
            update film_campaign_movie_archive set scheduled_count = scheduled_count + @scheduled_count, makeup_count = makeup_count + @makeup_count  where campaign_no = @campaign_no and movie_id = @arg_parent_movie_id and package_id = @package_id and @country_code = @country_code
            
            select @error = @@error
			if @error != 0
                goto error   
            
            delete film_campaign_movie_archive where campaign_no = @campaign_no and movie_id = @movie_id and package_id = @package_id and country_code = @country_code

            select @error = @@error
			if @error != 0
                goto error   
        end    
	    else
		begin
			update film_campaign_movie_archive set movie_id = @arg_parent_movie_id where campaign_no = @campaign_no and movie_id = @movie_id and package_id = @package_id and @country_code = @country_code
        
            select @error = @@error
			if @error != 0
                goto error   
        end
        fetch open_csr into @campaign_no, @movie_id, @package_id, @country_code,@scheduled_count, @makeup_count
    end
    
    close open_csr
    deallocate open_csr    

    /******************************************
    * movie_country Update *
    ******************************************/	
    declare     open_csr cursor static for 
    select      movie_id, country_code
    from        movie_country
    where       movie_id = @arg_child_movie_id
    for         read only
    
    open open_csr 
    fetch open_csr into @movie_id, @country_code
    while(@@fetch_status = 0) 
    begin
        if (select count(*) from movie_country 
                   where movie_id = @arg_parent_movie_id and country_code = @country_code) > 0
		begin
            delete movie_country where movie_id = @movie_id and country_code = @country_code

            select @error = @@error
			if @error != 0
                goto error   
		end
        else
		begin
            update movie_country set movie_id = @arg_parent_movie_id where movie_id = @movie_id and country_code = @country_code
            
            select @error = @@error
			if @error != 0
                goto error   
		end                
        fetch open_csr into @movie_id, @country_code
    end
    
    close open_csr
    deallocate open_csr
    
    /******************************************
    * target_audience Update *
    ******************************************/	
    declare     open_csr cursor static for 
    select      audience_profile_code, movie_id
    from        target_audience
    where       movie_id = @arg_child_movie_id
    for         read only
    
    open open_csr 
    fetch open_csr into @audience_profile_code, @movie_id
    while(@@fetch_status = 0) 
    begin
        if (select count(*) from target_audience 
                   where audience_profile_code = @audience_profile_code and movie_id = @arg_parent_movie_id) > 0
		begin
            delete target_audience where audience_profile_code = @audience_profile_code and movie_id = @movie_id

            select @error = @@error
			if @error != 0
                goto error   
		end
		else
		begin
            update target_audience set movie_id = @arg_parent_movie_id where audience_profile_code = @audience_profile_code and movie_id = @movie_id
            
            select @error = @@error
			if @error != 0
                goto error   
        end

        fetch open_csr into @audience_profile_code, @movie_id
    end
    
    close open_csr
    deallocate open_csr
    
    /******************************************
    * target_categories Update *
    ******************************************/	
    declare     open_csr cursor static for 
    select      movie_category_code, movie_id
    from        target_categories
    where       movie_id = @arg_child_movie_id
    for         read only
    
    open open_csr 
    fetch open_csr into @movie_category_code, @movie_id
    while(@@fetch_status = 0) 
    begin
        if (select count(*) from target_categories 
                   where movie_category_code = @movie_category_code and movie_id = @arg_parent_movie_id) > 0
		begin
			delete cinetam_live_movie_category_xref where movie_id = @arg_child_movie_id 

			select @error = @@error
			if @error != 0
				goto lasterror   


            delete target_categories where movie_category_code = @movie_category_code and movie_id = @movie_id

            select @error = @@error
			if @error != 0
                goto error   
		end		
        else
		begin
            update target_categories set movie_id = @arg_parent_movie_id where movie_category_code = @movie_category_code and movie_id = @movie_id
            
            select @error = @@error
			if @error != 0
                goto error   
		end
            
        fetch open_csr into @movie_category_code, @movie_id
    end
    
    close open_csr
    deallocate open_csr
    
	delete cinetam_movie_matches where movie_id = @arg_child_movie_id
            
    select @error = @@error
	if @error != 0
        goto lasterror   

	delete movie_cinetam_demographics where movie_id = @arg_child_movie_id
            
    select @error = @@error
	if @error != 0
        goto lasterror   

	delete movie_three_d_xref where movie_id = @arg_child_movie_id
            
    select @error = @@error
	if @error != 0
        goto lasterror   
	
	delete availability_follow_film_complex where movie_id = @arg_child_movie_id
            
    select @error = @@error
	if @error != 0
        goto lasterror   
	
	delete availability_follow_film_master where movie_id = @arg_child_movie_id
            
    select @error = @@error
	if @error != 0
        goto lasterror   

	delete	cinetam_trailers_screening_history where movie_movie_id = @arg_child_movie_id
	
    select @error = @@error
	if @error != 0
        goto lasterror   

	delete	cinetam_trailers_screening_history where trailer_movie_id = @arg_child_movie_id

    select @error = @@error
	if @error != 0
        goto lasterror   

	delete	cinetam_trailers_trailers where movie_id = @arg_child_movie_id 

    select @error = @@error
	if @error != 0
        goto lasterror   
		
	delete	cinetam_trailers_movie where movie_id = @arg_child_movie_id 

    select @error = @@error
	if @error != 0
        goto lasterror   

	delete cinetam_live_movie where movie_id = @arg_child_movie_id 

    select @error = @@error
	if @error != 0
        goto lasterror   

	delete cinetam_movie_category_match where movie_id = @arg_child_movie_id 

    select @error = @@error
	if @error != 0
        goto lasterror   

	insert into movie_history_sessions select @arg_parent_movie_id, complex_id, screening_date, print_medium, three_d_type,	session_time, premium_cinema
	from movie_history_sessions where movie_id = @arg_child_movie_id 
			
    select @error = @@error
	if @error != 0
        goto lasterror  

	insert into movie_history_sessions_certificate select @arg_parent_movie_id, complex_id, screening_date, print_medium, three_d_type,	session_time, premium_cinema, certificate_group_id
	from movie_history_sessions_certificate where movie_id = @arg_child_movie_id 
			
    select @error = @@error
	if @error != 0
        goto lasterror  

	delete movie_history_sessions_certificate where movie_id = @arg_child_movie_id 
    
    select @error = @@error
	if @error != 0
        goto lasterror  
		
	delete movie_history_sessions where movie_id = @arg_child_movie_id 
    
    select @error = @@error
	if @error != 0
        goto lasterror  



    update inclusion_campaign_spot_xref set movie_id = @arg_parent_movie_id where movie_id = @arg_child_movie_id 
    
    select @error = @@error
	if @error != 0
        goto lasterror  


    /******************************************
    * movie Update *
    ******************************************/	


    
    if (select count(*) from movie where movie_id = @arg_parent_movie_id) > 0
	begin
        delete movie where movie_id = @arg_child_movie_id
            
        select @error = @@error
		if @error != 0
            goto lasterror   
	end
    else
	begin
        update movie set movie_id = @arg_parent_movie_id where movie_id = @arg_child_movie_id
            
        select @error = @@error
		if @error != 0
            goto lasterror   
	end
end

/*make all return at this area to maintain logic consistency*/
success:
    COMMIT transaction
    return 0

/*only used when process haven't engaged with any transaction*/
dummyreturn:
 return 0
    
/*two stages of handling error to manage process with or without cursor*/
error:
	close open_csr
    deallocate  open_csr

lasterror:
    select @error = @@error
	rollback transaction
    raiserror ('Unable to merge Child Movie to Parent Movie' , 16, 1)
	return -1
GO
