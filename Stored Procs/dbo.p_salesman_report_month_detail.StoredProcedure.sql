/****** Object:  StoredProcedure [dbo].[p_salesman_report_month_detail]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_salesman_report_month_detail]
GO
/****** Object:  StoredProcedure [dbo].[p_salesman_report_month_detail]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_salesman_report_month_detail] 	@s_report 		varchar(255) , 
											@i_id 			int, 
											@s_code 		varchar(16), 
											@d_first 		datetime, 
											@d_last 		datetime, 
											@d_pfirst 		datetime, 
											@d_plast 		datetime,
											@d_period		datetime

with recompile
as

begin

/*
 * Declare Variables
 */

declare     @error_num              int
declare		@scorefile				varchar(64)
declare		@actual					money
declare		@target					money					
declare		@value					money					
declare		@scorerow				char(02)
declare		@actualrow				char(02)
declare		@targetrow				char(02)
declare     @buss_unit              int
declare     @revision_group         int
declare     @target_revision_group  int
declare     @period_no         		int

SELECT @buss_unit = 0
SELECT @revision_group = 0
SELECT @scorerow = '14'
SELECT @actualrow = '14'
SELECT @targetrow = '20'

select 	@period_no = period_no
from	film_sales_period
where	sales_period = @d_period

IF ( CHARINDEX ( 'bu=1', @s_report ) > 0 ) SELECT @buss_unit = 1
IF ( CHARINDEX ( 'bu=2', @s_report ) > 0 ) SELECT @buss_unit = 2
IF ( CHARINDEX ( 'bu=3', @s_report ) > 0 ) SELECT @buss_unit = 3
IF ( CHARINDEX ( 'bu=4', @s_report ) > 0 ) SELECT @buss_unit = 4
IF ( CHARINDEX ( 'bu=5', @s_report ) > 0 ) SELECT @buss_unit = 5
IF ( CHARINDEX ( 'bu=9', @s_report ) > 0 ) SELECT @buss_unit = 9
IF ( CHARINDEX ( 'rg=1', @s_report ) > 0 ) SELECT @revision_group = 1
IF ( CHARINDEX ( 'rg=2', @s_report ) > 0 ) SELECT @revision_group = 2
IF ( CHARINDEX ( 'rg=3', @s_report ) > 0 ) SELECT @revision_group = 3
IF ( CHARINDEX ( 'rg=4', @s_report ) > 0 ) SELECT @revision_group = 4
IF ( CHARINDEX ( 'unit=1', @s_report ) > 0 ) SELECT @buss_unit = 1
IF ( CHARINDEX ( 'unit=2', @s_report ) > 0 ) SELECT @buss_unit = 2
IF ( CHARINDEX ( 'unit=3', @s_report ) > 0 ) SELECT @buss_unit = 3
IF ( CHARINDEX ( 'unit=4', @s_report ) > 0 ) SELECT @buss_unit = 4
IF ( CHARINDEX ( 'unit=5', @s_report ) > 0 ) SELECT @buss_unit = 5
IF ( CHARINDEX ( 'unit=9', @s_report ) > 0 ) SELECT @buss_unit = 9
IF ( CHARINDEX ( 'group=1', @s_report ) > 0 ) SELECT @revision_group = 1
IF ( CHARINDEX ( 'group=2', @s_report ) > 0 ) SELECT @revision_group = 2
IF ( CHARINDEX ( 'group=3', @s_report ) > 0 ) SELECT @revision_group = 3
IF ( CHARINDEX ( 'group=4', @s_report ) > 0 ) SELECT @revision_group = 4

if @revision_group > 0
	select @target_revision_group = @revision_group
else
	select @target_revision_group = 1

SELECT @scorefile = 'G:\Development\Resources\1616\'

/* Create temporary tables for resultsets */

CREATE TABLE #workout
(		
		rep_title 				varchar(42) 	NULL,
		rep_category 			varchar(42) 	NULL,
		rep_cat_sort 			varchar(42) 	NULL,
		rep_series  			varchar(42) 	NULL,
		rep_series_sort  		varchar(42) 	NULL,
		rep_value_month 		money 			NULL,
		rep_value_onscreen 		money 			NULL,
		rep_value_offscreen 	money 			NULL,
		rep_tot_value_month 	money 			NULL,
		rep_tot_value_onscreen 	money 			NULL,
		rep_tot_value_offscreen money 			NULL,
		scorefilemonth  		varchar(64)		NULL,
		scorefileonscreen  		varchar(64)		NULL,
		scorefileoffscreen  	varchar(64)		NULL,
		scorefiletotmonth  		varchar(64)		NULL,
		scorefiletotonscreen  	varchar(64)		NULL,
		scorefiletotoffscreen  	varchar(64)		NULL
)

CREATE TABLE #workout2
(
		rep_title 				varchar(42) 	NULL,
		rep_category 			varchar(42) 	NULL,
		rep_cat_sort 			varchar(42) 	NULL,
		rep_series  			varchar(42) 	NULL,
		rep_series_sort  		varchar(42) 	NULL,
		rep_value_month 		money 			NULL,
		rep_value_onscreen 		money 			NULL,
		rep_value_offscreen 	money 			NULL,
		rep_tot_value_month 	money 			NULL,
		rep_tot_value_onscreen 	money 			NULL,
		rep_tot_value_offscreen money 			NULL,
		pct_value_month 		money 			NULL,
		pct_value_onscreen 		money 			NULL,
		pct_value_offscreen 	money 			NULL,
		pct_tot_value_month 	money 			NULL,
		pct_tot_value_onscreen 	money 			NULL,
		pct_tot_value_offscreen money 			NULL,
		scorefilemonth  		varchar(64)		NULL,
		scorefileonscreen  		varchar(64)		NULL,
		scorefileoffscreen  	varchar(64)		NULL,
		scorefiletotmonth  		varchar(64)		NULL,
		scorefiletotonscreen  	varchar(64)		NULL,
		scorefiletotoffscreen  	varchar(64)		NULL
)

CREATE TABLE #work
(		
		rep_title 				varchar(42) 	NULL,
		rep_category 			varchar(42) 	NULL,
		rep_cat_sort 			varchar(42) 	NULL,
		rep_series  			varchar(42) 	NULL,
		rep_series_sort  		varchar(42) 	NULL,
		rep_value 				money 			NULL,
		rep_type				varchar(42) 	null
)

