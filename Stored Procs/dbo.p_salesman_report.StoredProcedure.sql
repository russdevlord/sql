/****** Object:  StoredProcedure [dbo].[p_salesman_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_salesman_report]
GO
/****** Object:  StoredProcedure [dbo].[p_salesman_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_salesman_report] 
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

declare     @error_num              int
declare     @buss_unit              int
declare     @revision_group         int
declare		@target_revision_group	int

SELECT @buss_unit = 0
SELECT @revision_group = 0

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

/* Create temporary table for resultset */

CREATE TABLE #work
(		rep_title varchar(42) NULL,
		rep_category varchar(42) NULL,
		rep_cat_sort varchar(42) NULL,
		rep_series  varchar(42) NULL,
		rep_value money NULL,
		rep_value1 money NULL,
		rep_value2 money NULL
)

IF ( CHARINDEX ( 'YTD', @s_report ) > 0 ) 
begin

	IF  ( CHARINDEX ( 'branch' , @s_report ) > 0 )
	begin
	
		IF ( DateName ( year , @d_first ) != DateName ( year , @d_last ) ) 
		begin 
			insert 		#work 
			SELECT 		'Branch', 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 100 + period_year.period_no) , /* plus 100 because so as not to sort 1, 10 ,11,12 but 101, 102... 110*/
						DateName ( yy , @d_first) + '-' + DateName ( yy , @d_last) ,
						isnull(sum ( nett_amount ),0),
						null,
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period,
						film_sales_period AS period_year
			WHERE 		( book.branch_code =  @s_code 
			OR			book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
			AND 		( @revision_group=0 OR book.revision_group = @revision_group ) 
			AND 		( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
			AND			book.booking_period = period.sales_period
			AND 		period.sales_period between @d_first and @d_last 
			AND 		period.sales_period <= period_year.sales_period
			AND 		period_year.sales_period between @d_first and @d_last 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY 	DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 100 + period_year.period_no) 
			--HAVING isnull(sum ( nett_amount ),0) <> 0
			
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
				insert #work 
				SELECT 	'Branch', 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) ,
							DateName ( yy , @d_pfirst) + '-' + DateName ( yy , @d_plast) ,
							isnull(sum ( nett_amount ),0),
							isnull(sum ( nett_amount ),0),
							null
				FROM    	booking_figures AS book,
							film_sales_period AS period,
							film_sales_period AS period_year
				
				WHERE 	( book.branch_code =  @s_code OR  
									book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND	book.booking_period = period.sales_period
					AND 	period.sales_period between @d_pfirst and @d_plast AND period.sales_period <= period_year.sales_period
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) 
				--HAVING isnull(sum ( nett_amount ),0) <> 0
			end
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
				
				UPDATE #work set rep_series = 'Bookings'
				
				insert #work
				SELECT 	'Branch', 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) , /* plus 100 because so as not to sort 1, 10 ,11,12 but 101, 102... 110*/
							'Target' ,
							sum ( target ),
							sum ( target ),
							null
				FROM    	booking_target AS book,
							film_sales_period AS period,
							film_sales_period AS period_year
				
				WHERE 	( book.branch_code =  @s_code OR  
									book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 
					AND	book.sales_period = period.sales_period
					AND 	period.sales_period between @d_first and @d_last AND period.sales_period <= period_year.sales_period
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
				GROUP BY DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) , 
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end
		end
		else
		begin 
			insert #work 
			SELECT 	'Branch', 
						DateName ( month , period_year.sales_period) ,
						convert  ( char(2), period_year.sales_period, 1) ,
						DateName ( year , period_year.sales_period) ,
						isnull(sum ( nett_amount ),0),
						null,
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period,
						film_sales_period AS period_year
			
			WHERE 	( book.branch_code =  @s_code OR  
								book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND	book.booking_period = period.sales_period
				AND 	period.sales_period between @d_first and @d_last AND period.sales_period <= period_year.sales_period
				AND 	period_year.sales_period between @d_first and @d_last 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY DateName ( month , period_year.sales_period) ,
						convert  ( char(2), period_year.sales_period, 1) ,
						DateName ( year , period_year.sales_period) 
			--HAVING isnull(sum ( nett_amount ),0) <> 0

				
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
				
				insert #work 
				SELECT 	'Branch', 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) ,
							isnull(sum ( nett_amount ),0),
							isnull(sum ( nett_amount ),0),
							null
				FROM    	booking_figures AS book,
							film_sales_period AS period,
							film_sales_period AS period_year
				
				WHERE 	( book.branch_code =  @s_code OR  
									book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND	book.booking_period = period.sales_period
					AND 	period.sales_period between @d_pfirst and @d_plast AND period.sales_period <= period_year.sales_period
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) 
				--HAVING isnull(sum ( nett_amount ),0) <> 0

			end
		
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
				
				UPDATE #work set rep_series = 'Bookings'
				
				insert #work
				SELECT 	'Branch', 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							'Target' ,
							sum ( target ),
							sum ( target ),
							null
				FROM    	booking_target AS book,
							film_sales_period AS period,
							film_sales_period AS period_year
				
				WHERE 	( book.branch_code =  @s_code OR  
									book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 

					AND	book.sales_period = period.sales_period
					AND 	period.sales_period between @d_first and @d_last AND period.sales_period <= period_year.sales_period
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
				GROUP BY DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end
		end
		IF ( @s_code = 'A' ) UPDATE #work set rep_title = 'Australia'
		ELSE IF ( @s_code = 'A' ) UPDATE #work set rep_title = 'New Zealand'
		ELSE  UPDATE #work set rep_title = ( Select branch_name from branch where branch_code = @s_code )
				

	end /* branch */

	IF  ( CHARINDEX ( 'sales_rep' , @s_report ) > 0 )
	begin
	
		IF ( DateName ( year , @d_first ) != DateName ( year , @d_last ) ) 
		begin 
			insert #work 
			SELECT 	'Rep: ' + first_name + ' ' + last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 100 + period_year.period_no) ,
						DateName ( yy , @d_first) + '-' + DateName ( yy , @d_last) ,
						isnull(sum ( nett_amount ),0),
						null,
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period,
						film_sales_period AS period_year,
						sales_rep
			WHERE 	book.rep_id =  @i_id 
				AND 	book.rep_id = sales_rep.rep_id
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND	book.booking_period = period.sales_period
				AND 	period.sales_period between @d_first and @d_last AND period.sales_period <= period_year.sales_period
				AND 	period_year.sales_period between @d_first and @d_last 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY first_name , last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 100 + period_year.period_no)
			--HAVING isnull(sum ( nett_amount ),0) <> 0
						
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
	
				insert #work 
				SELECT 	'Rep: ' + first_name + ' ' + last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) ,
							DateName ( yy , @d_pfirst) + '-' + DateName ( yy , @d_plast) ,
							isnull(sum ( nett_amount ),0),
							isnull(sum ( nett_amount ),0),
							null
				FROM    	booking_figures AS book,
							film_sales_period AS period,
							film_sales_period AS period_year,
							sales_rep
				WHERE 	book.rep_id =  @i_id 
					AND 	book.rep_id = sales_rep.rep_id
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND	book.booking_period = period.sales_period
					AND 	period.sales_period between @d_pfirst and @d_plast AND period.sales_period <= period_year.sales_period
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY first_name , last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no)
				--HAVING isnull(sum ( nett_amount ),0) <> 0
			end		
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
	
				UPDATE #work set rep_series = 'Bookings'
	
				insert #work
				SELECT 	'Rep: ' + first_name + ' ' + last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) ,
							'Target' ,
							sum ( target ),
							sum ( target ),
							null
				FROM    	booking_target AS book,
							film_sales_period AS period,
							film_sales_period AS period_year,
							sales_rep
				
					WHERE book.rep_id =  @i_id 
					AND 	book.rep_id = sales_rep.rep_id
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 
					AND	book.sales_period = period.sales_period
					AND 	period.sales_period between @d_first and @d_last AND period.sales_period <= period_year.sales_period
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
				GROUP BY first_name, last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) ,
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end
		end
		else
		begin
			insert #work 
			SELECT 	'Rep: ' + first_name + ' ' + last_name, 
						DateName ( month , period_year.sales_period) ,
						convert  ( char(2), period_year.sales_period, 1) ,
						DateName ( year , period_year.sales_period) ,
						isnull(sum ( nett_amount ),0),
						null,
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period,
						film_sales_period AS period_year,
						sales_rep
			WHERE 	book.rep_id =  @i_id 
				AND 	book.rep_id = sales_rep.rep_id
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND	book.booking_period = period.sales_period
				AND 	period.sales_period between @d_first and @d_last AND period.sales_period <= period_year.sales_period
				AND 	period_year.sales_period between @d_first and @d_last 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY first_name ,last_name, 
						DateName ( month , period_year.sales_period) ,
						convert  ( char(2), period_year.sales_period, 1) ,
						DateName ( year , period_year.sales_period) 
			--HAVING isnull(sum ( nett_amount ),0) <> 0
			
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
				
				insert #work 
				SELECT 	'Rep: ' + first_name + ' ' + last_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) ,
							isnull(sum ( nett_amount ),0),
							isnull(sum ( nett_amount ),0),
							null
				FROM    	booking_figures AS book,
							film_sales_period AS period,
							film_sales_period AS period_year,
							sales_rep
				WHERE 	book.rep_id =  @i_id 
					AND 	book.rep_id = sales_rep.rep_id
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND	book.booking_period = period.sales_period
					AND 	period.sales_period between @d_pfirst and @d_plast AND period.sales_period <= period_year.sales_period
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY first_name, last_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) 
				--HAVING isnull(sum ( nett_amount ),0) <> 0
			end	
		
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
	
				UPDATE #work set rep_series = 'Bookings'
	
				insert #work
				SELECT 	'Rep: ' + first_name + ' ' + last_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							'Target' ,
							sum ( target ),
							sum ( target ),
							null
				FROM    	booking_target AS book,
							film_sales_period AS period,
							film_sales_period AS period_year,
							sales_rep
				
					WHERE book.rep_id =  @i_id 
					AND 	book.rep_id = sales_rep.rep_id
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 
					AND	book.sales_period = period.sales_period
					AND 	period.sales_period between @d_first and @d_last AND period.sales_period <= period_year.sales_period
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
				GROUP BY first_name, last_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end
		end
	end /*sales_rep*/
	
	IF  ( CHARINDEX ( 'team' , @s_report ) > 0 )
	begin
	
		IF ( DateName ( year , @d_first ) != DateName ( year , @d_last ) ) 
		begin 
			insert #work 
			SELECT 	'Team: ' + team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 100 + period_year.period_no) ,
						DateName ( yy , @d_first) + '-' + DateName ( yy , @d_last) ,
						isnull(sum ( nett_amount ),0),
						null,
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period,
						film_sales_period AS period_year,
						sales_team, booking_figure_team_xref
			WHERE 	book.figure_id =  booking_figure_team_xref.figure_id 
				AND 	booking_figure_team_xref.team_id = @i_id 
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 	booking_figure_team_xref.team_id = sales_team.team_id
				AND	book.booking_period = period.sales_period
				AND 	period.sales_period between @d_first and @d_last AND period.sales_period <= period_year.sales_period
				AND 	period_year.sales_period between @d_first and @d_last 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))

			GROUP BY team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 100 + period_year.period_no)
			--HAVING isnull(sum ( nett_amount ),0) <> 0
			
			
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
	
				insert #work 
				SELECT 	'Team: ' + team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) ,
							DateName ( yy , @d_pfirst) + '-' + DateName ( yy , @d_plast) ,
							isnull(sum ( nett_amount ),0),
							isnull(sum ( nett_amount ),0),
							null
				FROM    	booking_figures AS book,
							film_sales_period AS period,
							film_sales_period AS period_year,
							sales_team, booking_figure_team_xref
				WHERE 	book.figure_id =  booking_figure_team_xref.figure_id 
					AND 	booking_figure_team_xref.team_id = @i_id 
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 	booking_figure_team_xref.team_id = sales_team.team_id
					AND	book.booking_period = period.sales_period
					AND 	period.sales_period between @d_pfirst and @d_plast AND period.sales_period <= period_year.sales_period
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no)
				--HAVING isnull(sum ( nett_amount ),0) <> 0
			end
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
	
				UPDATE #work set rep_series = 'Bookings'
	
				insert #work
				SELECT 	'Team: ' + team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) ,
							'Target' ,
							sum ( target ),
							sum ( target ),
							null
				FROM    	booking_target AS book,
							film_sales_period AS period,
							film_sales_period AS period_year,
							sales_team
				
					WHERE book.team_id =  @i_id 
					AND 	book.team_id = sales_team.team_id
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 
					AND	book.sales_period = period.sales_period
					AND 	period.sales_period between @d_first and @d_last AND period.sales_period <= period_year.sales_period
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
				GROUP BY team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) ,
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end
		end

		ELSE

		begin
			insert #work 
			SELECT 	'Team: ' + team_name, 
						DateName ( month , period_year.sales_period) ,
						convert  ( char(2), period_year.sales_period, 1) ,
						DateName ( year , period_year.sales_period) ,
						isnull(sum ( nett_amount ),0),
						null,
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period,
						film_sales_period AS period_year,
						sales_team, booking_figure_team_xref
			WHERE 	book.figure_id =  booking_figure_team_xref.figure_id 
				AND 	booking_figure_team_xref.team_id = @i_id 
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 	booking_figure_team_xref.team_id = sales_team.team_id
				AND	book.booking_period = period.sales_period
				AND 	period.sales_period between @d_first and @d_last AND period.sales_period <= period_year.sales_period
				AND 	period_year.sales_period between @d_first and @d_last 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY team_name, 
						DateName ( month , period_year.sales_period) ,
						convert  ( char(2), period_year.sales_period, 1) ,
						DateName ( year , period_year.sales_period) 
			--HAVING isnull(sum ( nett_amount ),0) <> 0
			
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
				
				insert #work 
				SELECT 	'Team: ' + team_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) ,
							isnull(sum ( nett_amount ),0),
							isnull(sum ( nett_amount ),0),
							null
				FROM    	booking_figures AS book,
							film_sales_period AS period,
							film_sales_period AS period_year,
							sales_team, booking_figure_team_xref
				WHERE 	book.figure_id =  booking_figure_team_xref.figure_id 
					AND 	booking_figure_team_xref.team_id = @i_id 
					AND 	booking_figure_team_xref.team_id = sales_team.team_id
					AND	book.booking_period = period.sales_period
					AND 	period.sales_period between @d_pfirst and @d_plast AND period.sales_period <= period_year.sales_period
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY team_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) 
				--HAVING isnull(sum ( nett_amount ),0) <> 0
			end	

			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
	
				UPDATE #work set rep_series = 'Bookings'
	
				insert #work
				SELECT 	'Team: ' + team_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							'Target' ,
							sum ( target ),
							sum ( target ),
							null
				FROM    	booking_target AS book,
							film_sales_period AS period,
							film_sales_period AS period_year,
							sales_team
				
					WHERE book.team_id =  @i_id 
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 
					AND 	book.team_id = sales_team.team_id
					AND	book.sales_period = period.sales_period
					AND 	period.sales_period between @d_first and @d_last AND period.sales_period <= period_year.sales_period
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
				GROUP BY team_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end
		end
	end /* team */
