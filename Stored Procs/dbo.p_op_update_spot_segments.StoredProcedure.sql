/****** Object:  StoredProcedure [dbo].[p_op_update_spot_segments]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_update_spot_segments]
GO
/****** Object:  StoredProcedure [dbo].[p_op_update_spot_segments]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_op_update_spot_segments] 	@package_id			int

as

declare		@error			int,
			@spot_id		int,
			@start_date		datetime,
			@start_store	datetime,
			@end_date		datetime,
			@end_store		datetime,
			@start_insert	datetime,
			@end_insert		datetime,
			@row			int,
			@spot_store		int

set nocount on


create table #outpost_spot_daily_segment
(
spot_id			int,
start_date		datetime,
end_date		datetime
)

create table #outpost_spot_daily_segment_2
(
spot_id			int,
start_date		datetime,
end_date		datetime
)

begin transaction

/*
 * Insert all missing package bursts - as they are not inseted assume they last the duration of the package
 */

delete 	outpost_spot_daily_segment
where	spot_id in (	select 	spot_id 
                        from 	outpost_spot 
                        where 	package_id = @package_id
                        and     spot_status <> 'X'
                        and     spot_status <> 'U'
                        and     spot_status <> 'N'
                        and     spot_status <> 'R')

select @error = @@error
if @error <> 0
begin
    raiserror ('Error Deleting Spot Segments', 16, 1)
    rollback transaction
    return -1
end

insert into #outpost_spot_daily_segment
select 	spot_id, 
        DATEADD(ms, DATEDIFF(ms, 0, outpost_package_intra_pattern.start_date), DATEADD(dd, 0, DATEDIFF(dd, 0, dateadd(dd, 0, outpost_spot.screening_date)))),
        DATEADD(ms, DATEDIFF(ms, 0, outpost_package_intra_pattern.end_date), DATEADD(dd, 0, DATEDIFF(dd, 0, dateadd(dd, 0, outpost_spot.screening_date))))
from 	outpost_package_burst, 
        outpost_package_intra_pattern,
        outpost_spot
where 	outpost_package_intra_pattern.package_id = outpost_package_burst.package_id 
and 	outpost_spot.package_id = outpost_package_burst.package_id 
and 	outpost_spot.package_id =outpost_package_intra_pattern.package_id
and 	outpost_package_burst.start_date <= dateadd(dd, 0, outpost_spot.screening_date) 
and 	outpost_package_burst.end_date >= dateadd(dd, 0, outpost_spot.screening_date) 
and 	outpost_package_intra_pattern.patt_day = datepart(dw, dateadd(dd, 0, outpost_spot.screening_date))
and		dateadd(dd, 0, outpost_spot.screening_date) is not null
and		outpost_spot.package_id = @package_id
and     spot_status <> 'X'
and     spot_status <> 'U'
and     spot_status <> 'N'
and     spot_status <> 'R'
union all
select 	spot_id, 
        DATEADD(ms, DATEDIFF(ms, 0, outpost_package_intra_pattern.start_date), dateadd(dd, 1, DATEDIFF(dd, 1, dateadd(dd, 1, outpost_spot.screening_date)))),
        DATEADD(ms, DATEDIFF(ms, 0, outpost_package_intra_pattern.end_date), dateadd(dd, 1, DATEDIFF(dd, 1, dateadd(dd, 1, outpost_spot.screening_date))))
from 	outpost_package_burst, 
        outpost_package_intra_pattern,
        outpost_spot
where 	outpost_package_intra_pattern.package_id = outpost_package_burst.package_id 
and 	outpost_spot.package_id = outpost_package_burst.package_id 
and 	outpost_spot.package_id =outpost_package_intra_pattern.package_id
and 	outpost_package_burst.start_date <= dateadd(dd, 1, outpost_spot.screening_date) 
and 	outpost_package_burst.end_date >= dateadd(dd, 1, outpost_spot.screening_date) 
and 	outpost_package_intra_pattern.patt_day = datepart(dw, dateadd(dd, 1, outpost_spot.screening_date))
and		dateadd(dd, 1, outpost_spot.screening_date) is not null
and		outpost_spot.package_id = @package_id
and     spot_status <> 'X'
and     spot_status <> 'U'
and     spot_status <> 'N'
and     spot_status <> 'R'
union all
select 	spot_id, 
        DATEADD(ms, DATEDIFF(ms, 0, outpost_package_intra_pattern.start_date), dateadd(dd, 2, DATEDIFF(dd, 2, dateadd(dd, 2, outpost_spot.screening_date)))),
        DATEADD(ms, DATEDIFF(ms, 0, outpost_package_intra_pattern.end_date), dateadd(dd, 2, DATEDIFF(dd, 2, dateadd(dd, 2, outpost_spot.screening_date))))
