/****** Object:  StoredProcedure [dbo].[p_salesman_report_month]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_salesman_report_month]
GO
/****** Object:  StoredProcedure [dbo].[p_salesman_report_month]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_salesman_report_month] 
		@s_report varchar(255) , 
		@i_id int, 
		@s_code varchar(16), 
		@d_first datetime, 
		@d_last datetime, 
		@d_pfirst datetime, 
		@d_plast datetime

with recompile
as

begin
/*
 * Declare Variables
 */

declare     @error_num              	int
declare		@scorefile					varchar(64)
declare		@actual						money
declare		@target						money					
declare		@value						money					
declare		@scorerow					char(02)
declare		@actualrow					char(02)
declare		@targetrow					char(02)
declare     @buss_unit              	int
declare     @revision_group         	int
declare     @target_revision_group     	int

SELECT @buss_unit = 0
SELECT @revision_group = 0
SELECT @scorerow = '14'
SELECT @actualrow = '14'
SELECT @targetrow = '20'


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

if  @revision_group > 0
	select @target_revision_group = @revision_group
else 
	select @target_revision_group = 1

SELECT @scorefile = 'G:\Development\Resources\1616\'

/* Create temporary tables for resultsets */

CREATE TABLE #workout
(		rep_title varchar(42) NULL,
		rep_category varchar(42) NULL,
		rep_cat_sort varchar(42) NULL,
		rep_series  varchar(42) NULL,
		rep_series_sort  varchar(42) NULL,
		rep_value money NULL,
		rep_value1 money NULL,
		rep_value2 money NULL,
		rep_value3 money NULL,
		rep_value4 money NULL,
		rep_value5 money NULL,
		rep_value6 money NULL,
		rep_value7 money NULL,
		rep_value8 money NULL,
		rep_value9 money NULL,
		rep_value10 money NULL,
		rep_value11 money NULL,
		rep_value12 money NULL,
		scorefile  varchar(64)	NULL,
		scorefile1  varchar(64)	NULL,
		scorefile2  varchar(64)	NULL,
		scorefile3  varchar(64)	NULL,
		scorefile4  varchar(64)	NULL,
		scorefile5  varchar(64)	NULL,
		scorefile6  varchar(64)	NULL,
		scorefile7  varchar(64)	NULL,
		scorefile8  varchar(64)	NULL,
		scorefile9  varchar(64)	NULL,
		scorefile10  varchar(64)	NULL,
		scorefile11  varchar(64)	NULL,
		scorefile12  varchar(64)	NULL
)

CREATE TABLE #workout2
(		rep_title varchar(42) NULL,
		rep_category varchar(42) NULL,
		rep_cat_sort varchar(42) NULL,
		rep_series  varchar(42) NULL,
		rep_series_sort  varchar(42) NULL,
		rep_value money NULL,
		pct_value money NULL,
		rep_value1 money NULL,
		pct_value1 money NULL,
		rep_value2 money NULL,
		pct_value2 money NULL,
		rep_value3 money NULL,
		pct_value3 money NULL,
		rep_value4 money NULL,
		pct_value4 money NULL,
		rep_value5 money NULL,
		pct_value5 money NULL,
		rep_value6 money NULL,
		pct_value6 money NULL,
		rep_value7 money NULL,
		pct_value7 money NULL,
		rep_value8 money NULL,
		pct_value8 money NULL,
		rep_value9 money NULL,
		pct_value9 money NULL,
		rep_value10 money NULL,
		pct_value10 money NULL,
		rep_value11 money NULL,
		pct_value11 money NULL,
		rep_value12 money NULL,
		pct_value12 money NULL,
		scorefile  varchar(64)	NULL,
		scorefile1  varchar(64)	NULL,
		scorefile2  varchar(64)	NULL,
		scorefile3  varchar(64)	NULL,
		scorefile4  varchar(64)	NULL,
		scorefile5  varchar(64)	NULL,
		scorefile6  varchar(64)	NULL,
		scorefile7  varchar(64)	NULL,
		scorefile8  varchar(64)	NULL,
		scorefile9  varchar(64)	NULL,
		scorefile10  varchar(64)	NULL,
		scorefile11  varchar(64)	NULL,
		scorefile12  varchar(64)	NULL
)

