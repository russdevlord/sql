/****** Object:  StoredProcedure [dbo].[p_print_cue_sheet_all]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_print_cue_sheet_all]
GO
/****** Object:  StoredProcedure [dbo].[p_print_cue_sheet_all]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_print_cue_sheet_all]  	@complex_id			integer,
							   			   @screening_date	datetime
as
set nocount on 
/*
 * Declare Variables
 */

declare @carousel_code_1		char(3),
        @cinema_no_1				integer,
	  @carousel_code_2		char(3),
	  @cinema_no_2				integer,
	  @carousel_code_3		char(3),
        @cinema_no_3				integer,
	  @carousel_code_4		char(3),
	  @cinema_no_4          integer,
	  @complex_name			varchar(50),
        @cue_sheet_id_1			integer,
	  @cue_sheet_id_2			integer,
        @cue_sheet_id_3			integer,
	  @cue_sheet_id_4			integer

/*
 * Create Temporary Table
 */

create table #complex_cue_sheets
(
carousel_code_1		char(2)			null,
cinema_no_1				integer			null,
carousel_code_2		char(2)			null,
cinema_no_2				integer			null,
carousel_code_3		char(2)			null,
cinema_no_3				integer			null,
carousel_code_4		char(2)			null,
cinema_no_4				integer			null,
screening_date			datetime			null, 
cue_sheet_id_1			integer			null,
cue_sheet_id_2			integer			null,
cue_sheet_id_3			integer			null,
cue_sheet_id_4			integer			null
)


/*
 * Get Complex Information
 */

 declare complex_csr cursor static for  
  select carousel.carousel_code,   
		   cue_sheet.cinema_no,
		   cue_sheet.cue_sheet_id
    from complex,
 		   carousel,
		   cue_sheet
   where carousel.carousel_id = cue_sheet.carousel_id and
		   complex.complex_id = cue_sheet.complex_id and  
		   complex.complex_id = @complex_id and
		   cue_sheet.screening_date = @screening_date
order by cue_sheet.cinema_no
	  for read only
/*
 * Begin Processiong
 */

open complex_csr
fetch complex_csr into @carousel_code_1, @cinema_no_1, @cue_sheet_id_1
while(@@fetch_status=0)
begin

	fetch complex_csr into @carousel_code_2, @cinema_no_2, @cue_sheet_id_2

	if @@fetch_status<>0 
		select @carousel_code_2 = null, @cinema_no_2 = null, @cue_sheet_id_2 = null

	fetch complex_csr into @carousel_code_3, @cinema_no_3, @cue_sheet_id_3

	if @@fetch_status<>0 
		select @carousel_code_3 = null, @cinema_no_3 = null, @cue_sheet_id_3 = null

	fetch complex_csr into @carousel_code_4, @cinema_no_4, @cue_sheet_id_4

	if @@fetch_status<>0 
		select @carousel_code_4 = null, @cinema_no_4 = null, @cue_sheet_id_4 = null

		insert into #complex_cue_sheets
		(
		carousel_code_1,
		cinema_no_1,
		carousel_code_2,
		cinema_no_2,
		carousel_code_3,
		cinema_no_3,
		carousel_code_4,
		cinema_no_4,
		screening_date, 
		cue_sheet_id_1,
		cue_sheet_id_2,
		cue_sheet_id_3,
		cue_sheet_id_4
		) values
		(
		@carousel_code_1,
	   @cinema_no_1,
		@carousel_code_2,
	   @cinema_no_2,
		@carousel_code_3,
	   @cinema_no_3,
		@carousel_code_4,
	   @cinema_no_4,
		@screening_date, 
		@cue_sheet_id_1,
		@cue_sheet_id_2,
		@cue_sheet_id_3,
		@cue_sheet_id_4
		)
		
	fetch complex_csr into @carousel_code_1, @cinema_no_1, @cue_sheet_id_1
end

close complex_csr
deallocate complex_csr

/*
 * Return Success
 */

select * from #complex_cue_sheets order by cinema_no_1
return 0
GO
