/****** Object:  StoredProcedure [dbo].[p_cinatt_campaign_attendance]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinatt_campaign_attendance]
GO
/****** Object:  StoredProcedure [dbo].[p_cinatt_campaign_attendance]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_cinatt_campaign_attendance] @campaign_no		integer
as

/*
 * Declare Variables
  */

declare @actual_attendance      integer,
        @last_generated_date    datetime,
        @data_valid             char(1),
          @disclaimer_1     varchar(255),
          @disclaimer_2     varchar(255)


select  @actual_attendance = 0,
        @data_valid = 'N'

select @disclaimer_1 = 'Calculation not valid due to missing attendance data. Please refer to Film Campaign for details.'
select @disclaimer_2 = 'Please note the attendance figure does not include data for regional complexes as this data is not currently available.'

if exists
        (select 1
         from   film_campaign
         where  campaign_no = @campaign_no
         and    attendance_analysis = 'Y')
begin

  SELECT   @actual_attendance = sum(a.attendance),
           @last_generated_date = max(a.screening_date)
    FROM attendance_campaign_actuals a
 where a.campaign_no = @campaign_no
 
    select @data_valid = 'Y'
    if exists (select 1 from attendance_campaign_actuals where campaign_no = @campaign_no and data_valid <> 'Y')
        if exists (select 1 from attendance_campaign_actuals where campaign_no = @campaign_no and data_valid = 'N')
            select @data_valid = 'N'
        else
            select @data_valid = 'M'  /* special case for NZ where there is missing regional data */ 

end


select @actual_attendance 'attendance',
       @last_generated_date 'generated_date',
       @data_valid 'data_valid',
        @disclaimer_1 'cinatt_disclaimer_1',
        @disclaimer_2 'cinatt_disclaimer_2'

Return 0
GO
