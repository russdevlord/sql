/****** Object:  StoredProcedure [dbo].[p_film_shell_restrictions]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_shell_restrictions]
GO
/****** Object:  StoredProcedure [dbo].[p_film_shell_restrictions]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_film_shell_restrictions]   @complex_id			integer,
												@screening_date		datetime,
												@shell_code			char(7),
												@movie_id			integer,
												@restricted			char(1) OUTPUT							
as

/*
 * Declare Variables
 */

declare		@error					integer,
			@errorode					integer,
			@score					integer,
			@band					smallint,
			@allocations			integer,
			@count					integer,
			@classification			integer,
			@school_holiday			char(1),
			@complex_holidays		integer


/*
 * Initialise Restricted Variable
 */

select @restricted = 'N'

/*
 * Check Movie Restrictions
 */

select		@score = count(shell_code)
from		film_shell_movie_instructions
where		shell_code = @shell_code 
and			movie_id = @movie_id 
and			instruction_type = 3

select @error = @@error
if @error != 0 
begin
	raiserror ('Error retrieving film shell movie restrictions.', 16, 1)
	return -1
end

if @score > 0 
	select @restricted = 'Y'

/*
 * Check Category Restrictions
 */ 

if @restricted = 'N'
begin
	
	select	@score = count(shell_code)
	from	film_shell_category,
			target_categories
	where	film_shell_category.movie_category_code = target_categories.movie_category_code 
	and		film_shell_category.shell_code = @shell_code 
	and		target_categories.movie_id = @movie_id 
	and		film_shell_category.instruction_type = 3

	select @error = @@error
	if @error != 0 
	begin
		raiserror ('Error retrieving film shell movie restrictions.', 16, 1)
		return -1
	end

	if @score > 0 
		select @restricted = 'Y'
end

/*
 * Check Classification Restrictions
 */

if @restricted = 'N'
begin

	select	@score = count(shell_code)
	from	movie_history,
			movie_country,
			film_shell_classification
	where	movie_history.movie_id = movie_country.movie_id 
	and		movie_history.country = movie_country.country_code 
	and		movie_country.classification_id = film_shell_classification.classification_id 
	and		movie_history.movie_id = @movie_id 
	and		film_shell_classification.shell_code = @shell_code 
	and		movie_history.complex_id = @complex_id 
	and		movie_history.screening_date = @screening_date

	select @error = @@error
	if @error != 0 
	begin
		raiserror ('Error retrieving film shell movie restrictions.', 16, 1)
		return -1
	end

	if @score > 0 
		select @restricted = 'Y'
end

/*
 * Check School Holiday Restrictions
 */


if @restricted = 'N'
begin

	select	@school_holiday = shell_holidays 
	from	film_shell 
	where	shell_code = @shell_code

	select @error = @@error
	if @error != 0 
	begin
	raiserror ('Error retrieving film shell holiday restrictions.', 16, 1)
	return -1
	end

	select	@complex_holidays = count(complex.state_code)
	from	complex,
			school_holiday_xref
	where	complex.state_code = school_holiday_xref.state_code 
	and		complex.complex_id = @complex_id 
	and		school_holiday_xref.screening_date = @screening_date 

	select @error = @@error
	if @error != 0 
	begin
		raiserror ('Error retrieving complex holiday information.', 16, 1)
		return -1
	end

	if @complex_holidays > 0 and @school_holiday = 'N'
		select @restricted = 'Y'
end

/*
 * Return Success
 */

return 0
GO
