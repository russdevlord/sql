/****** Object:  StoredProcedure [dbo].[p_pda_campaign_market_summary]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_pda_campaign_market_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_pda_campaign_market_summary]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_pda_campaign_market_summary]		@campaign_no		int

as

declare		@screening_date				datetime,
			@market_code_1				char(3),
			@market_code_2				char(3),
			@market_code_3				char(3),
			@market_no_1				int,
			@market_no_2				int,
			@market_no_3				int,
			@spot_count_1				int,
			@spot_count_2				int,
			@spot_count_3				int,
			@product_desc				varchar(100)

create table #campaign_summary
(
	campaign_no				int				null,
	product_desc			varchar(100) 	null,
	screening_date			datetime		null,
	market_code_1			char(3)			null,
	market_code_2			char(3)			null,
	market_code_3			char(3)			null,
	market_no_1				int				null,
	market_no_2				int				null,
	market_no_3				int				null,
	spot_count_1			int				null,
	spot_count_2			int				null,
	spot_count_3			int				null
)

declare 	campaign_csr cursor for
select		distinct screening_date
from		campaign_spot
where		spot_type <> 'M' 
and 		spot_type <> 'V' 
and 		spot_type <> 'R' 
and			campaign_no = @campaign_no
and			screening_date is not null
group by 	screening_date
order by 	screening_date
for			read only

select 	@product_desc = product_desc
from	film_campaign 
where	campaign_no = @campaign_no

open campaign_csr
fetch campaign_csr into @screening_date
while(@@fetch_status = 0)
begin

	declare 	market_csr cursor for
	select		film_market_no,
				film_market_code
	from 		film_market
	where		film_market_no in (	select 		film_market_no 
									from 		complex, 
												campaign_spot 
									where 		campaign_spot.complex_id = complex.complex_id 
									and 		spot_type <> 'M' 
									and 		spot_type <> 'V' 
									and 		spot_type <> 'R' 
									and			campaign_no = @campaign_no
									and			screening_date = @screening_date)
	group by 	film_market_no,
				film_market_code
	order by	film_market_no
	for			read only

	select 	@market_code_1 = null,
			@market_code_2 = null,
			@market_code_3 = null,
			@market_no_1 = null,
			@market_no_2 = null,
			@market_no_3 = null,
			@spot_count_1 = null,
			@spot_count_2 = null,
			@spot_count_3 = null
	
	open market_csr
	fetch market_csr into @market_no_1, @market_code_1
	while(@@fetch_status = 0)
	begin

		select 		@spot_count_1 = count(spot_id)
		from		complex, 
					campaign_spot 
		where 		campaign_spot.complex_id = complex.complex_id 
		and 		spot_type <> 'M' 
		and 		spot_type <> 'V' 
		and 		spot_type <> 'R' 
		and			campaign_no = @campaign_no
		and			film_market_no = @market_no_1
		and			screening_date = @screening_date
		
	
		fetch market_csr into @market_no_2, @market_code_2

		if @@fetch_status = 0
		begin
			select 		@spot_count_2 = count(spot_id)
			from		complex, 
						campaign_spot 
			where 		campaign_spot.complex_id = complex.complex_id 
			and 		spot_type <> 'M' 
			and 		spot_type <> 'V' 
			and 		spot_type <> 'R' 
			and			campaign_no = @campaign_no
			and			film_market_no = @market_no_2
			and			screening_date = @screening_date
		end

		fetch market_csr into @market_no_3, @market_code_3

		if @@fetch_status = 0
		begin
			select 		@spot_count_3 = count(spot_id)
			from		complex, 
						campaign_spot 
			where 		campaign_spot.complex_id = complex.complex_id 
			and 		spot_type <> 'M' 
			and 		spot_type <> 'V' 
			and 		spot_type <> 'R' 
			and			campaign_no = @campaign_no
			and			film_market_no = @market_no_3
			and			screening_date = @screening_date

		end

		insert into #campaign_summary 
		values (@campaign_no,
				@product_desc,
				@screening_date,
				@market_code_1,
				@market_code_2,
				@market_code_3,
				@market_no_1,
				@market_no_2,
				@market_no_3,
				@spot_count_1,
				@spot_count_2,
				@spot_count_3)

		select 	@market_code_1 = null,
				@market_code_2 = null,
				@market_code_3 = null,
				@market_no_1 = null,
				@market_no_2 = null,
				@market_no_3 = null,
				@spot_count_1 = null,
				@spot_count_2 = null,
				@spot_count_3 = null

		fetch market_csr into @market_no_1, @market_code_1

	end
	
	deallocate market_csr

	fetch campaign_csr into @screening_date
end

deallocate campaign_csr

declare 	market_csr cursor for
select		film_market_no,
			film_market_code
from 		film_market
where		film_market_no in (	select 		film_market_no 
								from 		complex, 
											campaign_spot 
								where 		campaign_spot.complex_id = complex.complex_id 
								and 		spot_type <> 'M' 
								and 		spot_type <> 'V' 
								and 		spot_type <> 'R' 
								and			campaign_no = @campaign_no)
group by 	film_market_no,
			film_market_code
order by	film_market_no
for			read only

select 	@market_code_1 = null,
		@market_code_2 = null,
		@market_code_3 = null,
		@market_no_1 = null,
		@market_no_2 = null,
		@market_no_3 = null,
		@spot_count_1 = null,
		@spot_count_2 = null,
		@spot_count_3 = null

open market_csr
fetch market_csr into @market_no_1, @market_code_1
while(@@fetch_status = 0)
begin

	select 		@spot_count_1 = count(spot_id)
	from		complex, 
				campaign_spot 
	where 		campaign_spot.complex_id = complex.complex_id 
	and 		spot_type <> 'M' 
	and 		spot_type <> 'V' 
	and 		spot_type <> 'R' 
	and			campaign_no = @campaign_no
	and			film_market_no = @market_no_1
	

	fetch market_csr into @market_no_2, @market_code_2

	if @@fetch_status = 0
	begin
		select 		@spot_count_2 = count(spot_id)
		from		complex, 
					campaign_spot 
		where 		campaign_spot.complex_id = complex.complex_id 
		and 		spot_type <> 'M' 
		and 		spot_type <> 'V' 
		and 		spot_type <> 'R' 
		and			campaign_no = @campaign_no
		and			film_market_no = @market_no_2
	end

	fetch market_csr into @market_no_3, @market_code_3

	if @@fetch_status = 0
	begin
		select 		@spot_count_3 = count(spot_id)
		from		complex, 
					campaign_spot 
		where 		campaign_spot.complex_id = complex.complex_id 
		and 		spot_type <> 'M' 
		and 		spot_type <> 'V' 
		and 		spot_type <> 'R' 
		and			campaign_no = @campaign_no
		and			film_market_no = @market_no_3

	end

	insert into #campaign_summary 
	values (@campaign_no,
			@product_desc,
			'31-dec-4000',
			@market_code_1,
			@market_code_2,
			@market_code_3,
			@market_no_1,
			@market_no_2,
			@market_no_3,
			@spot_count_1,
			@spot_count_2,
			@spot_count_3)

	select 	@market_code_1 = null,
			@market_code_2 = null,
			@market_code_3 = null,
			@market_no_1 = null,
			@market_no_2 = null,
			@market_no_3 = null,
			@spot_count_1 = null,
			@spot_count_2 = null,
			@spot_count_3 = null

	fetch market_csr into @market_no_1, @market_code_1

end

deallocate market_csr

select * from #campaign_summary order by screening_date, market_no_1

return 0
GO
