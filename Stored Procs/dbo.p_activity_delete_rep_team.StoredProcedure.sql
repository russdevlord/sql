/****** Object:  StoredProcedure [dbo].[p_activity_delete_rep_team]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_activity_delete_rep_team]
GO
/****** Object:  StoredProcedure [dbo].[p_activity_delete_rep_team]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_activity_delete_rep_team]  @rep_id         integer,
                                        @week_ending    datetime
                                        
as



declare @error          integer

begin transaction

    delete  activity_rep_daily_summary
    where   rep_id = @rep_id
    and     week_ending = @week_ending
    select @error = @@error
    if ( @error !=0 )
    begin
    	rollback transaction
    	raiserror ('Error deleting data from activity_rep_daily_summary .', 16, 1)
        return @error
    end

    delete  activity_rep_team
    where   rep_id = @rep_id
    and     week_ending = @week_ending
    select @error = @@error
    if ( @error !=0 )
    begin
    	rollback transaction
    	raiserror ('Error deleting data from activity_rep_team .', 16, 1)
        return @error
    end

commit transaction

return 0
GO