from 	outpost_package_burst, 
        outpost_package_intra_pattern,
        outpost_spot
where 	outpost_package_intra_pattern.package_id = outpost_package_burst.package_id 
and 	outpost_spot.package_id = outpost_package_burst.package_id 
and 	outpost_spot.package_id =outpost_package_intra_pattern.package_id
and 	outpost_package_burst.start_date <= dateadd(dd, 2, outpost_spot.screening_date) 
and 	outpost_package_burst.end_date >= dateadd(dd, 2, outpost_spot.screening_date) 
and 	outpost_package_intra_pattern.patt_day = datepart(dw, dateadd(dd, 2, outpost_spot.screening_date))
and		outpost_spot.package_id = @package_id
and     spot_status <> 'X'
and     spot_status <> 'U'
and     spot_status <> 'N'
and     spot_status <> 'R'
union all
select 	spot_id, 
        DATEADD(ms, DATEDIFF(ms, 0, outpost_package_intra_pattern.start_date), dateadd(dd, 3, DATEDIFF(dd, 3, dateadd(dd, 3, outpost_spot.screening_date)))),
        DATEADD(ms, DATEDIFF(ms, 0, outpost_package_intra_pattern.end_date), dateadd(dd, 3, DATEDIFF(dd, 3, dateadd(dd, 3, outpost_spot.screening_date))))
from 	outpost_package_burst, 
        outpost_package_intra_pattern,
        outpost_spot
where 	outpost_package_intra_pattern.package_id = outpost_package_burst.package_id 
and 	outpost_spot.package_id = outpost_package_burst.package_id 
and 	outpost_spot.package_id =outpost_package_intra_pattern.package_id
and 	outpost_package_burst.start_date <= dateadd(dd, 3, outpost_spot.screening_date) 
and 	outpost_package_burst.end_date >= dateadd(dd, 3, outpost_spot.screening_date) 
and 	outpost_package_intra_pattern.patt_day = datepart(dw, dateadd(dd, 3, outpost_spot.screening_date))
and		outpost_spot.package_id = @package_id
and     spot_status <> 'X'
and     spot_status <> 'U'
and     spot_status <> 'N'
and     spot_status <> 'R'
union all
select 	spot_id, 
        DATEADD(ms, DATEDIFF(ms, 0, outpost_package_intra_pattern.start_date), dateadd(dd, 4, DATEDIFF(dd, 4, dateadd(dd, 4, outpost_spot.screening_date)))),
        DATEADD(ms, DATEDIFF(ms, 0, outpost_package_intra_pattern.end_date), dateadd(dd, 4, DATEDIFF(dd, 4, dateadd(dd, 4, outpost_spot.screening_date))))
from 	outpost_package_burst, 
        outpost_package_intra_pattern,
        outpost_spot
where 	outpost_package_intra_pattern.package_id = outpost_package_burst.package_id 
and 	outpost_spot.package_id = outpost_package_burst.package_id 
and 	outpost_spot.package_id =outpost_package_intra_pattern.package_id
and 	outpost_package_burst.start_date <= dateadd(dd, 4, outpost_spot.screening_date) 
and 	outpost_package_burst.end_date >= dateadd(dd, 4, outpost_spot.screening_date) 
and 	outpost_package_intra_pattern.patt_day = datepart(dw, dateadd(dd, 4, outpost_spot.screening_date))
and		outpost_spot.package_id = @package_id
and     spot_status <> 'X'
and     spot_status <> 'U'
and     spot_status <> 'N'
and     spot_status <> 'R'
union all
select 	spot_id, 
        DATEADD(ms, DATEDIFF(ms, 0, outpost_package_intra_pattern.start_date), dateadd(dd, 5, DATEDIFF(dd, 5, dateadd(dd, 5, outpost_spot.screening_date)))),
        DATEADD(ms, DATEDIFF(ms, 0, outpost_package_intra_pattern.end_date), dateadd(dd, 5, DATEDIFF(dd, 5, dateadd(dd, 5, outpost_spot.screening_date))))
