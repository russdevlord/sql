/****** Object:  StoredProcedure [dbo].[p_cin_agr_complex_disc_rep]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cin_agr_complex_disc_rep]
GO
/****** Object:  StoredProcedure [dbo].[p_cin_agr_complex_disc_rep]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cin_agr_complex_disc_rep]	

as

/*
 * Declare
 */

declare		@error							integer,
			@complex_id						integer,
			@today							datetime,
			@film_complex_status			char(1),
			@slide_complex_status			char(1),
			@records_exist					integer,
			@cinema_agreement_id			integer,
			@rent_inclusion_start			datetime,
			@rent_inclusion_end				datetime,
			@future_agreement				integer,
			@complex_name					varchar(50),
			@complex_agr_status				char(1),
			@agreement_no					char(6),
			@agreement_desc					varchar(50),
			@agreement_start				datetime,
			@agreement_end					datetime,
			@agreement_status				char(1),
			@message						varchar(60),
			@branch_code					char(2),
			@loop							integer,
			@exhibitor_id					integer,
			@exhibitor_name					varchar(50)

/*
 * Create temp table for select
 */
create table #complexes_disc (
		complex_id					integer			null,
		category_message			varchar(60)		null,
		complex_name				varchar(50)		null,
		slide_complex_status	    char(1)			null,
		film_complex_status			char(1)			null,
		complex_agr_status		    char(1)			null,
		rent_inclusion_start	    datetime		null,
		rent_inclusion_end		    datetime		null,
		agreement_no				char(6)			null,
		agreement_desc			    varchar(50)		null,
		agreement_start				datetime		null,
		agreement_end				datetime		null,
		agreement_status			char(1)			null,
		today						datetime		null,
		branch_code					char(2)			null,
		exhibitor_name			    varchar(50)		null
 )

/*
 * Initialise todays's date into a variable
 */
select @today = getdate()

/*
 * Declare cursor to loop over all active complexes.
 */
 declare complex_csr cursor static for
  select complex_id,
			complex_name,
			film_complex_status,
			NULL, --slide_complex_status,
			branch_code,
			exhibitor_id
    from complex 
order by complex_id
     for read only

