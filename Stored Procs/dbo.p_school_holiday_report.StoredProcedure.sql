/****** Object:  StoredProcedure [dbo].[p_school_holiday_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_school_holiday_report]
GO
/****** Object:  StoredProcedure [dbo].[p_school_holiday_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_school_holiday_report] @start_date		datetime,
                                    @end_date		datetime
as
set nocount on 
declare	@temp_start_date			 	datetime,
			@hol_start_date			 	datetime,
			@hol_end_date	 	 			datetime,
			@state_name			 			varchar(30),
			@screening_date				datetime,
			@screening_date_status   	char(1),
			@error							integer,
			@datepart						integer

/*
 * Declare Temporary Tables
 */

create table #school_holidays
(
	state_name					varchar(30)		null,
	start_date					datetime			null,
	end_date						datetime			null,
	screening_date				datetime			null,
	screening_date_status	char(1)			null,
	screening_date_type	integer			null,
)

/*
 * Declare Cursors
 */

 declare school_hol_csr cursor static for
  select st.state_name, 
         sh.start_date,           
		   sh.end_date
    from school_holidays sh,
         state st
   where st.state_code = sh.state_code and
		   sh.start_date >= @start_date and		 			 
		   sh.end_date <= @end_date			
order by st.state_name ASC,
         sh.start_date ASC

/*
 * Select School Holiday Info
 */
open school_hol_csr
fetch school_hol_csr into  @state_name, @temp_start_date, @hol_end_date
while(@@fetch_status = 0)
begin

	select @datepart = datepart(dw, @temp_start_date)
	if @datepart <> 5
		select @hol_start_date = dateadd(wk, -1, @temp_start_date)
	else
		select @hol_start_date = @temp_start_date

	 declare screening_date_csr cursor static for
	  select screening_date,
				screening_date_status
	    from film_screening_dates
	   where screening_date >= @hol_start_date and		 			 
			   screening_date <= @hol_end_date			
	order by screening_date ASC

	open screening_date_csr
	fetch screening_date_csr into @screening_date, @screening_date_status
	while(@@fetch_status = 0)
	begin

		insert into #school_holidays
		(state_name,
		 start_date, 
		 end_date,
		 screening_date,
		 screening_date_status,
		screening_date_type 
		) values
		(@state_name,
		 @temp_start_date,
		 @hol_end_date,
		 @screening_date,
		 @screening_date_status,
		 1
		)
	
		select @error = @@error
		if ( @error !=0 )
		begin
			raiserror ('Error retireving school holiday information', 16, 1)
			close school_hol_csr 
			close screening_date_csr 
			deallocate school_hol_csr 
			deallocate screening_date_csr
			return @error
		end	
		
		fetch screening_date_csr into @screening_date, @screening_date_status
	end
	close screening_date_csr
	deallocate screening_date_csr

	 declare screening_date_csr cursor static for
	  select screening_date,
				screening_date_status
	    from outpost_screening_dates
	   where screening_date >= @hol_start_date and		 			 
			   screening_date <= @hol_end_date			
	order by screening_date ASC

	open screening_date_csr
	fetch screening_date_csr into @screening_date, @screening_date_status
	while(@@fetch_status = 0)
	begin

		insert into #school_holidays
		(state_name,
		 start_date, 
		 end_date,
		 screening_date,
		 screening_date_status,
		screening_date_type 
		) values
		(@state_name,
		 @temp_start_date,
		 @hol_end_date,
		 @screening_date,
		 @screening_date_status,
		 2
		)
	
		select @error = @@error
		if ( @error !=0 )
		begin
			raiserror ('Error retireving school holiday information', 16, 1)
			close school_hol_csr 
			close screening_date_csr 
			deallocate school_hol_csr 
			deallocate screening_date_csr
			return @error
		end	
		
		fetch screening_date_csr into @screening_date, @screening_date_status
	end
	close screening_date_csr
	deallocate screening_date_csr
	fetch school_hol_csr into  @state_name, @temp_start_date, @hol_end_date
end


deallocate school_hol_csr 

/*
 * Return
 */

  select *
    from #school_holidays   

return 0
GO
