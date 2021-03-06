/****** Object:  StoredProcedure [dbo].[p_payroll_billing_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_payroll_billing_report]
GO
/****** Object:  StoredProcedure [dbo].[p_payroll_billing_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_payroll_billing_report] @rep_id				integer,
                                     @sales_period		datetime,
                                     @start_period		datetime
as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare @error          		integer,
        @rowcount					integer,
        @first_name				varchar(30),
        @last_name				varchar(30),
        @sales_period_start	datetime

/*
 * Acquire Rep Name
 */

select @first_name = first_name,
       @last_name = last_name
  from sales_rep
 where rep_id = @rep_id

/*
 * Acquire Sales Period Start Date
 */

select @sales_period_start = sales_period_start
  from sales_period
 where sales_period_end = @sales_period

/*
 * Return Results
 */

select @first_name,
       @last_name,
       sc.campaign_no,
       sc.name_on_slide,
       sc.official_period,
       tt.trantype_desc,
       st.tran_id,
       st.tran_date,
       st.tran_desc,
       st.nett_amount
  from slide_campaign sc,
       slide_transaction st,
       transaction_type tt
 where sc.contract_rep = @rep_id and
       sc.official_period >= @start_period and
       sc.campaign_no = st.campaign_no and
       st.tran_date >= @sales_period_start and
       st.tran_date <= @sales_period and
       st.tran_type = tt.trantype_id and
       tt.trantype_code in ('SBILL','SACOMM','SDISC','SBCR','SUSCR')

/*
 * Return Success
 */

return 0
GO
