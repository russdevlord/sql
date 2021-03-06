/****** Object:  StoredProcedure [dbo].[p_attendance_for_paul]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_attendance_for_paul]
GO
/****** Object:  StoredProcedure [dbo].[p_attendance_for_paul]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_attendance_for_paul]

as

declare			@loop		int, @screening_date datetime,  @long_name varchar(100)

create table #att_temp
(
long_name				varchar(100), 
screening_date		datetime, 
attendance				int,
no_prints					int,
top_1							int,
top_3							int,
top_5							int
)

set nocount on

insert into #att_temp
select long_name, screening_date, sum(attendance) as attendance, count(movie_history.movie_id) as no_prints  , 0, 0, 0
from movie_history, movie, complex, film_market where country = 'A' and movie.movie_id = movie_history.movie_id 
and screening_date between '25-sep-2010' and '28-sep-2011'
and movie_history.complex_id = complex.complex_id
and complex.film_market_no = film_market.film_market_no
group by long_name, screening_date


declare att_csr cursor for
select screening_date
from  #att_temp
order by screening_date

open att_csr 
fetch att_csr into @screening_date
while(@@fetch_status=0)
begin
	
	select @loop = 1 
	
	declare att_det_csr cursor for
	select long_name
	from  #att_temp
	where screening_date = @screening_date
	group by long_name
	order by sum(attendance) desc

	open att_det_csr
	fetch att_det_csr into @long_name
	while(@@fetch_status=0 and @loop <=5)			
	begin
			if @loop <=1
			begin
				update 	#att_temp
				set			top_1 = 1
				where	long_name  = @long_name
				and			screening_date = @screening_date
			end
			
			if @loop <=3
			begin
				update 	#att_temp
				set			top_3 = 1
				where	long_name  = @long_name
				and			screening_date = @screening_date
			end

			if @loop <=5
			begin
				update 	#att_temp
				set			top_5 = 1
				where	long_name  = @long_name
				and			screening_date = @screening_date
			end
			
			
			select @loop = @loop +1
			
			fetch att_det_csr into @long_name
	end

	deallocate att_det_csr
	

	fetch att_csr into @screening_date
end

select * from  #att_temp
return 0
GO
