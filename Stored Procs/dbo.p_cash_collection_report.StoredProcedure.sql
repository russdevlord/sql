/****** Object:  StoredProcedure [dbo].[p_cash_collection_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cash_collection_report]
GO
/****** Object:  StoredProcedure [dbo].[p_cash_collection_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cash_collection_report]	@a_end_date			datetime, 
													@a_start_date		datetime,
													@a_branch_code		char(2),
													@a_country_code	char(1)
as

set nocount on
/*
 * Declare Variables
 */

declare	@branch_code_tmp		char(3),
			@total_amount			money,
			@age_code				smallint,
			@tran_id					integer,
			@gross_amount_0		money,
			@gross_amount_1		money,
			@gross_amount_2		money,
			@gross_amount_3		money,
			@gross_amount_4		money,
			@tran_day				char(10),
			@reversal_amount		money,
			@rev_adjust				money,
			@group_by				integer,
			@increment				integer,
			@group_no				integer,
			@branch_code			char(3),
			@tran_date				datetime,
			@temp_date				datetime

/*
 * Get Branch Code
 */

if @a_country_code = null
begin
	select @branch_code_tmp = branch_code
  	  from branch
	 where branch_code = @a_branch_code

	select @a_branch_code = @branch_code_tmp
end

/*
 * Initialise Variables
 */

select @increment = 1,
       @group_no = 1

/*
 * Create Temporary Tables
 */

create table #age_totals
(
	age_code			integer   null,
   amount			money		 null
)

create table #temp
(
	tran_day				char(10)	null,
	tran_date			datetime	null,	
	gross_amount_0		money		null,
	gross_amount_1		money		null,
	gross_amount_2		money		null,
	gross_amount_3		money		null,
	gross_amount_4		money		null,
	total_amount		money		null,
	group_by				integer	null,
	reversal_amount	money		null,
	rev_adjust			money		null,
	branch_code			char(3)	null,
	country_code		char(1)	null,
)

/*
 *	Insert 0 values for all days in the date range, setting up a record for each day for each branch
 */

select @temp_date = @a_start_date
while (@temp_date <= @a_end_date)
begin

	select @group_by = @group_no
	select @increment = @increment + 1

	if @increment = 8
	begin
		select @group_no = @group_no + 1
		select @increment = 1
	end	

	insert into #temp (
		    tran_day,
		    tran_date,	
		    gross_amount_0,
		    gross_amount_1,
		    gross_amount_2,
		    gross_amount_3,
		    gross_amount_4,
		    total_amount,
		    group_by,
		    reversal_amount,
		    rev_adjust,
		    branch_code,
			 country_code) 
   select datename(dw, @temp_date),
			 @temp_date,
 			 0,
			 0,
			 0,
			 0,
			 0,
			 0,
			 @group_by,
			 0,
			 0,
			 branch_code,
			 country_code
     from branch
    where (branch_code = @a_branch_code or @a_branch_code is null) or
			 (country_code = @a_country_code or @a_country_code is null)

   select @temp_date = dateadd(dd,1,@temp_date)

end

/*
 * Declare Cursors
 */

declare     temp_csr cursor static forward_only for
select      tran_date,
            branch_code
from        #temp
order by    tran_date,
            branch_code

/*
 *	 Loop over each day for each branch and insert all values.
 */

