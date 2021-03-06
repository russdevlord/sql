/****** Object:  StoredProcedure [dbo].[p_campaign_operation_list]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_operation_list]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_operation_list]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE      proc [dbo].[p_campaign_operation_list]		@arg_screening_date		datetime,
												@arg_package_id			int
AS


DECLARE		@error						int,
			@ins_complete_divider		int,
			@ins_complete_divisor		int,
			@ins_generated_divider		int,
			@ins_generated_divisor		int,
			@control_idc				char(1),
			@campaign_status			char(1),  
			@campaign_no				int,   
			@product_desc				varchar(100),   
			@start_date					datetime,   
			@end_date					datetime,   
			@makeup_deadline			datetime,   
			@cinelight_status			char(1),  
			@includes_media				char(1),
			@includes_media_x			int,
			@includes_cinelights		char(1),
			@includes_cinelights_x		int,
			@includes_infoyer			char(1),
			@includes_infoyer_x			int,
			@includes_miscellaneous		char(1),
			@includes_miscellaneous_x	int,
			@includes_follow_film		char(1),
			@includes_premium_position	char(1),
			@includes_gold_class		char(1),
			@rep_id						int,
			@last_name					varchar(30),   
			@first_name					varchar(30),   
			@ins_complete				int,
			@ins_generated				int,
			@last_activity				datetime,
			@start_cnt					int,
			@unallocated_cnt			int,
			@makeup_cnt					int,
			@next_activity				datetime,
			@package_count				int,
			@package_id					int,
			@package_apprvcount			int,
			@package_waitcount			int,
			@package_declinedcount		int,
			@revision_status_code		char(1),
			@package_code				char(1),
			@package_desc				char(100),
			@package_ins_status			char(1),
			@package_start_date			datetime,
			@client_id					int,
			@client_name				varchar(50),
			@agency_name				varchar(50),
			@agency_deal				char(1),
			@state_code					char(10),
			@agency_id					int,
			@branch_code				char(2),
			@revision_no				int,
			@requestor					int

SET NOCOUNT ON

/*
 * Create Temp Table
 */

CREATE TABLE #mymaincampaign_list
(
	campaign_no	int	not null,
	package_id	int	not null
PRIMARY KEY
(
	campaign_no,
	package_id
)
)

INSERT INTO	#mymaincampaign_list
SELECT		film_campaign.campaign_no,
			campaign_package.package_id
FROM		film_campaign,
			campaign_package
WHERE		film_campaign.campaign_status = 'L' and
			film_campaign.campaign_no = campaign_package.campaign_no and
		( (	campaign_package.used_by_date is null or
			campaign_package.used_by_date >= @arg_screening_date	) and
		(	campaign_package.start_date is null or
			campaign_package.start_date <= @arg_screening_date	) ) and
		(	@arg_package_id is null or
			@arg_package_id = campaign_package.package_id		)
GROUP BY	film_campaign.campaign_no,
			campaign_package.package_id
ORDER BY	film_campaign.campaign_no,
			campaign_package.package_id

CREATE TABLE 	#mycampaign_list
(
		control_idc					char(1) 		null,
		campaign_status				char(1) 		null,  
		campaign_no					int 			null,   
		product_desc				varchar(100) 	null,   
		start_date					datetime 		null,   
		end_date					datetime 		null,   
		makeup_deadline				datetime 		null,   
		cinelight_status			char(1) 		null,  
		includes_media				char(1) 		null,
		includes_media_x			int 			null,
		includes_cinelights			char(1) 		null,
		includes_cinelights_x		int 			null,
		includes_infoyer			char(1) 		null,
		includes_infoyer_x			int 			null,
		includes_miscellaneous		char(1) 		null,
		includes_miscellaneous_x	int 			null,
		includes_follow_film 		char(1) 		null,
		includes_premium_position 	char(1) 		null,
		includes_gold_class 		char(1) 		null,
		rep_id 						int 			null,
		last_name 					varchar(30) 	null,   
		first_name 					varchar(30) 	null,   
		ins_complete 				int 			null,
		ins_generated 				int 			null,
		last_activity 				datetime 		null,
		start_cnt 					int 			null,
		unallocated_cnt 			int 			null,
		makeup_cnt 					int 			null,
		next_activity 				datetime 		null,
		package_apprvcount 			int 			null,
		package_waitcount 			int 			null,
		package_declinedcount 		int 			null,
		package_id 					int 			null,
		package_code 				char(1) 		null,
		package_desc 				char(100) 		null,
		package_ins_status 			char(1) 		null,
		client_id 					int 			null,
		client_name 				varchar(50)		null,
		agency_name 				varchar(50) 	null,
		agency_deal 				char(1) 		null,
		state_code 					char(10) 		null,
		agency_id 					int 			null,
		branch_code 				char(2) 		null,
		revision_no					int 			null,
		requestor					int 			null
)

/*
 * Declare Cursor
 */

