/****** Object:  StoredProcedure [dbo].[p_client_on_off_report]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_client_on_off_report]
GO
/****** Object:  StoredProcedure [dbo].[p_client_on_off_report]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_client_on_off_report]		@old_date		datetime,
													@current_date	datetime,
													@complex_id		integer,
													@branch_code	char(3)
as

declare  @carousel_id					integer,
		   @line_id							integer

create table #results
(
 	carousel_id		integer		null,
   line_id			integer		null,
   screening_id	integer		null,
   status			char(3)		null
)

create table #screenings_old
(
	carousel_id			integer		null,
	line_id				integer		null,
   screening_id		integer		null
)

create table #screenings_current
(
	carousel_id			integer		null,
	line_id				integer		null,
   screening_id		integer		null
)


declare	complex_csr cursor static for
select 	complex_id
from 	complex
where 	complex_id = (case when @complex_id > 0 then @complex_id else complex_id end)
and		branch_code = (case when @complex_id > 0 then branch_code else @branch_code end)
order by complex_id
for read only

open complex_csr
fetch complex_csr into @complex_id
while(@@fetch_status = 0) 
begin

	insert into #screenings_old (
		carousel_id,
		line_id,
      screening_id
	)
	select scs.carousel_id,
			 scs.campaign_line_id,
          scs.campaign_screening_id
	  from slide_campaign_screening scs
	 where scs.screening_date = @old_date and
			 scs.complex_id = @complex_id 
	

	insert into #screenings_current (
		carousel_id,
		line_id,
      screening_id
	)
	select scs.carousel_id,
			 scs.campaign_line_id,
          scs.campaign_screening_id
	  from slide_campaign_screening scs
	 where scs.screening_date = @current_date and
			 scs.complex_id = @complex_id 
	
	/*
	 *	Form the difference of the 2 sets.
	 */
	
	insert into #results ( carousel_id, line_id, screening_id, status )
	select distinct carousel_id, line_id, screening_id, 'OFF'
	  from #screenings_old so
	 where not exists
			 (select *
			  from #screenings_current sc
			  where sc.carousel_id = so.carousel_id AND
					  sc.line_id = so.line_id)

	 insert into #results ( carousel_id, line_id, screening_id, status )
	 select distinct carousel_id, line_id, screening_id, 'ON '
	   from #screenings_current sc
	  where not exists 
	 		 (select *
		 	  from #screenings_old so
		 	  where sc.carousel_id = so.carousel_id AND
			 		  sc.line_id = so.line_id) 

	truncate table #screenings_current
	truncate table #screenings_old

	fetch complex_csr into @complex_id
end
deallocate complex_csr


select scs.carousel_id,
		 scs.campaign_line_id,
		 sc.campaign_no,
		 sc.name_on_slide,
		 com.complex_name,
		 car.carousel_code,
		 cl.line_no,
		 cl.line_desc,
		 branch.branch_name,
       r.status
  from #results r,
       slide_campaign_screening scs,
		 campaign_line cl,
		 slide_campaign sc,
		 complex com,
		 carousel car,
	    branch
 where scs.campaign_screening_id = r.screening_id and
       scs.campaign_line_id = cl.campaign_line_id and
		 scs.carousel_id = car.carousel_id and
		 scs.complex_id = com.complex_id and
		 cl.campaign_no = sc.campaign_no and
		 com.branch_code = branch.branch_code

return 0
GO
