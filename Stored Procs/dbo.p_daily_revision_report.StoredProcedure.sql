/****** Object:  StoredProcedure [dbo].[p_daily_revision_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_daily_revision_report]
GO
/****** Object:  StoredProcedure [dbo].[p_daily_revision_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_daily_revision_report]			@report_date				datetime,
																				@employee_id			int

as

declare     @error											int,
					@campaign_no						int,   
					@revision_type							int,   
					@revision_no								int,   
					@revision_desc						varchar(255),   
					@confirmed_by							int,   
					@confirmation_date				datetime,   
					@comment									varchar(255),   
					@entry_date								datetime,   
					@contract_cost							money,   
					@hard_cost								money,    
					@product_desc						varchar(255),
					@previous_revision				int,
					@previous_contract_cost     money,
					@previous_hard_cost			money,
					@branch_code							char(1),
					@business_unit_id					int
            
set nocount on 

/*
 * Create Temp Table
 */
 
create table #daily_revision
(   
    campaign_no					int						null,   
    revision_type					int						null,   
    revision_no						int						null,   
    revision_desc				varchar(255)	null,   
    confirmed_by					int						null,   
    confirmation_date			datetime			null,   
    comment							varchar(255)	null,   
    entry_date						datetime			null,   
    contract_cost					money				null,   
    hard_cost							money				null,    
    product_desc					varchar(255)	null,
    branch_code					char(1)				null,
    business_unit_id           int						null
)
 
/*
 * Declare Cursor
 */
 
 
declare     revision_csr cursor static for
select		fcr.campaign_no,   
					fcr.revision_type,   
					fcr.revision_no,   
					fcr.revision_desc,   
					fcr.confirmed_by,   
					fcr.confirmation_date,   
					fcr.comment,   
					fcr.entry_date,   
					fcr.contract_cost,   
					fcr.hard_cost,   
					fc.product_desc,
					fc.branch_code,
					fc.business_unit_id 
from			film_campaign fc,   
					film_campaign_revision fcr
where		fc.campaign_no = fcr.campaign_no
and				fcr.confirmation_date > @report_date
and				fcr.confirmation_date <= dateadd(dd, 1, @report_date)
and				(fcr.confirmed_by = @employee_id
or				@employee_id = 0)
order by	fcr.campaign_no
for				read only         
            
/*
 * Begin Processing
 */
 
open revision_csr
fetch revision_csr into @campaign_no, @revision_type, @revision_no, @revision_desc, @confirmed_by, @confirmation_date, @comment, @entry_date, @contract_cost, @hard_cost, @product_desc, @branch_code, @business_unit_id
while(@@fetch_status=0)
begin

      if @revision_no = 0
        begin
            insert into #daily_revision
            (campaign_no,
             revision_type,
             revision_no,
             revision_desc,
             confirmed_by,
             confirmation_date,
             comment,
             entry_date,
             contract_cost,
             hard_cost,
             product_desc,
             branch_code,
             business_unit_id) values
             (@campaign_no, 
             @revision_type, 
             @revision_no, 
             @revision_desc, 
             @confirmed_by, 
             @confirmation_date, 
             @comment, 
             @entry_date, 
             @contract_cost, 
             @hard_cost, 
             @product_desc,
             @branch_code,
             @business_unit_id)
        end
        else
        begin
            select      @previous_hard_cost = isnull(hard_cost,0),
		                        @previous_contract_cost = isnull(contract_cost,0)
            from        film_campaign_revision
            where       campaign_no = @campaign_no
            and         revision_type = @revision_type
            and         revision_no = @revision_no - 1                        
            
                insert into #daily_revision
                (campaign_no,
                 revision_type,
                 revision_no,
                 revision_desc,
                 confirmed_by,
                 confirmation_date,
                 comment,
                 entry_date,
                 contract_cost,
                 hard_cost,
                 product_desc,
                 branch_code,
                 business_unit_id) values
                 (@campaign_no, 
                 @revision_type, 
                 @revision_no, 
                 @revision_desc, 
                 @confirmed_by, 
                 @confirmation_date, 
                 @comment, 
                 @entry_date, 
                 @contract_cost - @previous_contract_cost, 
                 @hard_cost - @previous_hard_cost, 
                 @product_desc,
                 @branch_code,
                 @business_unit_id)
                    
        end
    
    fetch revision_csr into @campaign_no, @revision_type, @revision_no, @revision_desc, @confirmed_by, @confirmation_date, @comment, @entry_date, @contract_cost, @hard_cost, @product_desc, @branch_code, @business_unit_id
end

deallocate revision_csr

select		#daily_revision.campaign_no, 
					#daily_revision.revision_type, 
					#daily_revision.revision_no, 
					#daily_revision.revision_desc, 
					#daily_revision.confirmed_by, 
					#daily_revision.confirmation_date, 
					#daily_revision.comment, 
					#daily_revision.entry_date, 
					#daily_revision.contract_cost, 
					#daily_revision.hard_cost, 
					#daily_revision.product_desc, 
					#daily_revision.branch_code, 
					#daily_revision.business_unit_id, 
					branch.country_code,
					@employee_id
from			#daily_revision, branch 
where		branch.branch_code = #daily_revision.branch_code 
order by	campaign_no
return 0
GO
