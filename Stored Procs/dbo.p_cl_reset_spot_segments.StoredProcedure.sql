/****** Object:  StoredProcedure [dbo].[p_cl_reset_spot_segments]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cl_reset_spot_segments]
GO
/****** Object:  StoredProcedure [dbo].[p_cl_reset_spot_segments]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_cl_reset_spot_segments]		@campaign_no			int,
																					@panels							xml,
																					@package_id				int,
																					@start_date					datetime,
																					@end_date						datetime,
																					@spot_status					char(1),
																					@spot_type					char(1)
																					
																					

as

declare		@error							int,
					@handle						int
/*
 * Begin Transaction
 */
 
EXEC @error =  sp_xml_preparedocument @handle OUTPUT, @panels

 select @error = @@error
if @error <> 0
begin
	raiserror ('Error: Failed to parse xml', 16, 1)
	return -1
end

 
begin transaction

/*
 * Delete Existing Segments
 */
 
delete 		cinelight_spot_daily_segment
from			cinelight_spot
where		cinelight_spot.spot_id = cinelight_spot_daily_segment.spot_id
and				cinelight_spot.campaign_no = @campaign_no
and				(cinelight_spot.screening_date >= @start_date or @start_date is null)
and				(cinelight_spot.screening_date <= @end_date or @end_date is null)
and				(package_id = @package_id or @package_id is null)
and				(spot_status = @spot_status or @spot_status is null)
and				(spot_type = @spot_type or @spot_type is null)
and				cinelight_id  in (SELECT * FROM OPENXML (@handle, '/ids/id') WITH (id INT '.'))


select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to delete existing segments', 16, 1)
	return -1
end

/*
 * Insert Segments
 */
 
insert into cinelight_spot_daily_segment
select 		spot_id, 
					DATEADD(ms, DATEDIFF(ms, 0, cinelight_package_intra_pattern.start_date), DATEADD(dd, 0, DATEDIFF(dd, 0, dateadd(dd, 0, cinelight_spot.screening_date)))),
					DATEADD(ms, DATEDIFF(ms, 0, cinelight_package_intra_pattern.end_date), DATEADD(dd, 0, DATEDIFF(dd, 0, dateadd(dd, 0, cinelight_spot.screening_date))))
from 			cinelight_package_burst, 
					cinelight_package_intra_pattern,
					cinelight_spot
where 		cinelight_package_intra_pattern.package_id = cinelight_package_burst.package_id 
and 			cinelight_spot.package_id = cinelight_package_burst.package_id 
and 			cinelight_spot.package_id =cinelight_package_intra_pattern.package_id
and 			cinelight_package_burst.start_date <= dateadd(dd, 0, cinelight_spot.screening_date) 
and 			cinelight_package_burst.end_date >= dateadd(dd, 0, cinelight_spot.screening_date) 
and 			cinelight_package_intra_pattern.patt_day = datepart(dw, dateadd(dd, 0, cinelight_spot.screening_date))
and				dateadd(dd, 0, cinelight_spot.screening_date) is not null
and				cinelight_spot.campaign_no = @campaign_no
and				(cinelight_spot.screening_date >= @start_date or @start_date is null)
and				(cinelight_spot.screening_date <= @end_date or @end_date is null)
and				(cinelight_spot.package_id = @package_id or @package_id is null)
and				(spot_status = @spot_status or @spot_status is null)
and				(spot_type = @spot_type or @spot_type is null)
and				cinelight_id  in (SELECT * FROM OPENXML (@handle, '/ids/id') WITH (id INT '.'))
union all
select 		spot_id, 
					DATEADD(ms, DATEDIFF(ms, 0, cinelight_package_intra_pattern.start_date), dateadd(dd, 1, DATEDIFF(dd, 1, dateadd(dd, 1, cinelight_spot.screening_date)))),
					DATEADD(ms, DATEDIFF(ms, 0, cinelight_package_intra_pattern.end_date), dateadd(dd, 1, DATEDIFF(dd, 1, dateadd(dd, 1, cinelight_spot.screening_date))))
from 			cinelight_package_burst, 
					cinelight_package_intra_pattern,
					cinelight_spot