IF ( CHARINDEX ( 'MONTH', @s_report ) > 0 ) 
begin
	IF  ( CHARINDEX ( 'branch' , @s_report ) > 0 )
	begin
			IF  ( CHARINDEX ( 'states' , @s_report ) > 0 )
			begin
					insert 		#work 
					SELECT 		state_code, 
								DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) ,
								state_code ,
								'90' + convert ( char(4) , branch.sort_order ),
								sum ( nett_amount ),
								'Onscreen'
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								branch
					WHERE 		( book.branch_code =  @s_code 
					OR  		  book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
					AND			book.booking_period = period_year.sales_period
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group )
					and			book.revision_group = 1
					AND 		( @buss_unit=0 
					OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		branch.branch_code = book.branch_code 
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
					GROUP BY 	DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) ,
								state_code,
								branch.sort_order
					HAVING 		sum ( nett_amount ) <> 0

					insert 		#work 
					SELECT 		state_code, 
								DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) ,
								state_code ,
								'90' + convert ( char(4) , branch.sort_order ),
								sum ( nett_amount ),
								'Offscreen'
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								branch
					WHERE 		( book.branch_code =  @s_code 
					OR  		  book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
					AND			book.booking_period = period_year.sales_period
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group )
					and			book.revision_group <> 1 and book.revision_group < 49
					AND 		( @buss_unit=0 
					OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		branch.branch_code = book.branch_code 
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
					GROUP BY 	DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) ,
								state_code,
								branch.sort_order
					HAVING 		sum ( nett_amount ) <> 0
			end	

			IF  ( CHARINDEX ( 'revisiongroup' , @s_report ) > 0 )
			begin
					insert 		#work 
					SELECT 		'', 
								DateName ( month , period_year.sales_period),
								convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 to not sort 1, 10 ,11,12  but 101, 102... 110*/
								'', 
								'7' + convert ( char(1) , film_campaign.business_unit_id - 2),
								sum ( nett_amount ),
								'Onscreen'
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								revision_group,
								film_campaign
					WHERE 		( book.branch_code =  @s_code 
					OR  		book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
					AND			book.booking_period = period_year.sales_period
					and			film_campaign.campaign_no = book.campaign_no
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group ) 
					and			book.revision_group = 1
					AND 		( @buss_unit=0 
					OR	 		EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		book.revision_group = revision_group.revision_group
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
					GROUP BY 	DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) ,
								film_campaign.business_unit_id
					HAVING 		sum ( nett_amount ) <> 0

					insert 		#work 
					SELECT 		'', 
								DateName ( month , period_year.sales_period),
								convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 to not sort 1, 10 ,11,12  but 101, 102... 110*/
								'', 
								'8' + convert ( char(1) , book.revision_group),
								sum ( nett_amount ),
								'Offscreen'
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								revision_group
					WHERE 		( book.branch_code =  @s_code 
					OR  		book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
					AND			book.booking_period = period_year.sales_period
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group ) 
					and			book.revision_group <> 1 and book.revision_group < 49
					AND 		( @buss_unit=0 
					OR	 		EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		book.revision_group = revision_group.revision_group
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
					GROUP BY 	DateName ( month , period_year.sales_period),
								convert ( char(3) , 200 +  period_year.period_no) ,
								book.revision_group
					HAVING 		sum ( nett_amount ) <> 0
			end	
		

	
			insert 		#work 
			SELECT 		'Branch', 
						DateName ( month , period_year.sales_period)  ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Bookings',--'Revenue' ,
						'10',
						sum ( nett_amount ),
						'Onscreen'
			FROM    	booking_figures AS book,
						film_sales_period AS period_year
			WHERE 		( book.branch_code =  @s_code 
			OR  		book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
			AND			book.booking_period = period_year.sales_period
			AND 		( @revision_group=0 
			OR 			book.revision_group = @revision_group ) 
			AND 		( @buss_unit=0 
			OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
			and			book.revision_group = 1
			AND 		period_year.sales_period between @d_first and @d_last 
			AND 		figure_type <> 'A'
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY 	DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) 
			HAVING 		sum ( nett_amount ) <> 0
	
			insert 		#work 
			SELECT 		'Branch', 
						DateName ( month , period_year.sales_period)  ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Bookings',--'Revenue' ,
						'10',
						sum ( nett_amount ),
						'Offscreen'
			FROM    	booking_figures AS book,
						film_sales_period AS period_year
			WHERE 		( book.branch_code =  @s_code 
			OR  		book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
			AND			book.booking_period = period_year.sales_period
			AND 		( @revision_group=0 
			OR 			book.revision_group = @revision_group ) 
			AND 		( @buss_unit=0 
			OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
			and			book.revision_group <> 1 and book.revision_group < 49
			AND 		period_year.sales_period between @d_first and @d_last 
			AND 		figure_type <> 'A'
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY 	DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) 
			HAVING 		sum ( nett_amount ) <> 0
	
			insert 		#work 
			SELECT 		'Branch', 
						DateName ( month , period_year.sales_period),
						convert ( char(3) , 200 +  period_year.period_no)  ,
						'Adj' ,
						'12',
						sum ( nett_amount ),
						'Onscreen'
			FROM    	booking_figures AS book,
						film_sales_period AS period_year
			WHERE 		( book.branch_code =  @s_code 
			OR  		book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
			AND			book.booking_period = period_year.sales_period
			AND 		( @revision_group=0 
			OR 			book.revision_group = @revision_group ) 
			and			book.revision_group = 1
			AND 		( @buss_unit=0 
			OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
			AND 		period_year.sales_period between @d_first and @d_last 
			AND 		figure_type = 'A'
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY 	DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) 
			HAVING 		sum ( nett_amount ) <> 0
			
			insert 		#work 
			SELECT 		'Branch', 
						DateName ( month , period_year.sales_period),
						convert ( char(3) , 200 +  period_year.period_no)  ,
						'Adj' ,
						'12',
						sum ( nett_amount ),
						'Offscreen'
			FROM    	booking_figures AS book,
						film_sales_period AS period_year
			WHERE 		( book.branch_code =  @s_code 
			OR  		book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
			AND			book.booking_period = period_year.sales_period
			AND 		( @revision_group=0 
			OR 			book.revision_group = @revision_group ) 
			and			book.revision_group <> 1 and book.revision_group < 49
			AND 		( @buss_unit=0 
			OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
			AND 		period_year.sales_period between @d_first and @d_last 
			AND 		figure_type = 'A'
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
 			GROUP BY 	DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) 
			HAVING 		sum ( nett_amount ) <> 0

			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
				insert 		#work 
				SELECT 		'Branch', 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no) ,
							'' ,
							'30',
							sum ( nett_amount ),
							'Onscreen'
				FROM    	booking_figures AS book,
							film_sales_period AS period_year
				WHERE 		( book.branch_code =  @s_code 
				OR  		book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND			book.booking_period = period_year.sales_period
				AND 		( @revision_group=0 
				OR 			book.revision_group = @revision_group ) 
				and			book.revision_group = 1
				AND 		( @buss_unit=0 
				OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 		period_year.sales_period between @d_pfirst and @d_plast 
				and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY 	DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no) 
				HAVING 		sum ( nett_amount ) <> 0

				insert 		#work 
				SELECT 		'Branch', 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no) ,
							'' ,
							'30',
							sum ( nett_amount ),
							'Offscreen'
				FROM    	booking_figures AS book,
							film_sales_period AS period_year
				WHERE 		( book.branch_code =  @s_code 
				OR  		book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND			book.booking_period = period_year.sales_period
				AND 		( @revision_group=0 
				OR 			book.revision_group = @revision_group ) 
				and			book.revision_group <> 1 and book.revision_group < 49
				AND 		( @buss_unit=0 
				OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 		period_year.sales_period between @d_pfirst and @d_plast 
				and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY 	DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no) 
				HAVING 		sum ( nett_amount ) <> 0
			end
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
				
				/*UPDATE #work set rep_series = 'Bookings'*/
				
				insert 		#work
				SELECT 		'Branch', 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 because so as not to sort 1, 10 ,11,12 but 101, 102... 110*/
							'' ,
							'20',
							sum ( target ),
							'Onscreen'
				FROM    	booking_target AS book,
							film_sales_period AS period_year
				WHERE 		( book.branch_code =  @s_code 
				OR  		book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND			book.sales_period = period_year.sales_period
				AND 		( @target_revision_group=0 
				OR 			book.revision_group = @target_revision_group ) 
				and			revision_group = 1
				AND 		( @buss_unit=0 
				OR 			book.business_unit_id = @buss_unit ) 
				AND 		period_year.sales_period between @d_first and @d_last 
				and			book.business_unit_id <> 6
				GROUP BY 	DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) , 
							DateName ( year , period_year.sales_period) 
				HAVING 		sum ( target ) <> 0


				insert 		#work
				SELECT 		'Branch', 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 because so as not to sort 1, 10 ,11,12 but 101, 102... 110*/
							'' ,
							'20',
							sum ( target ),
							'Offscreen'
				FROM    	booking_target AS book,
							film_sales_period AS period_year
				WHERE 		( book.branch_code =  @s_code 
				OR  		book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND			book.sales_period = period_year.sales_period
				AND 		( @revision_group=0 
				OR 			book.revision_group = @revision_group ) 
				and			revision_group <> 1
				AND 		( @buss_unit=0 
				OR 			book.business_unit_id = @buss_unit ) 
				AND 		period_year.sales_period between @d_first and @d_last 
				and			book.business_unit_id <> 6
				GROUP BY 	DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) , 
							DateName ( year , period_year.sales_period) 
				HAVING 		sum ( target ) <> 0
			end
	
		IF ( @s_code = 'A' ) UPDATE #work set rep_title = 'Australia'
		ELSE IF ( @s_code = 'A' ) UPDATE #work set rep_title = 'New Zealand'
		ELSE  UPDATE #work set rep_title = ( Select branch_name from branch where branch_code = @s_code )
				

	end /* branch */

	IF  ( CHARINDEX ( 'sales_rep' , @s_report ) > 0 )
	begin
	
			insert 		#work 
			SELECT 		'Rep: ' + first_name + ' ' + last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Bookings',--'Revenue' ,
						'10',
						sum ( nett_amount ),
						'Onscreen'
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_rep
			WHERE 		book.rep_id =  @i_id 
			AND 		book.rep_id = sales_rep.rep_id
			AND			book.booking_period = period_year.sales_period
			AND 		( @revision_group=0 
			OR 			book.revision_group = @revision_group )
			and			book.revision_group = 1 
			AND 		( @buss_unit=0 
			OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
			AND 		period_year.sales_period between @d_first and @d_last 
			AND 		figure_type <> 'A'
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY 	first_name , 
						last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no)
			HAVING 		sum ( nett_amount ) <> 0
	
			insert 		#work 
			SELECT 		'Rep: ' + first_name + ' ' + last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Bookings',--'Revenue' ,
						'10',
						sum ( nett_amount ),
						'Offscreen'
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_rep
			WHERE 		book.rep_id =  @i_id 
			AND 		book.rep_id = sales_rep.rep_id
			AND			book.booking_period = period_year.sales_period
			AND 		( @revision_group=0 
			OR 			book.revision_group = @revision_group )
			and			book.revision_group <> 1 and book.revision_group < 49 
			AND 		( @buss_unit=0 
			OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
			AND 		period_year.sales_period between @d_first and @d_last 
			AND 		figure_type <> 'A'
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY 	first_name , 
						last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no)
			HAVING 		sum ( nett_amount ) <> 0

			insert 		#work 
			SELECT 		'Rep: ' + first_name + ' ' + last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Adj' ,
						'12',
						sum ( nett_amount ),
						'Onscreen'
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_rep
			WHERE 		book.rep_id =  @i_id 
			AND 		book.rep_id = sales_rep.rep_id
			AND			book.booking_period = period_year.sales_period
			AND 		( @revision_group=0 
			OR 			book.revision_group = @revision_group ) 
			and			book.revision_group = 1
			AND 		( @buss_unit=0 
			OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
			AND 		period_year.sales_period between @d_first and @d_last 
			AND 		figure_type = 'A'
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY 	first_name , 
						last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no)
			HAVING 		sum ( nett_amount ) <> 0
						
			insert 		#work 
			SELECT 		'Rep: ' + first_name + ' ' + last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Adj' ,
						'12',
						sum ( nett_amount ),
						'Offscreen'
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_rep
			WHERE 		book.rep_id =  @i_id 
			AND 		book.rep_id = sales_rep.rep_id
			AND			book.booking_period = period_year.sales_period
			AND 		( @revision_group=0 
			OR 			book.revision_group = @revision_group ) 
			and			book.revision_group <> 1 and book.revision_group < 49
			AND 		( @buss_unit=0 
			OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
			AND 		period_year.sales_period between @d_first and @d_last 
			AND 		figure_type = 'A'
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY 	first_name , 
						last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no)
			HAVING 		sum ( nett_amount ) <> 0

			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
	
				insert 		#work 
				SELECT 		'Rep: ' + first_name + ' ' + last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no) ,
							'' ,
							'30',
							sum ( nett_amount ),
							'Onscreen'
				FROM    	booking_figures AS book,
							film_sales_period AS period_year,
							sales_rep
				WHERE 		book.rep_id =  @i_id 
				AND 		book.rep_id = sales_rep.rep_id
				AND			book.booking_period = period_year.sales_period
				AND 		( @revision_group=0 
				OR 			book.revision_group = @revision_group ) 
				and			book.revision_group = 1
				AND 		( @buss_unit=0 
				OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 		period_year.sales_period between @d_pfirst and @d_plast 
				and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY 	first_name , 
							last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no)
				HAVING 		sum ( nett_amount ) <> 0

				insert 		#work 
				SELECT 		'Rep: ' + first_name + ' ' + last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no) ,
							'' ,
							'30',
							sum ( nett_amount ),
							'Offscreen'
				FROM    	booking_figures AS book,
							film_sales_period AS period_year,
							sales_rep
				WHERE 		book.rep_id =  @i_id 
				AND 		book.rep_id = sales_rep.rep_id
				AND			book.booking_period = period_year.sales_period
				AND 		( @revision_group=0 
				OR 			book.revision_group = @revision_group ) 
				and			book.revision_group <> 1 and book.revision_group < 49
				AND 		( @buss_unit=0 
				OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 		period_year.sales_period between @d_pfirst and @d_plast 
				and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY 	first_name , 
							last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no)
				HAVING 		sum ( nett_amount ) <> 0
			end		
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
	
				/*UPDATE #work set rep_series = 'Bookings'*/
	
				insert 		#work
				SELECT 		'Rep: ' + first_name + ' ' + last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) ,
							'' ,
							'20',
							sum ( target ),
							'Onscreen'
				FROM    	booking_target AS book,
							film_sales_period AS period_year,
							sales_rep
				WHERE		book.rep_id =  @i_id 
				AND 		book.rep_id = sales_rep.rep_id
				AND			book.sales_period = period_year.sales_period
				AND 		( @target_revision_group=0 
				OR 			book.revision_group = @target_revision_group ) 	
				and			book.revision_group = 1
				AND 		( @buss_unit=0 
				OR 			book.business_unit_id = @buss_unit ) 
				AND 		period_year.sales_period between @d_first and @d_last 
				and			book.business_unit_id <> 6
				GROUP BY 	first_name, 
							last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) ,
							DateName ( year , period_year.sales_period) 
				HAVING 		sum ( target ) <> 0

				insert 		#work
				SELECT 		'Rep: ' + first_name + ' ' + last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) ,
							'' ,
							'20',
							sum ( target ),
							'Offscreen'
				FROM    	booking_target AS book,
							film_sales_period AS period_year,
							sales_rep
				WHERE		book.rep_id =  @i_id 
				AND 		book.rep_id = sales_rep.rep_id
				AND			book.sales_period = period_year.sales_period
				AND 		( @revision_group=0 
				OR 			book.revision_group = @revision_group ) 	
				and			book.revision_group <> 1 and book.revision_group < 49
				AND 		( @buss_unit=0 
				OR 			book.business_unit_id = @buss_unit ) 
				AND 		period_year.sales_period between @d_first and @d_last 
				and			book.business_unit_id <> 6
				GROUP BY 	first_name, 
							last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) ,
							DateName ( year , period_year.sales_period) 
				HAVING 		sum ( target ) <> 0
			end

			IF  ( CHARINDEX ( 'revisiongroup' , @s_report ) > 0 )
			begin
					insert 		#work 
					SELECT 		'', 
								DateName ( month , period_year.sales_period),
								convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 to not sort 1, 10 ,11,12  but 101, 102... 110*/
								'', 
								'7' + convert ( char(1) , film_campaign.business_unit_id - 2),
								sum ( nett_amount ),
								'Onscreen'
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								revision_group,
								film_campaign
					WHERE 		book.rep_id = @i_id
					AND			book.booking_period = period_year.sales_period
					and			film_campaign.campaign_no = book.campaign_no
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group ) 
					and			book.revision_group = 1
					AND 		( @buss_unit=0 
					OR	 		EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		book.revision_group = revision_group.revision_group
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
					GROUP BY 	DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) ,
								film_campaign.business_unit_id
					HAVING 		sum ( nett_amount ) <> 0

					insert 		#work 
					SELECT 		'', 
								DateName ( month , period_year.sales_period),
								convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 to not sort 1, 10 ,11,12  but 101, 102... 110*/
								'', 
								'8' + convert ( char(1) , book.revision_group),
								sum ( nett_amount ),
								'Offscreen'
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								revision_group
					WHERE 		book.rep_id = @i_id
					AND			book.booking_period = period_year.sales_period
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group ) 
					and			book.revision_group <> 1 and book.revision_group < 49
					AND 		( @buss_unit=0 
					OR	 		EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		book.revision_group = revision_group.revision_group
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
					GROUP BY 	DateName ( month , period_year.sales_period),
								convert ( char(3) , 200 +  period_year.period_no) ,
								book.revision_group
					HAVING 		sum ( nett_amount ) <> 0
			end	

	end /*sales_rep*/
	
	IF  ( CHARINDEX ( 'team' , @s_report ) > 0 )
	begin
	
			insert 		#work 
			SELECT 		'Team: ' + team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Bookings',--'Revenue' ,
						'10',
						sum ( nett_amount ),
						'Onscreen'
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_team, booking_figure_team_xref
			WHERE 		book.figure_id =  booking_figure_team_xref.figure_id 
			AND 		booking_figure_team_xref.team_id = @i_id 
			AND 		booking_figure_team_xref.team_id = sales_team.team_id
			AND			book.booking_period = period_year.sales_period
			AND 		( @revision_group=0 
			OR 			book.revision_group = @revision_group ) 
			and			book.revision_group = 1 
			AND 		( @buss_unit=0 
			OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
			AND 		period_year.sales_period between @d_first and @d_last 
			AND 		figure_type <> 'A'
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY 	team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no)
			HAVING 		sum ( nett_amount ) <> 0
	
			insert 		#work 
			SELECT 		'Team: ' + team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Bookings',--'Revenue' ,
						'10',
						sum ( nett_amount ),
						'Offscreen'
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_team, booking_figure_team_xref
			WHERE 		book.figure_id =  booking_figure_team_xref.figure_id 
			AND 		booking_figure_team_xref.team_id = @i_id 
			AND 		booking_figure_team_xref.team_id = sales_team.team_id
			AND			book.booking_period = period_year.sales_period
			AND 		( @revision_group=0 
			OR 			book.revision_group = @revision_group ) 
			and			book.revision_group <> 1 and book.revision_group < 49 
			AND 		( @buss_unit=0 
			OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
			AND 		period_year.sales_period between @d_first and @d_last 
			AND 		figure_type <> 'A'
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY 	team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no)
			HAVING 		sum ( nett_amount ) <> 0

			
			insert 		#work 
			SELECT 		'Team: ' + team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Adj' ,
						'12',
						sum ( nett_amount ),
						'Onscreen'
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_team, booking_figure_team_xref
			WHERE 		book.figure_id =  booking_figure_team_xref.figure_id 
			AND 		booking_figure_team_xref.team_id = @i_id 
			AND 		booking_figure_team_xref.team_id = sales_team.team_id
			AND			book.booking_period = period_year.sales_period
			AND 		( @revision_group=0 
			OR 			book.revision_group = @revision_group ) 
			and			book.revision_group = 1
			AND 		( @buss_unit=0 
			OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
			AND 		period_year.sales_period between @d_first and @d_last 
			AND 		figure_type = 'A'
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY 	team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no)
			HAVING 		sum ( nett_amount ) <> 0
			
			insert 		#work 
			SELECT 		'Team: ' + team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Adj' ,
						'12',
						sum ( nett_amount ),
						'Offscreen'
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_team, booking_figure_team_xref
			WHERE 		book.figure_id =  booking_figure_team_xref.figure_id 
			AND 		booking_figure_team_xref.team_id = @i_id 
			AND 		booking_figure_team_xref.team_id = sales_team.team_id
			AND			book.booking_period = period_year.sales_period
			AND 		( @revision_group=0 
			OR 			book.revision_group = @revision_group ) 
			and			book.revision_group <> 1 and book.revision_group < 49
			AND 		( @buss_unit=0 
			OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
			AND 		period_year.sales_period between @d_first and @d_last 
			AND 		figure_type = 'A'
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY 	team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no)
			HAVING 		sum ( nett_amount ) <> 0
			
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
	
				insert 		#work 
				SELECT 		'Team: ' + team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no) ,
							'' ,
							'30',
							sum ( nett_amount ),
							'Onscreen'
				FROM    	booking_figures AS book,
							film_sales_period AS period_year,
							sales_team, booking_figure_team_xref
				WHERE 		book.figure_id =  booking_figure_team_xref.figure_id 
				AND 		booking_figure_team_xref.team_id = @i_id 
				AND 		booking_figure_team_xref.team_id = sales_team.team_id
				AND			book.booking_period = period_year.sales_period
				AND 		( @revision_group=0 
				OR 			book.revision_group = @revision_group ) 
				and			book.revision_group = 1
				AND 		( @buss_unit=0 
				OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 		period_year.sales_period between @d_pfirst and @d_plast 
				and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY 	team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no)
				HAVING 		sum ( nett_amount ) <> 0


				insert 		#work 
				SELECT 		'Team: ' + team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no) ,
							'' ,
							'30',
							sum ( nett_amount ),
							'Offscreen'
				FROM    	booking_figures AS book,
							film_sales_period AS period_year,
							sales_team, booking_figure_team_xref
				WHERE 		book.figure_id =  booking_figure_team_xref.figure_id 
				AND 		booking_figure_team_xref.team_id = @i_id 
				AND 		booking_figure_team_xref.team_id = sales_team.team_id
				AND			book.booking_period = period_year.sales_period
				AND 		( @revision_group=0 
				OR 			book.revision_group = @revision_group ) 
				and			book.revision_group <> 1 and book.revision_group < 49
				AND 		( @buss_unit=0 
				OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 		period_year.sales_period between @d_pfirst and @d_plast 
				and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY 	team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no)
				HAVING 		sum ( nett_amount ) <> 0
			end
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
	
				/*UPDATE #work set rep_series = 'Bookings'*/
	
				insert 		#work
				SELECT 		'Team: ' + team_name, 
							DateName ( month , period_year.sales_period)  ,
							convert ( char(3) , 200 +  period_year.period_no) ,
							'' ,
							'20',
							sum ( target ),
							'Onscreen'
				FROM    	booking_target AS book,
							film_sales_period AS period_year,
							sales_team
				WHERE 		book.team_id =  @i_id 
				AND 		book.team_id = sales_team.team_id
				AND			book.sales_period = period_year.sales_period
				AND 		( @target_revision_group=0 
				OR 			book.revision_group = @target_revision_group ) 
				and			book.revision_group = 1
				AND 		( @buss_unit=0 
				OR 			book.business_unit_id = @buss_unit ) 
				AND 		period_year.sales_period between @d_first and @d_last 
				and			book.business_unit_id <> 6
				GROUP BY 	team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) ,
							DateName ( year , period_year.sales_period) 
				HAVING 		sum ( target ) <> 0

				insert 		#work
				SELECT 		'Team: ' + team_name, 
							DateName ( month , period_year.sales_period)  ,
							convert ( char(3) , 200 +  period_year.period_no) ,
							'' ,
							'20',
							sum ( target ),
							'Offscreen'
				FROM    	booking_target AS book,
							film_sales_period AS period_year,
							sales_team
				WHERE 		book.team_id =  @i_id 
				AND 		book.team_id = sales_team.team_id
				AND			book.sales_period = period_year.sales_period
				AND 		( @target_revision_group=0 
				OR 			book.revision_group = @target_revision_group ) 
				and			book.revision_group <> 1 and book.revision_group < 49
				AND 		( @buss_unit=0 
				OR 			book.business_unit_id = @buss_unit ) 
				AND 		period_year.sales_period between @d_first and @d_last 
				and			book.business_unit_id <> 6
				GROUP BY 	team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) ,
							DateName ( year , period_year.sales_period) 
				HAVING 		sum ( target ) <> 0
			end
			IF  ( CHARINDEX ( 'revisiongroup' , @s_report ) > 0 )
			begin
					insert 		#work 
					SELECT 		'', 
								DateName ( month , period_year.sales_period),
								convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 to not sort 1, 10 ,11,12  but 101, 102... 110*/
								'', 
								'7' + convert ( char(1) , film_campaign.business_unit_id - 2),
								sum ( nett_amount ),
								'Onscreen'
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								revision_group,
								film_campaign,
								booking_figure_team_xref
					WHERE 		book.figure_id = booking_figure_team_xref.figure_id
					and			booking_figure_team_xref.team_id = @i_id
					AND			book.booking_period = period_year.sales_period
					and			film_campaign.campaign_no = book.campaign_no
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group ) 
					and			book.revision_group = 1
					AND 		( @buss_unit=0 
					OR	 		EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		book.revision_group = revision_group.revision_group
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
					GROUP BY 	DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) ,
								film_campaign.business_unit_id
					HAVING 		sum ( nett_amount ) <> 0

					insert 		#work 
					SELECT 		'', 
								DateName ( month , period_year.sales_period),
								convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 to not sort 1, 10 ,11,12  but 101, 102... 110*/
								'', 
								'8' + convert ( char(1) , book.revision_group),
								sum ( nett_amount ),
								'Offscreen'
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								revision_group,
								booking_figure_team_xref
					WHERE 		book.figure_id = booking_figure_team_xref.figure_id
					and			booking_figure_team_xref.team_id = @i_id
					AND			book.booking_period = period_year.sales_period
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group ) 
					and			book.revision_group <> 1 and book.revision_group < 49
					AND 		( @buss_unit=0 
					OR	 		EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		book.revision_group = revision_group.revision_group
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
					GROUP BY 	DateName ( month , period_year.sales_period),
								convert ( char(3) , 200 +  period_year.period_no) ,
								book.revision_group
					HAVING 		sum ( nett_amount ) <> 0
			end	


		end /* team */
	end /* month */

--select * from #work
	insert into 	#workout
	(
		rep_title, 
		rep_category, 
		rep_cat_sort, 
		rep_series,  
		rep_series_sort, 
		rep_value_onscreen ,
		rep_tot_value_onscreen
	)
	select 		rep_title, 
				rep_category, 
				rep_cat_sort, 
				rep_series,  
				rep_series_sort,
				sum(rep_value),
				(select 	sum(isnull(w.rep_value,0)) 
				from 		#work w
				where 		w.rep_type = 'Onscreen' 
				and			w.rep_series_sort = #work.rep_series_sort)
	from		#work
	where		(rep_cat_sort = convert ( char(3) , 200 +  @period_no)
	or 			rep_cat_sort = convert ( char(3) , 100 +  @period_no))
	and			rep_type = 'Onscreen'
	group by 	rep_title, 
				rep_category, 
				rep_cat_sort, 
				rep_series,  
				rep_series_sort
	
	insert into 	#workout
	(
		rep_title, 
		rep_category, 
		rep_cat_sort, 
		rep_series,  
		rep_series_sort, 
		rep_value_offscreen,
		rep_tot_value_offscreen
	)
	select 		rep_title, 
				rep_category, 
				rep_cat_sort, 
				rep_series,  
				rep_series_sort,
				sum(rep_value),
				(select 	sum(isnull(w.rep_value,0)) 
				from 		#work w 
				where 		w.rep_type = 'Offscreen' 
				and			w.rep_series_sort = #work.rep_series_sort)
	from		#work
	where		(rep_cat_sort = convert ( char(3) , 200 +  @period_no)
	or 			rep_cat_sort = convert ( char(3) , 100 +  @period_no))
	and			rep_type = 'Offscreen'
	group by 	rep_title, 
				rep_category, 
				rep_cat_sort, 
				rep_series,  
				rep_series_sort

	/*
	 * Insert Rows that aren't on the given month ie if qld didn't sell anything for the month but did for the 6 months
	 */			

	insert into 	#workout
	(
		rep_title, 
		rep_category, 
		rep_cat_sort, 
		rep_series,  
		rep_series_sort, 
		rep_value_onscreen ,
		rep_tot_value_onscreen
	)
	select 		rep_title, 
				rep_category, 
				rep_cat_sort, 
				rep_series,  
				rep_series_sort,
				0,
				sum(isnull(rep_value,0))
	from		#work
	where		rep_type = 'Onscreen'
	and			rep_series_sort not in (select rep_series_sort from #workout where rep_value_onscreen is not null)
	group by 	rep_title, 
				rep_category, 
				rep_cat_sort, 
				rep_series,  
				rep_series_sort
	
	insert into 	#workout
	(
		rep_title, 
		rep_category, 
		rep_cat_sort, 
		rep_series,  
		rep_series_sort, 
		rep_value_offscreen,
		rep_tot_value_offscreen
	)
	select 		rep_title, 
				rep_category, 
				rep_cat_sort, 
				rep_series,  
				rep_series_sort,
				0,
				sum(isnull(rep_value,0))
	from		#work
	where		rep_type = 'Offscreen'
	and			rep_series_sort not in (select rep_series_sort from #workout where rep_value_offscreen is not null)
	group by 	rep_title, 
				rep_category, 
				rep_cat_sort, 
				rep_series,  
				rep_series_sort


	update 	#workout 
	set 	rep_tot_value_month = isnull(rep_tot_value_onscreen,0) + isnull(rep_tot_value_offscreen,0),
			rep_value_month = isnull(rep_value_onscreen,0) + isnull(rep_value_offscreen,0)
	where 	rep_series_sort <> '20'
	
	update 	#workout 
	set 	rep_tot_value_month = isnull(rep_tot_value_onscreen,0) ,
			rep_value_month = isnull(rep_value_onscreen,0)
	where 	rep_series_sort = '20'

	IF ( CHARINDEX ( 'summary', @s_report ) > 0 ) 
	begin
		INSERT into #workout
		(
			rep_title,
			rep_series,
			rep_series_sort,
			rep_value_month,
			rep_value_onscreen,
			rep_value_offscreen,
			rep_tot_value_month,
			rep_tot_value_onscreen,
			rep_tot_value_offscreen
	
		)
			SELECT
			rep_title ,
			'Total',
			@actualrow,
			sum ( rep_value_month ),
			sum ( rep_value_onscreen ),
			sum ( rep_value_offscreen ),
			sum ( rep_tot_value_month ),
			sum ( rep_tot_value_onscreen ),
			sum ( rep_tot_value_offscreen )
		FROM #workout
		WHERE rep_series_sort in ( '10','12' )
		GROUP BY rep_title, rep_series, rep_series_sort 
	
		/* target variance */
		INSERT into #workout
		(
			rep_title,
			rep_series,
			rep_series_sort,
			rep_value_month,
			rep_value_onscreen,
			rep_value_offscreen,
			rep_tot_value_month,
			rep_tot_value_onscreen,
			rep_tot_value_offscreen
	
		)
			SELECT
			rep_title ,
			'(+/-)',
			'24',
			sum ( rep_value_month ),
			sum ( rep_value_onscreen ),
			sum ( rep_value_offscreen ),
			sum ( rep_tot_value_month ),
			sum ( rep_tot_value_onscreen ),
			sum ( rep_tot_value_offscreen )
		FROM #workout
		WHERE rep_series_sort in ( '10','12' )
		GROUP BY rep_title, rep_series, rep_series_sort 
	
		INSERT into #workout
		(
			rep_title,
			rep_series,
			rep_series_sort,
			rep_value_month,
			rep_value_onscreen,
			rep_value_offscreen,
			rep_tot_value_month,
			rep_tot_value_onscreen,
			rep_tot_value_offscreen
	
		)
			SELECT
			rep_title ,
			'(+/-)',
			'24',
			sum ( rep_value_onscreen * -1),
			sum ( rep_value_onscreen * -1 ),
			sum ( rep_value_offscreen * -1 ),
			sum ( rep_tot_value_onscreen * -1 ),
			sum ( rep_tot_value_onscreen * -1 ),
			sum ( rep_tot_value_offscreen * -1 )
		FROM #workout
		WHERE rep_series_sort in ( '20' )
		GROUP BY rep_title, rep_series, rep_series_sort 
		/* Now select for summary result set */
	
		Insert into #workout2 
		(
			rep_title,
			rep_series,
			rep_series_sort,
			rep_value_month,
			rep_value_onscreen,
			rep_value_offscreen,
			rep_tot_value_month,
			rep_tot_value_onscreen,
			rep_tot_value_offscreen,
			pct_value_month,
			pct_value_onscreen,
			pct_value_offscreen,
			pct_tot_value_month,
			pct_tot_value_onscreen,
			pct_tot_value_offscreen
		)
		SELECT
			rep_title ,
			rep_series,
			rep_series_sort,
			sum(rep_value_month),
			sum(rep_value_onscreen),
			sum(rep_value_offscreen),
			sum(rep_tot_value_month),
			sum(rep_tot_value_onscreen),
			sum(rep_tot_value_offscreen),
			0,
			0,
			0,
			0,
			0,
			0
		FROM #workout
		GROUP BY rep_title, rep_series, rep_series_sort
		ORDER BY rep_series_sort 

		
		UPDATE #workout2 SET
			scorefilemonth = @scorefile + 'About.bmp',
			scorefileonscreen = @scorefile + 'About.bmp',
			scorefileoffscreen = @scorefile + 'About.bmp',
			scorefiletotmonth = @scorefile + 'About.bmp',
			scorefiletotonscreen = @scorefile + 'About.bmp',
			scorefiletotoffscreen = @scorefile + 'About.bmp',
			pct_value_month = null,
			pct_value_onscreen = null,
			pct_value_offscreen = null,
			pct_tot_value_month = null,
			pct_tot_value_onscreen = null,
			pct_tot_value_offscreen = null
		WHERE rep_series_sort = @scorerow
	
	
		SELECT @actual = 0
		SELECT @target = 0
	
		SELECT @actual = rep_value_month FROM #workout2 WHERE rep_series_sort = @actualrow
		IF @actual != 0 
		begin
			UPDATE #workout2 SET pct_value_month = rep_value_month / @actual WHERE rep_series_sort > '30'
			UPDATE #workout2 SET pct_value_month = rep_value_month / @actual WHERE rep_series_sort in( '10','12')
		end
		SELECT @target = rep_value_month FROM #workout2 WHERE rep_series_sort = @targetrow
		IF @target IS NOT NULL and @target != 0 
		begin
			SELECT @actual = IsNull( @actual , 0) / @target
			UPDATE #workout2 SET pct_value_month = @actual WHERE rep_series_sort = @scorerow
			IF @actual >= 1.2 UPDATE #workout2 SET scorefilemonth = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
			else IF @actual >= 1.0 UPDATE #workout2 SET scorefilemonth = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
			else IF @actual >= .8 UPDATE #workout2 SET scorefilemonth = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
			else IF @actual >= .5 UPDATE #workout2 SET scorefilemonth = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
			else UPDATE #workout2 SET scorefilemonth = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
		end
	
		SELECT @actual = 0
		SELECT @target = 0

		SELECT @actual = rep_value_onscreen FROM #workout2 WHERE rep_series_sort = @actualrow
		IF @actual != 0 
		begin
			UPDATE #workout2 SET pct_value_onscreen = rep_value_onscreen / @actual WHERE rep_series_sort > '30'
			UPDATE #workout2 SET pct_value_onscreen = rep_value_onscreen / @actual WHERE rep_series_sort in( '10','12')
		end
		SELECT @target = rep_value_onscreen FROM #workout2 WHERE rep_series_sort = @targetrow
		IF @target IS NOT NULL and @target != 0 
		begin
			SELECT @actual = IsNull( @actual , 0) / @target
			UPDATE #workout2 SET pct_value_onscreen = @actual WHERE rep_series_sort = @scorerow
			IF @actual >= 1.2 UPDATE #workout2 SET scorefileonscreen = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
			else IF @actual >= 1.0 UPDATE #workout2 SET scorefileonscreen = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
			else IF @actual >= .8 UPDATE #workout2 SET scorefileonscreen = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
			else IF @actual >= .5 UPDATE #workout2 SET scorefileonscreen = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
			else UPDATE #workout2 SET scorefileonscreen = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
		end

		SELECT @actual = 0
		SELECT @target = 0

		SELECT @actual = rep_value_offscreen FROM #workout2 WHERE rep_series_sort = @actualrow
		IF @actual != 0 
		begin
			UPDATE #workout2 SET pct_value_offscreen = rep_value_offscreen / @actual WHERE rep_series_sort > '30'
			UPDATE #workout2 SET pct_value_offscreen = rep_value_offscreen / @actual WHERE rep_series_sort in( '10','12')
		end
		SELECT @target = rep_value_offscreen FROM #workout2 WHERE rep_series_sort = @targetrow
		IF @target IS NOT NULL and @target != 0 
		begin
			SELECT @actual = IsNull( @actual , 0) / @target
			UPDATE #workout2 SET pct_value_offscreen = @actual WHERE rep_series_sort = @scorerow
			IF @actual >= 1.2 UPDATE #workout2 SET scorefileoffscreen = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
			else IF @actual >= 1.0 UPDATE #workout2 SET scorefileoffscreen = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
			else IF @actual >= .8 UPDATE #workout2 SET scorefileoffscreen = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
			else IF @actual >= .5 UPDATE #workout2 SET scorefileoffscreen = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
			else UPDATE #workout2 SET scorefileoffscreen = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
		end

		SELECT @actual = 0
		SELECT @target = 0

		SELECT @actual = rep_tot_value_offscreen FROM #workout2 WHERE rep_series_sort = @actualrow
		IF @actual != 0 
		begin
			UPDATE #workout2 SET pct_tot_value_offscreen = rep_tot_value_offscreen / @actual WHERE rep_series_sort > '30'
			UPDATE #workout2 SET pct_tot_value_offscreen = rep_tot_value_offscreen / @actual WHERE rep_series_sort in( '10','12')
		end
		SELECT @target = rep_tot_value_offscreen FROM #workout2 WHERE rep_series_sort = @targetrow
		IF @target IS NOT NULL and @target != 0 
		begin
			SELECT @actual = IsNull( @actual , 0) / @target
			UPDATE #workout2 SET pct_tot_value_offscreen = @actual WHERE rep_series_sort = @scorerow
			IF @actual >= 1.2 UPDATE #workout2 SET scorefiletotoffscreen = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
			else IF @actual >= 1.0 UPDATE #workout2 SET scorefiletotoffscreen = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
			else IF @actual >= .8 UPDATE #workout2 SET scorefiletotoffscreen = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
			else IF @actual >= .5 UPDATE #workout2 SET scorefiletotoffscreen = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
			else UPDATE #workout2 SET scorefiletotoffscreen = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
		end

		SELECT @actual = 0
		SELECT @target = 0

		SELECT @actual = rep_tot_value_onscreen FROM #workout2 WHERE rep_series_sort = @actualrow
		IF @actual != 0 
		begin
			UPDATE #workout2 SET pct_tot_value_onscreen = rep_tot_value_onscreen / @actual WHERE rep_series_sort > '30'
			UPDATE #workout2 SET pct_tot_value_onscreen = rep_tot_value_onscreen / @actual WHERE rep_series_sort in( '10','12')
		end
		SELECT @target = rep_tot_value_onscreen FROM #workout2 WHERE rep_series_sort = @targetrow
		IF @target IS NOT NULL and @target != 0 
		begin
			SELECT @actual = IsNull( @actual , 0) / @target
			UPDATE #workout2 SET pct_tot_value_onscreen = @actual WHERE rep_series_sort = @scorerow
			IF @actual >= 1.2 UPDATE #workout2 SET scorefiletotonscreen = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
			else IF @actual >= 1.0 UPDATE #workout2 SET scorefiletotonscreen = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
			else IF @actual >= .8 UPDATE #workout2 SET scorefiletotonscreen = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
			else IF @actual >= .5 UPDATE #workout2 SET scorefiletotonscreen = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
			else UPDATE #workout2 SET scorefiletotonscreen = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
		end

		SELECT @actual = 0
		SELECT @target = 0

		SELECT @actual = rep_tot_value_month FROM #workout2 WHERE rep_series_sort = @actualrow
		IF @actual != 0 
		begin
			UPDATE #workout2 SET pct_tot_value_month = rep_tot_value_month / @actual WHERE rep_series_sort > '30'
			UPDATE #workout2 SET pct_tot_value_month = rep_tot_value_month / @actual WHERE rep_series_sort in( '10','12')
		end
		SELECT @target = rep_tot_value_month FROM #workout2 WHERE rep_series_sort = @targetrow
		IF @target IS NOT NULL and @target != 0 
		begin
			SELECT @actual = IsNull( @actual , 0) / @target
			UPDATE #workout2 SET pct_tot_value_month = @actual WHERE rep_series_sort = @scorerow
			IF @actual >= 1.2 UPDATE #workout2 SET scorefiletotmonth = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
			else IF @actual >= 1.0 UPDATE #workout2 SET scorefiletotmonth = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
			else IF @actual >= .8 UPDATE #workout2 SET scorefiletotmonth = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
			else IF @actual >= .5 UPDATE #workout2 SET scorefiletotmonth = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
			else UPDATE #workout2 SET scorefiletotmonth = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
		end

		SELECT		rep_title,
					rep_category,
					rep_cat_sort,
					rep_series,
					rep_series_sort,
					isnull(rep_value_month,0),
					isnull(rep_value_onscreen,0),
					isnull(rep_value_offscreen,0),
					isnull(rep_tot_value_month,0),
					isnull(rep_tot_value_onscreen,0),
					isnull(rep_tot_value_offscreen,0),
					pct_value_month,
					pct_value_onscreen,
					pct_value_offscreen,
					pct_tot_value_month,
					pct_tot_value_onscreen,
					pct_tot_value_offscreen,
					scorefilemonth,
					scorefileonscreen,
					scorefileoffscreen,
					scorefiletotmonth,
					scorefiletotonscreen,
					scorefiletotoffscreen
		  FROM 		#workout2
	end			
	else
	begin
		SELECT		rep_title,
					rep_category,
					rep_cat_sort,
					rep_series,
					rep_series_sort,
					rep_value_month,
					rep_value_onscreen,
					rep_value_offscreen,
					rep_tot_value_month,
					rep_tot_value_onscreen,
					rep_tot_value_offscreen,
					rep_value_month as pct_value_month,
					rep_value_onscreen as pct_value_onscreen,
					rep_value_offscreen as pct_value_offscreen,
					rep_tot_value_month as pct_tot_value_month,
					rep_tot_value_onscreen as pct_tot_value_onscreen,
					rep_tot_value_offscreen as pct_tot_value_offscreen,
					scorefilemonth,
					scorefileonscreen,
					scorefileoffscreen,
					scorefiletotmonth,
					scorefiletotonscreen,
					scorefiletotoffscreen
		FROM #workout
			ORDER BY rep_series_sort, rep_cat_sort, rep_value_month desc
	end
end

return 0
GO
