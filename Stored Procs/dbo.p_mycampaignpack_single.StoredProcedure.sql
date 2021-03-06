/****** Object:  StoredProcedure [dbo].[p_mycampaignpack_single]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_mycampaignpack_single]
GO
/****** Object:  StoredProcedure [dbo].[p_mycampaignpack_single]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE          proc [dbo].[p_mycampaignpack_single]	@arg_login_id		varchar(30),
					@arg_screening_date	datetime,
					@arg_campaign_no	int
AS


DECLARE		@error				int,
		@ins_complete_divider		int,
		@ins_complete_divisor		int,
		@ins_generated_divider		int,
		@ins_generated_divisor		int,
		@control_idc			char(1),
		@campaign_status		char(1),  
		@campaign_no			int,   
		@product_desc			varchar(100),   
		@start_date			datetime,   
		@end_date			datetime,   
		@makeup_deadline		datetime,   
		@cinelight_status		char(1),  
		@includes_media			char(1),
		@includes_media_x		int,
		@includes_cinelights		char(1),
		@includes_cinelights_x		int,
		@includes_infoyer		char(1),
		@includes_infoyer_x		int,
		@includes_miscellaneous		char(1),
		@includes_miscellaneous_x	int,
		@includes_follow_film		char(1),
		@includes_premium_position	char(1),
		@includes_gold_class		char(1),
		@rep_id				int,
		@last_name			varchar(30),   
		@first_name			varchar(30),   
		@ins_complete			int,
		@ins_generated			int,
		@last_activity			datetime,
		@start_cnt			int,
		@unallocated_cnt		int,
		@makeup_cnt			int,
		@next_activity			datetime,
		@package_count			int,
		@package_id			int,
		@package_apprvcount		int,
		@package_waitcount		int,
		@package_declinedcount		int,
		@revision_status_code		char(1),
		@package_code			char(1),
		@package_desc			char(100),
		@package_ins_status		char(1),
		@package_start_date		datetime,
		@client_id			int,
		@client_name			varchar(50),
		@agency_name			varchar(50),
		@agency_deal			char(1),
		@state_code			char(10),
		@agency_id			int,
		@branch_code			char(2),
		@prev_campaign_no		int

SET NOCOUNT ON

/*
 * Create Temp Table
 */

CREATE TABLE #mymaincampaign_list
(
	campaign_no	int	not null,
	package_id	int	not null,
	control_idc	char(1)	not null,
PRIMARY KEY
(
	campaign_no,
	package_id,
	control_idc
)
)

INSERT INTO	#mymaincampaign_list
SELECT		film_campaign.campaign_no,
		campaign_package.package_id,
		film_campaign_reps.control_idc
FROM		employee,
		film_campaign_reps,
		film_campaign,
		campaign_package
WHERE		employee.login_id = @arg_login_id and
		employee.rep_id = film_campaign_reps.rep_id and
		film_campaign_reps.control_idc <> 'A' and
		film_campaign_reps.campaign_no = film_campaign.campaign_no and
		film_campaign.campaign_status = 'L' and
		film_campaign.campaign_no = campaign_package.campaign_no and
		( (	campaign_package.used_by_date is null or
			campaign_package.used_by_date >= @arg_screening_date	) and
		(	campaign_package.start_date is null or
			campaign_package.start_date <= @arg_screening_date	) ) and
		film_campaign.campaign_no = @arg_campaign_no
GROUP BY	film_campaign.campaign_no,
		campaign_package.package_id,
		film_campaign_reps.control_idc
union
SELECT		distinct fc.campaign_no,
			cp.package_id,
			'W'
FROM		employee e,
			sales_team_coordinators stc,
			campaign_rep_teams crt, 
			film_campaign_reps fcr, 
			film_campaign fc,
			campaign_package cp
