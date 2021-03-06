/****** Object:  StoredProcedure [dbo].[p_slide_campaign_listing]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_campaign_listing]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_campaign_listing]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_slide_campaign_listing] @a_branch_code				char(2),
                                     @a_campaign_category		char(1),
                                     @a_campaign_type			char(1),
                                     @a_campaign_status			char(1),
                                     @a_campaign_complex		integer,
                                     @a_contract_rep			integer,
                                     @a_service_rep				integer,
                                     @a_industry_cat			integer,
                                     @a_show_details			char(1),
                                     @a_address_mode			integer,
                                     @a_groupby_mode			integer,
                                     @a_sort_mode				integer
as
set nocount on 
/*
 * Declare Variables
 */

declare		@campaign_no				char(7),
			@branch_code_tmp			char(2),
			@campaign_category_tmp		char(1),
			@campaign_type_tmp			char(1),
			@campaign_status_tmp		char(1),
			@campaign_complex_tmp		integer,
			@industry_cat_tmp			integer,
			@industry_category_id		integer,
			@industry_category_desc		varchar(50),
         	@complex_id					integer,
			@name_on_slide				varchar(50),
			@agency_deal				char(1),
			@client_agency_name			varchar(50),
			@address_1					varchar(50),
			@address_2					varchar(50),
			@town_suburb				varchar(30),
			@postcode					char(5),
			@state						char(3),
			@signatory					varchar(30),
			@contact					varchar(30),
			@campaign_phone				varchar(20),
			@cr_first_name				varchar(30),
			@cr_last_name				varchar(30),
			@sr_first_name				varchar(30),
			@sr_last_name				varchar(30),
			@cc_name					varchar(50),
			@nett_contract_value		money,
			@campaign_status			char(1),
			@campaign_type				char(1),
			@campaign_category			char(1),
			@campaign_branch			char(2),
			@campaign_branch_name		varchar(50),
			@campaign_complex_name		varchar(50),
			@line1						varchar(50),
			@line2						varchar(50),
			@line3						varchar(50),
			@line4						varchar(50),
			@contract_rep_tmp			integer,
			@service_rep_tmp			integer,
			@email						varchar(100)

/*
 * Create the Temporary Loader Table
 */

create table #campaign
(
	campaign_no							char(7)				null,
	name_on_slide						varchar(50)			null,
	agency_deal							char(1)				null,
	client_agency_name					varchar(50)			null,
	address_1							varchar(50)			null,
	address_2							varchar(50)			null,
	town_suburb							varchar(30)			null,
	postcode							char(5)				null,
	state								char(3)				null,
	signatory							varchar(30)			null,
	contact								varchar(30)			null,
	campaign_phone						varchar(20)			null,
	cr_first_name						varchar(30)			null,
	cr_last_name						varchar(30)			null,
	sr_first_name						varchar(30)			null,
	sr_last_name						varchar(30)			null,
	cc_name								varchar(50)			null,
	nett_contract_value					money				null,
	campaign_status						char(1)				null,
	campaign_type						char(1)				null,
	campaign_category					char(1)				null,
	campaign_branch						char(2)				null,
	campaign_branch_name				varchar(50)			null,
	campaign_complex					integer				null,
	campaign_complex_name				varchar(50)			null,
	line1								varchar(50)			null,
	line2								varchar(50)			null,
	line3								varchar(50)			null,
	line4								varchar(50)			null,
   	industry_category_id				integer				null,
   	industry_category_desc				varchar(50)			null,
	email								varchar(100)		null
)

select @branch_code_tmp = branch.branch_code
  from branch
 where branch.branch_code = @a_branch_code

select @campaign_category_tmp = @a_campaign_category
 where @a_campaign_category in ( 'N', 'C', 'X' )

select @campaign_type_tmp = campaign_type_code
  from slide_campaign_type
 where slide_campaign_type.campaign_type_code = @a_campaign_type

select @campaign_status_tmp = slide_campaign_status.campaign_status_code
  from slide_campaign_status
 where slide_campaign_status.campaign_status_code = @a_campaign_status

select @campaign_complex_tmp = complex.complex_id
  from complex
 where complex.complex_id = @a_campaign_complex

select @contract_rep_tmp = sales_rep.rep_id
  from sales_rep
 where sales_rep.rep_id = @a_contract_rep

select @service_rep_tmp = sales_rep.rep_id
  from sales_rep
 where sales_rep.rep_id = @a_service_rep

select @industry_cat_tmp = industry_category_id
  from industry_category
 where industry_category_id = @a_industry_cat

select @a_branch_code = @branch_code_tmp,
       @a_campaign_category = @campaign_category_tmp,
       @a_campaign_type = @campaign_type_tmp,
       @a_campaign_status = @campaign_status_tmp,
       @a_campaign_complex = @campaign_complex_tmp,
       @a_contract_rep = @contract_rep_tmp,
       @a_service_rep = @service_rep_tmp,
       @a_industry_cat = @industry_cat_tmp

/*
 * Declare Cursors
 */

