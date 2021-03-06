/****** Object:  StoredProcedure [dbo].[p_select_screening_dates]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_select_screening_dates]
GO
/****** Object:  StoredProcedure [dbo].[p_select_screening_dates]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*  Filter Types
  *  S (status), C (cycle), B (branch), Any other for all dates
  */

CREATE PROC [dbo].[p_select_screening_dates]		  @filter_type  char(1),
						  @status_type  char(1), --A, B, C , R or S for status
						  @status_open  char(1), --O (open) , X (closed) , A (all)
						  @default_pos  char(1), --L (last), F (first)
						  @default_open char(1), --O (last), X (first), A (all ie. the absolute 1st or absolute last)
						  @branch		 char(2),
						  @cycle			 tinyint,
						  @select_all	 char(1)

as
set nocount on 
declare		@status_description		varchar(20)

create table #dates
(
	screening_date		datetime				null,
	cycle					tinyint				null,
	scroll_to_flag		char(1)				null,
)

create table #status
(
	screening_date		datetime				null,
	status				char(1)				null
)

--Setup the status required
if @status_type = 'A' --Approval Status
begin
	insert #status ( screening_date, status )
	select screening_date, approval_status
	  from slide_screening_dates
	 where ( ( @status_open = 'O' and approval_status = 'O') or
			   ( @status_open = 'X' and approval_status = 'X') or
			   ( @status_open = 'A') ) and
            ( ( @select_all = 'Y' ) or ( @select_all = 'N' and screening_date >= dateadd( year, -1, getdate() ) and screening_date <= dateadd( year, 1, getdate() ) ) )
	select @status_description = 'Approval Status'
end
else if @status_type = 'B' --Billing status
begin
	insert #status ( screening_date, status )
	select screening_date, billing_status
	  from slide_screening_dates
	 where ( ( @status_open = 'O' and billing_status = 'O') or
			   ( @status_open = 'X' and billing_status = 'X') or
			   ( @status_open = 'A') ) and
            ( ( @select_all = 'Y' ) or ( @select_all = 'N' and screening_date >= dateadd( year, -1, getdate() ) and screening_date <= dateadd( year, 1, getdate() ) ) )
	select @status_description = 'Billing Status'
end
else if @status_type = 'C' --Credit Letter Status
begin
	insert #status ( screening_date, status )
	select screening_date, credit_letter_status
	  from slide_screening_dates
	 where ( ( @status_open = 'O' and credit_letter_status = 'O') or
			   ( @status_open = 'X' and credit_letter_status = 'X') or
			   ( @status_open = 'A') ) and
            ( ( @select_all = 'Y' ) or ( @select_all = 'N' and screening_date >= dateadd( year, -1, getdate() ) and screening_date <= dateadd( year, 1, getdate() ) ) )
	select @status_description = 'Credit Letter Status'
end
else if @status_type = 'R' --Recording status
begin
	insert #status ( screening_date, status )
	select screening_date, recording_status
	  from slide_screening_dates
	 where ( ( @status_open = 'O' and recording_status = 'O') or
			   ( @status_open = 'X' and recording_status = 'X') or
			   ( @status_open = 'A') ) and
            ( ( @select_all = 'Y' ) or ( @select_all = 'N' and screening_date >= dateadd( year, -1, getdate() ) and screening_date <= dateadd( year, 1, getdate() ) ) )
	select @status_description = 'Recording Status'
end
else if @status_type = 'S' --Screening status
begin
	insert #status ( screening_date, status )
	select screening_date, screening_status
	  from slide_screening_dates
	 where ( ( @status_open = 'O' and screening_status = 'O') or
			   ( @status_open = 'X' and screening_status = 'X') or
			   ( @status_open = 'A') ) and
            ( ( @select_all = 'Y' ) or ( @select_all = 'N' and screening_date >= dateadd( year, -1, getdate() ) and screening_date <= dateadd( year, 1, getdate() ) ) )
	select @status_description = 'Screening Status'
end
	
if @filter_type = 'S'
begin
	--Insert all the screening dates, when we join at the end these will be filtered.
	insert #dates ( screening_date, cycle, scroll_to_flag )
	select screening_date, billing_cycle, 'N'
	  from slide_screening_dates
    where ( ( @select_all = 'Y' ) or ( @select_all = 'N' and screening_date >= dateadd( year, -1, getdate() ) and screening_date <= dateadd( year, 1, getdate() ) ) )
end
else if @filter_type = 'C'
begin
	--Restrict to a certain cycle
	insert #dates ( screening_date, cycle, scroll_to_flag )
	select screening_date, billing_cycle, 'N'
	  from slide_screening_dates
	 where slide_screening_dates.billing_cycle = @cycle and
          ( ( @select_all = 'Y' ) or ( @select_all = 'N' and screening_date >= dateadd( year, -1, getdate() ) and screening_date <= dateadd( year, 1, getdate() ) ) )
end
else if @filter_type = 'B' --Branch
begin
	--Restrict to a certain cycle, first look up branch billing_cycle
	select @cycle = billing_cycle from branch where branch_code = @branch
 
	insert #dates ( screening_date, cycle, scroll_to_flag )
	select screening_date, billing_cycle, 'N'
	  from slide_screening_dates
	 where slide_screening_dates.billing_cycle = @cycle and
          ( ( @select_all = 'Y' ) or ( @select_all = 'N' and screening_date >= dateadd( year, -1, getdate() ) and screening_date <= dateadd( year, 1, getdate() ) ) )
end
else
begin
	insert #dates ( screening_date, cycle, scroll_to_flag )
	select screening_date, billing_cycle, 'N'
	  from slide_screening_dates
    where ( ( @select_all = 'Y' ) or ( @select_all = 'N' and screening_date >= dateadd( year, -1, getdate() ) and screening_date <= dateadd( year, 1, getdate() ) ) )
end 

update #dates 
   set scroll_to_flag = 'Y' 
  from #status
 where #dates.screening_date = #status.screening_date and
		 ( @default_open = 'A' and 
			( 
				( @default_pos = 'L' and 
				  #dates.screening_date = (select max(#dates.screening_date) from #status,#dates where #dates.screening_date = #status.screening_date)
				) OR
				( @default_pos = 'F' and 
				  #dates.screening_date = (select min(#dates.screening_date) from #status,#dates where #dates.screening_date = #status.screening_date)
				)
			)
		 ) OR ( (@default_open = 'X' or @default_open = 'O') and 
			(
				( @default_pos = 'L' and 
				  #dates.screening_date = (select max(#dates.screening_date) from #status,#dates where #dates.screening_date = #status.screening_date and status = @default_open) 
				) OR
				( @default_pos = 'F' and 
				  #dates.screening_date = (select min(#dates.screening_date) from #status,#dates where #dates.screening_date = #status.screening_date and status = @default_open) 
				)
		 	)
		 ) 

--Return
select #dates.screening_date,
		 #dates.cycle,
		 #dates.scroll_to_flag,
		 #status.status,
		 @status_description as status_label
  from #dates, #status
 where #dates.screening_date = #status.screening_date
order by #dates.screening_date


return 0
GO
