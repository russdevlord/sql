USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_get_rep_region_id]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_get_rep_region_id]   @rep_id         integer,
                                @rep_date       datetime
                                        
as
set nocount on 

declare @region_id integer

select  @region_id = region_reps.region_id
from    region_reps, region_rep_dates
where   region_reps.region_rep_id = region_rep_dates.region_rep_id
and     region_reps.rep_id = @rep_id
and     region_rep_dates.start_period <= @rep_date
and     isnull(region_rep_dates.end_period,'31-dec-3000') >= @rep_date


return @region_id
GO
