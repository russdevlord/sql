/****** Object:  StoredProcedure [dbo].[p_ffin_payment_audit_rpt]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_ffin_payment_audit_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_ffin_payment_audit_rpt]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_ffin_payment_audit_rpt] @accounting_period		datetime,
                                     @country_code				char(1)
as

set nocount on                               

declare @error							integer,
        @errorode							integer,
        @branch_code					char(2),
        @campaign_no					integer,
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
	campaign_no					integer			null,
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
         ct.tran_id,
         ct.campaign_no,
         ct.tran_date,
         ct.tran_desc,
         ct.nett_amount,
         ct.gst_amount,
         ct.gst_rate,
         ct.gross_amount
    from campaign_transaction ct,
         statement s,
         film_campaign fc,
         branch b
   where ct.statement_id = s.statement_id and
         ct.tran_category = 'C' and
         s.accounting_period = @accounting_period and
         ct.campaign_no = fc.campaign_no and
         fc.branch_code = b.branch_code and
         b.country_code = @country_code
order by b.country_code ASC,
         b.branch_code ASC, 
         ct.campaign_no ASC
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

	                                      

	select @nett_alloc = isnull(sum(ta.nett_amount),0),
          @gst_alloc = isnull(sum(ta.gst_amount),0),
          @gross_alloc = isnull(sum(ta.gross_amount),0),
          @distrib_alloc = isnull(sum(ta.alloc_amount),0)
     from transaction_allocation ta
    where ta.from_tran_id = @tran_id and
          ta.to_tran_id is not null

	                                                                  

	select @distrib_this_month = isnull(sum(ta.alloc_amount),0)
     from transaction_allocation ta
    where ta.from_tran_id = @tran_id and
          ta.to_tran_id is not null and
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
