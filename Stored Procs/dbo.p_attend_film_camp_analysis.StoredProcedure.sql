/****** Object:  StoredProcedure [dbo].[p_attend_film_camp_analysis]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_attend_film_camp_analysis]
GO
/****** Object:  StoredProcedure [dbo].[p_attend_film_camp_analysis]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_attend_film_camp_analysis]  @campaign_no   integer,
                                         @start_date    datetime,
                                         @end_date      datetime

as

declare @error          		integer,
        @csr_open               tinyint,
        @err_msg                varchar(100),
        @status_outstanding     char(1),
        @rowcount               integer,
        @csr_rep_id             integer,
        @team_id                integer,
        @area_id                integer,
        @region_id              integer

-- /*
--     declare csr_activity_reps cursor static for
--     select  rep_id
--     from    sales_rep
--     where   status = 'A'
--     and     activity_tracking = 'Y'
--     and     branch_code = @branch_code
--     and     rep_id <> 0
--     for read only
-- 
-- 
-- select  @csr_open = 0
-- 
-- create table    #activity_days
--                (activity_date   datetime    not null)
-- 
-- begin transaction
-- 
--     /* populate activity_reps_weekly - active reps only unless specific rep entered*/
-- 
--     open csr_activity_reps
--     fetch csr_activity_reps into @csr_rep_id
--     select  @csr_open = 1
--     while (@@sqlstatus = 0)
--     begin
-- 
--         /* get team id's */
--         select   @team_id = null,
--                  @area_id = null,
--                  @region_id = null
-- 
--         exec p_get_rep_team_ids @csr_rep_id, @week_ending, @team_id OUTPUT, @area_id OUTPUT, @region_id OUTPUT
-- 
--         insert  activity_rep_team(
--                 rep_id,
--                 week_ending,
--                 sales_period,
--                 branch_code,
--                 team_id,
--                 area_id,
--                 region_id)
--         select  @csr_rep_id,
--                 @week_ending,
--                 @sales_period,
--                 @branch_code,
--                 @team_id,
--                 @area_id,
--                 @region_id
--         where   @csr_rep_id not in (select rep_id from activity_rep_team
--                                where   week_ending = @week_ending
--                                and     branch_code = @branch_code)
-- 
--         select @error = @@error, @rowcount = @@rowcount
--         if ( @error !=0 )
--         begin
--          	rollback transaction
--             select @err_msg = 'Error creating Activity Rep record for rep id ' + convert(varchar(10),@csr_rep_id) + ' for selected branch and sales period.'
--            	raiserror ( @err_msg, 16, 1)
--             goto error
--         end
-- 
--         fetch csr_activity_reps into @csr_rep_id
-- 
--     end /*while*/
-- 
--     close csr_activity_reps
--     deallocate cursor csr_activity_reps
-- 
--     select @csr_open = 0
-- 
--     /* populate activity_rep_daily_summary */
--     insert into  #activity_days values (dateadd(dd,-4,@week_ending))
--     select @error = @@error
--     if ( @error !=0 )
--     begin
--     	rollback transaction
--     	raiserror ( 'Error creating temporary Activity Date records.', 16, 1)
--         return @error
--     end
-- 
--     insert into  #activity_days values (dateadd(dd,-3,@week_ending))
--     select @error = @@error
--     if ( @error !=0 )
--     begin
--     	rollback transaction
--     	raiserror ('Error creating temporary Activity Date records.'
--         return @error
--     end
-- 
--     insert into  #activity_days values (dateadd(dd,-2,@week_ending))
--     select @error = @@error
--     if ( @error !=0 )
--     begin
--     	rollback transaction
--     	raiserror ('Error creating temporary Activity Date records.', 16, 1)
--         return @error
--     end
-- 
--     insert into  #activity_days values (dateadd(dd,-1,@week_ending))
--     select @error = @@error
--     if ( @error !=0 )
--     begin
--     	rollback transaction
--     	raiserror ('Error creating temporary Activity Date records.', 16, 1)
--         return @error
--     end
-- 
--     insert into  #activity_days values (@week_ending)
--     select @error = @@error
--     if ( @error !=0 )
--     begin
--     	rollback transaction
--     	raiserror ('Error creating temporary Activity Date records.', 16, 1)
--         return @error
--     end
-- 
--     insert  activity_rep_daily_summary(
--                 rep_id                  ,
--                 activity_date           ,
--                 activity_type           ,
--                 week_ending             ,
--                 activity_status         ,
--                 calls_phone             ,
--                 calls_face              ,
--                 appts_phone             ,
--                 appts_face              ,
--                 presentations_kept_phone      ,
--                 presentations_kept_face      ,
--                 presentations_cancelled ,
--                 sales_qty               ,
--                 sales_value             ,
--                 future_appts_phone      ,
--                 future_appts_face       ,
--                 poster_deliveries       ,
--                 artwork_approvals       ,
--                 servicing_calls_phone   ,
--                 servicing_calls_face    )
--       select    art.rep_id,
--                 aday.activity_date,
--                 @activity_type,
--                 @week_ending,
--                 @status_outstanding,
--                 0,
--                 0,
--                 0,
--                 0,
--                 0,
--                 0,
--                 0,
--                 0,
--                 0,
--                 0,
--                 0,
--                 0,
--                 0,
--                 0,
--                 0
--       from      activity_rep_team art, #activity_days aday
--       where     art.sales_period = @sales_period
--       and       art.branch_code = @branch_code
--       and       art.week_ending = @week_ending
--       and       (art.rep_id = @rep_id OR @rep_id is null)
--       and       art.rep_id not in (select rep_id from activity_rep_daily_summary
--                                    where week_ending = @week_ending
--                                    and   activity_type = @activity_type)
-- 
--     select @error = @@error
--     if ( @error !=0 )
--     begin
--     	rollback transaction
--     	raiserror ('Error creating daily Rep Activity summary records.', 16, 1)
--         return @error
--     end
-- 
-- commit transaction



return 0

error:
--close csr_activity_reps
--deallocate cursor csr_activity_reps
	
return 0
GO
