/****** Object:  StoredProcedure [dbo].[p_cert_report_return_slip]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cert_report_return_slip]
GO
/****** Object:  StoredProcedure [dbo].[p_cert_report_return_slip]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cert_report_return_slip] @complex_id			int,
                                 @screening_date	datetime
as

/*
 * Declare Variables
 */

declare @error     			integer,
		  @group_no_1			integer,
		  @group_no_2			integer,
		  @group_no_3			integer,
		  @state_code			char(2),
		  @complex_name		varchar(50),
		  @fax_no				varchar(30),
		  @contractor_code	char(3),
		  @complex_branch		char(2),
		  @address_category	char(3)	

/*
 * Create Temporary Tables
 */

create table #cert_items
(
	complex_id			integer				null,
	screening_date		datetime				null,
	complex_name		varchar(50)			null,
	state_code			char(2)				null,
	group_no_1			smallint				null,
	group_no_2			smallint				null,
	group_no_3			smallint				null,
	fax_no				varchar(30)			null
)

/*
 * Get Certificate Address Information
 */

select @contractor_code = contractor_code,
       @complex_branch = branch_code
  from complex
 where complex_id = @complex_id

if(@contractor_code = 'Val')
	select @address_category = 'fsc'
else
	select @address_category = 'isc'

select @fax_no = address_5
  from branch_address with (nolock)
 where branch_code = @complex_branch and
       address_category = @address_category

/*
 * Begin Collection Dataset
 */

select @state_code = state_code,
		 @complex_name = complex_name
  from complex with (nolock)
 where complex_id = @complex_id

/*
 * Declare Cursor
 */

 declare complex_csr cursor static for 
  select distinct certificate_group.group_no
    from certificate_group with (nolock)/*,
         certificate_item*/
   where certificate_group.complex_id = @complex_id and
		   certificate_group.screening_date = @screening_date /*and 
         certificate_group.certificate_group_id = certificate_item.certificate_group and
         certificate_item.item_show = 'Y' */
order by certificate_group.group_no
	  for read only

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

	insert into #cert_items
	(
	complex_id,
	screening_date,
	complex_name,
	state_code,
	group_no_1,
	group_no_2,
	group_no_3,
	fax_no
	) values
	(
	@complex_id,
	@screening_date,
	@complex_name,
	@state_code,
	@group_no_1,
	@group_no_2,
	@group_no_3,
	@fax_no
	)

	fetch complex_csr into @group_no_1
end

close complex_csr
deallocate complex_csr

/*
 * Select dataset and return
 */

select * from #cert_items order by #cert_items.group_no_1
return 0
GO
