/****** Object:  StoredProcedure [dbo].[p_print_certificate_all]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_print_certificate_all]
GO
/****** Object:  StoredProcedure [dbo].[p_print_certificate_all]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_print_certificate_all]		@complex_id					int,
																				@screening_date			datetime,
																				@mode							char(1)
as
set nocount on 
/*
 * Declare Variables
 */

declare		@error     						integer,
					@group_no_1			integer,
					@group_no_2			integer,
					@group_no_3			integer,
					@group_no_4			integer

/*
 * Create Temporary Tables
 */

create table #cert_items
(
	complex_id					integer				null,
	screening_date			datetime			null,
	group_no_1					smallint				null,
	group_no_2					smallint				null,
	group_no_3					smallint				null,
	group_no_4					smallint				null
)

/*
 * Declare Cursor
 */

declare			complex_csr cursor static for 
select			distinct certificate_group.group_no
from				certificate_group
where			certificate_group.complex_id = @complex_id 
and					certificate_group.screening_date = @screening_date 
and					((@mode = 'S'
and					left(group_name, 13) = 'Cinema Screen')
or					(@mode = 'M'
and					left(group_name, 13) <> 'Cinema Screen'))
order by		certificate_group.group_no
for					read only

/*
 * Begin Collection Dataset
 */

open complex_csr
fetch complex_csr into @group_no_1
while(@@fetch_status=0)
begin

	fetch complex_csr into @group_no_2

	if @@fetch_status<>0
		select @group_no_2 = null

	fetch complex_csr into @group_no_3

	if @@fetch_status<>0
		select @group_no_3 = null

	fetch complex_csr into @group_no_4

	if @@fetch_status<>0
		select @group_no_4 = null

	insert into #cert_items
	(
	complex_id,
	screening_date,
	group_no_1,
	group_no_2,
	group_no_3,
	group_no_4
	) values
	(
	@complex_id,
	@screening_date,
	@group_no_1,
	@group_no_2,
	@group_no_3,
	@group_no_4
	)

	fetch complex_csr into @group_no_1
end

close complex_csr
deallocate  complex_csr

/*
 * Select dataset and return
 */

select * from #cert_items order by #cert_items.group_no_1
return 0
GO
