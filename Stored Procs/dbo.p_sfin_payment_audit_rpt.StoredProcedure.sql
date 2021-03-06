/****** Object:  StoredProcedure [dbo].[p_sfin_payment_audit_rpt]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_payment_audit_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_payment_audit_rpt]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[p_sfin_payment_audit_rpt] @accounting_period		datetime,
                                     @country_code				char(1)
as
set nocount on 
                              

declare @error							integer,
        @errorode							integer,
        @branch_code					char(2),
        @campaign_no					char(7),
        @tran_id						integer,
        @tran_date					datetime,
        @tran_desc					varchar(255),
        @nett_amount					money,
	     @gst_amount					money,
	     @gst_rate						numeric(6,4),
        @gross_amount				money,
	     @nett_alloc              money,
        @gst_alloc               money,
        @gross_alloc             money,
        @distrib_alloc           money,
        @distrib_this_month      money


                                

create table #results 
(
   accounting_period			datetime			null,
	country_code				char(1)			null,
	branch_code					char(2)			null,
	campaign_no					char(7)			null,
   tran_id						integer			null,
   tran_date					datetime			null,
   tran_desc					varchar(255)	null,
   nett_amount					money				null,
	gst_amount					money				null,
	gst_rate						numeric(6,4)	null,
   gross_amount				money				null,
   nett_alloc              money				null,
   gst_alloc               money				null,
   gross_alloc             money				null,
   distrib_alloc           money				null,
   distrib_this_month      money				null
)

                                      

 declare tran_csr cursor static for
  select b.branch_code,
         st.tran_id,
         st.campaign_no,
         st.tran_date,
         st.tran_desc,
         st.nett_amount,
         st.gst_amount,
         st.gst_rate,
         st.gross_amount
    from slide_transaction st,
         slide_campaign sc,
         branch b
   where st.accounting_period = @accounting_period and
         st.tran_category = 'C' and
         st.campaign_no = sc.campaign_no and
         sc.branch_code = b.branch_code and
         b.country_code = @country_code
order by b.country_code ASC,
         b.branch_code ASC, 
         st.campaign_no ASC
     for read only

                             

open tran_csr
fetch tran_csr into @branch_code, 
                    @tran_id, 
                    @campaign_no, 
                    @tran_date, 
                    @tran_desc, 
                    @nett_amount, 
                    @gst_amount, 
                    @gst_rate, 
                    @gross_amount

while(@@fetch_status = 0)
begin

	                                      

	select @nett_alloc = isnull(sum(sa.nett_amount),0),
          @gst_alloc = isnull(sum(sa.gst_amount),0),
          @gross_alloc = isnull(sum(sa.gross_amount),0),
          @distrib_alloc = isnull(sum(sa.alloc_amount),0)
     from slide_allocation sa
    where sa.from_tran_id = @tran_id and
          sa.to_tran_id is not null

	                                                                  

	select @distrib_this_month = isnull(sum(sa.alloc_amount),0)
     from slide_allocation sa
    where sa.from_tran_id = @tran_id and
          sa.to_tran_id is not null and
          process_period = @accounting_period
  
	                                                       

	insert into #results (
          accounting_period,
	       country_code,
	       branch_code,
	       campaign_no,
          tran_id,
          tran_date,
          tran_desc,
          nett_amount,
	       gst_amount,
	       gst_rate,
          gross_amount,
	       nett_alloc,
          gst_alloc,
          gross_alloc,
          distrib_alloc,
          distrib_this_month ) values (
          @accounting_period,
          @country_code,
	       @branch_code,
		    @campaign_no,
          @tran_id,
          @tran_date,
          @tran_desc,
          @nett_amount,
	       @gst_amount,
	       @gst_rate,
          @gross_amount,
	       @nett_alloc,
          @gst_alloc,
          @gross_alloc,
          @distrib_alloc,
          @distrib_this_month )
			
	                            

	fetch tran_csr into @branch_code, 
							  @tran_id, 
							  @campaign_no, 
							  @tran_date, 
							  @tran_desc, 
							  @nett_amount, 
							  @gst_amount, 
							  @gst_rate, 
							  @gross_amount

end
close tran_csr
deallocate tran_csr

                             

select accounting_period,
       country_code,
	    branch_code,
	    campaign_no,
       tran_id,
       tran_date,
       tran_desc,
       nett_amount,
	    gst_amount,
	    gst_rate,
       gross_amount,
	    nett_alloc,
       gst_alloc,
       gross_alloc,
       distrib_alloc,
       distrib_this_month

  from #results

                          

return 0
GO
