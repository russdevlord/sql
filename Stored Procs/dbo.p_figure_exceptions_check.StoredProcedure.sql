/****** Object:  StoredProcedure [dbo].[p_figure_exceptions_check]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_figure_exceptions_check]
GO
/****** Object:  StoredProcedure [dbo].[p_figure_exceptions_check]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_figure_exceptions_check] @campaign_no		char(7),
                                      @return_code		tinyint
as

/*
 * Declare Variables
 */

declare @error        				int,
        @rowcount     				int,
        @errorode							int,
        @req_count					int,
        @scr_count					int,
        @actual_deposit				money,
        @camp_deposit				money,
        @camp_type					char(1),
        @error_found					tinyint,
        @error_msg					varchar(100),
        @renewal_no					char(7),
        @renewal_nos					varchar(50),
        @renewal_start				datetime,
        @renewal_end					datetime,
        @renewal_period				smallint,
        @is_official					char(1),
        @form_date					varchar(11),
        @campaign_release			char(1),
        @done							tinyint

/*
 * Create Temporary Table
 */

create table #excepts
(
	error_desc	varchar(255)	null
)

/*
 * Get Campaign Information
 */

select @camp_deposit = deposit,
       @camp_type = campaign_type,
       @is_official = is_official,
       @campaign_release = campaign_release
  from slide_campaign
 where campaign_no = @campaign_no

select @error = @@error,
		 @rowcount = @@rowcount

if(@error != 0 or @rowcount != 1)
	return -1

/*
 * Return if the Figures have not been Released
 */

if(@campaign_release = 'N')
	return 0

/*
 * Check Deposit
 */

select @actual_deposit = isnull(sum(gross_amount),0)
  from slide_transaction
 where campaign_no = @campaign_no and
       tran_type = 57 --Slide Deposit

if(@actual_deposit = 0)
begin

	if(@return_code = 0)
		return 1
	else
	begin
		select @error_msg = 'No Deposit.'
		insert into #excepts values (@error_msg)
	end

end

if(@actual_deposit <> ( 0 - @camp_deposit ))
begin

	if(@return_code = 0)
		return 1
	else
	begin
		select @error_msg = 'Deposit Conflict. Campaign Deposit is $' + convert(varchar(10),(0 - @camp_deposit)) + ' and Actual Deposit is $' + convert(varchar(10),@actual_deposit) + '.'
		insert into #excepts values (@error_msg)
	end

end

/*
 * Report all Renewals, Extensions and Supercedes
 */

if(@camp_type = 'R' or @camp_type = 'S' or @camp_type = 'E')
begin

	/*
    * Get Parent Campaign No
    */

	select @renewal_no = max(parent_campaign)
     from slide_family
    where child_campaign = @campaign_no and
          relationship_type = @camp_type

	select @error = @@error,
			 @rowcount = @@rowcount

	if(@error = 0 or @rowcount = 1)
	begin

		/*
		 * Get Campaign Information from Parent Campaign
		 */
	
		select @renewal_nos = name_on_slide,
				 @renewal_start = start_date,
				 @renewal_period = min_campaign_period + bonus_period
		  from slide_campaign
		 where campaign_no = @renewal_no
	
		select @renewal_end = dateadd(dd,((@renewal_period * 7) -1),@renewal_start)

		if(@renewal_end < @renewal_start)
		begin
			select @renewal_end = @renewal_start
		end
	
		/*
		 * Setup Message
		 */
	
		if(@return_code = 0)
			return 1
		else
		begin

			if(@camp_type = 'R')
				select @error_msg = 'Renewal of Campaign: '

			if(@camp_type = 'S')
				select @error_msg = 'Supercede of Campaign: '

			if(@camp_type = 'E')
				select @error_msg = 'Extension of Campaign: '

		   execute p_sfin_format_date @renewal_end, 1, @form_date OUTPUT
			select @error_msg = @error_msg + @renewal_no + ' - ' + @renewal_nos + ' ( Expiring on ' + @form_date + ' )'
			insert into #excepts values (@error_msg)

		end

	end
end

/*
 * Check Screenings
 */

select @scr_count = count(slide_campaign_screening.campaign_screening_id)
  from slide_campaign_screening,   
       slide_campaign_spot  
 where slide_campaign_screening.spot_id = slide_campaign_spot.spot_id and  
       slide_campaign_spot.campaign_no = @campaign_no

if(@scr_count = 0)
begin

	if(@return_code = 0)
		return 1
	else
	begin
		select @error_msg = 'New Account Entry Problems: No campaign screenings detected.'
		insert into #excepts values (@error_msg)
	end

end

/*
 * Check NPU Requests
 */

select @req_count = 0,
       @done      = 0

/*
 * Check if Campaign has any Accepted Requests
 */

select @req_count = count(request_no)
  from npu_request
 where campaign_no = @campaign_no and
		 request_judgement = 'A'

if(@req_count > 0)
	select @done = 1

/*
 * Check if Campaign has any Submitted Requests
 */

if(@done = 0)
begin

	select @req_count = count(request_no)
	  from npu_request
	 where campaign_no = @campaign_no and
			 request_judgement = 'R'

	if(@req_count > 0)
	begin

		select @done = 1

		if(@return_code = 0)
			return 1
		else
		begin
			select @error_msg = 'Production Request(s) have been Rejected by the NPU.'
			insert into #excepts values (@error_msg)
		end

	end

end

/*
 * Check if Campaign has No Submitted Requests
 */

if(@done = 0)
begin

	select @req_count = count(request_no)
	  from npu_request
	 where campaign_no = @campaign_no and
			 request_status = 'S'

	if(@req_count > 0)
	begin

		select @done = 1

		if(@return_code = 0)
			return 1
		else
		begin
			select @error_msg = 'Production Request(s) waiting on Judgement.'
			insert into #excepts values (@error_msg)
		end

	end

end

/*
 * Assume No Valid Request
 */

if(@done = 0)
begin

	if(@return_code = 0)
		return 1
	else
	begin
		select @error_msg = 'No Production Request has yet been submitted to the NPU.'
		insert into #excepts values (@error_msg)
	end

end 

/*
 * Return Dataset
 */

if(@return_code = 1)
	select * from #excepts

/*
 * Return Success
 */

return 0
GO