where 		cinelight_package_intra_pattern.package_id = cinelight_package_burst.package_id 
and 			cinelight_spot.package_id = cinelight_package_burst.package_id 
and 			cinelight_spot.package_id =cinelight_package_intra_pattern.package_id
and 			cinelight_package_burst.start_date <= dateadd(dd, 1, cinelight_spot.screening_date) 
and 			cinelight_package_burst.end_date >= dateadd(dd, 1, cinelight_spot.screening_date) 
and 			cinelight_package_intra_pattern.patt_day = datepart(dw, dateadd(dd, 1, cinelight_spot.screening_date))
and				dateadd(dd, 1, cinelight_spot.screening_date) is not null
and				cinelight_spot.campaign_no = @campaign_no
and				(cinelight_spot.screening_date >= @start_date or @start_date is null)
and				(cinelight_spot.screening_date <= @end_date or @end_date is null)
and				(cinelight_spot.package_id = @package_id or @package_id is null)
and				(spot_status = @spot_status or @spot_status is null)
and				(spot_type = @spot_type or @spot_type is null)
and				cinelight_id  in (SELECT * FROM OPENXML (@handle, '/ids/id') WITH (id INT '.'))
union all
select 		spot_id, 
					DATEADD(ms, DATEDIFF(ms, 0, cinelight_package_intra_pattern.start_date), dateadd(dd, 2, DATEDIFF(dd, 2, dateadd(dd, 2, cinelight_spot.screening_date)))),
					DATEADD(ms, DATEDIFF(ms, 0, cinelight_package_intra_pattern.end_date), dateadd(dd, 2, DATEDIFF(dd, 2, dateadd(dd, 2, cinelight_spot.screening_date))))
from			cinelight_package_burst, 
					cinelight_package_intra_pattern,
					cinelight_spot
where 		cinelight_package_intra_pattern.package_id = cinelight_package_burst.package_id 
and 			cinelight_spot.package_id = cinelight_package_burst.package_id 
and 			cinelight_spot.package_id =cinelight_package_intra_pattern.package_id
and 			cinelight_package_burst.start_date <= dateadd(dd, 2, cinelight_spot.screening_date) 
and 			cinelight_package_burst.end_date >= dateadd(dd, 2, cinelight_spot.screening_date) 
and 			cinelight_package_intra_pattern.patt_day = datepart(dw, dateadd(dd, 2, cinelight_spot.screening_date))
and				cinelight_spot.campaign_no = @campaign_no
and				(cinelight_spot.screening_date >= @start_date or @start_date is null)
and				(cinelight_spot.screening_date <= @end_date or @end_date is null)
and				(cinelight_spot.package_id = @package_id or @package_id is null)
and				(spot_status = @spot_status or @spot_status is null)
and				(spot_type = @spot_type or @spot_type is null)
and				cinelight_id  in (SELECT * FROM OPENXML (@handle, '/ids/id') WITH (id INT '.'))
union all
select 		spot_id, 
					DATEADD(ms, DATEDIFF(ms, 0, cinelight_package_intra_pattern.start_date), dateadd(dd, 3, DATEDIFF(dd, 3, dateadd(dd, 3, cinelight_spot.screening_date)))),
					DATEADD(ms, DATEDIFF(ms, 0, cinelight_package_intra_pattern.end_date), dateadd(dd, 3, DATEDIFF(dd, 3, dateadd(dd, 3, cinelight_spot.screening_date))))
from			cinelight_package_burst, 
					cinelight_package_intra_pattern,
					cinelight_spot
where		cinelight_package_intra_pattern.package_id = cinelight_package_burst.package_id 
and 			cinelight_spot.package_id = cinelight_package_burst.package_id 
and				cinelight_spot.package_id =cinelight_package_intra_pattern.package_id
and				cinelight_package_burst.start_date <= dateadd(dd, 3, cinelight_spot.screening_date) 
and				cinelight_package_burst.end_date >= dateadd(dd, 3, cinelight_spot.screening_date) 
and 			cinelight_package_intra_pattern.patt_day = datepart(dw, dateadd(dd, 3, cinelight_spot.screening_date))
and				cinelight_spot.campaign_no = @campaign_no
and				(cinelight_spot.screening_date >= @start_date or @start_date is null)
and				(cinelight_spot.screening_date <= @end_date or @end_date is null)
and				(cinelight_spot.package_id = @package_id or @package_id is null)
and				(spot_status = @spot_status or @spot_status is null)
and				(spot_type = @spot_type or @spot_type is null)
and				cinelight_id  in (SELECT * FROM OPENXML (@handle, '/ids/id') WITH (id INT '.'))
union all
select 		spot_id, 
					DATEADD(ms, DATEDIFF(ms, 0, cinelight_package_intra_pattern.start_date), dateadd(dd, 4, DATEDIFF(dd, 4, dateadd(dd, 4, cinelight_spot.screening_date)))),
					DATEADD(ms, DATEDIFF(ms, 0, cinelight_package_intra_pattern.end_date), dateadd(dd, 4, DATEDIFF(dd, 4, dateadd(dd, 4, cinelight_spot.screening_date))))
from 			cinelight_package_burst, 
					cinelight_package_intra_pattern,
					cinelight_spot
