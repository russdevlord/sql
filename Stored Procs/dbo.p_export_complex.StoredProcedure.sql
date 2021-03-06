/****** Object:  StoredProcedure [dbo].[p_export_complex]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_export_complex]
GO
/****** Object:  StoredProcedure [dbo].[p_export_complex]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_export_complex]		@complex_id			int,
										@screening_date		datetime
as

declare @error     			int,
        @rowcount			int,
        @group_count		int

/*
 * Create Temporary Tables
 */
create table #cert_items (
		group_no			smallint			null,
		group_name			varchar(60)			null,
		is_movie			char(1)				null,
		sequence_no			smallint			null,
		item_comment		varchar(100)		null,
		campaign_no			integer				null,
		print_id			integer				null,
		print_name			varchar(50)			null,
		duration			smallint			null,
		sound_format		char(1)				null,
		print_ratio			char(1)				null,
		client				varchar(30)			null,
		times_in			integer				null,
		print_type			char(1)				null
)

/*
 * Insert Certificate Items into Temporary Table
 */
insert into #cert_items
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
        0, 
        film_print.print_type
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
		null
FROM	certificate_group INNER JOIN
		certificate_item ON certificate_group.certificate_group_id = certificate_item.certificate_group
where	certificate_group.complex_id = @complex_id and
		certificate_group.screening_date = @screening_date
group by certificate_group_id,
		certificate_group.group_no
having count(certificate_item_id) = 0

select @rowcount = @@rowcount
select @group_count = @group_count + @rowcount

/*
 * Update Client
 */
update #cert_items
   set client = client.client_short_name
  from film_campaign fc,
       client
 where #cert_items.campaign_no = fc.campaign_no and
       fc.client_id = client.client_id

/*
 * Update Times In
 */
update #cert_items
   set times_in = ( 
select count(ci.certificate_item_id)
  from certificate_item ci,
       certificate_group cg
 where #cert_items.print_id = ci.print_id and
       ci.certificate_group = cg.certificate_group_id and
       cg.complex_id = @complex_id and
       cg.screening_date < @screening_date )

/*
 * Return Result Set
 */
if (@group_count=0)
	begin
		select @screening_date as screening_date,
			cplx.complex_name,
			cplx.manager,
			cplx.address_1,
			cplx.address_2,
			convert(varchar(30),cplx.town_suburb),
			cplx.state_code,
			cplx.postcode,
			cplx.fax,
			cplx.certificate_send_method,
			cplx.email,
			cd.certificate_revision,
			branch_address.branch_code,
			branch_address.address_1,
			branch_address.address_2,
			branch_address.address_3,
			branch_address.address_4,
			branch_address.address_5,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			null,
			@group_count,
			null,
			null,
			cd.certificate_comment
		from complex_date cd,
			complex cplx,
			branch_address
		where cd.complex_id = @complex_id and
			cd.screening_date = @screening_date and
			cd.complex_id = cplx.complex_id and
			cplx.branch_code = branch_address.branch_code and
			branch_address.address_category = 'FSC' 
	end
else
	begin
		select @screening_date as screening_date,
			cplx.complex_name,
			cplx.manager,
			cplx.address_1,
			cplx.address_2,
			convert(varchar(30),cplx.town_suburb),
			cplx.state_code,
			cplx.postcode,
			cplx.fax,
			cplx.certificate_send_method,
			cplx.email,
			cd.certificate_revision,
			branch_address.branch_code,
			branch_address.address_1,
			branch_address.address_2,
			branch_address.address_3,
			branch_address.address_4,
			branch_address.address_5,
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
			cd.certificate_comment
		from complex_date cd,
			complex cplx,
			branch_address,
			#cert_items
		where cd.complex_id = @complex_id and
			cd.screening_date = @screening_date and
			cd.complex_id = cplx.complex_id and
			cplx.branch_code = branch_address.branch_code and
			branch_address.address_category = 'FSC'
		order by #cert_items.group_no,
			#cert_items.sequence_no 
end
GO
