/****** Object:  StoredProcedure [dbo].[p_cinelight_posting_certificate]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinelight_posting_certificate]
GO
/****** Object:  StoredProcedure [dbo].[p_cinelight_posting_certificate]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_cinelight_posting_certificate] 		@screening_date 			datetime

as

declare		@error							int,
			@rowcount						int,
			@film_market_no					int,
			@film_market_code				char(3),
			@complex_name					varchar(50),
			@cinelight_id					int,
			@cinelight_desc					varchar(50),
			@cinelight_type_desc			varchar(50),
			@cinelight_booking_group_id		int,
			@cinelight_booking_group_desc	varchar(30),
			@campaign_no_1					int,
			@product_desc_1					varchar(100),
			@print_id_1						int,
			@print_name_1					varchar(50),
			@new_print_1					int,
			@screening_date_1				datetime,
			@campaign_no_2					int,
			@product_desc_2					varchar(100),
			@print_id_2						int,
			@print_name_2					varchar(50),
			@new_print_2					int,
			@screening_date_2				datetime,
			@campaign_no_3					int,
			@product_desc_3					varchar(100),
			@print_id_3						int,
			@print_name_3					varchar(50),
			@new_print_3					int,
			@screening_date_3				datetime,
			@campaign_no_4					int,
			@product_desc_4					varchar(100),
			@print_id_4						int,
			@print_name_4					varchar(50),
			@new_print_4					int,
			@screening_date_4				datetime,
			@contact						varchar(255)

create table #certificate
(
	film_market_no					int				not null,
	film_market_code				char(3)			not null,
	complex_name					varchar(50)		not null,
	cinelight_id					int				not null,
	cinelight_desc					varchar(50)		not null,
	cinelight_type_desc				varchar(50)		not null,
	cinelight_booking_group_id		int				not null,
	cinelight_booking_group_desc	varchar(30)		not null,
	campaign_no_1					int				null,
	product_desc_1					varchar(100)	null,
	print_id_1						int				null,
	print_name_1					varchar(50)		null,
	new_print_1						int				null,
	screening_date_1				datetime		null,
	campaign_no_2					int				null,
	product_desc_2					varchar(100)	null,
	print_id_2						int				null,
	print_name_2					varchar(50)		null,
	new_print_2						int				null,
	screening_date_2				datetime		null,
	campaign_no_3					int				null,
	product_desc_3					varchar(100)	null,
	print_id_3						int				null,
	print_name_3					varchar(50)		null,
	new_print_3						int				null,
	screening_date_3				datetime		null,
	campaign_no_4					int				null,
	product_desc_4					varchar(100)	null,
	print_id_4						int				null,
	print_name_4					varchar(50)		null,
	new_print_4						int				null,
	screening_date_4				datetime		null
)

select @contact = address_1 + ' ' + address_2 + ' ' + address_3 + ' ' + address_4 + ' ' + address_5
  from branch_address
 where branch_code = 'N' and
       address_category = 'CSC'

insert into #certificate
(
	film_market_no,
	film_market_code,
	complex_name,
	cinelight_id,
	cinelight_desc,
	cinelight_type_desc,
	cinelight_booking_group_id,
	cinelight_booking_group_desc
)
select 		fm.film_market_no,
			fm.film_market_code,
			c.complex_name,
			cl.cinelight_id,
			cl.cinelight_desc,
			ct.cinelight_type_desc,
			cbg.cinelight_booking_group_id,
			cbg.cinelight_booking_group_desc
from		complex c,
			cinelight cl,
			cinelight_type ct, 
			film_market fm,
			cinelight_booking_group cbg
where		cl.complex_id = c.complex_id
and			fm.film_market_no = c.film_market_no
and			cl.cinelight_type = ct.cinelight_type
and			cl.cinelight_status = 'O'
and			cl.cinelight_booking_group_id = cbg.cinelight_booking_group_id
and			ct.cinelight_type_group = 'C'

declare 	cinelight_csr cursor forward_only static for
select 		distinct cinelight_id
from		#certificate
order by	cinelight_id

open cinelight_csr
fetch cinelight_csr into 	@cinelight_id
while(@@fetch_status = 0)
begin

	select 	@campaign_no_1 = null,
			@product_desc_1 = null,
			@print_id_1 = null,
			@print_name_1 = null,
			@screening_date_1 = null,
			@new_print_1 = null,
			@campaign_no_2 = null,
			@product_desc_2 = null,
			@print_id_2 = null,
			@print_name_2 = null,
			@screening_date_2 = null,
			@new_print_2 = null,
			@campaign_no_3 = null,
			@product_desc_3 = null,
			@print_id_3 = null,
			@print_name_3 = null,
			@screening_date_3 = null,
			@new_print_3 = null,
			@campaign_no_4 = null,
			@product_desc_4 = null,
			@print_id_4 = null,
			@print_name_4 = null,
			@screening_date_4 = null,
			@new_print_4 = null

	select 	@campaign_no_1 = fc.campaign_no,
			@product_desc_1 = fc.product_desc,
			@print_id_1 = cpr.print_id,
			@print_name_1 = cpr.print_name,
			@screening_date_1 = cs.screening_date,
			@new_print_1 = (select count(distinct cinelight_package.package_id) 
							from 	cinelight_package,
									cinelight_spot 
							where 	cinelight_package.package_id = cinelight_spot.package_id
							and		cinelight_package.package_id = cp.package_id
							and		cinelight_spot.cinelight_id = cs.cinelight_id
							and		cinelight_spot.screening_date = dateadd(wk, -1, @screening_date))
	from	cinelight_spot cs,
			cinelight_package cp,
			cinelight_print cpr,
			cinelight_print_package cpp,
			film_campaign fc,  
			complex c,
			cinelight cl,
			cinelight_type ct, 
			film_market fm
	where	cs.package_id = cp.package_id
	and		cs.screening_date = @screening_date
	and		cp.package_id = cpp.package_id
	and		cpp.print_id = cpr.print_id
	and		cs.campaign_no = fc.campaign_no
	and		cp.campaign_no = cs.campaign_no
	and		cp.campaign_no = fc.campaign_no
	and 	cs.cinelight_id = cl.cinelight_id
	and		cl.complex_id = c.complex_id
	and		fm.film_market_no = c.film_market_no
	and		cl.cinelight_type = ct.cinelight_type
	and		(cs.spot_status = 'X'
	or		cs.spot_status = 'A')
	and		cs.cinelight_id = @cinelight_id
	
	select @rowcount = @@rowcount
	if @rowcount = 0
		select @screening_date_1 = @screening_date


	select 	@campaign_no_2 = fc.campaign_no,
			@product_desc_2 = fc.product_desc,
			@print_id_2 = cpr.print_id,
			@print_name_2 = cpr.print_name,
			@screening_date_2 = cs.screening_date,
			@new_print_2 = (select count(distinct cinelight_package.package_id) 
							from 	cinelight_package,
									cinelight_spot 
							where 	cinelight_package.package_id = cinelight_spot.package_id
							and		cinelight_package.package_id = cp.package_id
							and		cinelight_spot.cinelight_id = cs.cinelight_id
							and		cinelight_spot.screening_date <= @screening_date)
	from	cinelight_spot cs,
			cinelight_package cp,
			cinelight_print cpr,
			cinelight_print_package cpp,
			film_campaign fc,  
			complex c,
			cinelight cl,
			cinelight_type ct, 
			film_market fm
	where	cs.package_id = cp.package_id
	and		cs.screening_date = dateadd(wk, 1, @screening_date)
	and		cp.package_id = cpp.package_id
	and		cpp.print_id = cpr.print_id
	and		cs.campaign_no = fc.campaign_no
	and		cp.campaign_no = cs.campaign_no
	and		cp.campaign_no = fc.campaign_no
	and 	cs.cinelight_id = cl.cinelight_id
	and		cl.complex_id = c.complex_id
	and		fm.film_market_no = c.film_market_no
	and		cl.cinelight_type = ct.cinelight_type
	and		(cs.spot_status = 'X'
	or		cs.spot_status = 'A')
	and		cs.cinelight_id = @cinelight_id
	
	select @rowcount = @@rowcount
	if @rowcount = 0
		select @screening_date_2 = dateadd(wk, 1, @screening_date)

	select 	@campaign_no_3 = fc.campaign_no,
			@product_desc_3 = fc.product_desc,
			@print_id_3 = cpr.print_id,
			@print_name_3 = cpr.print_name,
			@screening_date_3 = cs.screening_date,
			@new_print_3 = (select count(distinct cinelight_package.package_id) 
							from 	cinelight_package,
									cinelight_spot 
							where 	cinelight_package.package_id = cinelight_spot.package_id
							and		cinelight_package.package_id = cp.package_id
							and		cinelight_spot.cinelight_id = cs.cinelight_id
							and		cinelight_spot.screening_date = dateadd(wk, 1, @screening_date))
	from	cinelight_spot cs,
			cinelight_package cp,
			cinelight_print cpr,
			cinelight_print_package cpp,
			film_campaign fc,  
			complex c,
			cinelight cl,
			cinelight_type ct, 
			film_market fm
	where	cs.package_id = cp.package_id
	and		cs.screening_date = dateadd(wk, 2, @screening_date)
	and		cp.package_id = cpp.package_id
	and		cpp.print_id = cpr.print_id
	and		cs.campaign_no = fc.campaign_no
	and		cp.campaign_no = cs.campaign_no
	and		cp.campaign_no = fc.campaign_no
	and 	cs.cinelight_id = cl.cinelight_id
	and		cl.complex_id = c.complex_id
	and		fm.film_market_no = c.film_market_no
	and		cl.cinelight_type = ct.cinelight_type
	and		(cs.spot_status = 'X'
	or		cs.spot_status = 'A')
	and		cs.cinelight_id = @cinelight_id
	
	select @rowcount = @@rowcount
	if @rowcount = 0
		select @screening_date_3= dateadd(wk, 2,@screening_date)

	select 	@campaign_no_4 = fc.campaign_no,
			@product_desc_4 = fc.product_desc,
			@print_id_4 = cpr.print_id,
			@print_name_4 = cpr.print_name,
			@screening_date_4 = cs.screening_date,
			@new_print_4 = (select count(distinct cinelight_package.package_id) 
							from 	cinelight_package,
									cinelight_spot 
							where 	cinelight_package.package_id = cinelight_spot.package_id
							and		cinelight_package.package_id = cp.package_id
							and		cinelight_spot.cinelight_id = cs.cinelight_id
							and		cinelight_spot.screening_date = dateadd(wk, 2,@screening_date))
	from	cinelight_spot cs,
			cinelight_package cp,
			cinelight_print cpr,
			cinelight_print_package cpp,
			film_campaign fc,  
			complex c,
			cinelight cl,
			cinelight_type ct, 
			film_market fm
	where	cs.package_id = cp.package_id
	and		cs.screening_date = dateadd(wk, 3, @screening_date)
	and		cp.package_id = cpp.package_id
	and		cpp.print_id = cpr.print_id
	and		cs.campaign_no = fc.campaign_no
	and		cp.campaign_no = cs.campaign_no
	and		cp.campaign_no = fc.campaign_no
	and 	cs.cinelight_id = cl.cinelight_id
	and		cl.complex_id = c.complex_id
	and		fm.film_market_no = c.film_market_no
	and		cl.cinelight_type = ct.cinelight_type
	and		(cs.spot_status = 'X'
	or		cs.spot_status = 'A')
	and		cs.cinelight_id = @cinelight_id
	
	select @rowcount = @@rowcount
	if @rowcount = 0
		select @screening_date_4 = dateadd(wk, 3, @screening_date)


	update 	#certificate
	set 	campaign_no_1 = @campaign_no_1,
			product_desc_1 = @product_desc_1,
			print_id_1 = @print_id_1,
			print_name_1 = @print_name_1,
			screening_date_1 = @screening_date_1,
			new_print_1 = @new_print_1,
			campaign_no_2 = @campaign_no_2,
			product_desc_2 = @product_desc_2,
			print_id_2 = @print_id_2,
			print_name_2 = @print_name_2,
			screening_date_2 = @screening_date_2,
			new_print_2 = @new_print_2,
			campaign_no_3 = @campaign_no_3,
			product_desc_3 = @product_desc_3,
			print_id_3 = @print_id_3,
			print_name_3 = @print_name_3,
			screening_date_3 = @screening_date_3,
			new_print_3 = @new_print_3,
			campaign_no_4 = @campaign_no_4,
			product_desc_4 = @product_desc_4,
			print_id_4 = @print_id_4,
			print_name_4 = @print_name_4,
			screening_date_4 = @screening_date_4,
			new_print_4 = @new_print_4
	where	cinelight_id = @cinelight_id

	fetch 	cinelight_csr into 	@cinelight_id

end

select *, @contact from #certificate
return 0
GO
