/****** Object:  StoredProcedure [dbo].[p_slide_campaign_rate_disc_rpt]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_campaign_rate_disc_rpt]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_campaign_rate_disc_rpt]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_campaign_rate_disc_rpt] @sales_period			datetime,
					 @country_code			char(1),
					 @branch_code			char(1)
as
set nocount on 
/*
 * Declare Variables
 */

declare @error     				integer,
		  @csr_complex				integer,
        @total_screens			integer,
		  @campaign_csr_open		integer,
		  @complex_csr_open		integer,
		  @complex_name			varchar(50),
		  @list_rate				money,
        @orig_screens			integer,
		  @discount					decimal(2,2),
		  @discount_desc			varchar(50),
		  @campaign_no				char(7),
		  @name_on_slide			varchar(50),
		  @nett_contract_value	money,
		  @nett_contract_calc	money,
		  @orig_period				smallint,
		  @csr_branch_code		char(1),
		  @first_name				char(30),
		  @last_name				char(30),
		  @rep_id					integer,
		  @branch_name				varchar(50),
		  @complex_count			integer,
		  @agency_deal				char(1),
		  @agency_comm				decimal(2,2),
		  @campaign_line_id		integer,
		  @series_count 			integer,
		  @acomm_discount			decimal(2,2),
		  @series_loading			decimal(2,2),
		  @short_loading			decimal(3,2),
        @acceptable_var 		decimal(2,2)

/*
 * Create a temp table for returning results
 */

create table #complexes
(
	campaign_no				char(7)			null,
   name_on_slide			varchar(50)		null,
   nett_contract_value	money				null,
   nett_contract_calc	money				null,
   orig_period				smallint			null,
   branch_code				char(1)			null,
	agency_deal				char(1)			null,
	agency_comm				decimal(2,2)	null,
   first_name				char(30)			null,
   last_name				char(30)			null,
   rep_id					integer			null,
   branch_name				varchar(50)		null,
	complex_name			varchar(50)		null,
	list_rate				money				null,
   orig_screens			integer			null,
	total_screens			integer			null,
	discount					decimal(2,2)	null,
	discount_desc			varchar(50)		null,
	acomm_discount    	decimal(2,2)	null,
	series_loading    	decimal(2,2)	null,
	short_loading   		decimal(3,2)	null,
   acceptable_var			decimal(2,2)	null
)

/*
 * Initialise Variables
 */

select @campaign_csr_open = 0,
       @complex_csr_open = 0,
       @total_screens = 0,
       @acceptable_var = 0.01

/*
 * Loop Through Campaigns
 */
declare campaign_csr cursor static for
 select sc.campaign_no,
        sc.name_on_slide,
        sc.nett_contract_value,
        sc.orig_campaign_period,
        sc.branch_code,
        sc.agency_deal,
        sc.discount,
        sr.first_name,
        sr.last_name,
        sr.rep_id,
        b.branch_name
	from slide_campaign sc,
        branch b,
        sales_rep sr
  where sc.official_period = @sales_period and
        sc.branch_code = b.branch_code and
        sc.contract_rep = sr.rep_id and
		( @country_code is null or b.country_code = @country_code) and
		( @branch_code = '@' or sc.branch_code = @branch_code)
	 for read only

open campaign_csr
select @campaign_csr_open = 1
fetch campaign_csr into @campaign_no, 
								@name_on_slide, 
								@nett_contract_value, 
								@orig_period, 
								@csr_branch_code, 
								@agency_deal,
								@agency_comm,
								@first_name, 
								@last_name, 
								@rep_id, 
								@branch_name

