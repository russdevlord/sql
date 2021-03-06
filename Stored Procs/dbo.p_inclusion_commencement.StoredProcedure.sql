/****** Object:  StoredProcedure [dbo].[p_inclusion_commencement]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_inclusion_commencement]
GO
/****** Object:  StoredProcedure [dbo].[p_inclusion_commencement]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_inclusion_commencement] 	@start_date 	datetime,
                                    	@end_date 		datetime,
										@country_code	char(1)
as

declare @campaign_no				integer,
		@errorode   					integer,
		@pack_max					integer,
		@print_id					integer,
		@product_desc				varchar(100),
		@error						integer,
		@cinema_qty      			integer,
		@vm_qty          			integer,
		@requested_qty    			integer,
		@sched_start_date			datetime,
		@print_name		      		varchar(50),
		@inclusion_id					integer

/*
 * Declare Cursor
 */

select 		film_campaign.campaign_no,
			film_campaign.product_desc,
			inclusion_desc,
			min(screening_date)
from 		film_campaign,
			inclusion,
			inclusion_spot,
			branch
where 		film_campaign.campaign_status = 'L'
and			film_campaign.campaign_no = inclusion.campaign_no
and			film_campaign.campaign_no = inclusion_spot.campaign_no
and			inclusion.inclusion_id = inclusion_spot.inclusion_id
and			inclusion.campaign_no = inclusion_spot.campaign_no
and			inclusion_spot.spot_status <> 'P'
and			film_campaign.branch_code = branch.branch_code
and			branch.country_code = @country_code
and			inclusion.inclusion_format <> 'R'
group by 	film_campaign.campaign_no,
			film_campaign.product_desc,
			inclusion.inclusion_desc
having		min(inclusion_spot.screening_date) between @start_date and @end_date

union all
 
select 		film_campaign.campaign_no,
			film_campaign.product_desc,
			inclusion_desc,
			min(op_screening_date)
from 		film_campaign,
			inclusion,
			inclusion_spot,
			branch
where 		film_campaign.campaign_status = 'L'
and			film_campaign.campaign_no = inclusion.campaign_no
and			film_campaign.campaign_no = inclusion_spot.campaign_no
and			inclusion.inclusion_id = inclusion_spot.inclusion_id
and			inclusion.campaign_no = inclusion_spot.campaign_no
and			inclusion_spot.spot_status <> 'P'
and			film_campaign.branch_code = branch.branch_code
and			branch.country_code = @country_code
and			inclusion.inclusion_format = 'R'
group by 	film_campaign.campaign_no,
			film_campaign.product_desc,
			inclusion.inclusion_desc
having		min(inclusion_spot.op_screening_date) between @start_date and @end_date 
order by 	film_campaign.campaign_no
GO
