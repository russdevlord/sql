/****** Object:  StoredProcedure [dbo].[p_print_certificate_sub]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_print_certificate_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_print_certificate_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_print_certificate_sub] @complex_id			integer,
                                 	 @screening_date	datetime,
												 @group_no			integer

as
set nocount on 
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
	print_name		varchar(50)			null
)


/*
 * Insert Certificate Items into Temporary Table
 */

insert into #cert_items
select certificate_group.group_name,
       certificate_item.sequence_no,
       film_print.print_name
  from certificate_group,
       certificate_item,
       film_print
 where certificate_group.complex_id = @complex_id and
		 certificate_group.screening_date = @screening_date and 
       certificate_group.certificate_group_id = certificate_item.certificate_group and
       certificate_item.item_show = 'Y' and
       certificate_item.print_id = film_print.print_id and
		 certificate_group.group_no = @group_no

  insert into #cert_items
  select min(certificate_group.group_name),
         1,
         'NO BOOKINGS THIS WEEK'
FROM	certificate_group  with(nolock) LEFT OUTER JOIN
		certificate_item with(nolock) ON certificate_group.certificate_group_id = certificate_item.certificate_group
WHERE	(certificate_group.complex_id = @complex_id) 
AND		(certificate_group.screening_date = @screening_date) 
AND		(certificate_group.group_no = @group_no)
GROUP BY certificate_group.certificate_group_id, 
		certificate_group.group_no
HAVING      (COUNT(certificate_item.certificate_item_id) = 0)




  select #cert_items.group_name,
         #cert_items.sequence_no,
         #cert_items.print_name
    from #cert_items
order by #cert_items.sequence_no
return 0
GO
