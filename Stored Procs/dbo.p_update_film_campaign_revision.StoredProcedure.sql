/****** Object:  StoredProcedure [dbo].[p_update_film_campaign_revision]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_update_film_campaign_revision]
GO
/****** Object:  StoredProcedure [dbo].[p_update_film_campaign_revision]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_update_film_campaign_revision]	@campaign_no				int,
																					@revision_no					int,
																					@revision_type				int,
																					@comment						varchar(255),
																					@revision_desc				varchar(255)

as 

declare			@error			int

begin transaction

update	film_campaign_revision
set			revision_desc = @revision_desc,
				comment = @comment
where		campaign_no = @campaign_no
and			revision_no = @revision_no
and			revision_type = @revision_type

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: failed to update film_campaign_revision', 16, 1)
	return -1
end

commit transaction
return 0
GO