from 	outpost_package_burst, 
        outpost_package_intra_pattern,
        outpost_spot
where 	outpost_package_intra_pattern.package_id = outpost_package_burst.package_id 
and 	outpost_spot.package_id = outpost_package_burst.package_id 
and 	outpost_spot.package_id =outpost_package_intra_pattern.package_id
and 	outpost_package_burst.start_date <= dateadd(dd, 5, outpost_spot.screening_date) 
and 	outpost_package_burst.end_date >= dateadd(dd, 5, outpost_spot.screening_date) 
and 	outpost_package_intra_pattern.patt_day = datepart(dw, dateadd(dd, 5, outpost_spot.screening_date))
and		outpost_spot.package_id = @package_id
and     spot_status <> 'X'
and     spot_status <> 'U'
and     spot_status <> 'N'
and     spot_status <> 'R'
union all
select 	spot_id, 
        DATEADD(ms, DATEDIFF(ms, 0, outpost_package_intra_pattern.start_date), dateadd(dd, 6, DATEDIFF(dd, 6, dateadd(dd, 6, outpost_spot.screening_date)))),
        DATEADD(ms, DATEDIFF(ms, 0, outpost_package_intra_pattern.end_date), dateadd(dd, 6, DATEDIFF(dd, 6, dateadd(dd, 6, outpost_spot.screening_date))))
from 	outpost_package_burst, 
        outpost_package_intra_pattern,
        outpost_spot
where 	outpost_package_intra_pattern.package_id = outpost_package_burst.package_id 
and 	outpost_spot.package_id = outpost_package_burst.package_id 
and 	outpost_spot.package_id = outpost_package_intra_pattern.package_id
and 	outpost_package_burst.start_date <= dateadd(dd, 6, outpost_spot.screening_date) 
and 	outpost_package_burst.end_date >= dateadd(dd, 6, outpost_spot.screening_date) 
and 	outpost_package_intra_pattern.patt_day = datepart(dw, dateadd(dd, 6, outpost_spot.screening_date))
and		dateadd(dd, 6, outpost_spot.screening_date) is not null
and		outpost_spot.package_id = @package_id
and     spot_status <> 'X'
and     spot_status <> 'U'
and     spot_status <> 'N'
and     spot_status <> 'R'

select @error = @@error
if @error <> 0
begin
    raiserror ('Error inserting tmp Spot Segments', 16, 1)
    rollback transaction
    return -1
end

select 		@start_date = '1-jan-1900',
            @end_date = '1-jan-1900',
            @start_insert = '1-jan-1900',
            @end_insert = '1-jan-1900',
            @start_store = '1-jan-1900',
            @end_store = '1-jan-1900',
            @row = 0,
            @spot_store = 0


declare 	temp_segment_csr cursor forward_only for
select 		spot_id, 
            start_date,
            end_date
from 		#outpost_spot_daily_segment
order by 	spot_id, 
            start_date
for			read only

open temp_segment_csr
fetch temp_segment_csr into @spot_id, @start_date, @end_date
while(@@fetch_status=0)
begin

    if @start_date <> dateadd(ss, 1, @end_store)
    begin
        if @end_store <> '1-jan-1900'
        begin
            insert into #outpost_spot_daily_segment_2 values( @spot_store, @start_insert, @end_store)
        end

        select 	@start_insert = @start_date,
                @spot_store = @spot_id
    end

    select 	@start_store = @start_date,
            @end_store = @end_date

    fetch temp_segment_csr into @spot_id, @start_date, @end_date
end

if @spot_store <> 0
	insert into #outpost_spot_daily_segment_2 values (@spot_store, @start_insert, @end_store)

select @error = @@error
if @error <> 0
begin
    raiserror ('Error inserting actual Spot Segments', 16, 1)
    rollback transaction
    return -1
end

close temp_segment_csr
deallocate temp_segment_csr

insert into outpost_spot_daily_segment select spot_id, start_date, end_date from #outpost_spot_daily_segment_2
--select spot_id, start_date, end_date from #outpost_spot_daily_segment_2


delete #outpost_spot_daily_segment

delete #outpost_spot_daily_segment_2

commit transaction
return 0
GO
