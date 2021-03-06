/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_complex]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_live_extract_complex]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_complex]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_cinetam_live_extract_complex]

as

declare			@error			int

set nocount on

select			complex.complex_id,
				complex_name,
				complex.film_market_no,
				film_market_desc,
				regional_indicator,
				complex.complex_region_class,
				complex_region_class.region_class_desc,
				complex.exhibitor_id,
				exhibitor_name,
				no_cinemas,
				case complex_type when 'M' then 'Mainstream' when 'A' then 'Arthouse' else 'Unknown' end as complex_type_desc
from			complex
inner join		film_market on complex.film_market_no = film_market.film_market_no
inner join		complex_region_class on complex.complex_region_class = complex_region_class.complex_region_class
inner join		exhibitor on complex.exhibitor_id = exhibitor.exhibitor_id
where			complex.complex_id in (select complex_id from movie_history where screening_date > '25-dec-2017' and country = 'A')
and				complex.complex_id not in (select complex_id from cinetam_live_complex where added = 'Y')
--for json path

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce complex list for cinetam live bigquery datawarehouse', 16, 1)
	return -1
end

begin transaction

insert into		cinetam_live_complex
select			complex.complex_id,
				'Y',
				'N'
from			complex
where			complex.complex_id in (select complex_id from movie_history where screening_date > '25-dec-2017' and country = 'A')
and				complex.complex_id not in (select complex_id from cinetam_live_complex where added = 'Y')

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce complex list for cinetam live bigquery datawarehouse', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