WHERE		e.login_id = @arg_login_id
and			fc.campaign_no = fcr.campaign_no
and 		fcr.campaign_reps_id = crt.campaign_reps_id
and			crt.team_id = stc.team_id
and			e.employee_id = stc.employee_id	
and			fc.campaign_status = 'L' 
and			fc.campaign_no = cp.campaign_no 
and			((cp.used_by_date is null 
or			cp.used_by_date >= @arg_screening_date	) 
and			(cp.start_date is null 
or			cp.start_date <= @arg_screening_date))
GROUP BY	fc.campaign_no,
			cp.package_id
union
SELECT		film_campaign.campaign_no,
		campaign_package.package_id,
		film_campaign_reps.control_idc
FROM		employee,
			employee_rep_xref erx,
		film_campaign_reps,
		film_campaign,
		campaign_package
WHERE		employee.login_id = @arg_login_id and
		employee.employee_id = erx.employee_id and
		erx.rep_id = film_campaign_reps.rep_id and
		film_campaign_reps.control_idc <> 'A' and
		film_campaign_reps.campaign_no = film_campaign.campaign_no and
		film_campaign.campaign_status = 'L' and
		film_campaign.campaign_no = campaign_package.campaign_no and
		( (	campaign_package.used_by_date is null or
			campaign_package.used_by_date >= @arg_screening_date	) and
		(	campaign_package.start_date is null or
			campaign_package.start_date <= @arg_screening_date	) ) and
		film_campaign.campaign_no = @arg_campaign_no
GROUP BY	film_campaign.campaign_no,
		campaign_package.package_id,
		film_campaign_reps.control_idc

ORDER BY	film_campaign.campaign_no,
		campaign_package.package_id

CREATE TABLE 	#mycampaign_list
(
		control_idc			char(1) null,
		campaign_status			char(1) null,  
		campaign_no			int null,   
		product_desc			varchar(100) null,   
		start_date			datetime null,   
		end_date			datetime null,   
		makeup_deadline			datetime null,   
		cinelight_status		char(1) null,  
		includes_media			char(1) null,
		includes_media_x		int null,
		includes_cinelights		char(1) null,
		includes_cinelights_x		int null,
		includes_infoyer		char(1) null,
		includes_infoyer_x		int null,
		includes_miscellaneous		char(1) null,
		includes_miscellaneous_x	int null,
		includes_follow_film 		char(1) null,
		includes_premium_position 	char(1) null,
		includes_gold_class 		char(1) null,
		rep_id 				int null,
		last_name 			varchar(30) null,   
		first_name 			varchar(30) null,   
		ins_complete 			int null,
		ins_generated 			int null,
		last_activity 			datetime null,
		start_cnt 			int null,
		unallocated_cnt 		int null,
		makeup_cnt 			int null,
		next_activity 			datetime null,
		package_apprvcount 		int null,
		package_waitcount 		int null,
		package_declinedcount 		int null,
		package_id 			int null,
		package_code 			char(1) null,
		package_desc 			char(100) null,
		package_ins_status 		char(1) null,
		client_id 			int null,
		client_name 			varchar(50) null,
		agency_name 			varchar(50) null,
		agency_deal 			char(1) null,
		state_code 			char(10) null,
		agency_id 			int null,
		branch_code 			char(2) null
)

/*
 * Declare Cursor
 */

DECLARE		campaign_csr CURSOR FORWARD_ONLY STATIC FOR
SELECT 		#mymaincampaign_list.control_idc,
		film_campaign.campaign_status,  
		film_campaign.campaign_no,   
		film_campaign.product_desc,   
		film_campaign.start_date,   
		film_campaign.end_date,   
		film_campaign.makeup_deadline,   
		film_campaign.cinelight_status,  
		film_campaign.includes_media,
		film_campaign.includes_cinelights,
		film_campaign.includes_infoyer,
		film_campaign.includes_miscellaneous,
		film_campaign.includes_follow_film,
		film_campaign.includes_premium_position,
		film_campaign.includes_gold_class,
		film_campaign.rep_id,
		sales_rep.last_name,   
		sales_rep.first_name,   
		film_campaign.client_id,
		client.client_name,
		agency.agency_name,
		film_campaign.agency_deal,
		branch.state_code,
		film_campaign.agency_id,
		film_campaign.branch_code,
		campaign_package.package_id,
		campaign_package.package_code,
		campaign_package.package_desc,
		campaign_package.start_date	