end /* YTD*/

IF ( CHARINDEX ( 'MONTH', @s_report ) > 0 ) 
begin

	IF  ( CHARINDEX ( 'branch' , @s_report ) > 0 )
	begin
	
		IF ( DateName ( year , @d_first ) != DateName ( year , @d_last ) ) 
		begin 
			insert #work 
			SELECT 	'Branch', 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 100 + period_year.period_no) , /* plus 100 because so as not to sort 1, 10 ,11,12 but 101, 102... 110*/
						DateName ( yy , @d_first) + '-' + DateName ( yy , @d_last) ,
						isnull(sum ( nett_amount ),0),
						null,
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period_year
			
			WHERE 	( book.branch_code =  @s_code OR  
								book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND	book.booking_period = period_year.sales_period
				AND 	period_year.sales_period between @d_first and @d_last 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 100 + period_year.period_no) 
			--HAVING isnull(sum ( nett_amount ),0) <> 0
			
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
				insert #work 
				SELECT 	'Branch', 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) ,
							DateName ( yy , @d_pfirst) + '-' + DateName ( yy , @d_plast) ,
							isnull(sum ( nett_amount ),0),
							isnull(sum ( nett_amount ),0),
							null
				FROM    	booking_figures AS book,
							film_sales_period AS period_year
				
				WHERE 	( book.branch_code =  @s_code OR  
									book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND	book.booking_period = period_year.sales_period
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) 
				--HAVING isnull(sum ( nett_amount ),0) <> 0
			end
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
				
				UPDATE #work set rep_series = 'Bookings'
				
				insert #work
				SELECT 	'Branch', 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) , /* plus 100 because so as not to sort 1, 10 ,11,12 but 101, 102... 110*/
							'Target' ,
							sum ( target ),
							sum ( target ),
							null
				FROM    	booking_target AS book,
							film_sales_period AS period_year
				
				WHERE 	( book.branch_code =  @s_code OR  
									book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 
					AND	book.sales_period = period_year.sales_period
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
				GROUP BY DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) , 
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end
		end
		else
		begin 
			insert #work 
			SELECT 	'Branch', 
						DateName ( month , period_year.sales_period) ,
						convert  ( char(2), period_year.sales_period, 1) ,
						DateName ( year , period_year.sales_period) ,
						isnull(sum ( nett_amount ),0),
						null,
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period_year
			
			WHERE 	( book.branch_code =  @s_code OR  
								book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND	book.booking_period = period_year.sales_period
				AND 	period_year.sales_period between @d_first and @d_last 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY DateName ( month , period_year.sales_period) ,
						convert  ( char(2), period_year.sales_period, 1) ,
						DateName ( year , period_year.sales_period) 
			--HAVING isnull(sum ( nett_amount ),0) <> 0

				
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
				
				insert #work 
				SELECT 	'Branch', 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) ,
							isnull(sum ( nett_amount ),0),
							isnull(sum ( nett_amount ),0),
							null
				FROM    	booking_figures AS book,
							film_sales_period AS period_year
				
				WHERE 	( book.branch_code =  @s_code OR  
									book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND	book.booking_period = period_year.sales_period
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) 
				--HAVING isnull(sum ( nett_amount ),0) <> 0

			end
		
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
				
				UPDATE #work set rep_series = 'Bookings'
				
				insert #work
				SELECT 	'Branch', 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							'Target' ,
							sum ( target ),
							sum ( target ),
							null
				FROM    	booking_target AS book,
							film_sales_period AS period_year
				
				WHERE 	( book.branch_code =  @s_code OR  
									book.branch_code in (SELECT branch.branch_code from branch where country_code = @s_code))
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 
					AND	book.sales_period = period_year.sales_period
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
				GROUP BY DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end
		end
		IF ( @s_code = 'A' ) UPDATE #work set rep_title = 'Australia'
		ELSE IF ( @s_code = 'A' ) UPDATE #work set rep_title = 'New Zealand'
		ELSE  UPDATE #work set rep_title = ( Select branch_name from branch where branch_code = @s_code )
				

	end /* branch */

	IF  ( CHARINDEX ( 'sales_rep' , @s_report ) > 0 )
	begin
	
		IF ( DateName ( year , @d_first ) != DateName ( year , @d_last ) ) 
		begin 
			insert #work 
			SELECT 	'Rep: ' + first_name + ' ' + last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 100 + period_year.period_no) ,
						DateName ( yy , @d_first) + '-' + DateName ( yy , @d_last) ,
						isnull(sum ( nett_amount ),0),
						null,
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_rep
			WHERE 	book.rep_id =  @i_id 
				AND 	book.rep_id = sales_rep.rep_id
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND	book.booking_period = period_year.sales_period
				AND 	period_year.sales_period between @d_first and @d_last 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY first_name , last_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 100 + period_year.period_no)
			--HAVING isnull(sum ( nett_amount ),0) <> 0
						
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
	
				insert #work 
				SELECT 	'Rep: ' + first_name + ' ' + last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) ,
							DateName ( yy , @d_pfirst) + '-' + DateName ( yy , @d_plast) ,
							isnull(sum ( nett_amount ),0),
							isnull(sum ( nett_amount ),0),
							null
				FROM    	booking_figures AS book,
							film_sales_period AS period_year,
							sales_rep
				WHERE 	book.rep_id =  @i_id 
					AND 	book.rep_id = sales_rep.rep_id
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND	book.booking_period = period_year.sales_period
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
				and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY first_name , last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no)
				--HAVING isnull(sum ( nett_amount ),0) <> 0
			end		
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
	
				UPDATE #work set rep_series = 'Bookings'
	
				insert #work
				SELECT 	'Rep: ' + first_name + ' ' + last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) ,
							'Target' ,
							sum ( target ),
							sum ( target ),
							null
				FROM    	booking_target AS book,
							film_sales_period AS period_year,
							sales_rep
				
					WHERE book.rep_id =  @i_id 
					AND 	book.rep_id = sales_rep.rep_id
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 
					AND	book.sales_period = period_year.sales_period
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
				GROUP BY first_name, last_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) ,
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end
		end
		else
		begin
			insert #work 
			SELECT 	'Rep: ' + first_name + ' ' + last_name, 
						DateName ( month , period_year.sales_period) ,
						convert  ( char(2), period_year.sales_period, 1) ,
						DateName ( year , period_year.sales_period) ,
						isnull(sum ( nett_amount ),0),
						null,
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_rep
			WHERE 	book.rep_id =  @i_id 
				AND 	book.rep_id = sales_rep.rep_id
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND	book.booking_period = period_year.sales_period
				AND 	period_year.sales_period between @d_first and @d_last 
			and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY first_name ,last_name, 
						DateName ( month , period_year.sales_period) ,
						convert  ( char(2), period_year.sales_period, 1) ,
						DateName ( year , period_year.sales_period) 
			--HAVING isnull(sum ( nett_amount ),0) <> 0
			
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
				
				insert #work 
				SELECT 	'Rep: ' + first_name + ' ' + last_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) ,
							isnull(sum ( nett_amount ),0),
							isnull(sum ( nett_amount ),0),
							null
				FROM    	booking_figures AS book,
							film_sales_period AS period_year,
							sales_rep
				WHERE 	book.rep_id =  @i_id 
					AND 	book.rep_id = sales_rep.rep_id
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND	book.booking_period = period_year.sales_period
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
				and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY first_name, last_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) 
				--HAVING isnull(sum ( nett_amount ),0) <> 0
			end	
		
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
	
				UPDATE #work set rep_series = 'Bookings'
	
				insert #work
				SELECT 	'Rep: ' + first_name + ' ' + last_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							'Target' ,
							sum ( target ),
							sum ( target ),
							null
				FROM    	booking_target AS book,
							film_sales_period AS period_year,
							sales_rep
				
					WHERE book.rep_id =  @i_id 
					AND 	book.rep_id = sales_rep.rep_id
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 
					AND	book.sales_period = period_year.sales_period
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
			GROUP BY first_name, last_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end
		end
	end /*sales_rep*/
	
	IF  ( CHARINDEX ( 'team' , @s_report ) > 0 )
	begin
	
		IF ( DateName ( year , @d_first ) != DateName ( year , @d_last ) ) 
		begin 
			insert #work 
			SELECT 	'Team: ' + team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 100 + period_year.period_no) ,
						DateName ( yy , @d_first) + '-' + DateName ( yy , @d_last) ,
						isnull(sum ( nett_amount ),0),
						null,
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_team, booking_figure_team_xref
			WHERE 	book.figure_id =  booking_figure_team_xref.figure_id 
				AND 	booking_figure_team_xref.team_id = @i_id 
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 	booking_figure_team_xref.team_id = sales_team.team_id
				AND	book.booking_period = period_year.sales_period
				AND 	period_year.sales_period between @d_first and @d_last 
				and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
		GROUP BY team_name, 
						DateName ( month , period_year.sales_period) ,
						convert ( char(3) , 100 + period_year.period_no)
			--HAVING isnull(sum ( nett_amount ),0) <> 0
			
			
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
	
				insert #work 
				SELECT 	'Team: ' + team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) ,
							DateName ( yy , @d_pfirst) + '-' + DateName ( yy , @d_plast) ,
							isnull(sum ( nett_amount ),0),
							isnull(sum ( nett_amount ),0),
							null
				FROM    	booking_figures AS book,
							film_sales_period AS period_year,
							sales_team, booking_figure_team_xref
				WHERE 	book.figure_id =  booking_figure_team_xref.figure_id 
					AND 	booking_figure_team_xref.team_id = @i_id 
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 	booking_figure_team_xref.team_id = sales_team.team_id
					AND	book.booking_period = period_year.sales_period
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
				and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no)
				--HAVING isnull(sum ( nett_amount ),0) <> 0
			end
			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
	
				UPDATE #work set rep_series = 'Bookings'
	
				insert #work
				SELECT 	'Team: ' + team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) ,
							'Target' ,
							sum ( target ),
							sum ( target ),
							null
				FROM    	booking_target AS book,
							film_sales_period AS period_year,
							sales_team
				
					WHERE book.team_id =  @i_id 
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 
					AND 	book.team_id = sales_team.team_id
					AND	book.sales_period = period_year.sales_period
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
				GROUP BY team_name, 
							DateName ( month , period_year.sales_period) ,
							convert ( char(3) , 100 + period_year.period_no) ,
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end
		end

		ELSE

		begin
			insert #work 
			SELECT 	'Team: ' + team_name, 
						DateName ( month , period_year.sales_period) ,
						convert  ( char(2), period_year.sales_period, 1) ,
						DateName ( year , period_year.sales_period) ,
						isnull(sum ( nett_amount ),0),
						null,
						isnull(sum ( nett_amount ),0)
			FROM    	booking_figures AS book,
						film_sales_period AS period_year,
						sales_team, booking_figure_team_xref
			WHERE 	book.figure_id =  booking_figure_team_xref.figure_id 
				AND 	booking_figure_team_xref.team_id = @i_id 
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) 
				AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
				AND 	booking_figure_team_xref.team_id = sales_team.team_id
				AND	book.booking_period = period_year.sales_period
				AND 	period_year.sales_period between @d_first and @d_last 
				and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
			GROUP BY team_name, 
						DateName ( month , period_year.sales_period) ,
						convert  ( char(2), period_year.sales_period, 1) ,
						DateName ( year , period_year.sales_period) 
			--HAVING isnull(sum ( nett_amount ),0) <> 0
			
			IF ( CHARINDEX ( 'prior', @s_report ) > 0 ) 
			begin
				
				insert #work 
				SELECT 	'Team: ' + team_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) ,
							isnull(sum ( nett_amount ),0),
							isnull(sum ( nett_amount ),0),
							null
				FROM    	booking_figures AS book,
							film_sales_period AS period_year,
							sales_team, booking_figure_team_xref
				WHERE 	book.figure_id =  booking_figure_team_xref.figure_id 
					AND 	booking_figure_team_xref.team_id = @i_id 
				AND 	( @revision_group=0 OR book.revision_group = @revision_group ) AND ( @buss_unit=0 OR EXISTS ( SELECT * FROM film_campaign fc WHERE book.campaign_no = fc.campaign_no AND fc.business_unit_id = @buss_unit )) 
					AND 	booking_figure_team_xref.team_id = sales_team.team_id
					AND	book.booking_period = period_year.sales_period
					AND 	period_year.sales_period between @d_pfirst and @d_plast 
				and			book.campaign_no not in (select campaign_no from film_campaign where business_unit_id in (6,7,8))
				GROUP BY team_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) 
				--HAVING isnull(sum ( nett_amount ),0) <> 0
			end	

			IF ( CHARINDEX ( 'target', @s_report ) > 0 ) 
			begin
	
				UPDATE #work set rep_series = 'Bookings'
	
				insert #work
				SELECT 	'Team: ' + team_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							'Target' ,
							sum ( target ),
							sum ( target ),
							null
				FROM    	booking_target AS book,
							film_sales_period AS period_year,
							sales_team
				
					WHERE book.team_id =  @i_id 
				AND 	( @target_revision_group=0 OR book.revision_group = @target_revision_group ) AND ( @buss_unit=0 OR book.business_unit_id = @buss_unit ) 
					AND 	book.team_id = sales_team.team_id
					AND	book.sales_period = period_year.sales_period
					AND 	period_year.sales_period between @d_first and @d_last 
			and			book.business_unit_id not  in (6,7,8)
				GROUP BY team_name, 
							DateName ( month , period_year.sales_period) ,
							convert  ( char(2), period_year.sales_period, 1) ,
							DateName ( year , period_year.sales_period) 
				--HAVING sum ( target ) <> 0
			end
		end
	end /* team */
end /* YTD*/



SELECT * FROM #work
ORDER BY rep_cat_sort, rep_series, rep_value desc

end


return 0
GO
