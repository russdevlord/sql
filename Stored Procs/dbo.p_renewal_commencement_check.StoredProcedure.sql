/****** Object:  StoredProcedure [dbo].[p_renewal_commencement_check]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_renewal_commencement_check]
GO
/****** Object:  StoredProcedure [dbo].[p_renewal_commencement_check]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_renewal_commencement_check] @branch_code		char(2)
as
set nocount on 
/*
 * Declare Valiables
 */ 

declare @error				integer,
	@sqlstatus			integer,
        @errorode				integer,
        @branch_name			varchar(50),
  	@campaign_no			char(7),
  	@name_on_slide			varchar(50),
	@parent_campaign_no		char(7),	
        @parent_name_on_slide		varchar(50),
        @parent_start_date			datetime,
        @parent_end_date			datetime,
        @parent_duration			integer,
        @scheduled_start			datetime,
	     @scheduled_billing			datetime,
        @tree_count					integer,
        @done							tinyint

/*
 * Create Temporary Table
 */

create table #renewals
(
	branch_name					varchar(50)		null,
	campaign_no					char(7)			null,
	name_on_slide				varchar(50)		null,
	parent_campaign_no		char(7)			null,
	parent_name_on_slide		varchar(50)		null,
   parent_start_date			datetime			null,
   parent_end_date			datetime			null,
	scheduled_start			datetime			null,
	scheduled_billing			datetime			null
)

/*
 * Declare Cursors
 */ 
 
 declare camp_csr cursor static for
  select sc.campaign_no,
         sc.name_on_slide,
         b.branch_name
    from slide_campaign sc,
         branch b
   where sc.campaign_status = 'U' and
         sc.campaign_type = 'R' and
         sc.branch_code = b.branch_code and
         b.branch_code = @branch_code
order by sc.campaign_no ASC
     for read only

/*
 * Loop Campaigns
 */

open camp_csr
fetch camp_csr into @campaign_no, @name_on_slide, @branch_name
while (@@fetch_status = 0)
begin

	/*
    * Re-Initialise Variables
    */

	select @parent_campaign_no = null,
          @parent_name_on_slide = null,
          @parent_start_date = null,
          @parent_end_date = null,
          @scheduled_start = null,
	       @scheduled_billing = null,
          @done = 0

	/*
    * Count Number of Renewal Relationships
    */

	select @tree_count = count(family_id)
     from slide_family
    where child_campaign = @campaign_no and
          relationship_type = 'R' --Renewal

	if(@tree_count <> 1)
	begin
		select @parent_campaign_no = '???????'
      select @parent_name_on_slide = 'Parent Not Found. Fix Family Tree.'
		select @done = 1
	end

	/*
    * Get Parent Information
    */

	if(@done = 0)
	begin

	   select @parent_campaign_no = sc.campaign_no,
             @parent_name_on_slide = sc.name_on_slide,
             @parent_start_date = sc.start_date,
             @parent_duration = sc.min_campaign_period + sc.bonus_period
        from slide_family sf,
             slide_campaign sc
		 where sf.child_campaign = @campaign_no and
				 sf.relationship_type = 'R' and --Renewal
		       sf.parent_campaign = sc.campaign_no

		if(@parent_start_date is not null)
		begin
			select @parent_end_date = dateadd(dd,((@parent_duration) * 7) - 1, @parent_start_date)
			select @scheduled_start = dateadd(dd, 1, @parent_end_date)
			select @scheduled_billing = dateadd(dd, -27, @parent_end_date)

			if(@parent_end_date < @parent_start_date)
			begin
				select @parent_end_date = @parent_start_date
			end
		end

	end

	/*
    * Insert Row
    */

	insert into #renewals
   select @branch_name,
          @campaign_no,
	       @name_on_slide,
	       @parent_campaign_no,
	       @parent_name_on_slide,
          @parent_start_date,
          @parent_end_date,
	       @scheduled_start,
	       @scheduled_billing

	/*
    * Fetch Next
    */

	fetch camp_csr into @campaign_no, @name_on_slide, @branch_name

end
close camp_csr
deallocate camp_csr

/*
 * Return Dataset
 */

select branch_name,
       campaign_no,
	    name_on_slide,
	    parent_campaign_no,
	    parent_name_on_slide,
       parent_start_date,
       parent_end_date,
	    scheduled_start,
	    scheduled_billing	
  from #renewals

/*
 * Return
 */

return 0
GO