FROM		#mymaincampaign_list,
		film_campaign,
		campaign_package,
	 	sales_rep,
		client,
		agency,
		branch
WHERE		#mymaincampaign_list.campaign_no = film_campaign.campaign_no and
		film_campaign.campaign_no = campaign_package.campaign_no and
		#mymaincampaign_list.package_id = campaign_package.package_id and
		film_campaign.rep_id = sales_rep.rep_id and
		film_campaign.client_id = client.client_id and 
		film_campaign.agency_id = agency.agency_id and
		film_campaign.branch_code = branch.branch_code
FOR READ ONLY

OPEN		campaign_csr
FETCH		campaign_csr
INTO		@control_idc,
		@campaign_status,  
		@campaign_no,   
		@product_desc,   
		@start_date,   
		@end_date,   
		@makeup_deadline,   
		@cinelight_status,  
		@includes_media,
		@includes_cinelights,
		@includes_infoyer,
		@includes_miscellaneous,
		@includes_follow_film,
		@includes_premium_position,
		@includes_gold_class,
		@rep_id,
		@last_name,   
		@first_name,   
		@client_id,
		@client_name,
		@agency_name,
		@agency_deal,
		@state_code,
		@agency_id,
		@branch_code,
		@package_id,
		@package_code,
		@package_desc,
		@package_start_date

