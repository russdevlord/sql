/****** Object:  StoredProcedure [dbo].[p_arclist_film_screening_date]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_arclist_film_screening_date]
GO
/****** Object:  StoredProcedure [dbo].[p_arclist_film_screening_date]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_arclist_film_screening_date] 
as

/*
 * Declare Variables
 */

declare @error     					integer,
		  @screening_date				datetime,
		  @certificate_group			integer,
		  @screening_date_status	char(1),
	     @complex_date_removed 	char(1),
		  @certificate_removed		char(1),
		  @screening_date_csr_open	integer,
		  @item_count					integer

set nocount on

/*
 * Create a temp table for returning results
 */

create table #screening_date
(
	screening_date				datetime			null,
	certificate_item			integer			null,
	screening_date_status	char(1)			null,
	complex_date_removed		char(1)			null,
	certificate_removed		char(1)			null
)

/*
 * Initialise Variables
 */

select @screening_date_csr_open = 0

/*
 * Declare Fillm Screening Date Cursor
 */ 

  declare screening_date_csr cursor static for
   select fsd.screening_date,
			 fsd.screening_date_status,
			 fsd.complex_date_removed,
			 fsd.screening_certificate_removed
     from film_screening_dates fsd
 order by fsd.screening_date
	    for read only

/*
 * Loop through Screening Dates
 */

open screening_date_csr
fetch screening_date_csr into @screening_date, @screening_date_status, @complex_date_removed, @certificate_removed							
while(@@fetch_status=0)
begin

	if @certificate_removed = 'N'
	begin
		select @item_count = count(ci.certificate_item_id)
		  from certificate_item ci,
				 certificate_group cg
		 where cg.screening_date = @screening_date and
				 cg.certificate_group_id = ci.certificate_group and
				 ci.campaign_summary = 'N'
	end
	else
    begin
		select @item_count = 0
    end

		/*
		 * Insert Values into Temp Table #screening_date
		 */

     	insert into #screening_date values ( @screening_date,
														 @item_count,
														 @screening_date_status,
														 @complex_date_removed,
														 @certificate_removed )		

		select @error = @@error
		if (@error != 0)
		begin
            deallocate screening_date_csr
			raiserror ( 'p_arclist_film_screening_date:insert', 16, 1) 
			return -1
		end	
	
	/*
	 * Fetch Next Screening Date
	 */

	fetch screening_date_csr into @screening_date, @screening_date_status, @complex_date_removed, @certificate_removed							

end

/*
 * Close Movie History Cursor
 */

deallocate screening_date_csr

/*
 * Return Results
 */

  select screening_date,
			certificate_item,
			screening_date_status,
			complex_date_removed,
			certificate_removed
    from #screening_date
order by screening_date asc

/*
 * Return
 */

return 0
GO
