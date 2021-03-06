/****** Object:  StoredProcedure [dbo].[p_theatre_check_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_theatre_check_report]
GO
/****** Object:  StoredProcedure [dbo].[p_theatre_check_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_theatre_check_report]  		@user_date 		datetime,
																				@complex_id		integer
as
set nocount on 
declare	@error 											integer,
				@film_screening_date			datetime,
				@slide_screening_date			datetime,
				@week_before							datetime,
				@complex_name						varchar(50),
				@branch_name						varchar(50),
				@branch_code							char(2),
				@exhibitor_name						varchar(50)

select		@complex_name = complex_name,
					@branch_code = branch_code
from			complex
where		complex_id = @complex_id

select		@exhibitor_name = exhibitor_name
from			exhibitor,
					complex
where		exhibitor.exhibitor_id = complex.exhibitor_id
and				complex.complex_id = @complex_id
        
select		@week_before	= dateadd(wk, -1, @user_date)

select		@film_screening_date = screening_date 
from			film_screening_dates
where		screening_date <= @user_date 
and				screening_date > @week_before

select @week_before	= dateadd(mm, -1, @user_date)

select @slide_screening_date = screening_date
  from slide_screening_dates,
		 branch
 where screening_date <= @user_date and
		 screening_date > @week_before and
		 branch.billing_cycle = slide_screening_dates.billing_cycle and
		 branch.branch_code = @branch_code

select @branch_name = branch_name
  from branch
 where branch_code = @branch_code

create table #mode
(mode			char(1)			not null)

insert into #mode values ('F') 
insert into #mode values ('M') 
insert into #mode values ('S') 

select			@complex_id,
						@branch_code,
						@film_screening_date,
						@slide_screening_date,
						@complex_name,
						@branch_name,
						@exhibitor_name,
						mode
from				#mode
order by		mode

return 0
GO