declare campaign_csr cursor static for
 select sc.campaign_no
   from slide_campaign sc
  where ( sc.branch_code = @a_branch_code or @a_branch_code is null ) and
        ( sc.campaign_category = @a_campaign_category or @a_campaign_category is null ) and
        ( sc.campaign_type = @a_campaign_type or @a_campaign_type is null ) and
        ( sc.campaign_status = @a_campaign_status or @a_campaign_status is null ) and
        ( sc.contract_rep = @a_contract_rep or @a_contract_rep is null ) and
        ( sc.service_rep = @a_service_rep or @a_service_rep is null ) and
        ( sc.industry_category = @a_industry_cat or @a_industry_cat is null )
group by sc.campaign_no
order by sc.campaign_no asc
for read only

open campaign_csr
fetch campaign_csr into @campaign_no
while (@@fetch_status = 0)
begin

   select @complex_id = null

   select @complex_id = slide_campaign_complex.complex_id
     from slide_campaign_complex
    where slide_campaign_complex.campaign_no = @campaign_no and
          slide_campaign_complex.complex_id = @a_campaign_complex

	if @a_campaign_complex is null or @complex_id = @a_campaign_complex
	begin

      /*
       * Load Campaign details
       */

      select @name_on_slide = sc.name_on_slide,
             @agency_deal = agency_deal,
             @signatory = sc.signatory,
             @contact = sc.contact,
             @campaign_phone = sc.phone,
             @cr_first_name = cr.first_name,
             @cr_last_name = cr.last_name,
             @sr_first_name = sr.first_name,
             @sr_last_name = sr.last_name,
             @cc_name = cc.employee_name,
             @nett_contract_value = sc.nett_contract_value,
             @campaign_category = sc.campaign_category,
             @campaign_type = sc.campaign_type,
             @campaign_status = sc.campaign_status,
             @campaign_branch = sc.branch_code,
             @campaign_branch_name = branch.branch_name,
             @industry_category_id = sc.industry_category
        from slide_campaign sc,
             branch,
             sales_rep cr,
             sales_rep sr,
             employee cc,
             industry_category ic
       where sc.campaign_no = @campaign_no and
             sc.branch_code = branch.branch_code and
             sc.contract_rep = cr.rep_id and
             sc.service_rep = sr.rep_id and
             sc.credit_controller = cc.employee_id

      select @campaign_complex_name = complex.complex_name
        from complex
       where complex.complex_id = @complex_id

      if @agency_deal = 'Y'
      begin
         select @client_agency_name = agency.agency_name,
                @address_1 = agency.address_1,
                @address_2 = agency.address_2,
                @town_suburb = agency.town_suburb,
                @state = agency.state_code,
                @postcode = agency.postcode,
				@email = agency.email
           from slide_campaign sc,
                agency
          where sc.campaign_no = @campaign_no and
                sc.agency_id = agency.agency_id
      end
      else
      begin
         select @client_agency_name = client.client_name,
                @address_1 = client.address_1,
                @address_2 = client.address_2,
                @town_suburb = client.town_suburb,
                @state = client.state_code,
                @postcode = client.postcode,
				@email = client.email
           from slide_campaign sc,
                client
          where sc.campaign_no = @campaign_no and
                sc.client_id = client.client_id
      end

		/*
       * Get Industry_category
       */

		select @industry_category_desc = null
		select @industry_category_desc = industry_category_desc
        from industry_category
       where industry_category_id = @industry_category_id

      /*
       * Assign the Address Lines
       */

      if @a_address_mode = 1
      begin
         select @line1 = @signatory
      end
      else
      if @a_address_mode = 2
      begin
         select @line1 = @contact
      end
      else
      if @a_address_mode = 3
      begin
         select @line1 = @client_agency_name
      end

      select @line2 = @address_1
      select @line3 = @address_2
      select @line4 = ltrim(isnull(@town_suburb, '') + ' ' + isnull(@state, '') + ' ' + isnull(@postcode, ''))

      if @line2 = NULL or len(ltrim(rtrim(@line2))) = 0
      begin
         select @line2 = @line3
         select @line3 = @line4
         select @line4 = NULL
      end

      if @line3 = NULL or len(ltrim(rtrim(@line3))) = 0
      begin
         select @line3 = @line4
         select @line4 = NULL
      end

      insert into #campaign
          values (	@campaign_no,
					@name_on_slide,
					@agency_deal,
					@client_agency_name,
					@address_1,
					@address_2,
					@town_suburb,
					@postcode,
					@state,
					@signatory,
					@contact,
					@campaign_phone,
					@cr_first_name,
					@cr_last_name,
					@sr_first_name,
					@sr_last_name,
					@cc_name,
					@nett_contract_value,
					@campaign_status,
					@campaign_type,
					@campaign_category,
					@campaign_branch,
					@campaign_branch_name,
					@complex_id,
					@campaign_complex_name,
					@line1,
					@line2,
					@line3,
					@line4,
					@industry_category_id,
					@industry_category_desc,
					@email )
	end
	
	/*
    * Fetch Next
    */

   fetch campaign_csr into @campaign_no

end
close campaign_csr
deallocate campaign_csr

/*
 * Return contents of the table
 */

select * from #campaign

/*
 * Return Success
 */

return 0
GO