CREATE TABLE #work
(		rep_title varchar(42) NULL,
		rep_category varchar(42) NULL,
		rep_cat_sort varchar(42) NULL,
		rep_series  varchar(42) NULL,
		rep_series_sort  varchar(42) NULL,
		rep_value money NULL
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
								isnull(sum ( nett_amount ),0)
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								branch
					WHERE 		( book.branch_code =  @s_code 
					OR  		  book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
					AND			book.booking_period = period_year.sales_period
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group ) 
					AND 		( @buss_unit=0 
					OR 			EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		branch.branch_code = book.branch_code 
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))

					GROUP BY 	DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) ,
								state_code,
								branch.sort_order
					--HAVING 		sum ( nett_amount ) <> 0
			end	
			IF  ( CHARINDEX ( 'revisiongroup' , @s_report ) > 0 )
			begin
					insert 		#work 
					SELECT 		'', 
								DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 to not sort 1, 10 ,11,12  but 101, 102... 110*/
								'', 
								'7' + convert ( char(1) , film_campaign.business_unit_id - 2),
								isnull(sum ( nett_amount ),0)
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								revision_group,
								film_campaign
					WHERE 		( book.branch_code =  @s_code 
					OR  		book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
					AND			book.booking_period = period_year.sales_period
					and 		film_campaign.campaign_no = book.campaign_no
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group ) 
					AND 		( @buss_unit=0 
					OR	 		EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		book.revision_group = revision_group.revision_group
					and			book.revision_group = 1
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))

					GROUP BY 	DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) ,
								film_campaign.business_unit_id
					--HAVING 		sum ( nett_amount ) <> 0

					insert 		#work 
					SELECT 		'', 
								DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 to not sort 1, 10 ,11,12  but 101, 102... 110*/
								'', 
								'8' + convert ( char(1) , book.revision_group),
								isnull(sum ( nett_amount ),0)
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								revision_group
					WHERE 		( book.branch_code =  @s_code 
					OR  		book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
					AND			book.booking_period = period_year.sales_period
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group ) 
					AND 		( @buss_unit=0 
					OR	 		EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		book.revision_group = revision_group.revision_group
					and			book.revision_group > 1 and book.revision_group < 49
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))

					GROUP BY 	DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) ,
								book.revision_group
					--HAVING 		sum ( nett_amount ) <> 0
			end	
		

	
			insert #work 
			SELECT 	'Branch', 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Bookings',--'Revenue' ,
						'10',
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period_year
			
			WHERE 	( book.branch_code =  @s_code OR  
								book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND	book.booking_period = period_year.sales_period
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 	period_year.sales_period between @d_first and @d_last 
				AND 	figure_type <> 'A'
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) 
			--HAVING sum ( nett_amount ) <> 0
	
			insert #work 
			SELECT 	'Branch', 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Adj' ,
						'12',
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period_year
			
			WHERE 	( book.branch_code =  @s_code OR  
								book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND	book.booking_period = period_year.sales_period
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 	period_year.sales_period between @d_first and @d_last 
				AND 	figure_type = 'A'
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) 
			--HAVING sum ( nett_amount ) <> 0
			
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
				insert #work 
				SELECT 	'Branch', 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no) ,
							'' ,
							'30',
							isnull(sum ( nett_amount ),0)
				FROM    	booking_figures AS book,
							film_sales_period AS period_year
				
				WHERE 	( book.branch_code =  @s_code OR  
									book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
					AND	book.booking_period = period_year.sales_period
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no) 
				--HAVING sum ( nett_amount ) <> 0
			end
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
				
				/*UPDATE #work set rep_series = 'Bookings'*/
				
				insert #work
				SELECT 	'Branch', 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 because so as not to sort 1, 10 ,11,12 but 101, 102... 110*/
							'' ,
							'20',
							sum ( target )
				FROM    	booking_target AS book,
							film_sales_period AS period_year
				
				WHERE 	( book.branch_code =  @s_code OR  
									book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
					AND	book.sales_period = period_year.sales_period
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
				GROUP BY DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) , 
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end
	
		IF ( @s_code = 'A' ) UPDATE #work set rep_title = 'Australia'
		ELSE IF ( @s_code = 'A' ) UPDATE #work set rep_title = 'New Zealand'
		ELSE  UPDATE #work set rep_title = ( Select branch_name from branch where branch_code = @s_code )
				

	end /* branch */

	IF  ( CHARINDEX ( 'sales_rep' , @s_report ) > 0 )
	begin
	
			insert #work 
			SELECT 	'Rep: ' + first_name + ' ' + last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Bookings',--'Revenue' ,
						'10',
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_rep
			WHERE 	book.rep_id =  @i_id 
				AND 	book.rep_id = sales_rep.rep_id
				AND	book.booking_period = period_year.sales_period
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 	period_year.sales_period between @d_first and @d_last 
				AND 	figure_type <> 'A'
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))

			GROUP BY first_name , last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no)
			--HAVING sum ( nett_amount ) <> 0
	
			insert #work 
			SELECT 	'Rep: ' + first_name + ' ' + last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Adj' ,
						'12',
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_rep
			WHERE 	book.rep_id =  @i_id 
				AND 	book.rep_id = sales_rep.rep_id
				AND	book.booking_period = period_year.sales_period
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 	period_year.sales_period between @d_first and @d_last 
				AND 	figure_type = 'A'
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY first_name , last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no)
			--HAVING sum ( nett_amount ) <> 0
						
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
	
				insert #work 
				SELECT 	'Rep: ' + first_name + ' ' + last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no) ,
							'' ,
							'30',
							isnull(sum ( nett_amount ),0)
				FROM    	booking_figures AS book,
							film_sales_period AS period_year,
							sales_rep
				WHERE 	book.rep_id =  @i_id 
					AND 	book.rep_id = sales_rep.rep_id
					AND	book.booking_period = period_year.sales_period
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY first_name , last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no)
				--HAVING sum ( nett_amount ) <> 0
			end		
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
	
				/*UPDATE #work set rep_series = 'Bookings'*/
	
				insert #work
				SELECT 	'Rep: ' + first_name + ' ' + last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) ,
							'' ,
							'20',
							sum ( target )
				FROM    	booking_target AS book,
							film_sales_period AS period_year,
							sales_rep
				
					WHERE book.rep_id =  @i_id 
					AND 	book.rep_id = sales_rep.rep_id
					AND	book.sales_period = period_year.sales_period
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
				GROUP BY first_name, last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) ,
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end

			IF  ( CHARINDEX ( 'revisiongroup' , @s_report ) > 0 )
			begin
					insert 		#work 
					SELECT 		'', 
								DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 to not sort 1, 10 ,11,12  but 101, 102... 110*/
								'', 
								'7' + convert ( char(1) , film_campaign.business_unit_id - 2),
								isnull(sum ( nett_amount ),0)
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								revision_group,
								film_campaign
					WHERE 		book.rep_id =  @i_id 
					AND			book.booking_period = period_year.sales_period
					and 		film_campaign.campaign_no = book.campaign_no
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group ) 
					AND 		( @buss_unit=0 
					OR	 		EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		book.revision_group = revision_group.revision_group
					and			book.revision_group = 1
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
					GROUP BY 	DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) ,
								film_campaign.business_unit_id
					--HAVING 		sum ( nett_amount ) <> 0

					insert 		#work 
					SELECT 		'', 
								DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 to not sort 1, 10 ,11,12  but 101, 102... 110*/
								'', 
								'8' + convert ( char(1) , book.revision_group),
								isnull(sum ( nett_amount ),0)
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								revision_group
					WHERE 		book.rep_id =  @i_id 
					AND			book.booking_period = period_year.sales_period
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group ) 
					AND 		( @buss_unit=0 
					OR	 		EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		book.revision_group = revision_group.revision_group
					and			book.revision_group > 1 and book.revision_group < 49
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
					GROUP BY 	DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) ,
								book.revision_group
					--HAVING 		sum ( nett_amount ) <> 0
			end	


	end /*sales_rep*/
	
	IF  ( CHARINDEX ( 'team' , @s_report ) > 0 )
	begin
	
			insert #work 
			SELECT 	'Team:  ' + team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Bookings',--'Revenue' ,
						'10',
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_team, booking_figure_team_xref
			WHERE 	book.figure_id =  booking_figure_team_xref.figure_id 
				AND 	booking_figure_team_xref.team_id = @i_id 
				AND 	booking_figure_team_xref.team_id = sales_team.team_id
				AND	book.booking_period = period_year.sales_period
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 	period_year.sales_period between @d_first and @d_last 
				AND 	figure_type <> 'A'
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no)
			--HAVING sum ( nett_amount ) <> 0
	
			insert #work 
			SELECT 	'Team:  ' + team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no) ,
						'Adj' ,
						'12',
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_team, booking_figure_team_xref
			WHERE 	book.figure_id =  booking_figure_team_xref.figure_id 
				AND 	booking_figure_team_xref.team_id = @i_id 
				AND 	booking_figure_team_xref.team_id = sales_team.team_id
				AND	book.booking_period = period_year.sales_period
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 	period_year.sales_period between @d_first and @d_last 
				AND 	figure_type = 'A'
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 200 +  period_year.period_no)
			--HAVING sum ( nett_amount ) <> 0
			
			
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
	
				insert #work 
				SELECT 	'Team:  ' + team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no) ,
							'' ,
							'30',
							isnull(sum ( nett_amount ),0)
				FROM    	booking_figures AS book,
							film_sales_period AS period_year,
							sales_team, booking_figure_team_xref
				WHERE 	book.figure_id =  booking_figure_team_xref.figure_id 
					AND 	booking_figure_team_xref.team_id = @i_id 
					AND 	booking_figure_team_xref.team_id = sales_team.team_id
					AND	book.booking_period = period_year.sales_period
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 +  period_year.period_no)
				--HAVING sum ( nett_amount ) <> 0
			end
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
	
				/*UPDATE #work set rep_series = 'Bookings'*/
	
				insert #work
				SELECT 	'Team:  ' + team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) ,
							'' ,
							'20',
							sum ( target )
				FROM    	booking_target AS book,
							film_sales_period AS period_year,
							sales_team
				
					WHERE book.team_id =  @i_id 
					AND 	book.team_id = sales_team.team_id
					AND	book.sales_period = period_year.sales_period
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
				GROUP BY team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 200 +  period_year.period_no) ,
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end

			IF  ( CHARINDEX ( 'revisiongroup' , @s_report ) > 0 )
			begin
					insert 		#work 
					SELECT 		'', 
								DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 to not sort 1, 10 ,11,12  but 101, 102... 110*/
								'', 
								'7' + convert ( char(1) , film_campaign.business_unit_id - 2),
								isnull(sum ( nett_amount ),0)
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								revision_group,
								film_campaign,
								booking_figure_team_xref
					WHERE 		book.figure_id =  booking_figure_team_xref.figure_id
					and			booking_figure_team_xref.team_id = @i_id
					AND			book.booking_period = period_year.sales_period
					and 		film_campaign.campaign_no = book.campaign_no
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group ) 
					AND 		( @buss_unit=0 
					OR	 		EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		book.revision_group = revision_group.revision_group
					and			book.revision_group = 1
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
					GROUP BY 	DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) ,
								film_campaign.business_unit_id
					--HAVING 		sum ( nett_amount ) <> 0

					insert 		#work 
					SELECT 		'', 
								DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) , /* plus 100 to not sort 1, 10 ,11,12  but 101, 102... 110*/
								'', 
								'8' + convert ( char(1) , book.revision_group),
								isnull(sum ( nett_amount ),0)
					FROM    	booking_figures AS book,
								film_sales_period AS period_year,
								revision_group,
								booking_figure_team_xref
					WHERE 		book.figure_id =  booking_figure_team_xref.figure_id
					and			booking_figure_team_xref.team_id = @i_id
					AND			book.booking_period = period_year.sales_period
					AND 		( @revision_group=0 
					OR 			book.revision_group = @revision_group ) 
					AND 		( @buss_unit=0 
					OR	 		EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 		period_year.sales_period between @d_first and @d_last 
					AND 		book.revision_group = revision_group.revision_group
					and			book.revision_group > 1 and book.revision_group < 49
					and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
					GROUP BY 	DateName ( month , period_year.sales_period) ,
								convert ( char(3) , 200 +  period_year.period_no) ,
								book.revision_group
					--HAVING 		sum ( nett_amount ) <> 0
			end	

	end /* team */
end /* month */

INSERT #workout 
		SELECT rep_title, rep_category, rep_cat_sort, rep_series, rep_series_sort, isnull(rep_value,0),isnull(rep_value,0), 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		FROM #work WHERE rep_cat_sort in (  '101' , '201')
INSERT #workout 
		SELECT rep_title, rep_category, rep_cat_sort, rep_series, rep_series_sort, isnull(rep_value,0),0, isnull(rep_value,0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		FROM #work WHERE rep_cat_sort in (  '102' , '202')
INSERT #workout 
		SELECT rep_title, rep_category, rep_cat_sort, rep_series, rep_series_sort, isnull(rep_value,0),0, 0,isnull(rep_value,0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		FROM #work WHERE rep_cat_sort in (  '103' , '203')
INSERT #workout 
		SELECT rep_title, rep_category, rep_cat_sort, rep_series, rep_series_sort, isnull(rep_value,0),0, 0,0,isnull(rep_value,0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		FROM #work WHERE rep_cat_sort in (  '104' , '204')
INSERT #workout 
		SELECT rep_title, rep_category, rep_cat_sort, rep_series, rep_series_sort, isnull(rep_value,0),0, 0,0,0,isnull(rep_value,0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		FROM #work WHERE rep_cat_sort in (  '105' , '205') 
INSERT #workout 
		SELECT rep_title, rep_category, rep_cat_sort, rep_series, rep_series_sort, isnull(rep_value,0),0, 0,0,0,0,isnull(rep_value,0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		FROM #work WHERE rep_cat_sort in (  '106' , '206') 
INSERT #workout 
		SELECT rep_title, rep_category, rep_cat_sort, rep_series, rep_series_sort, isnull(rep_value,0),0, 0,0,0,0,0,isnull(rep_value,0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		FROM #work WHERE rep_cat_sort in (  '107' , '207')
INSERT #workout 
		SELECT rep_title, rep_category, rep_cat_sort, rep_series, rep_series_sort, isnull(rep_value,0),0, 0,0,0,0,0,0,isnull(rep_value,0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		FROM #work WHERE rep_cat_sort in (  '108' , '208') 
INSERT #workout 
		SELECT rep_title, rep_category, rep_cat_sort, rep_series, rep_series_sort, isnull(rep_value,0),0, 0,0,0,0,0,0,0,isnull(rep_value,0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		FROM #work WHERE rep_cat_sort in (  '109' , '209')
INSERT #workout 
		SELECT rep_title, rep_category, rep_cat_sort, rep_series, rep_series_sort, isnull(rep_value,0),0, 0,0,0,0,0,0,0,0,isnull(rep_value,0),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		FROM #work WHERE rep_cat_sort in (  '110' , '210')
INSERT #workout 
		SELECT rep_title, rep_category, rep_cat_sort, rep_series, rep_series_sort, isnull(rep_value,0),0, 0,0,0,0,0,0,0,0,0,isnull(rep_value,0),0,0,0,0,0,0,0,0,0,0,0,0,0,0
		FROM #work WHERE rep_cat_sort in (  '111' , '211')
INSERT #workout 
		SELECT rep_title, rep_category, rep_cat_sort, rep_series, rep_series_sort, isnull(rep_value,0),0, 0,0,0,0,0,0,0,0,0,0,isnull(rep_value,0),0,0,0,0,0,0,0,0,0,0,0,0,0
		FROM #work WHERE rep_cat_sort in (  '112' , '212') 


	IF ( CHARINDEX ( 'summary', @s_report ) > 0 ) 
		begin
			INSERT #workout
				SELECT
				rep_title ,
				null,
				null,
				'Total',
				@actualrow,
				sum ( rep_value ),
				sum ( rep_value1 ),
				sum ( rep_value2 ),
				sum ( rep_value3 ),
				sum ( rep_value4 ),
				sum ( rep_value5 ),
				sum ( rep_value6 ),
				sum ( rep_value7 ),
				sum ( rep_value8 ),
				sum ( rep_value9 ),
				sum ( rep_value10 ),
				sum ( rep_value11 ),
				sum ( rep_value12 ),
				null,null,null,null,null,null,null,null,null,null,null,null,null
			FROM #workout
			WHERE rep_series_sort in ( '10','12' )
			GROUP BY rep_title, rep_series, rep_series_sort 

			/* target variance */
			INSERT #workout
				SELECT
				rep_title ,
				null,
				null,
				'(+/-)',
				'24',
				sum ( rep_value ),
				sum ( rep_value1 ),
				sum ( rep_value2 ),
				sum ( rep_value3 ),
				sum ( rep_value4 ),
				sum ( rep_value5 ),
				sum ( rep_value6 ),
				sum ( rep_value7 ),
				sum ( rep_value8 ),
				sum ( rep_value9 ),
				sum ( rep_value10 ),
				sum ( rep_value11 ),
				sum ( rep_value12 ),
				null,null,null,null,null,null,null,null,null,null,null,null,null
			FROM #workout
			WHERE rep_series_sort in ( '10','12' )
			GROUP BY rep_title, rep_series, rep_series_sort 

			INSERT #workout
				SELECT
				rep_title ,
				null,
				null,
				'(+/-)',
				'24',
				sum ( rep_value * - 1),
				sum ( rep_value1 * - 1),
				sum ( rep_value2 * - 1),
				sum ( rep_value3 * - 1),
				sum ( rep_value4 * - 1),
				sum ( rep_value5 * - 1),
				sum ( rep_value6 * - 1),
				sum ( rep_value7 * - 1),
				sum ( rep_value8 * - 1),
				sum ( rep_value9 * - 1),
				sum ( rep_value10 * - 1),
				sum ( rep_value11 * - 1),
				sum ( rep_value12  * - 1),
				null,null,null,null,null,null,null,null,null,null,null,null,null
			FROM #workout
			WHERE rep_series_sort in ( '20' )
			GROUP BY rep_title, rep_series, rep_series_sort 

			/*INSERT #workout
				SELECT
				rep_title ,
				null,
				null,
				'As at',
				'19',
				sum ( rep_value ),
				sum ( rep_value1 ),
				sum ( rep_value2 ),
				sum ( rep_value3 ),
				sum ( rep_value4 ),
				sum ( rep_value5 ),
				sum ( rep_value6 ),
				sum ( rep_value7 ),
				sum ( rep_value8 ),
				sum ( rep_value9 ),
				sum ( rep_value10 ),
				sum ( rep_value11 ),
				sum ( rep_value12  ),
				null,null,null,null,null,null,null,null,null,null,null,null,null
			FROM #workout
			WHERE rep_series_sort in ( '20' )
			GROUP BY rep_title, rep_series, rep_series_sort */

			/* Now select for summary result set */

			Insert #workout2 
			SELECT
				rep_title ,
				null,
				null,
				rep_series,
				rep_series_sort,
				sum ( rep_value ),
				0,
				sum ( rep_value1 ),
				0,
				sum ( rep_value2 ),
				0,
				sum ( rep_value3 ),
				0,
				sum ( rep_value4 ),
				0,
				sum ( rep_value5 ),
				0,
				sum ( rep_value6 ),
				0,
				sum ( rep_value7 ),
				0,
				sum ( rep_value8 ),
				0,
				sum ( rep_value9 ),
				0,
				sum ( rep_value10 ),
				0,
				sum ( rep_value11 ),
				0,
				sum ( rep_value12 ),
				0,
				scorefile,
				scorefile1,
				scorefile2,
				scorefile3,
				scorefile4,
				scorefile5,
				scorefile6,
				scorefile7,
				scorefile8,
				scorefile9,
				scorefile10,
				scorefile11,
				scorefile12
			FROM #workout
			GROUP BY rep_title, rep_series, rep_series_sort,
				 scorefile,scorefile1,scorefile2,scorefile3,scorefile4,scorefile5,scorefile6,scorefile7,scorefile8,scorefile9,scorefile10,scorefile11,scorefile12
			ORDER BY rep_series_sort 
			
			UPDATE #workout2 SET 
					scorefile = @scorefile + 'About.bmp' ,
					scorefile1 = @scorefile + 'About.bmp' ,
					scorefile2 = @scorefile + 'About.bmp' ,
					scorefile3 = @scorefile + 'About.bmp' ,
					scorefile4 = @scorefile + 'About.bmp' ,
					scorefile5 = @scorefile + 'About.bmp' ,
					scorefile6 = @scorefile + 'About.bmp' ,
					scorefile7 = @scorefile + 'About.bmp' ,
					scorefile8 = @scorefile + 'About.bmp' ,
					scorefile9 = @scorefile + 'About.bmp' ,
					scorefile10 = @scorefile + 'About.bmp' ,
					scorefile11 = @scorefile + 'About.bmp' ,
					scorefile12 = @scorefile + 'About.bmp' ,
					pct_value = NULL,
					pct_value1 = NULL,
					pct_value2 = NULL,
					pct_value3 = NULL,
					pct_value4 = NULL,
					pct_value5 = NULL,
					pct_value6 = NULL,
					pct_value7 = NULL,
					pct_value8 = NULL,
					pct_value9 = NULL,
					pct_value10 = NULL,
					pct_value11 = NULL,
					pct_value12 = NULL
			WHERE rep_series_sort = @scorerow


			SELECT @actual = 0
			SELECT @target = 0

			SELECT @actual = rep_value FROM #workout2 WHERE rep_series_sort = @actualrow
			IF @actual != 0 UPDATE #workout2 SET pct_value = rep_value / @actual WHERE rep_series_sort > '30'
			SELECT @target = rep_value FROM #workout2 WHERE rep_series_sort = @targetrow
			IF @target IS NOT NULL and @target != 0 
				begin
					SELECT @actual = IsNull( @actual , 0) / @target
					UPDATE #workout2 SET pct_value = @actual WHERE rep_series_sort = @scorerow
					IF @actual >= 1.2 UPDATE #workout2 SET scorefile = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
					else IF @actual >= 1.0 UPDATE #workout2 SET scorefile = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .8 UPDATE #workout2 SET scorefile = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .5 UPDATE #workout2 SET scorefile = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
					else UPDATE #workout2 SET scorefile = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
				end
			ELSE 
		
			SELECT @actual = 0
			SELECT @target = 0

			SELECT @actual = rep_value1 FROM #workout2 WHERE rep_series_sort = @actualrow
			IF @actual != 0 UPDATE #workout2 SET pct_value1 = rep_value1 / @actual WHERE rep_series_sort > '30'
			SELECT @target = rep_value1 FROM #workout2 WHERE rep_series_sort = @targetrow
			IF @actual != 0 
				begin
					UPDATE #workout2 SET pct_value1 = rep_value1 / @actual WHERE rep_series_sort in( '10','12')
				end 
			IF @target IS NOT NULL and @target != 0 
				begin
					SELECT @actual = IsNull( @actual , 0) / @target
					UPDATE #workout2 SET pct_value1 = @actual WHERE rep_series_sort in( @scorerow)
					IF @actual >= 1.2 UPDATE #workout2 SET scorefile1 = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
					else IF @actual >= 1.0 UPDATE #workout2 SET scorefile1 = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .8 UPDATE #workout2 SET scorefile1 = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .5 UPDATE #workout2 SET scorefile1 = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
					else UPDATE #workout2 SET scorefile1 = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
				end

			SELECT @actual = 0
			SELECT @target = 0

			SELECT @actual = rep_value2 FROM #workout2 WHERE rep_series_sort = @actualrow
			IF @actual != 0 UPDATE #workout2 SET pct_value2 = rep_value2 / @actual WHERE rep_series_sort > '30'
			SELECT @target = rep_value2 FROM #workout2 WHERE rep_series_sort = @targetrow
			IF @actual != 0 
				begin
					UPDATE #workout2 SET pct_value2 = rep_value2 / @actual WHERE rep_series_sort in( '10','12')
				end 
			IF @target IS NOT NULL and @target != 0 
				begin
					SELECT @actual = IsNull( @actual , 0) / @target
					UPDATE #workout2 SET pct_value2 = @actual WHERE rep_series_sort in( @scorerow)
					IF @actual >= 1.2 UPDATE #workout2 SET scorefile2 = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
					else IF @actual >= 1.0 UPDATE #workout2 SET scorefile2 = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .8 UPDATE #workout2 SET scorefile2 = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .5 UPDATE #workout2 SET scorefile2 = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
					else UPDATE #workout2 SET scorefile2 = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
				end

			SELECT @actual = 0
			SELECT @target = 0
	
			SELECT @actual = rep_value3 FROM #workout2 WHERE rep_series_sort = @actualrow
			IF @actual != 0 UPDATE #workout2 SET pct_value3 = rep_value3 / @actual WHERE rep_series_sort > '30'
			IF @actual != 0 
				begin
					UPDATE #workout2 SET pct_value3 = rep_value3 / @actual WHERE rep_series_sort in( '10','12')
				end 
			SELECT @target = rep_value3 FROM #workout2 WHERE rep_series_sort = @targetrow
			IF @target IS NOT NULL and @target != 0 
				begin
					SELECT @actual = IsNull( @actual , 0) / @target
					UPDATE #workout2 SET pct_value3 = @actual WHERE rep_series_sort in( @scorerow)
					IF @actual >= 1.2 UPDATE #workout2 SET scorefile3 = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
					else IF @actual >= 1.0 UPDATE #workout2 SET scorefile3 = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .8 UPDATE #workout2 SET scorefile3 = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .5 UPDATE #workout2 SET scorefile3 = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
					else UPDATE #workout2 SET scorefile3 = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
				end

			SELECT @actual = 0
			SELECT @target = 0
		
			SELECT @actual = rep_value4 FROM #workout2 WHERE rep_series_sort = @actualrow
			IF @actual != 0 UPDATE #workout2 SET pct_value4 = rep_value4 / @actual WHERE rep_series_sort > '30'
			IF @actual != 0 
				begin
					UPDATE #workout2 SET pct_value4 = rep_value4 / @actual WHERE rep_series_sort in( '10','12')
				end 
			SELECT @target = rep_value4 FROM #workout2 WHERE rep_series_sort = @targetrow
			IF @target IS NOT NULL and @target != 0 
				begin
					SELECT @actual = IsNull( @actual , 0) / @target
					UPDATE #workout2 SET pct_value4 = @actual WHERE rep_series_sort in( @scorerow)
					IF @actual >= 1.2 UPDATE #workout2 SET scorefile4 = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
					else IF @actual >= 1.0 UPDATE #workout2 SET scorefile4 = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .8 UPDATE #workout2 SET scorefile4 = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .5 UPDATE #workout2 SET scorefile4 = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
					else UPDATE #workout2 SET scorefile4 = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
				end

			SELECT @actual = 0
			SELECT @target = 0
		
			SELECT @actual = rep_value5 FROM #workout2 WHERE rep_series_sort = @actualrow
			IF @actual != 0 UPDATE #workout2 SET pct_value5 = rep_value5 / @actual WHERE rep_series_sort > '30'
			IF @actual != 0 
				begin
					UPDATE #workout2 SET pct_value5 = rep_value5 / @actual WHERE rep_series_sort in( '10','12')
				end 
			SELECT @target = rep_value5 FROM #workout2 WHERE rep_series_sort = @targetrow
			IF @target IS NOT NULL and @target != 0 
				begin
					SELECT @actual = IsNull( @actual , 0) / @target
					UPDATE #workout2 SET pct_value5 = @actual WHERE rep_series_sort in( @scorerow)
					IF @actual >= 1.2 UPDATE #workout2 SET scorefile5 = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
					else IF @actual >= 1.0 UPDATE #workout2 SET scorefile5 = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .8 UPDATE #workout2 SET scorefile5 = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .5 UPDATE #workout2 SET scorefile5 = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
					else UPDATE #workout2 SET scorefile5 = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
				end

			SELECT @actual = 0
			SELECT @target = 0
		
			SELECT @actual = rep_value6 FROM #workout2 WHERE rep_series_sort = @actualrow
			IF @actual != 0 UPDATE #workout2 SET pct_value6 = rep_value6 / @actual WHERE rep_series_sort > '30'
			IF @actual != 0 
				begin
					UPDATE #workout2 SET pct_value6 = rep_value6 / @actual WHERE rep_series_sort in( '10','12')
				end 
			SELECT @target = rep_value6 FROM #workout2 WHERE rep_series_sort = @targetrow
			IF @target IS NOT NULL and @target != 0 
				begin
					SELECT @actual = IsNull( @actual , 0) / @target
					UPDATE #workout2 SET pct_value6 = @actual WHERE rep_series_sort in( @scorerow)
					IF @actual >= 1.2 UPDATE #workout2 SET scorefile6 = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
					else IF @actual >= 1.0 UPDATE #workout2 SET scorefile6 = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .8 UPDATE #workout2 SET scorefile6 = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .5 UPDATE #workout2 SET scorefile6 = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
					else UPDATE #workout2 SET scorefile6 = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
				end

			SELECT @actual = 0
			SELECT @target = 0
		
			SELECT @actual = rep_value7 FROM #workout2 WHERE rep_series_sort = @actualrow
			IF @actual != 0 UPDATE #workout2 SET pct_value7 = rep_value7 / @actual WHERE rep_series_sort > '30'
			IF @actual != 0 
				begin
					UPDATE #workout2 SET pct_value7 = rep_value7 / @actual WHERE rep_series_sort in( '10','12')
				end 
			SELECT @target = rep_value7 FROM #workout2 WHERE rep_series_sort = @targetrow
			IF @target IS NOT NULL and @target != 0 
				begin
					SELECT @actual = IsNull( @actual , 0) / @target
					UPDATE #workout2 SET pct_value7 = @actual WHERE rep_series_sort in( @scorerow)
					IF @actual >= 1.2 UPDATE #workout2 SET scorefile7 = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
					else IF @actual >= 1.0 UPDATE #workout2 SET scorefile7 = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .8 UPDATE #workout2 SET scorefile7 = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .5 UPDATE #workout2 SET scorefile7 = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
					else UPDATE #workout2 SET scorefile7 = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
				end

			SELECT @actual = 0
			SELECT @target = 0
		
			SELECT @actual = rep_value8 FROM #workout2 WHERE rep_series_sort = @actualrow
			IF @actual != 0 UPDATE #workout2 SET pct_value8 = rep_value8 / @actual WHERE rep_series_sort > '30'
			IF @actual != 0 
				begin
					UPDATE #workout2 SET pct_value8 = rep_value8 / @actual WHERE rep_series_sort in( '10','12')
				end 
			SELECT @target = rep_value8 FROM #workout2 WHERE rep_series_sort = @targetrow
			IF @target IS NOT NULL and @target != 0 
				begin
					SELECT @actual = IsNull( @actual , 0) / @target
					UPDATE #workout2 SET pct_value8 = @actual WHERE rep_series_sort in( @scorerow)
					IF @actual >= 1.2 UPDATE #workout2 SET scorefile8 = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
					else IF @actual >= 1.0 UPDATE #workout2 SET scorefile8 = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .8 UPDATE #workout2 SET scorefile8 = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .5 UPDATE #workout2 SET scorefile8 = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
					else UPDATE #workout2 SET scorefile8 = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
				end

			SELECT @actual = 0
			SELECT @target = 0
		
			SELECT @actual = rep_value9 FROM #workout2 WHERE rep_series_sort = @actualrow
			IF @actual != 0 UPDATE #workout2 SET pct_value9 = rep_value9 / @actual WHERE rep_series_sort > '30'
			IF @actual != 0 
				begin
					UPDATE #workout2 SET pct_value9 = rep_value9 / @actual WHERE rep_series_sort in( '10','12')
				end 
			SELECT @target = rep_value9 FROM #workout2 WHERE rep_series_sort = @targetrow
			IF @target IS NOT NULL and @target != 0 
				begin
					SELECT @actual = IsNull( @actual , 0) / @target
					UPDATE #workout2 SET pct_value9 = @actual WHERE rep_series_sort in( @scorerow)
					IF @actual >= 1.2 UPDATE #workout2 SET scorefile9 = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
					else IF @actual >= 1.0 UPDATE #workout2 SET scorefile9 = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .8 UPDATE #workout2 SET scorefile9 = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .5 UPDATE #workout2 SET scorefile9 = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
					else UPDATE #workout2 SET scorefile9 = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
				end

			SELECT @actual = 0
			SELECT @target = 0
		
			SELECT @actual = rep_value10 FROM #workout2 WHERE rep_series_sort = @actualrow
			IF @actual != 0 UPDATE #workout2 SET pct_value10 = rep_value10 / @actual WHERE rep_series_sort > '30'
			IF @actual != 0 
				begin
					UPDATE #workout2 SET pct_value10 = rep_value10 / @actual WHERE rep_series_sort in( '10','12')
				end 
			SELECT @target = rep_value10 FROM #workout2 WHERE rep_series_sort = @targetrow
			IF @target IS NOT NULL and @target != 0 
				begin
					SELECT @actual = IsNull( @actual , 0) / @target
					UPDATE #workout2 SET pct_value10 = @actual WHERE rep_series_sort in( @scorerow)
					IF @actual >= 1.2 UPDATE #workout2 SET scorefile10 = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
					else IF @actual >= 1.0 UPDATE #workout2 SET scorefile10 = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .8 UPDATE #workout2 SET scorefile10 = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .5 UPDATE #workout2 SET scorefile10 = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
					else UPDATE #workout2 SET scorefile10 = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
				end

			SELECT @actual = 0
			SELECT @target = 0
		
			SELECT @actual = rep_value11 FROM #workout2 WHERE rep_series_sort = @actualrow
			IF @actual != 0 UPDATE #workout2 SET pct_value11 = rep_value11 / @actual WHERE rep_series_sort > '30'
			IF @actual != 0 
				begin
					UPDATE #workout2 SET pct_value11 = rep_value11 / @actual WHERE rep_series_sort in( '10','12')
				end 
			SELECT @target = rep_value11 FROM #workout2 WHERE rep_series_sort = @targetrow
			IF @target IS NOT NULL and @target != 0 
				begin
					SELECT @actual = IsNull( @actual , 0) / @target
					UPDATE #workout2 SET pct_value11 = @actual WHERE rep_series_sort in( @scorerow)
					IF @actual >= 1.2 UPDATE #workout2 SET scorefile11 = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
					else IF @actual >= 1.0 UPDATE #workout2 SET scorefile11 = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .8 UPDATE #workout2 SET scorefile11 = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .5 UPDATE #workout2 SET scorefile11 = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
					else UPDATE #workout2 SET scorefile11 = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
				end

			SELECT @actual = 0
			SELECT @target = 0
		
			SELECT @actual = rep_value12 FROM #workout2 WHERE rep_series_sort = @actualrow
			IF @actual != 0 UPDATE #workout2 SET pct_value12 = rep_value12 / @actual WHERE rep_series_sort > '30'
			IF @actual != 0 
				begin
					UPDATE #workout2 SET pct_value12 = rep_value12 / @actual WHERE rep_series_sort in( '10','12')
				end 
			SELECT @target = rep_value12 FROM #workout2 WHERE rep_series_sort = @targetrow
			IF @target IS NOT NULL and @target != 0 
				begin
					SELECT @actual = IsNull( @actual , 0) / @target
					UPDATE #workout2 SET pct_value12 = @actual WHERE rep_series_sort in( @scorerow)
					IF @actual >= 1.2 UPDATE #workout2 SET scorefile12 = @scorefile + 'flame.jpg' WHERE rep_series_sort = @scorerow
					else IF @actual >= 1.0 UPDATE #workout2 SET scorefile12 = @scorefile + 'OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .8 UPDATE #workout2 SET scorefile12 = @scorefile + 'Red OK.bmp' WHERE rep_series_sort = @scorerow
					else IF @actual >= .5 UPDATE #workout2 SET scorefile12 = @scorefile + 'No entry.bmp' WHERE rep_series_sort = @scorerow
					else UPDATE #workout2 SET scorefile12 = @scorefile + 'Cancel.bmp' WHERE rep_series_sort = @scorerow
				end
		
			SELECT rep_title,
		rep_category,
		rep_cat_sort,
		rep_series,
		rtrim(rep_series_sort),
		rep_value,
		pct_value,
		rep_value1,
		pct_value1,
		rep_value2,
		pct_value2,
		rep_value3,
		pct_value3,
		rep_value4,
		pct_value4,
		rep_value5,
		pct_value5,
		rep_value6,
		pct_value6,
		rep_value7,
		pct_value7,
		rep_value8,
		pct_value8,
		rep_value9,
		pct_value9,
		rep_value10,
		pct_value10,
		rep_value11,
		pct_value11,
		rep_value12,
		pct_value12,
		scorefile,
		scorefile1,
		scorefile2,
		scorefile3,
		scorefile4,
		scorefile5,
		scorefile6,
		scorefile7,
		scorefile8,
		scorefile9,
		scorefile10,
		scorefile11,
		scorefile12 FROM #workout2

		end			

	else
		begin
	
			SELECT
				rep_title ,
				rep_category,
				rep_cat_sort,
				rep_series,
				rtrim(rep_series_sort),
				rep_value ,
				rep_value as pct_value,
				rep_value1 ,
				rep_value1 as pct_value1,
				rep_value2 ,
				rep_value2 as pct_value2,
				rep_value3 ,
				rep_value3 as pct_value3,
				rep_value4 ,
				rep_value4 as pct_value4,
				rep_value5 ,
				rep_value5 as pct_value5,
				rep_value6 ,
				rep_value6 as pct_value6,
				rep_value7 ,
				rep_value7 as pct_value7,
				rep_value8 ,
				rep_value8 as pct_value8,
				rep_value9 ,
				rep_value9 as pct_value9,
				rep_value10 ,
				rep_value10 as pct_value10,
				rep_value11 ,
				rep_value11 as pct_value11,
				rep_value12 ,
				rep_value12 as pct_value12,
				scorefile,
				scorefile1,
				scorefile2,
				scorefile3,
				scorefile4,
				scorefile5,
				scorefile6,
				scorefile7,
				scorefile8,
				scorefile9,
				scorefile10,
				scorefile11,
				scorefile12
			FROM #workout
				ORDER BY rep_series_sort, rep_cat_sort, rep_value desc
		end
end


return 0
GO
