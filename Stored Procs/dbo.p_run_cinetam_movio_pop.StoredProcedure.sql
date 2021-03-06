/****** Object:  StoredProcedure [dbo].[p_run_cinetam_movio_pop]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_run_cinetam_movio_pop]
GO
/****** Object:  StoredProcedure [dbo].[p_run_cinetam_movio_pop]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create proc [dbo].[p_run_cinetam_movio_pop]		@mode								int,
																							@arg_screening_date	datetime,
																							@country_code					char(1)

as

declare			@screening_date		datetime,
					@error						int,
					@count						int
					
declare				screening_date_csr cursor for				
select				distinct screening_date 
from					movie_history 
where				isnull(attendance,0) <> 0 
and						screening_date >= '10-may-2012'
and						country = @country_code
and						((@mode = 1
and						screening_date not in (select distinct screening_date from cinetam_movie_history where country_code = @country_code))
or						(@mode = 2
and						screening_date = @arg_screening_date)
or						(@mode = 3))
order by screening_date DESC

open screening_date_csr
fetch screening_date_csr into @screening_date
while(@@FETCH_STATUS=0)
begin

    print 'PROCESSING'
	print @screening_date

	/*
	 * Check if any movio data exists for this week - error if not
	 */

	 select @count = count(*)
	 from movio_data 
	 where screening_date = @screening_date
	  and country_code = @country_code

	  select @error = @@error
	  if @error <> 0
	  begin
		raiserror ('Error: No loyalty data has been imported', 16, 1)
		return -1
	  end 


	
    /* 
    print 'About to collect 1'
	exec p_cinetam_collect_movio_data_1 @screening_date, @country_code
    print 'Finished Collect - 1'
    print convert(varchar(50), getdate(), 109)

    print 'About to collect 2'
	exec p_cinetam_collect_movio_data_2 @screening_date, @country_code
    print 'Finished Collect - 2'
    print convert(varchar(50), getdate(), 109)

    print 'About to collect 3'
	exec p_cinetam_collect_movio_data_3 @screening_date,@country_code
    print 'Finished Collect - 3'
    print convert(varchar(50), getdate(), 109)
    */
    
    print 'About to process transform'
    print @country_code
	exec @error = p_cinetam_transform_movio_data @screening_date, @country_code

	if @error <> 0 
	begin
		raiserror ('Error: Failed to Transform Loyalty Data', 16, 1)
		return -1
	  end 

	print 'Finished Transform'
	print convert(varchar(50), getdate(), 109)

	print 'About to process close'
	exec @error = p_cinetam_close_screening_date @screening_date, @country_code
	
	if @error <> 0 
	begin
		raiserror ('Error: Failed to Close Cinetam screening date', 16, 1)
		return -1
	end 

	print 'Finished Close'
	print convert(varchar(50), getdate(), 109)
	
	fetch screening_date_csr into @screening_date
end

return 0
GO
