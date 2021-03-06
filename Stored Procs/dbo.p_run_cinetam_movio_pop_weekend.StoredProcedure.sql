/****** Object:  StoredProcedure [dbo].[p_run_cinetam_movio_pop_weekend]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_run_cinetam_movio_pop_weekend]
GO
/****** Object:  StoredProcedure [dbo].[p_run_cinetam_movio_pop_weekend]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_run_cinetam_movio_pop_weekend]		@mode								int,
																										@arg_screening_date		datetime,
																										@country_code					char(1)

as

declare		@screening_date		datetime,
					@error							int
					
declare		screening_date_csr cursor for				
select			distinct screening_date 
from			movie_history_weekend
where			isnull(attendance,0) <> 0 
and				screening_date >= '10-may-2012'
--and						screening_date between '5-sep-2019' and '9-jan-2020'
and				country = @country_code
and				((@mode = 1
and				screening_date not in (select distinct screening_date from cinetam_movie_history where country_code = @country_code))
or					(@mode = 2
and				screening_date = @arg_screening_date)
or					(@mode = 3))
order by		screening_date DESC

open screening_date_csr
fetch screening_date_csr into @screening_date
while(@@FETCH_STATUS=0)
begin

    print 'PROCESSING'
	print @screening_date
	
    /*print 'About to collect 1'
	exec p_cinetam_collect_movio_data_weekend_1 @screening_date, @country_code
    print 'Finished Collect - 1'
    print convert(varchar(50), getdate(), 109)

    print 'About to collect 2'
	exec p_cinetam_collect_movio_data_weekend_2 @screening_date, @country_code
    print 'Finished Collect - 2'
    print convert(varchar(50), getdate(), 109)

    print 'About to collect 3'
	exec p_cinetam_collect_movio_data_weekend_3 @screening_date,@country_code
    print 'Finished Collect - 3'
    print convert(varchar(50), getdate(), 109)*/
    
    print 'About to process transform'
    print @country_code
	exec p_cinetam_transform_movio_data_weekend @screening_date, @country_code
	print 'Finished Transform'
	print convert(varchar(50), getdate(), 109)

	print 'About to process close'
	exec p_cinetam_close_screening_date_weekend @screening_date, @country_code
	print 'Finished Close'
	print convert(varchar(50), getdate(), 109)
	
	fetch screening_date_csr into @screening_date
end

return 0
GO
