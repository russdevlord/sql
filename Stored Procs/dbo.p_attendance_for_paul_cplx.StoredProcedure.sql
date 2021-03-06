/****** Object:  StoredProcedure [dbo].[p_attendance_for_paul_cplx]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_attendance_for_paul_cplx]
GO
/****** Object:  StoredProcedure [dbo].[p_attendance_for_paul_cplx]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_attendance_for_paul_cplx]

as

declare			@loop		int, @screening_date datetime,  @complex_name varchar(100)

create table #att_temp
(
complex_name				varchar(100), 
screening_date		datetime, 
attendance				int,
no_prints					int,
top_10							int,
top_20							int,
top_50							int
)

set nocount on

insert into #att_temp
select complex_name, screening_date, sum(attendance) as attendance, count(movie_history.movie_id) as no_prints  , 0, 0, 0
from movie_history, movie, complex, film_market where country = 'A' and movie.movie_id = movie_history.movie_id 
and screening_date between '25-sep-2010' and '28-sep-2011'
and movie_history.complex_id = complex.complex_id
and complex.film_market_no = film_market.film_market_no
group by complex_name, screening_date


declare att_csr cursor for
select distinct screening_date
from  #att_temp
order by screening_date

open att_csr 
fetch att_csr into @screening_date
while(@@fetch_status=0)
begin
	
	select @loop = 1 
	
	declare att_det_csr cursor for
	select complex_name
	from  #att_temp
	where screening_date = @screening_date
	group by complex_name
	order by sum(attendance) desc

	open att_det_csr
	fetch att_det_csr into @complex_name
	while(@@fetch_status=0 and @loop <=50)			
	begin
			if @loop <=10
			begin
				update 	#att_temp
				set			top_10 = 1
				where	complex_name  = @complex_name
				and			screening_date = @screening_date
			end
			
			if @loop <=20
			begin
				update 	#att_temp
				set			top_20 = 1
				where	complex_name  = @complex_name
				and			screening_date = @screening_date
			end

			if @loop <=50
			begin
				update 	#att_temp
				set			top_50 = 1
				where	complex_name  = @complex_name
				and			screening_date = @screening_date
			end
			
			
			select @loop = @loop +1
			
			fetch att_det_csr into @complex_name
	end

	deallocate att_det_csr
	

	fetch att_csr into @screening_date
end

select * from  #att_temp
return 0
GO