where 		cinelight_package_intra_pattern.package_id = cinelight_package_burst.package_id 
and 			cinelight_spot.package_id = cinelight_package_burst.package_id 
and 			cinelight_spot.package_id =cinelight_package_intra_pattern.package_id
and 			cinelight_package_burst.start_date <= dateadd(dd, 4, cinelight_spot.screening_date) 
and 			cinelight_package_burst.end_date >= dateadd(dd, 4, cinelight_spot.screening_date) 
and 			cinelight_package_intra_pattern.patt_day = datepart(dw, dateadd(dd, 4, cinelight_spot.screening_date))
and				cinelight_spot.campaign_no = @campaign_no
and				(cinelight_spot.screening_date >= @start_date or @start_date is null)
and				(cinelight_spot.screening_date <= @end_date or @end_date is null)
and				(cinelight_spot.package_id = @package_id or @package_id is null)
and				(spot_status = @spot_status or @spot_status is null)
and				(spot_type = @spot_type or @spot_type is null)
and				cinelight_id  in (SELECT * FROM OPENXML (@handle, '/ids/id') WITH (id INT '.'))
union all
select 		spot_id, 
					DATEADD(ms, DATEDIFF(ms, 0, cinelight_package_intra_pattern.start_date), dateadd(dd, 5, DATEDIFF(dd, 5, dateadd(dd, 5, cinelight_spot.screening_date)))),
					DATEADD(ms, DATEDIFF(ms, 0, cinelight_package_intra_pattern.end_date), dateadd(dd, 5, DATEDIFF(dd, 5, dateadd(dd, 5, cinelight_spot.screening_date))))
from 			cinelight_package_burst, 
					cinelight_package_intra_pattern,
					cinelight_spot
where 		cinelight_package_intra_pattern.package_id = cinelight_package_burst.package_id 
and 			cinelight_spot.package_id = cinelight_package_burst.package_id 
and 			cinelight_spot.package_id =cinelight_package_intra_pattern.package_id
and 			cinelight_package_burst.start_date <= dateadd(dd, 5, cinelight_spot.screening_date) 
and 			cinelight_package_burst.end_date >= dateadd(dd, 5, cinelight_spot.screening_date) 
and 			cinelight_package_intra_pattern.patt_day = datepart(dw, dateadd(dd, 5, cinelight_spot.screening_date))
and				cinelight_spot.campaign_no = @campaign_no
and				(cinelight_spot.screening_date >= @start_date or @start_date is null)
and				(cinelight_spot.screening_date <= @end_date or @end_date is null)
and				(cinelight_spot.package_id = @package_id or @package_id is null)
and				(spot_status = @spot_status or @spot_status is null)
and				(spot_type = @spot_type or @spot_type is null)
and				cinelight_id  in (SELECT * FROM OPENXML (@handle, '/ids/id') WITH (id INT '.'))
union all
select 		spot_id, 
					DATEADD(ms, DATEDIFF(ms, 0, cinelight_package_intra_pattern.start_date), dateadd(dd, 6, DATEDIFF(dd, 6, dateadd(dd, 6, cinelight_spot.screening_date)))),
					DATEADD(ms, DATEDIFF(ms, 0, cinelight_package_intra_pattern.end_date), dateadd(dd, 6, DATEDIFF(dd, 6, dateadd(dd, 6, cinelight_spot.screening_date))))
from 			cinelight_package_burst, 
					cinelight_package_intra_pattern,
					cinelight_spot
where 		cinelight_package_intra_pattern.package_id = cinelight_package_burst.package_id 
and 			cinelight_spot.package_id = cinelight_package_burst.package_id 
and 			cinelight_spot.package_id = cinelight_package_intra_pattern.package_id
and 			cinelight_package_burst.start_date <= dateadd(dd, 6, cinelight_spot.screening_date) 
and 			cinelight_package_burst.end_date >= dateadd(dd, 6, cinelight_spot.screening_date) 
and 			cinelight_package_intra_pattern.patt_day = datepart(dw, dateadd(dd, 6, cinelight_spot.screening_date))
and				dateadd(dd, 6, cinelight_spot.screening_date) is not null
and				cinelight_spot.campaign_no = @campaign_no
and				(cinelight_spot.screening_date >= @start_date or @start_date is null)
and				(cinelight_spot.screening_date <= @end_date or @end_date is null)
and				(cinelight_spot.package_id = @package_id or @package_id is null)
and				(spot_status = @spot_status or @spot_status is null)
and				(spot_type = @spot_type or @spot_type is null)
and				cinelight_id  in (SELECT * FROM OPENXML (@handle, '/ids/id') WITH (id INT '.'))

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error: Failed to insert new segments', 16, 1)
	return -1
end

/*
 * Commit & Return
 */ 

commit transaction
return 0
GO
