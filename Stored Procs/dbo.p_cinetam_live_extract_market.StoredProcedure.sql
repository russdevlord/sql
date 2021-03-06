/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_market]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetam_live_extract_market]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetam_live_extract_market]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create proc [dbo].[p_cinetam_live_extract_market]

as

declare			@error			int

set nocount on

select			film_market_no,
				film_market_desc,
				film_market_code,
				country_code, 
				regional
from			film_market
where			country_code = 'A'
and				film_market_no not in (select film_market_no from cinetam_live_film_market where added = 'Y')
--for json path

select @error = @@error
if @error <> 0
begin
	raiserror ('Error: failed to produce complex list for cinetam live bigquery datawarehouse', 16, 1)
	return -1
end

begin transaction

insert into		cinetam_live_film_market
select			film_market_no,
				'Y',
				'N'
from			film_market
where			country_code = 'A'
and				film_market_no not in (select film_market_no from cinetam_live_film_market where added = 'Y')

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
