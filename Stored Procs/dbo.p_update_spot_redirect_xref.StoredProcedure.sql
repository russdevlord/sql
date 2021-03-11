USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_update_spot_redirect_xref]    Script Date: 11/03/2021 2:30:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_update_spot_redirect_xref]

as

declare		@error						integer

set nocount on

begin transaction

delete campaign_spot_redirect_xref

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error delete campaign_spot_redirect_xref', 16, 1)
	return -100
end

insert into campaign_spot_redirect_xref
(
original_spot_id, 
redirect_spot_id
) 
select		spota.spot_id,
			spotb.spot_id
from		campaign_spot spota,
			campaign_spot spotb
where       dbo.f_spot_redirect(spota.spot_id) = spotb.spot_id
and         spota.spot_redirect is not null
and         spota.spot_status <> 'P'


select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error delete campaign_spot_redirect_xref', 16, 1)
	return -100
end


commit transaction
return 0
GO