DECLARE		campaign_csr CURSOR FORWARD_ONLY STATIC FOR
SELECT 		'',
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
	select 	@package_apprvcount	= 0 
	select 	@package_waitcount = 0
	select 	@package_declinedcount	= 0
	select  @revision_status_code = '',
			@revision_no = 0,
			@requestor = 0

	select 	@makeup_cnt = 0
	select 	@unallocated_cnt = 0

	select 	@makeup_cnt = count(spot_id)
	from	campaign_spot
	where	campaign_no = @campaign_no
	and		(spot_type = 'M'
	or		spot_type  = 'V')	

	select 	@unallocated_cnt = count(spot_id)
	from	campaign_spot
	where	campaign_no = @campaign_no
	and		(spot_status = 'U'
	or		spot_status  = 'N')	

	select 	@start_cnt = count(spot_id)
	from	campaign_spot
	where	campaign_no = @campaign_no
	and		screening_date = @arg_screening_date
	and		package_id = @package_id
	
	select	@start_cnt = isnull(@start_cnt,0) 
	
	select	@start_cnt = @start_cnt + count(*)
	from 	inclusion,
			inclusion_spot
	where	inclusion.inclusion_id = inclusion_spot.inclusion_id 
	and		inclusion.inclusion_type in (24, 29, 30, 31, 32) 
	and		inclusion_spot.campaign_no =	@campaign_no 
	and		inclusion_spot.screening_date = @arg_screening_date

	select 	@unallocated_cnt = @unallocated_cnt - @makeup_cnt

	if @start_cnt > 0 or @unallocated_cnt > 0
	begin
			
		SELECT		@revision_status_code = campaign_package_revision.revision_status_code, @revision_no = campaign_package_revision.revision_no, @requestor = campaign_package_revision.requestor
		FROM		campaign_package_revision, campaign_package_ins_xref
		WHERE 		(campaign_package_revision.package_id = @package_id 	) AND
				(campaign_package_ins_xref.screening_date = @arg_screening_date	) AND 
				(campaign_package_revision.package_id = campaign_package_ins_xref.package_id ) AND  
				(campaign_package_revision.revision_no = campaign_package_ins_xref.revision_no ) AND  
				(campaign_package_revision.revision_status_code = campaign_package_ins_xref.revision_status_code ) AND
				(campaign_package_revision.revision_status_code in ('N','S'))
	
		IF isnull(@revision_status_code,'') = ''
				SELECT		@revision_status_code = campaign_package_revision.revision_status_code, @revision_no = campaign_package_revision.revision_no, @requestor = campaign_package_revision.requestor
				FROM		campaign_package_revision, campaign_package_ins_xref
				WHERE 		(campaign_package_revision.package_id = @package_id 	) AND
						(campaign_package_ins_xref.screening_date = @arg_screening_date	) AND 
						(campaign_package_revision.package_id = campaign_package_ins_xref.package_id ) AND  
						(campaign_package_revision.revision_no = campaign_package_ins_xref.revision_no ) AND  
						(campaign_package_revision.revision_status_code = campaign_package_ins_xref.revision_status_code ) AND
						(campaign_package_revision.revision_status_code in ('A'))
	
	
		IF isnull(@revision_status_code,'') = ''
			begin
			select	@package_ins_status = 'X'
			select 	@package_declinedcount = @package_declinedcount + 1	
			end
		ELSE
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
				branch_code,
				revision_no,
				requestor)
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
				@branch_code,
				@revision_no,
				@requestor)
		end

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

select 			#mycampaign_list.control_idc,
			#mycampaign_list.campaign_status,  
			#mycampaign_list.campaign_no,   
			#mycampaign_list.product_desc,   
			#mycampaign_list.start_date,   
			#mycampaign_list.end_date,   
			#mycampaign_list.makeup_deadline,   
			#mycampaign_list.cinelight_status,  
			#mycampaign_list.includes_media,
			#mycampaign_list.includes_media_x,
			#mycampaign_list.includes_cinelights,
			#mycampaign_list.includes_cinelights_x,
			#mycampaign_list.includes_infoyer,
			#mycampaign_list.includes_infoyer_x,
			#mycampaign_list.includes_miscellaneous,
			#mycampaign_list.includes_miscellaneous_x,
			#mycampaign_list.includes_follow_film,
			#mycampaign_list.includes_premium_position,
			#mycampaign_list.includes_gold_class,
			#mycampaign_list.rep_id,
			#mycampaign_list.last_name,   
			#mycampaign_list.first_name,   
			#mycampaign_list.ins_complete,
			#mycampaign_list.ins_generated,
			#mycampaign_list.last_activity,
			#mycampaign_list.start_cnt,
			#mycampaign_list.unallocated_cnt,
			#mycampaign_list.makeup_cnt,
			#mycampaign_list.next_activity,
			#mycampaign_list.package_apprvcount,
			#mycampaign_list.package_waitcount,
			#mycampaign_list.package_declinedcount,
			#mycampaign_list.package_id,
			#mycampaign_list.package_code,
			#mycampaign_list.package_desc,
			#mycampaign_list.package_ins_status,
			#mycampaign_list.client_id,
			#mycampaign_list.client_name,
			#mycampaign_list.agency_name,
			#mycampaign_list.agency_deal,
			#mycampaign_list.state_code,
			#mycampaign_list.agency_id,
			#mycampaign_list.branch_code,
			#mycampaign_list.revision_no,
			#mycampaign_list.requestor,
			film_campaign.business_unit_id
from 			#mycampaign_list,
				film_campaign
where							#mycampaign_list.campaign_no = film_campaign.campaign_no
order by #mycampaign_list.rep_id, #mycampaign_list.campaign_no, package_code

return 0
GO
