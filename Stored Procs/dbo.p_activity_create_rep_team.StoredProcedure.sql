/****** Object:  StoredProcedure [dbo].[p_activity_create_rep_team]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_activity_create_rep_team]
GO
/****** Object:  StoredProcedure [dbo].[p_activity_create_rep_team]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_activity_create_rep_team]  @branch_code    char(2),
                                        @week_ending    datetime,
                                        @sales_period   datetime,
                                        @activity_type  char(1),
                                        @rep_id         integer
as



declare @error          integer,
        @rowcount       integer


if exists (select 1 from activity_rep_team 
            where   rep_id = @rep_id
            and     week_ending = @week_ending)
begin /*record already exists */
   	raiserror ('Rep already exists for selected Activity Period.', 16, 1)
    return 0
end
        
exec @error = p_activity_create_rep_daily @branch_code, @week_ending, @sales_period, @activity_type, @rep_id

return @error
GO
