/****** Object:  StoredProcedure [dbo].[p_sfin_projected_commissions]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sfin_projected_commissions]
GO
/****** Object:  StoredProcedure [dbo].[p_sfin_projected_commissions]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_sfin_projected_commissions]  @mode						integer,
					@sales_rep				integer,
					@branch_code			char(2),
					@country_code			char(2)
as
set nocount on 
/*
 * Declare Valiables
 */ 

declare @error							integer,
	     @sqlstatus					integer,
        @errorode							integer,
		  @account_period				datetime,
		  @account_start				datetime,
		  @current_account_period 	datetime,
		  @nett_billings				money,
		  @campaign_count				integer,
		  @suspended					money,
		  @cancelled					money,
		  @credits						money,
		  @rep_id						integer,
		  @first_name					varchar(30),
        @last_name					varchar(30),	 
		  @branch_name					varchar(30),
		  @country_name				varchar(30)

/*
 * Initialise Variables
 */

select @nett_billings = 0,
       @campaign_count = 0,
       @suspended = 0,
       @cancelled = 0,
       @credits = 0

/*
 * Calculate Current Accounting Period
 */

select @current_account_period = min(end_date)
  from accounting_period
 where status = 'O'

select @error = @@error
if (@error !=0)
	goto error


/*
 * Create Temporary Table
 */

create table #results
(
	rep_id					integer			null,
	branch_code				char(2)			null,
	branch_name				varchar(30)		null,
	country_code			char(2)			null,
	country_name			varchar(30)		null,
	first_name				varchar(30)		null,
	last_name				varchar(30)		null,
	period					datetime			null,
	bill						money				null
)

/*
 * Declare cursor to loop over all future accounting_periods and payroll reps.
 */
 declare projection_csr cursor static for 
  select accounting_period.end_date,
         accounting_period.start_date,
			sales_rep.rep_id, 
			sales_rep.first_name,
			sales_rep.last_name,
			sales_rep.branch_code,
			branch.branch_name,
			branch.country_code,
			country.country_name
    from accounting_period,
			sales_rep,
			branch,
			country
   where	accounting_period.end_date >= getdate() and
			sales_rep.status <> 'X' and
			sales_rep.end_date is null and
			sales_rep.rep_id in (select distinct payroll_rep from slide_campaign) and
			sales_rep.branch_code = branch.branch_code and
			branch.country_code = country.country_code and
			((sales_rep.rep_id = @sales_rep and
			@mode = 1) or
			(sales_rep.branch_code = @branch_code and
			@mode = 2) or
			(branch.country_code = @country_code and
			@mode = 3 ))
order by sales_rep.rep_id,
			accounting_period.end_date ASC
for read only

/*
 * Open Cursor and begin collection data
 */ 
open projection_csr
fetch projection_csr into @account_period, @account_start, @rep_id, @first_name, @last_name, @branch_code, @branch_name, @country_code, @country_name
while(@@fetch_status=0)
begin

	/*
	 * Get Nett Billings
	 */
	
	select @nett_billings = isnull(sum(spot.nett_rate * sc.comm_rate),0)
	  from slide_campaign_spot spot,
			 slide_campaign sc
	 where ( spot.billing_status = 'B' or
				spot.billing_status = 'C' or
				spot.billing_status = 'L' ) and
				spot.campaign_no = sc.campaign_no and
				spot.screening_date >= @account_start and
				spot.screening_date <= @account_period and
				sc.billing_commission = 'Y' and
				sc.payroll_rep = @rep_id
	
	select @error = @@error
	if (@error !=0)
		goto error
	
	/*
	 * Calculate Cancelled Spots
	 */
	
	select @cancelled = isnull(sum(spot.nett_rate * sc.comm_rate),0)
	  from slide_campaign_spot spot,
			 slide_campaign sc
	 where spot.billing_status = 'X' and
			 spot.spot_status <> 'S' and
			 spot.campaign_no = sc.campaign_no and
			 spot.screening_date >= @account_start and
			 spot.screening_date <= @account_period and
			 sc.billing_commission = 'Y' and
			 sc.payroll_rep = @rep_id
	
	select @error = @@error
	if (@error !=0)
		goto error
	
	/*
	 * Get Credits
	 */
	
	if(@account_period = @current_account_period)
	begin
	
		select @credits = isnull(sum(nett_amount * sc.comm_rate),0)
		  from slide_campaign sc,
				 slide_transaction st,
				 transaction_type tt
		 where sc.campaign_no = st.campaign_no and
				 st.accounting_period = null and
				 st.tran_type = tt.trantype_id and
			  ( tt.trantype_code = 'SUSCR' or
				 tt.trantype_code = 'SAUCR' or
				 tt.trantype_code = 'SBCR' ) and
				 sc.billing_commission = 'Y' and
				 sc.payroll_rep = @rep_id and
				 tt.create_commission = 'Y'
	
	end
	else
	begin
	
		select @credits = isnull(sum(nett_amount * sc.comm_rate),0)
		  from slide_campaign sc,
				 slide_transaction st,
				 transaction_type tt
		 where sc.campaign_no = st.campaign_no and
				 st.accounting_period = @account_period and
				 st.tran_type = tt.trantype_id and
			  ( tt.trantype_code = 'SUSCR' or
				 tt.trantype_code = 'SAUCR' or
				 tt.trantype_code = 'SBCR' ) and
				 sc.billing_commission = 'Y' and
				 sc.payroll_rep = @rep_id and
				 tt.create_commission = 'Y'
	
	end

	select @error = @@error
	if (@error !=0)
		goto error


		select @nett_billings = @nett_billings - @cancelled - @credits

		if @nett_billings <> 0
		begin
			insert into #results
			(rep_id,
			branch_code,
			branch_name,
			country_code,
			country_name,
			first_name,
			last_name,
			period,
			bill) values
			(@rep_id,
			@branch_code,
			@branch_name,
			@country_code,
			@country_name,
			@first_name,
			@last_name,
			@account_period,
			@nett_billings)
	
			select @error = @@error
			if (@error !=0)
				goto error
		end

	fetch projection_csr into @account_period, @account_start, @rep_id, @first_name, @last_name, @branch_code, @branch_name, @country_code, @country_name
end
close projection_csr 
deallocate projection_csr 

/*
 * Return
 */

select * from #results
return 0

/*
 * Error Handler
 */

error:
	
	return -1
GO
