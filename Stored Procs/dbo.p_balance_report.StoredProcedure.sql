/****** Object:  StoredProcedure [dbo].[p_balance_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_balance_report]
GO
/****** Object:  StoredProcedure [dbo].[p_balance_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_balance_report]		@screening_date		datetime,
										@branch_code		char(3)

as

declare		@carousel_id		integer,
			@count				integer

create table #screenings (
	carousel_id			integer		null,
	carousel_code		char(3)		null,
	complex_name		varchar(50) null,
	branch_code			char(3)		null,
	num_screenings		integer		null	
)

insert into #screenings (
	carousel_id,
	carousel_code,
	complex_name,
	branch_code,
	num_screenings )
select	carousel.carousel_id,
		carousel.carousel_code,
		complex.complex_name,
		complex.branch_code,
		0
from	carousel,
		complex
where	carousel.complex_id = complex.complex_id
and		complex.film_complex_status <> 'C' --complex.slide_complex_status <> 'C'
and		complex.branch_code = @branch_code

declare	carousel_csr cursor static for
select	carousel_id
from	#screenings
order by carousel_id
for read only

open carousel_csr
fetch carousel_csr into @carousel_id
while(@@fetch_status = 0) 
begin
	  select @count = count(line_artwork_id)
		 from line_artwork,
				slide_campaign_screening
		where ( slide_campaign_screening.carousel_id = @carousel_id ) and
				( slide_campaign_screening.screening_date = @screening_date ) and
				( line_artwork.campaign_line_id = slide_campaign_screening.campaign_line_id ) and
				( line_artwork.cue_cat <> 'H')

		if @count > 0
		begin
			update #screenings
				set num_screenings = @count
			 where carousel_id = @carousel_id
		end

	fetch carousel_csr into @carousel_id
end
deallocate carousel_csr

--Return
select * 
from #screenings 
order by branch_code, complex_name, carousel_code

return 0
GO
