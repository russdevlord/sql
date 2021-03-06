/****** Object:  StoredProcedure [dbo].[p_cert_report_return_slip_sub]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cert_report_return_slip_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_cert_report_return_slip_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cert_report_return_slip_sub]	 @complex_id			integer,
                                 					@screening_date			datetime,
													@group_no				integer

as

/*
 * Declare Variables
 */

declare @error     			integer,
        @rowcount       	integer,
        @group_count			integer,
        @contractor_code	char(3),
        @complex_branch		char(2),
        @address1				varchar(50),
        @address2				varchar(50),
        @address3				varchar(50),
        @address4				varchar(50),
        @address5				varchar(50),
        @address_category	char(3)

/*
 * Create Temporary Tables
 */

create table #cert_items
(
	group_name		varchar(60)			null,
	sequence_no		smallint				null,
	print_name		varchar(50)			null,
	is_movie			char(1)				null,
	print_type		char(1)				null
)


/*
 * Insert Certificate Items into Temporary Table
 */

insert into #cert_items
select certificate_group.group_name,
	certificate_item.sequence_no,
	film_print.print_name,
	certificate_group.is_movie,
	film_print.print_type
from certificate_group with (nolock),
	certificate_item with (nolock),
	film_print with (nolock)
where certificate_group.complex_id = @complex_id and
	certificate_group.screening_date = @screening_date and 
	certificate_group.certificate_group_id = certificate_item.certificate_group and
	certificate_item.item_show = 'Y' and
	certificate_item.print_id = film_print.print_id and
	certificate_group.group_no = @group_no

select @group_count = @@rowcount

if @group_count = 0
	insert into #cert_items
	SELECT	certificate_group.group_name, 
			NULL, 
			'NO BOOKINGS THIS WEEK', 
			certificate_group.is_movie, 
			'' AS Expr3
	FROM	certificate_group  with (nolock) LEFT OUTER JOIN
						  certificate_item  with (nolock) ON certificate_group.certificate_group_id = certificate_item.certificate_group
	WHERE	(certificate_group.complex_id = @complex_id) 
	AND		(certificate_group.screening_date = @screening_date) 
	AND		(certificate_group.group_no = @group_no)

  select	#cert_items.group_name,
			#cert_items.sequence_no,
			#cert_items.print_name,
			#cert_items.is_movie,
			#cert_items.print_type
    from	#cert_items
order by	#cert_items.sequence_no

return 0
GO
