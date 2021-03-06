/****** Object:  StoredProcedure [dbo].[p_cinatt_camp_prop_attend]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_camp_prop_attend]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_camp_prop_attend]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_camp_prop_attend] @campaign_no		integer
as

/* Gets total estimated attendance for campaign proposal */

/*
 * Declare Variables
 */

declare @errorode						integer,
	    @actual_attendance		integer

select @actual_attendance = 0

exec   @errorode = p_cinatt_camp_prop_attend_out @campaign_no, @actual_attendance OUTPUT

if @errorode = 0
begin
    select @actual_attendance 'attendance'
    return 0
end
else
begin
    select 0 'attendance'
    return -1
end
GO