while(@@fetch_status=0)
begin

	select @total_screens = 0
	select @complex_count = 0

	/*
 	 * Loop through Complexes
 	 */

	/*
	 * Declare Complex Cursor
	 */ 
	declare complex_csr cursor static for
	 select scc.complex_id,
	        scc.orig_screens,
	        scc.list_rate,
	        c.complex_name
	   from slide_campaign_complex scc,
	        complex c
	  where scc.campaign_no = @campaign_no and
	        scc.complex_id = c.complex_id and
	  		  scc.orig_screens > 0
	    for read only

	open complex_csr
	select @complex_csr_open = 1
	fetch complex_csr into @csr_complex, @orig_screens, @list_rate, @complex_name
	while(@@fetch_status=0)
	begin
	
		/*
       * Sum Screens
       */
		
		select @total_screens = @total_screens + @orig_screens
		select @complex_count = @complex_count + 1		
		if(@complex_count = 1)
			select @nett_contract_calc = @nett_contract_value
		else
			select @nett_contract_calc = 0

		/*
		 * Insert Values into Temp Table #Complexes
		 */

     	insert into #complexes values ( @campaign_no,
												  @name_on_slide,
												  @nett_contract_value,
												  @nett_contract_calc,
												  @orig_period,
												  @csr_branch_code,
												  @agency_deal,
												  @agency_comm,
												  @first_name,
												  @last_name,
												  @rep_id,
												  @branch_name,
												  @complex_name, 
												  @list_rate, 
												  @orig_screens, 
												  @total_screens, 
												  0, 
												  null,
												  0,
												  0,
                                      0,
                                      @acceptable_var )		

		select @error = @@error
		if (@error != 0)
		begin
			raiserror ('p_slide_campaign_rate_disc_rpt: insert error', 16, 1)
			return -1
		end	
	
		/*
		 * Fetch Next Complex
		 */
		
		fetch complex_csr into @csr_complex, @orig_screens, @list_rate, @complex_name
				
	end
	close complex_csr
	deallocate complex_csr
	select @complex_csr_open = 0
	
	/*
	 * Set the Agency Commission or Full Payment Discount Rate
    */

	select @acomm_discount = 0
	if(@agency_comm > 0)
	begin
		select @acomm_discount = isnull(@agency_comm, 0)
	end

	/*
	 * Short Term Loading.
	 * -------------------
 	 * Determine Short Term Contract Loadings.
	 *
	 */
	
	select @short_loading = 0.0

	if(@orig_period > 0 and @orig_period <= 8)
		select @short_loading = 1.0
	if(@orig_period > 8 and @orig_period <= 16)
		select @short_loading = 0.75
	if(@orig_period > 16 and @orig_period < 56)
		select @short_loading = 0.50
	
	/*
	 * Get the Discount Rate.
	 * ---------------------
 	 * Discount Rate only applies to FULL TERM Contracts - i.e. 56 Weeks or more.
	 *
	 */

	select @discount = 0,
          @discount_desc = 'No Discount'

	if(@orig_period >= 56)
   begin

		select @discount = scc.discount,
				 @discount_desc = scc.discount_desc
		  from slide_screen_discount scc
		 where min_screens <= @total_screens and
				 max_screens >= @total_screens 
	
		select @error = @@error
		if (@error != 0)
		begin
			raiserror ('p_slide_campaign_rate_disc_rpt : select error', 16, 1)
			return -1
		end	
   end

	/*
	 * Determine if Campaign package is in a Series
    * (i.e. GYOH or Trivial Pursuit or Movie Challeng)
    *
	 */	
	
	select @series_count = 0,
			 @series_loading = 0.0

	select @series_count = isnull(count(s.series_type),0)
	  from campaign_line cl,
			 line_series ls,
			 series_item si,
			 series s
	 where cl.campaign_no = @campaign_no and
			 cl.campaign_line_id = ls.campaign_line_id and
			 ls.series_item_code = si.series_item_code and
			 si.series_id = s.series_id and
		  ( s.series_code = 'TP' or
			 s.series_code = 'GH' or 
			 s.series_code = 'MC')
		
	if @series_count > 0
	begin
		select @series_loading = 0.20
	end

	/*
	 * Update Complexes with Discounts and Loadings
	 */

	update #complexes
		set total_screens = @total_screens,
			 discount = @discount,
		 	 discount_desc = @discount_desc,
          acomm_discount = @acomm_discount,
          series_loading = @series_loading,
          short_loading = @short_loading
	 where campaign_no = @campaign_no

	/*
	 * Fetch Next Campaign
	 */

	fetch campaign_csr into @campaign_no, 
									@name_on_slide, 
									@nett_contract_value, 
									@orig_period, 
									@csr_branch_code, 
									@agency_deal,
									@agency_comm,
									@first_name, 
									@last_name, 
									@rep_id, 
									@branch_name


end

/*
 * Close Camapign Cursor
 */

close campaign_csr
deallocate campaign_csr
select @campaign_csr_open = 0


/*
 * Return Results
 */

  select campaign_no,
			name_on_slide,
			nett_contract_value,
			nett_contract_calc,
			orig_period,
			branch_code,
			agency_deal,
			agency_comm,
			first_name,
			last_name,
			rep_id,
			branch_name,
			complex_name,
			list_rate,
   		orig_screens,
			total_screens,
			discount,
			discount_desc,
         acomm_discount,
         series_loading,
         short_loading,
         acceptable_var
    from #complexes
order by branch_code asc, 
         rep_id asc,
         campaign_no asc,
         complex_name asc

/*
 * Return
 */

return 0

/*
 * Error Handler
 */

error:

	if (@campaign_csr_open = 1)
   begin
		close campaign_csr
		deallocate campaign_csr
	end

	if (@complex_csr_open = 1)
   begin
		close complex_csr
		deallocate complex_csr
	end

	return -1
GO
