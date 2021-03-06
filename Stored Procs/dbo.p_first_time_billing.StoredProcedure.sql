/****** Object:  StoredProcedure [dbo].[p_first_time_billing]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_first_time_billing]
GO
/****** Object:  StoredProcedure [dbo].[p_first_time_billing]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_first_time_billing] @billing_date	datetime
as

/*
 * Declare Procedure Variables
 */

declare 	@error          			integer,
			@rowcount			integer,
			@campaign_no			char(7),
			@name_on_slide			varchar(50),
			@start_date			datetime,
			@orig_camp_period		smallint,
			@contract_value			money,
			@branch_name			varchar(50),
			@campaign_type_code		char(1),
			@campaign_type			varchar(30),
			@parent_campaign		char(7)

/*
 * Create temp table 
 */

create table #temp
(
	billing_date			datetime		null,
	campaign_no				char(7) 		null,
	name_on_slide			varchar(50)	null,
	start_date				datetime		null,
	orig_camp_period		smallint		null,
	contract_value			money			null,
	campaign_type			varchar(30)	null,
	branch_name				varchar(50) null,
	parent_campaign		char(7)		null
)

/*
 * Declare Cursor
 */

declare billing_csr cursor static for 
 select campaign_no
   from slide_statement
  where statement_no = 1 and
        statement_date = @billing_date
    for read only

/*
 * Loop First Time Billings
 */

open billing_csr
fetch billing_csr into @campaign_no
while (@@fetch_status = 0)
begin

	select @parent_campaign = ''

	select @name_on_slide = slide_campaign.name_on_slide,
          @start_date = slide_campaign.start_date,
          @orig_camp_period = slide_campaign.orig_campaign_period,
          @campaign_type_code = slide_campaign.campaign_type,
          @campaign_type = slide_campaign_type.campaign_type_desc,
          @contract_value = slide_campaign.nett_contract_value,
          @branch_name = branch.branch_name
     from slide_campaign,
          slide_campaign_type,
          branch
    where slide_campaign.campaign_no = @campaign_no and
          slide_campaign.branch_code = branch.branch_code and
          slide_campaign.campaign_type = slide_campaign_type.campaign_type_code
	
	if(@campaign_type_code = 'R' or @campaign_type_code = 'S' or @campaign_type_code = 'E')
	begin
 
		select @parent_campaign = isnull(max(slide_family.parent_campaign),'Unknown')
		  from slide_campaign,
				 slide_family
		 where slide_family.child_campaign = @campaign_no and
             slide_family.child_campaign = slide_campaign.campaign_no and
             slide_family.relationship_type = slide_campaign.campaign_type

	end

	/*
	 * Insert into Temp Table
	 */
	
	insert into #temp values ( @billing_date,
                              @campaign_no,
				@name_on_slide,
				@start_date,
				@orig_camp_period,
				@contract_value,
				@campaign_type,
				@branch_name,
				@parent_campaign )

	/*
    * Fetch Next
    */

	fetch billing_csr into @campaign_no

end
close billing_csr
deallocate billing_csr

/*
 * Return Datset
 */

select * from #temp

/*
 * Return
 */

return 0
GO
