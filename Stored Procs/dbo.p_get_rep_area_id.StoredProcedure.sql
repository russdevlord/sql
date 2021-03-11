USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_get_rep_area_id]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_get_rep_area_id]   @rep_id         integer,
                                @rep_date       datetime
                                        
as
set nocount on 

declare @area_id integer

select  @area_id = area_reps.area_id
from    area_reps, area_rep_dates
where   area_reps.area_rep_id = area_rep_dates.area_rep_id
and     area_reps.rep_id = @rep_id
and     area_rep_dates.start_period <= @rep_date
and     isnull(area_rep_dates.end_period,'31-dec-3000') >= @rep_date


return @area_id
GO
