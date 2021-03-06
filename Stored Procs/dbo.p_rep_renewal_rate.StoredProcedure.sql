/****** Object:  StoredProcedure [dbo].[p_rep_renewal_rate]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_rep_renewal_rate]
GO
/****** Object:  StoredProcedure [dbo].[p_rep_renewal_rate]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_rep_renewal_rate]	@branch_code	char(1),
                        @start_date		datetime,
			@end_date		datetime,
  			@exclude_term		char(1),
			@mode			char(1)
as
set nocount on 
/*
 * Declare Variables
 */

declare  @rep_id				integer,
	@campaign_no				char(7),
         @name_on_slide				varchar(50),
         @nett_contract				money,
	@renewed				char(1),
         @renewal_camp				char(7),
         @renewal_name_on_slide		varchar(50),
         @renewal_nett_contract		money,
         @renewal_date					datetime,
         @event_date						datetime,
         @camp_branch					char(2)

/*
 * Create Temp Table
 */

create table #results
(
   branch_code					char(2)			null,
	rep_id						integer			null,
   campaign_no					char(7)			null,
   name_on_slide				varchar(50)		null,
   nett_contract				money				null,
	renewed						char(1)			null,
   renewal_camp				char(7)			null,
   renewal_name_on_slide	varchar(50)		null,
   renewal_nett_contract	money				null,
   renewal_date				datetime			null,
   event_date					datetime			null
)

/*
 * Declare Cursors
 */

if @mode = 'C'
begin

	 declare renewal_csr cursor static for
	  select sc.campaign_no,
				sc.name_on_slide,
				sc.branch_code,
				sc.nett_contract_value,
				sc.contract_rep,
				ce.event_date
		 from slide_campaign sc,
				sales_rep sr,
				campaign_event ce
		where ce.event_date >= @start_date and  
				ce.event_date <= @end_date and
				ce.event_type = 'D' and
				ce.campaign_no = sc.campaign_no and
				sc.contract_rep = sr.rep_id and
				sc.campaign_category = 'S' and
			 ( sc.branch_code = @branch_code or
				@branch_code = '@' ) and
			 ( sr.status = 'A' or
				@exclude_term = 'N')
	order by rep_id
		  for read only

end
else
begin

	 declare renewal_csr cursor static for
	  select sc.campaign_no,
				sc.name_on_slide,
				sc.branch_code,
				sc.nett_contract_value,
				sc.service_rep,
				ce.event_date
		 from slide_campaign sc,
				sales_rep sr,
				campaign_event ce
		where ce.event_date >= @start_date and  
				ce.event_date <= @end_date and
				ce.event_type = 'D' and
				ce.campaign_no = sc.campaign_no and
				sc.service_rep = sr.rep_id and
				sc.campaign_category = 'S' and
			 ( sc.branch_code = @branch_code or
				@branch_code = '@' ) and
			 ( sr.status = 'A' or
				@exclude_term = 'N')
	order by rep_id
		  for read only

end

/*
 * Loop Campaigns
 */

open renewal_csr
fetch renewal_csr into @campaign_no, @name_on_slide, @camp_branch, @nett_contract, @rep_id, @event_date
while(@@fetch_status = 0) 
begin

	if(substring(@campaign_no,2,1) <> 'P')
	begin

		/*
		 * Is it Renewed
		 */

		select @renewal_camp = null

		select @renewal_camp = child_campaign
		  from slide_family 
		 where relationship_type = 'R' and
				 parent_campaign = @campaign_no

		if(@renewal_camp is null)
			select @renewed = 'N',
					 @renewal_name_on_slide = null,
					 @renewal_nett_contract = null,
					 @renewal_date = null
		else
			select @renewed = 'Y',
					 @renewal_name_on_slide = sc.name_on_slide,
					 @renewal_nett_contract = sc.nett_contract_value,
					 @renewal_date = sp.proposal_date
			  from slide_campaign sc,
					 slide_proposal sp
			 where sc.campaign_no = @renewal_camp and
					 sc.campaign_no = sp.campaign_no

		/*
		 * Insert Record
		 */

		insert into #results (
				 branch_code,
				 rep_id,
				 campaign_no,
				 name_on_slide,
				 nett_contract,
				 renewed,
				 renewal_camp,
				 renewal_name_on_slide,
				 renewal_nett_contract,
				 renewal_date,
             event_date ) values (
				 @camp_branch,
				 @rep_id,
				 @campaign_no,
				 @name_on_slide,
				 @nett_contract,
				 @renewed,
				 @renewal_camp,
				 @renewal_name_on_slide,
				 @renewal_nett_contract,
				 @renewal_date,
             @event_date )


	end

	/*
	 * Fetch Next
	 */

	fetch renewal_csr into @campaign_no, @name_on_slide, @camp_branch, @nett_contract, @rep_id, @event_date
		
end
close renewal_csr
deallocate renewal_csr

/*
 * Return Result Set
 */

select sr.branch_code,
       sr.status,
       r.branch_code,
       r.rep_id,
		 r.campaign_no,
       r.name_on_slide,
       r.nett_contract,
       r.renewed,
       r.renewal_camp,
       r.renewal_name_on_slide,
       r.renewal_nett_contract,
       r.renewal_date,
       r.event_date
  from #results r,
       sales_rep sr
 where r.rep_id = sr.rep_id

/*
 * Return Success
 */

return 0
GO