open complex_csr
fetch complex_csr into @complex_id, @complex_name, @film_complex_status, @slide_complex_status, @branch_code, @exhibitor_id
while(@@fetch_status=0)
begin

	select @message = null,
			 @cinema_agreement_id = null,
			 @rent_inclusion_start = null,
			 @rent_inclusion_end = null,
			 @complex_agr_status = null,
			 @agreement_no = null,
			 @agreement_desc = null,
			 @agreement_start = null,
			 @agreement_end = null,
			 @agreement_status = null,
			 @exhibitor_name = exhibitor_name
     from exhibitor
    where exhibitor.exhibitor_id = @exhibitor_id

	if @film_complex_status = 'C' --and @slide_complex_status = 'C'
		select @records_exist = -10
	else
		select @records_exist = 0

	select @loop = 0

	/*
	 * Delcare cursor to loop over cinema_agreement_complex records
	 */

	 declare cinema_agreement_complex_csr cursor static for
	  select cinema_agreement_id,
				rent_inclusion_start,
				rent_inclusion_end,
				active_flag
		 from cinema_agreement_complex 
	   where complex_id = @complex_id and
				rent_inclusion_start <= @today and
				(rent_inclusion_end >= @today	or
				rent_inclusion_end is null)

	open cinema_agreement_complex_csr
	fetch cinema_agreement_complex_csr into @cinema_agreement_id, @rent_inclusion_start, @rent_inclusion_end, @complex_agr_status
	while(@@fetch_status=0)
	begin

			select @agreement_no = agreement_no,
					 @agreement_desc = agreement_desc,
					 @agreement_start = agreement_start,
					 @agreement_end = agreement_end,
					 @agreement_status = agreement_status
			  from cinema_agreement
			 where cinema_agreement_id = @cinema_agreement_id

			if @film_complex_status <> 'C' --or @slide_complex_status <> 'C'
					and @agreement_status <> 'D' and @agreement_status <> 'X'
				select @records_exist = @records_exist + 1,
						 @message = null

			if @film_complex_status = 'C' --and @slide_complex_status = 'C' 
					and @agreement_status <> 'D' and @agreement_status <> 'X'
				select @message = 'Closed Complex Active on a Valid Agreement',
						 @records_exist = -10

			if @film_complex_status = 'C' --and @slide_complex_status = 'C' 
					and (@agreement_status = 'D' or @agreement_status = 'X')
				select @message = 'Closed Complex Active on an Invalid Agreement',
						 @records_exist = -10

			if @film_complex_status <> 'C' --or @slide_complex_status <> 'C'
					and (@agreement_status = 'D' or @agreement_status = 'X')
				select @message = 'Open Complex Active on an Invalid Agreement',
						 @records_exist = -10

			if @film_complex_status <> 'C' --or @slide_complex_status <> 'C'
					and @rent_inclusion_end < dateadd(mm, 3, @today) and @agreement_status <> 'D' and @agreement_status <> 'X'
			begin
				
				select @future_agreement = count(cinema_agreement_id)
				  from cinema_agreement_complex
				 where complex_id = @complex_id and
						 rent_inclusion_start > @rent_inclusion_end and
						 rent_inclusion_start <= dateadd(mm,3,@today)

				if @future_agreement = 0 
					select @message = 'Complex expires from all agreements within 3 months',
							 @records_exist = -10
				end
	
			if @message is not null
				insert into #complexes_disc
				(complex_id,
				 category_message,
				 complex_name,
				 slide_complex_status,
				 film_complex_status,
				 complex_agr_status,
				 rent_inclusion_start,
				 rent_inclusion_end,
				 agreement_no,
				 agreement_desc,
				 agreement_start,
				 agreement_end,
				 agreement_status,
				 today,
				 branch_code,
				 exhibitor_name) values	
				(@complex_id,
				 @message,
				 @complex_name,
				 @slide_complex_status,
				 @film_complex_status,
				 @complex_agr_status,
				 @rent_inclusion_start,
				 @rent_inclusion_end,
				 @agreement_no,
				 @agreement_desc,
				 @agreement_start,
				 @agreement_end,
				 @agreement_status,
				 @today,
				 @branch_code,
				 @exhibitor_name)

			select @loop = @loop + 1

		fetch cinema_agreement_complex_csr into @cinema_agreement_id, @rent_inclusion_start, @rent_inclusion_end, @complex_agr_status
	end
	close cinema_agreement_complex_csr
	deallocate cinema_agreement_complex_csr

	if @records_exist = 0
	begin
		select @message = 'No Valid Cinema Agreement for this Complex'

		insert into #complexes_disc
		(complex_id,
		 category_message,
		 complex_name,
		 slide_complex_status,
		 film_complex_status,
		 complex_agr_status,
		 rent_inclusion_start,
		 rent_inclusion_end,
		 agreement_no,
		 agreement_desc,
		 agreement_start,
		 agreement_end,
		 agreement_status,
		 today,
		 branch_code,
		 exhibitor_name) values	
		(@complex_id,
		 @message,
		 @complex_name,
		 @slide_complex_status,
		 @film_complex_status,
		 @complex_agr_status,
		 @rent_inclusion_start,
		 @rent_inclusion_end,
		 @agreement_no,
		 @agreement_desc,
		 @agreement_start,
		 @agreement_end,
		 @agreement_status,
		 @today,
		 @branch_code,
		 @exhibitor_name)
	end

	if @loop > 1 
	begin
		select @message = 'Complex on Multiple Agreements'
	
		insert into #complexes_disc
		(complex_id,
		 category_message,
		 complex_name,
		 slide_complex_status,
		 film_complex_status,
		 complex_agr_status,
		 rent_inclusion_start,
		 rent_inclusion_end,
		 agreement_no,
		 agreement_desc,
		 agreement_start,
		 agreement_end,
		 agreement_status,
		 today,
		 branch_code,
		 exhibitor_name) 
select @complex_id,
		 @message,
		 @complex_name,
		 @slide_complex_status,
		 @film_complex_status,
		 @complex_agr_status,
		 rent_inclusion_start,
		 rent_inclusion_end,
		 agreement_no,
		 agreement_desc,
		 agreement_start,
		 agreement_end,
		 agreement_status,
		 @today,
		 @branch_code,
		 @exhibitor_name
  from cinema_agreement,
		 cinema_agreement_complex
 where cinema_agreement.cinema_agreement_id = cinema_agreement_complex.cinema_agreement_id and
		 cinema_agreement_complex.complex_id = @complex_id
	end

	fetch complex_csr into @complex_id, @complex_name, @film_complex_status, @slide_complex_status, @branch_code, @exhibitor_id
end

close complex_csr
deallocate complex_csr

/* 
 * Select dataset and return
 */

select * from #complexes_disc order by complex_id

return 0
GO
