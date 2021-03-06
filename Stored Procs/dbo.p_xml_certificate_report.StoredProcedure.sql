/****** Object:  StoredProcedure [dbo].[p_xml_certificate_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_xml_certificate_report]
GO
/****** Object:  StoredProcedure [dbo].[p_xml_certificate_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_xml_certificate_report]		@complex_id			int,
												@screening_date	datetime
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
create table #cert_items (
	group_no			    smallint			null,
	group_name		        varchar(60)			null,
	is_movie			    char(1)				null,
	sequence_no		        smallint			null,
	item_comment	        varchar(100)		null,
	campaign_no		        int 				null,
	print_id		        int 				null,
	print_name		        varchar(50)			null,
	duration			    smallint			null,
	sound_format	        char(1)				null,
	print_ratio		        char(1)				null,
    client			        varchar(30)			null,
    times_in		        int 				null,
	print_type              char(1)				null,
    certificate_source      char(1)             null,
    uuid                    char(36)            null
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

select @address1 = address_1,
		 @address2 = address_2,
		 @address3 = address_3,
		 @address4 = address_4,
		 @address5 = address_5
  from branch_address
 where branch_code = @complex_branch and
       address_category = @address_category

/*
 * Insert Certificate Items into Temporary Table
 */

insert      into #cert_items
--select      certificate_group.group_no,
--            certificate_group.group_name,
--            certificate_group.is_movie,
--            certificate_item.sequence_no,
--            certificate_item.item_comment,
--            campaign_spot.campaign_no,
--            film_print.print_id,
--            film_print.print_name,
--            film_print.duration,
--            film_print.sound_format,
--            film_print.print_ratio,
--            null,
--            (select     count(ci.certificate_item_id)
--            from        certificate_item ci,
--                        certificate_group cg
--            where       certificate_item.print_id = ci.print_id 
--            and         ci.certificate_group = cg.certificate_group_id 
--            and         cg.complex_id = @complex_id 
--            and         cg.screening_date < @screening_date),
--            film_print.print_type,
--            certificate_item.certificate_source,
--            uuid = (select uuid from film_print_file_locations where print_id = film_print.print_id)
--from        certificate_group,
--            certificate_item,
--            film_print,
--            campaign_spot
--where       certificate_group.complex_id = @complex_id 
--and         certificate_group.screening_date = @screening_date 
--and         certificate_group.certificate_group_id = certificate_item.certificate_group 
--and         certificate_item.item_show = 'Y' 
--and         certificate_item.print_id = film_print.print_id 
--and         campaign_spot.spot_id =* certificate_item.spot_reference
SELECT	certificate_group.group_no, 
		certificate_group.group_name, 
		certificate_group.is_movie, 
		certificate_item.sequence_no, 
		certificate_item.item_comment, 
		campaign_spot.campaign_no, 
		film_print.print_id, 
		film_print.print_name, 
		film_print.duration, 
		film_print.sound_format, 
		film_print.print_ratio, 
		NULL,
		(	SELECT	COUNT(ci.certificate_item_id)
			FROM	certificate_item AS ci INNER JOIN
					certificate_group AS cg ON ci.certificate_group = cg.certificate_group_id
			WHERE	(certificate_item.print_id = ci.print_id) 
			AND		(cg.complex_id = @complex_id) 
			AND		(cg.screening_date < @screening_date)), 
		film_print.print_type, 
		certificate_item.certificate_source,
		(	SELECT	uuid
			FROM	film_print_file_locations
			WHERE	(print_id = film_print.print_id)) AS uuid
FROM	certificate_group INNER JOIN
		certificate_item ON certificate_group.certificate_group_id = certificate_item.certificate_group INNER JOIN
		film_print ON certificate_item.print_id = film_print.print_id LEFT OUTER JOIN
		campaign_spot ON certificate_item.spot_reference = campaign_spot.spot_id
WHERE	(certificate_group.complex_id = @complex_id) 
AND		(certificate_group.screening_date = @screening_date) 
AND		(certificate_item.item_show = 'Y')

select @group_count = @@rowcount

/*
 * Insert Certificate Items for Groups with No Bookings
 */
insert into #cert_items
select	certificate_group.group_no,
		min(certificate_group.group_name),
		min(certificate_group.is_movie),
		1,
		null,
		null,
		null,
		'NO BOOKINGS THIS WEEK',
		0,
		null,
		null,
		null,
		0,
		null,
		null,
		null
--from	certificate_group,
--		certificate_item
--where	certificate_group.certificate_group_id *= certificate_item.certificate_group
--		certificate_group.complex_id = @complex_id and
--		certificate_group.screening_date = @screening_date and
FROM	certificate_group LEFT OUTER JOIN
                      certificate_item ON certificate_group.certificate_group_id = certificate_item.certificate_group		
WHERE	certificate_group.complex_id = @complex_id and
		certificate_group.screening_date = @screening_date
group by certificate_group_id,
		certificate_group.group_no
having count(certificate_item_id) = 0

select @rowcount = @@rowcount
select @group_count = @group_count + @rowcount

update #cert_items
   set client = client.client_short_name
  from film_campaign fc,
       client
 where #cert_items.campaign_no = fc.campaign_no and
       fc.client_id = client.client_id

/*
 * Return Result Set
 */

select	@screening_date as screening_date,
        cplx.complex_name,
        cplx.manager,
        cplx.address_1,
        cplx.address_2,
        convert(varchar(30),cplx.town_suburb) as suburb,
        cplx.state_code,
        cplx.postcode,
        cplx.fax,
        cplx.certificate_send_method,
        cplx.email,
        cd.certificate_revision,
        @complex_branch as complex_branch,
        @address1 as address_1,
        @address2 as address_2,
        @address3 as address_3,
        @address4 as address_4,
        @address5 as address_5,
        #cert_items.group_no,
        #cert_items.group_name,
        #cert_items.is_movie,
        #cert_items.sequence_no,
        #cert_items.item_comment,
        #cert_items.print_name,
        convert(varchar(6),#cert_items.duration) + ' sec'  as duration,
        #cert_items.sound_format,
        #cert_items.print_ratio,
        #cert_items.client,
        #cert_items.times_in,
        @group_count as group_count,
        #cert_items.print_type,
        #cert_items.print_id,
        #cert_items.certificate_source,
        cd.certificate_comment,
        @contractor_code as contractor_code,
        bm.branch_message_text,
        #cert_items.uuid
--from	complex_date cd,
--		complex     cplx,
--		#cert_items,
--		branch_message bm
--where       cd.complex_id = @complex_id 
--and         cd.screening_date = @screening_date 
--and         cd.complex_id = cplx.complex_id 
--and         cplx.complex_id = @complex_id 
--and         cplx.branch_code *= bm.branch_code 
--and         bm.message_category_code = 'C'
FROM	complex_date AS cd INNER JOIN
		complex AS cplx ON cd.complex_id = cplx.complex_id LEFT OUTER JOIN
		branch_message AS bm ON cplx.branch_code = bm.branch_code CROSS JOIN
		#cert_items
WHERE	(cd.complex_id = @complex_id) 
AND		(cd.screening_date = @screening_date) 
AND		(cplx.complex_id = @complex_id) 
AND		(bm.message_category_code = 'C')

order by #cert_items.group_no
GO