WHILE	(@@fetch_status=0)
begin
	
	/*
	 * Verifying if DNA have have entries in @screening_date
	 */
	if @prev_campaign_no = @campaign_no
		goto jump_to_package

	/*
	 * Following computation are campain level computation and needs to skip if same
	 * campain_no in the loop
	 */
	select @prev_campaign_no = @campaign_no

	select @includes_media_x = 	(	
					select 	count(*)
				 	from 	campaign_spot
		 		    	where 	campaign_spot.campaign_no = @campaign_no and
						campaign_spot.screening_date = @arg_screening_date
					)
	
	select @includes_cinelights_x =	(
					select 	count(*)
					from 	cinelight_spot
		 			where	cinelight_spot.campaign_no = @campaign_no and 
						cinelight_spot.screening_date = @arg_screening_date
					)
	select @includes_infoyer_x = 	(
					select 	count(*)
					from 	inclusion,
						inclusion_spot
					where 	inclusion.inclusion_id = inclusion_spot.inclusion_id and
						inclusion.inclusion_type in (5,14) and
						inclusion_spot.campaign_no = @campaign_no and
						inclusion_spot.screening_date = @arg_screening_date
					)

	select @includes_miscellaneous_x = (
					select	count(*)
					from 	inclusion,
						inclusion_spot
					where	inclusion.inclusion_id = inclusion_spot.inclusion_id and
						inclusion.inclusion_type not in (5,11,12,13,14) and
						inclusion_spot.campaign_no =@campaign_no and
						inclusion_spot.screening_date = @arg_screening_date
					)

	/*
	Campaign Activity
	*/
	select @last_activity = 	(
					select	max(screening_date)
					from 	campaign_spot
					where	campaign_spot.campaign_no = @campaign_no and 
						campaign_spot.screening_date < @arg_screening_date and
						campaign_spot.spot_type <> 'M'
					)
	/*
	Unders/Overs
	*/	


	select @start_cnt = 		(
					select 	count(spot_status)
					from	campaign_spot
					where 	campaign_spot.campaign_no = @campaign_no and
						campaign_spot.screening_date < @arg_screening_date and
						(	campaign_spot.spot_status = 'U' or
							campaign_spot.spot_status = 'N'	)
					) -
					(
					select 	count(spot_status)
					from	campaign_spot
					where 	campaign_spot.campaign_no = @campaign_no and
						campaign_spot.screening_date < @arg_screening_date and
						(	campaign_spot.spot_type = 'M' or
							campaign_spot.spot_type = 'V'	) and
						campaign_spot.spot_status = 'X'
					)


	select @unallocated_cnt = 	(
					select	count(spot_id)
					from	campaign_spot
					where	campaign_spot.campaign_no = @campaign_no and
						campaign_spot.screening_date = @arg_screening_date and
						(spot_status = 'U' or spot_status = 'N')
					)

	select @makeup_cnt	=	(
					select	count(spot_id)
					from	campaign_spot
					where	campaign_spot.campaign_no = @campaign_no and
						campaign_spot.screening_date = @arg_screening_date and
						(	spot_type = 'M' or spot_type = 'V'	) and
						spot_status = 'X'
					)


	select	@next_activity	= 	(
					select	min(screening_date)
					from campaign_spot
					where campaign_spot.campaign_no = @campaign_no and
						campaign_spot.screening_date > @arg_screening_date and
						campaign_spot.spot_type <> 'M'
					)


	select 	@package_apprvcount 	= 0 
	select 	@package_waitcount 	= 0
	select 	@package_declinedcount 	= 0

	select	@ins_generated_divider 	= sum	(case complex_date.certificate_status
							when 'G' then 	1
							when 'E' then 	1
							else 		0
							end
						), 
		@ins_generated_divisor = count 	(campaign_spot.spot_id)  
	from	campaign_spot, complex_date
	where	campaign_spot.campaign_no = @campaign_no and
		campaign_spot.complex_id = complex_date.complex_id and
		campaign_spot.screening_date = complex_date.screening_date and
		campaign_spot.screening_date = @arg_screening_date

	if isnull(@ins_generated_divider,0) = 0 or isnull(@ins_generated_divisor,0) = 0
		select	@ins_generated = 0
	else
		select	@ins_generated = (@ins_generated_divider / @ins_generated_divisor) * 100	

	jump_to_package:

	/*
	Verify if ok to insert in the list
	*/		
	if (@includes_media_x + @includes_cinelights_x + @includes_infoyer_x) = 0 and  @start_cnt + ( @unallocated_cnt -  @makeup_cnt ) = 0
		and not ((dateadd(dd,7,@end_date) <= @arg_screening_date) and @makeup_deadline >= @arg_screening_date)
		GOTO jumptofetcher

	/*
	 * Do not calculate packages if no onscreen activity
	 */
	if @includes_media_x = 0 
		and not ((dateadd(dd,7,@end_date) <= @arg_screening_date) and @makeup_deadline >= @arg_screening_date)
		GOTO jumptofetcher

	declare		campaign_packagests_csr cursor forward_only static for
	SELECT		campaign_package_revision.revision_status_code
	FROM		campaign_package_revision, campaign_package_ins_xref
	WHERE 		(campaign_package_revision.package_id = @package_id 	) AND
			(campaign_package_ins_xref.screening_date = @arg_screening_date	) AND 
			(campaign_package_revision.package_id = campaign_package_ins_xref.package_id ) AND  
			(campaign_package_revision.revision_no = campaign_package_ins_xref.revision_no ) AND  
			(campaign_package_revision.revision_status_code = campaign_package_ins_xref.revision_status_code ) AND
			(campaign_package_revision.revision_status_code <> 'D')
	order by	campaign_package_revision.revision_status_code desc,
			revision_date desc,
			last_reviewed_date desc
	FOR READ ONLY
	open	campaign_packagests_csr
	fetch	campaign_packagests_csr into @revision_status_code
		
	if @package_start_date > @arg_screening_date
		select @package_ins_status = ''
	else
	begin		
		if @@fetch_status != 0
			begin
				select	@package_ins_status = 'X'				select 	@package_declinedcount = @package_declinedcount + 1
			end
		else
			begin
				select @package_ins_status = @revision_status_code
				if @revision_status_code = 'S'
					select 	@package_waitcount = @package_waitcount + 1
				else
					if @revision_status_code = 'A'
						select 	@package_apprvcount = @package_apprvcount + 1
					else
						select 	@package_declinedcount = @package_declinedcount + 1
			end
	end

	insertdata:

	close		campaign_packagests_csr
	deallocate	campaign_packagests_csr

        insert into	#mycampaign_list
        		(control_idc,
			campaign_status,  
			campaign_no,   
			product_desc,   
			start_date,   
			end_date,   
			makeup_deadline,   
			cinelight_status,  
			includes_media,includes_media_x,
			includes_cinelights,
			includes_cinelights_x,
			includes_infoyer,
			includes_infoyer_x,
			includes_miscellaneous,
			includes_miscellaneous_x,
			includes_follow_film,
			includes_premium_position,
			includes_gold_class,
			rep_id,
			last_name,   
			first_name,   
			ins_complete,
			ins_generated,
			last_activity,
			start_cnt,
			unallocated_cnt,
			makeup_cnt,
			next_activity,
			package_apprvcount,
			package_waitcount,
			package_declinedcount,
			package_id,
			package_code,
			package_desc,
			package_ins_status,
			client_id,
			client_name,
			agency_name,
			agency_deal,
			state_code,
			agency_id,
			branch_code)
	values		(@control_idc,
			@campaign_status,  
			@campaign_no,   
			@product_desc,   
			@start_date,   
			@end_date,   
			@makeup_deadline,   
			@cinelight_status,  
			@includes_media,
			@includes_media_x,
			@includes_cinelights,
			@includes_cinelights_x,
			@includes_infoyer,
			@includes_infoyer_x,
			@includes_miscellaneous,
			@includes_miscellaneous_x,
			@includes_follow_film,
			@includes_premium_position,
			@includes_gold_class,
			@rep_id,
			@last_name,   
			@first_name,   
			@ins_complete,
			@ins_generated,
			@last_activity,
			@start_cnt,
			@unallocated_cnt,
			@makeup_cnt,
			@next_activity,
			@package_apprvcount,
			@package_waitcount,
			@package_declinedcount,
			@package_id,
			@package_code,
			@package_desc,
			@package_ins_status,
			@client_id,
			@client_name,
			@agency_name,
			@agency_deal,
			@state_code,
			@agency_id,
			@branch_code)

	/*
	 * jumptofetcher
	 */
	jumptofetcher:

	fetch		campaign_csr
	into		@control_idc,
			@campaign_status,  
			@campaign_no,   
			@product_desc,   
			@start_date,   
			@end_date,   
			@makeup_deadline,   
			@cinelight_status,  
			@includes_media,
			@includes_cinelights,
			@includes_infoyer,
			@includes_miscellaneous,
			@includes_follow_film,
			@includes_premium_position,
			@includes_gold_class,
			@rep_id,
			@last_name,   
			@first_name,   
			@client_id,
			@client_name,
			@agency_name,
			@agency_deal,
			@state_code,
			@agency_id,
			@branch_code,
			@package_id,
			@package_code,
			@package_desc,
			@package_start_date
end




deallocate		campaign_csr

select 			control_idc,
			campaign_status,  
			campaign_no,   
			product_desc,   
			start_date,   
			end_date,   
			makeup_deadline,   
			cinelight_status,  
			includes_media,
			includes_media_x,
			includes_cinelights,
			includes_cinelights_x,
			includes_infoyer,
			includes_infoyer_x,
			includes_miscellaneous,
			includes_miscellaneous_x,
			includes_follow_film,includes_premium_position,
			includes_gold_class,
			rep_id,
			last_name,   
			first_name,   
			ins_complete,
			ins_generated,
			last_activity,
			start_cnt,
			unallocated_cnt,
			makeup_cnt,
			next_activity,
			package_apprvcount,
			package_waitcount,
			package_declinedcount,
			package_id,
			package_code,
			package_desc,
			package_ins_status,
			client_id,
			client_name,
			agency_name,
			agency_deal,
			state_code,
			agency_id,
			branch_code
from 			#mycampaign_list

return 0
GO
