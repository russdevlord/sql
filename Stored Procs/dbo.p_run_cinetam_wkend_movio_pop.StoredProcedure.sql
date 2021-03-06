/****** Object:  StoredProcedure [dbo].[p_run_cinetam_wkend_movio_pop]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_run_cinetam_wkend_movio_pop]
GO
/****** Object:  StoredProcedure [dbo].[p_run_cinetam_wkend_movio_pop]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_run_cinetam_wkend_movio_pop]			@mode											int,
																															@arg_screening_date				datetime

as

declare		@screening_date			datetime,
					@error					int
					
declare		screening_date_csr cursor for				
select		distinct screening_date 
from			movie_history
where		screening_date >= '25-dec-2009'
and				screening_date not in (select distinct screening_date from cinetam_wkend_movio_data)
and				((@mode = 1
and				isnull(attendance,0) <> 0 )
or				(@mode = 2
and				screening_date = @arg_screening_date))
order by	screening_date desc


open screening_date_csr
fetch screening_date_csr into @screening_date
while(@@FETCH_STATUS=0)
begin

	print @screening_date
    print 'About to Weekend collect 1'
	
	exec p_cinetam_wkend_movio_data_1 @screening_date
	
    print 'Finished Weekend Collect - 1'
    print convert(varchar(50), getdate(), 109)
    print 'About to Weekend collect 2'
	
	exec p_cinetam_wkend_movio_data_2 @screening_date
	
    print 'Finished Weekend Collect - 2'
    print convert(varchar(50), getdate(), 109)
    print 'About to Weekend cellect 3'

	exec p_cinetam_wkend_movio_data_3 @screening_date
	
    print 'Finished Weekend Collect - 3'
    print convert(varchar(50), getdate(), 109)
    print 'About to process Weekend transform'

	print 'Processing Australian Weekend transform'
	exec p_cinetam_wkend_transform_movio_data @screening_date, 'A'
	
    print 'Processing New Zealand Weekend transform'
	exec p_cinetam_wkend_transform_movio_data @screening_date, 'Z'
	
	print 'Finished Weekend Transform'
	print convert(varchar(50), getdate(), 109)
	print 'About to process Weekend close'
	
	exec p_cinetam_wkend_close_screening_date @screening_date, 'A'
	
	exec p_cinetam_wkend_close_screening_date @screening_date, 'Z'
	
	print 'Finished Weekend Close'
	print convert(varchar(50), getdate(), 109)
	print 'About to process Weekend Campaign close'
	
	exec p_cinetam_wkend_close_campaigns @screening_date
	
	print 'Finished Weekend Campaign Close'
	fetch screening_date_csr into @screening_date
end

return 0

GRANT EXECUTE ON dbo.p_run_cinetam_wkend_movio_pop TO public
GO
