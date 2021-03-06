/****** Object:  StoredProcedure [dbo].[p_complex_list_rates]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_list_rates]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_list_rates]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_complex_list_rates] @mode					integer,
                                 @film_market_no	integer,
                                 @branch_code		char(2),
                                 @state_code			char(3)
as

declare	@film_market_no_tmp	integer,
         @branch_code_tmp		char(2),
         @state_code_tmp		char(3)
                                            

create table #complex
(
	film_market_no						integer			null,
   film_market_desc					varchar(30)		null,
	branch_code							char(2)			null,
	branch_name							varchar(50)		null,
	state_code							char(3)			null,
	state_name							varchar(30)		null,
	complex_name						varchar(50)		null,
	complex_session					integer			null,
	cinema_session						integer			null,
	cinema_no							integer			null,
	seating_capacity					integer			null,
	list_rate							money				null,
	slide_comment						varchar(50)		null,
	film_comment						varchar(50)		null,
	film_note							varchar(50)		null
)

select @film_market_no_tmp = film_market.film_market_no
  from film_market
 where film_market.film_market_no = @film_market_no
select @film_market_no = @film_market_no_tmp

select @branch_code_tmp = branch.branch_code
  from branch
 where branch.branch_code = @branch_code
select @branch_code = @branch_code_tmp

select @state_code_tmp = state.state_code
  from state
 where state.state_code = @state_code
select @state_code = @state_code_tmp

if @mode = 1
begin
   insert into #complex
     select film_market.film_market_no,
				film_market.film_market_desc,
				complex.branch_code,
            branch.branch_name,
            complex.state_code,
            state.state_name,
            complex.complex_name,
				complex.session_target,
            cinema.list_sessions,
            cinema.cinema_no,
            cinema.seating_capacity,
            cinema.list_rate,
            cinema.slide_comment,
            cinema.film_comment,
            cinema.film_note
       from complex,
            film_market,
            cinema,
            branch,
            state
      where complex.complex_id = cinema.complex_id 
		  and complex.film_market_no = film_market.film_market_no
        and complex.branch_code = branch.branch_code 
		  and complex.state_code = state.state_code
		  and complex.film_complex_status <> 'C' 
		  and ( @mode = 1 
		  and ( film_market.film_market_no = @film_market_no 
			or @film_market_no is null ))
end
else
if @mode = 2 or @mode = 3
begin
   insert into #complex
     select @film_market_no,
				null, 					-- Insert NULL value for Film Market Description
            complex.branch_code,
            branch.branch_name,
            complex.state_code,
            state.state_name,
            complex.complex_name,
            complex.session_target,
            cinema.list_sessions,
            cinema.cinema_no,
            cinema.seating_capacity,
            cinema.list_rate,
            cinema.slide_comment,
            cinema.film_comment,
            cinema.film_note
       from complex,
            cinema,
            branch,
            state
      where complex.complex_id = cinema.complex_id and
            complex.branch_code = branch.branch_code and
            complex.state_code = state.state_code and
            complex.film_complex_status <> 'C' and
            ( ( @mode = 2 and
                ( complex.branch_code = @branch_code or
                  @branch_code is null ) ) or
              ( @mode = 3  and
                ( complex.state_code = @state_code or
                  @state_code is null ) ) )
end

  select @mode as mode,
			film_market_no,
			film_market_desc,
         branch_code,
         branch_name,
         state_code,
         state_name,
         complex_name,
         complex_session,
			cinema_session,
			cinema_no,
			seating_capacity,
			list_rate,
			slide_comment,
         film_comment,
         film_note
    from #complex

/*
 * Return Success
 */

return 0
GO
