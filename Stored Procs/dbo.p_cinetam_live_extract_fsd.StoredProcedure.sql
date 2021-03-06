/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_fsd]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_live_extract_fsd]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_fsd]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_cinetam_live_extract_fsd]

as

declare			@error			int

set nocount on

select			film_screening_dates.screening_date,
				film_screening_date_xref.benchmark_end,
				year(benchmark_end) as cal_year,
				case month(case benchmark_end when '1-jul-2015' then '30-jun-2015' else benchmark_end end)
				when 1 then 'Q1' 
				when 2 then 'Q1'
				when 3 then 'Q1'
				when 4 then 'Q2' 
				when 5 then 'Q2' 
				when 6 then 'Q2' 
				when 7 then 'Q3' 
				when 8 then 'Q3' 
				when 9 then 'Q3' 
				when 10 then 'Q4'
				when 11 then 'Q4'
				when 12 then 'Q4' end as cal_qtr,
				case month(case benchmark_end when '1-jul-2015' then '30-jun-2015' else benchmark_end end)
				when 1 then year(benchmark_end)
				when 2 then year(benchmark_end)
				when 3 then year(benchmark_end)
				when 4 then year(benchmark_end)
				when 5 then year(benchmark_end)
				when 6 then year(benchmark_end)
				when 7 then year(benchmark_end) + 1 
				when 8 then year(benchmark_end) + 1
				when 9 then year(benchmark_end)  + 1
				when 10 then year(benchmark_end) + 1
				when 11 then year(benchmark_end) + 1
				when 12 then year(benchmark_end) + 1 end as fin_year,
				case month(case benchmark_end when '1-jul-2015' then '30-jun-2015' else benchmark_end end)
				when 1 then 'Q3' 
				when 2 then 'Q3'
				when 3 then 'Q3'
				when 4 then 'Q4' 
				when 5 then 'Q4' 
				when 6 then 'Q4' 
				when 7 then 'Q1' 
				when 8 then 'Q1' 
				when 9 then 'Q1' 
				when 10 then 'Q2'
				when 11 then 'Q2'
				when 12 then 'Q2' end as fin_qtr,
				case month(case benchmark_end when '1-jul-2015' then '30-jun-2015' else benchmark_end end)
				when 1 then 'H1' 
				when 2 then 'H1'
				when 3 then 'H1'
				when 4 then 'H1' 
				when 5 then 'H1' 
				when 6 then 'H1' 
				when 7 then 'H2' 
				when 8 then 'H2' 
				when 9 then 'H2' 
				when 10 then 'H2'
				when 11 then 'H2'
				when 12 then 'H2' end as cal_half,
				case month(case benchmark_end when '1-jul-2015' then '30-jun-2015' else benchmark_end end)
				when 1 then 'H2' 
				when 2 then 'H2'
				when 3 then 'H2'
				when 4 then 'H2' 
				when 5 then 'H2' 
				when 6 then 'H2' 
				when 7 then 'H1' 
				when 8 then 'H1' 
				when 9 then 'H1' 
				when 10 then 'H1'
				when 11 then 'H1'
				when 12 then 'H1' end as fin_half
from			film_screening_dates
inner join		film_screening_date_xref on film_screening_dates.screening_date = film_screening_date_xref.screening_date
where			film_screening_dates.screening_date >= '27-dec-2017'
and				film_screening_dates.screening_date not in (	select			screening_date
																from			cinetam_live_fsd
																where			added = 'Y')
and				attendance_status = 'X'
--for json path

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce film screening_date list for cinetam live bigquery datawarehouse', 16, 1)
	return -1
end

begin transaction

insert into		cinetam_live_fsd
select			screening_date, 
				'Y',
				'N'
from			film_screening_dates
where			film_screening_dates.screening_date >= '27-dec-2017'
and				film_screening_dates.screening_date not in (	select			screening_date
																from			cinetam_live_fsd
																where			added = 'Y')
and				attendance_status = 'X'

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce film screening_date list for cinetam live bigquery datawarehouse', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
