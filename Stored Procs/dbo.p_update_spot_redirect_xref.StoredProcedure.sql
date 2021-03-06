/****** Object:  StoredProcedure [dbo].[p_update_spot_redirect_xref]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_update_spot_redirect_xref]
GO
/****** Object:  StoredProcedure [dbo].[p_update_spot_redirect_xref]    Script Date: 12/03/2021 10:03:50 AM ******/
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
