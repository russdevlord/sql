/****** Object:  StoredProcedure [dbo].[p_activity_set_status_all_reps]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_activity_set_status_all_reps]
GO
/****** Object:  StoredProcedure [dbo].[p_activity_set_status_all_reps]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_activity_set_status_all_reps]  @branch_code     char(2),
                                            @activity_date   datetime,
                                            @status          char(1),
                                            @activity_type   char(1)

as

declare @error          integer

begin transaction

    update  activity_rep_daily_summary
    set     activity_status = @status
    from    activity_rep_daily_summary, activity_rep_team
    where   activity_rep_daily_summary.rep_id = activity_rep_team.rep_id
    and     activity_rep_team.branch_code = @branch_code
    and     activity_rep_daily_summary.activity_date = @activity_date
    and     activity_rep_daily_summary.activity_type = @activity_type

    select @error = @@error
    if ( @error !=0 )
    begin
    	rollback transaction
    	raiserror ('Error deleting data from activity_rep_daily_summary .', 16, 1)
        return @error
    end


commit transaction

return 0
GO