open temp_csr
fetch temp_csr into  @tran_date,@branch_code
while(@@fetch_status = 0)
begin

	/*
	 *	 Initialise vars
	 */

	select @gross_amount_0 = null,
			 @gross_amount_1 = null,
			 @gross_amount_2 = null,
			 @gross_amount_3 = null,
			 @gross_amount_4 = null,
			 @total_amount = null,
			 @reversal_amount = null,
			 @rev_adjust = null

	/*
    * Delete Age Totals
    */

	delete #age_totals

	/*
	 *	Insert any payment allocation amounts.
	 */

	  insert into #age_totals (age_code, amount)
	  select sa.age_code,isnull(sum(sa.gross_amount),0)
	    from slide_allocation sa,
 			   slide_transaction st,
	  		   slide_campaign sc
	   where sa.from_tran_id  = st.tran_id and
            st.campaign_no = sc.campaign_no and
            sc.branch_code = @branch_code and
            st.tran_date = @tran_date and
			   st.tran_category in ('C','X') and
            st.gross_amount < 0 and
            sa.to_tran_id is not null
	group by sa.age_code
	order by sa.age_code

	select @gross_amount_0 = sum(amount)
	  from #age_totals
	 where age_code in (0,-1)

	select @gross_amount_1 = amount
	  from #age_totals
	 where age_code = 1

	select @gross_amount_2 = amount
	  from #age_totals
	 where age_code = 2

	select @gross_amount_3 = amount
	  from #age_totals
	 where age_code = 3

	select @gross_amount_4 = amount
	  from #age_totals
	 where age_code = 4

	select @total_amount = 	isnull(sum(st.gross_amount),0)
	  from slide_transaction st,
			 slide_campaign sc
	 where st.campaign_no = sc.campaign_no and
          sc.branch_code = @branch_code and
          st.tran_date = @tran_date and
			 st.tran_category in ('C','X') and
          st.gross_amount < 0
	
	/*
	 *	Now insert reversal amounts.
	 */

	select @reversal_amount = isnull(sum(st.gross_amount),0)
	  from slide_allocation sa,
 			 slide_transaction st,
			 slide_campaign sc
	 where sa.to_tran_id  = st.tran_id and
          st.campaign_no = sc.campaign_no and
          sc.branch_code = @branch_code and
          st.tran_date = @tran_date and
			 st.tran_category in ('C','X') and
          st.gross_amount > 0 and
          sa.from_tran_id is not null

	select @rev_adjust = isnull(sum(st.gross_amount),0)
     from slide_allocation sa,
  			 slide_transaction st,
			 slide_transaction st2,
			 slide_campaign sc
	 where sa.to_tran_id  = st.tran_id and
          st.campaign_no = sc.campaign_no and
          sc.branch_code = @branch_code and
			 sa.from_tran_id = st2.tran_id and
          st2.tran_date = @tran_date and
			 st.tran_category in ('C','X') and
          st.gross_amount > 0 and
          sa.from_tran_id is not null

	/*
	 *	Check for nulls
	 */

	select @gross_amount_0  = isnull(@gross_amount_0,0),
			 @gross_amount_1  = isnull(@gross_amount_1,0),
			 @gross_amount_2  = isnull(@gross_amount_2,0),
			 @gross_amount_3  = isnull(@gross_amount_3,0),
			 @gross_amount_4  = isnull(@gross_amount_4,0),
			 @total_amount    = isnull(@total_amount,0),
			 @reversal_amount = isnull(@reversal_amount,0),
			 @rev_adjust      = isnull(@rev_adjust,0)

	update #temp
		set gross_amount_0  = @gross_amount_0,
			 gross_amount_1  = @gross_amount_1,
			 gross_amount_2  = @gross_amount_2,
			 gross_amount_3  = @gross_amount_3,
			 gross_amount_4  = @gross_amount_4,
			 total_amount    = @total_amount,
			 reversal_amount = @reversal_amount,
			 rev_adjust      = @rev_adjust
	where  tran_date = @tran_date
	  and	 branch_code = @branch_code

	/*
    * Fetch Next
    */

	fetch temp_csr into  @tran_date,@branch_code

end
close temp_csr
deallocate temp_csr

/*
 * Return Result Set
 */

  select tran_day,
         tran_date,	
         gross_amount_0,
         gross_amount_1,
         gross_amount_2,
         gross_amount_3,
         gross_amount_4,
         total_amount,
         group_by,
         reversal_amount,
         rev_adjust,
         branch_code,
			country_code
    from #temp
   where (country_code = @a_country_code) or
			(branch_code = @a_branch_code)
order by branch_code, tran_date

/*
 * Return Success
 */

return 0
GO
