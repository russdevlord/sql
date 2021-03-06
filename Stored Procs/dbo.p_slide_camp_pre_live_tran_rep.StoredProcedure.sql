/****** Object:  StoredProcedure [dbo].[p_slide_camp_pre_live_tran_rep]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_camp_pre_live_tran_rep]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_camp_pre_live_tran_rep]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_slide_camp_pre_live_tran_rep]	@country_code				char(1),
															@branch_code				char(2)
as
set nocount on 
declare  @country_code_tmp			char(1),
         @branch_code_tmp			char(1)

select @country_code_tmp = country_code
  from country
 where country_code = @country_code

select @branch_code_tmp = branch_code
  from branch
 where branch_code = @branch_code

select @country_code = @country_code_tmp,
       @branch_code = @branch_code_tmp

/*
 * Select and report data
 */

  select st.campaign_no,   
         sc.name_on_slide,   
         max(st.tran_desc) as tran_desc,   
         max(st.gross_amount) as gross_amount,   
         max(st.nett_amount) as nett_amount,   
         max(st.gst_amount) as gst_amount,   
         sum(sa.pay_gst) as pay_gst,  
         max(st.tran_date) as tran_date,   
         st.tran_id,   
         max(country.country_code) as country_code,   
         max(country.country_name) as country_name,
         max(branch.branch_code) as branch_code,   
         max(branch.branch_name) as branch_name,
         max(st.tran_type) as tran_type,
         max(tt.trantype_desc) as trantype_desc,
         max(sc.campaign_status),
         max(sc.start_date)
    from slide_transaction st,
         transaction_type tt,
         slide_allocation sa,
         slide_campaign sc,   
         branch,
         country
   where st.gross_amount > 0 and
         st.tran_type = tt.trantype_id and
         st.tran_id = sa.to_tran_id and
         st.campaign_no = sc.campaign_no and
         sc.branch_code = branch.branch_code and
         branch.country_code = country.country_code and
         sc.is_closed = 'N' and
         not exists(select campaign_event.campaign_no from campaign_event where campaign_event.campaign_no = sc.campaign_no and campaign_event.event_type = 'V') and
         ( branch.branch_code = @branch_code or @branch_code is null) and
         ( country.country_code = @country_code or @country_code is null)
group by st.campaign_no,
         sc.name_on_slide,   
         st.tran_id
union
  select st.campaign_no,   
         sc.name_on_slide,   
         max(st.tran_desc) as tran_desc,   
         max(st.gross_amount) as tran_amount,   
         max(st.nett_amount) as nett_amount,   
         max(st.gst_amount) as gst_amount,   
         sum(sa.pay_gst) as pay_gst,  
         max(st.tran_date) as tran_date,   
         st.tran_id,   
         max(country.country_code) as country_code,   
         max(country.country_name) as country_name,
         max(branch.branch_code) as branch_code,   
         max(branch.branch_name) as branch_name,
         max(st.tran_type) as tran_type,
         max(tt.trantype_desc) as trantype_desc,
         max(sc.campaign_status),
         max(sc.start_date)
    from slide_transaction st,
         transaction_type tt,
         slide_allocation sa,
         slide_campaign sc,   
         branch,
         country
   where st.gross_amount < 0 and
         st.tran_type = tt.trantype_id and
         st.tran_id = sa.from_tran_id and
         st.campaign_no = sc.campaign_no and
         sc.branch_code = branch.branch_code and
         branch.country_code = country.country_code and
         sc.is_closed = 'N' and
         not exists(select campaign_event.campaign_no from campaign_event where campaign_event.campaign_no = sc.campaign_no and campaign_event.event_type = 'V') and
         ( branch.branch_code = @branch_code or @branch_code is null) and
         ( country.country_code = @country_code or @country_code is null)
group by st.campaign_no,
         sc.name_on_slide,   
         st.tran_id

/*
 * Return
 */

return 0
GO
