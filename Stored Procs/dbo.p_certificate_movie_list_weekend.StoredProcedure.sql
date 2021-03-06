/****** Object:  StoredProcedure [dbo].[p_certificate_movie_list_weekend]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_movie_list_weekend]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_movie_list_weekend]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_certificate_movie_list_weekend] 
	@campaign_no			integer,
                                     	@package_id				integer,
                                     	@instruction_type		tinyint,
										@complex_id				int,
										@screening_date			datetime
as   
----****	for testing		****
--declare	@campaign_no			integer,
--		@package_id				integer,
--		@instruction_type		tinyint,
--		@complex_id				int,
--		@screening_date			datetime
--set @campaign_no = 208367
--set @package_id = 26682
--set @instruction_type = 1
--set @complex_id = 124 
--set @screening_date = '2014-02-13'

/*
 * Declare Variables
 */

declare @error						int,
        @errorode						int,
		@three_d_type_pack			int,
		@three_d_type_movie			int,
		@three_d_sort				int,
		@movie_id					int,
		@sequence_no				int,
		@occurence					int,
		@screen_flag				char(1) 


create table #movie_list
(
	campaign_no			int 	not null,
	package_id			int		not null,
	movie_id			int		not null,
	instruction_type 	int		not null,
	sequence_no			int		not null,
	alloc_here			int		not null,
	alloc_tot			int		not null,
	bookmark			char(1)	not null,
	three_d				int		not null,
	occurence			int		not null
)

/*
 * Load Package 3D 
 */

select 	@three_d_type_pack 	= count(print_package.print_package_id)
from	print_package,
		print_package_three_d
where	print_package.print_package_id = print_package_three_d.print_package_id
and		print_package.package_id = @package_id
and		three_d_type > 1

/*
 * Select Movie List
 */

declare 	movie_csr cursor for
select 		msi.movie_id,
			msi.sequence_no  
			,'f' as screen_flag
from 		campaign_package pack,   
       		movie_screening_instructions msi  
where 		pack.campaign_no = @campaign_no 
and			pack.package_id = @package_id 
and			pack.package_id = msi.package_id 
and			msi.instruction_type = @instruction_type  
union
	select 102 as movie_id
	,film_plan_id as sequence
	,'t' as screen_flag
	from campaign_spot
	where film_plan_id is not null
	and complex_id = @complex_id
	and screening_date = @screening_date
	and package_id = @package_id
	order by	movie_id,
				sequence_no 
			
			
for read only
open movie_csr
fetch movie_csr into @movie_id, @sequence_no, @screen_flag
while(@@fetch_status=0)
begin

	select @three_d_sort = 0
	
	if @screen_flag = 't'
	begin
		select @occurence = occurence
		from	movie_history_weekend_prerun
		where	complex_id = @complex_id
		and		screening_date = @screening_date
		and		movie_id = @movie_id
		and		occurence = @sequence_no
	end
	else
	begin
		select @occurence = occurence
		from	movie_history_weekend_prerun
		where	complex_id = @complex_id
		and		screening_date = @screening_date
		and		movie_id = @movie_id
	end

	if @three_d_type_pack > 0
	begin
		select 	@three_d_type_movie = count(movie_id)
		from	movie_history_weekend_prerun
		where	complex_id = @complex_id
		and		screening_date = @screening_date
		and		movie_id = @movie_id
		and 	three_d_type > 1

		if @three_d_type_movie > 0 
			select @three_d_sort = 1
		else
			select @three_d_sort = 0

	end
	else
	begin
		select @three_d_sort = 0
	end
	
	if @occurence is null
	begin
		set @occurence = 1
	end

	insert into #movie_list values (@campaign_no, @package_id, @movie_id, @instruction_type,@sequence_no, 0, 0, 'N', @three_d_sort,@occurence)

	fetch movie_csr into @movie_id, @sequence_no, @screen_flag
end

select * from #movie_list
--return 0
GO
