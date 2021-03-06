/****** Object:  StoredProcedure [dbo].[p_campaign_evaluation_cinatt_sub]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_campaign_evaluation_cinatt_sub]
GO
/****** Object:  StoredProcedure [dbo].[p_campaign_evaluation_cinatt_sub]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_campaign_evaluation_cinatt_sub] @campaign_no		integer
as

/*
 * Declare Variables
  */

declare @actual_attendance      integer,
        @last_generated_date    datetime,
        @data_valid             char(1),
        @disclaimer_1     varchar(255),
        @disclaimer_2     varchar(255),
	 	@product_desc		varchar(100),   
		@start_date		datetime,
		@end_date			datetime,
        @agency_name		varchar(50),
        @client_name		varchar(50)


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
    FROM film_cinatt_actuals a
 where a.campaign_no = @campaign_no
 
    select @data_valid = 'Y'
    if exists (select 1 from film_cinatt_actuals where campaign_no = @campaign_no and data_valid <> 'Y')
        if exists (select 1 from film_cinatt_actuals where campaign_no = @campaign_no and data_valid = 'N')
            select @data_valid = 'N'
        else
            select @data_valid = 'M'  /* special case for NZ where there is missing regional data */ 

end


  select @product_desc = fc.product_desc,   
		 @start_date = fc.start_date,
		 @end_date = fc.end_date,
         @agency_name = agency_name,
         @client_name = client_name
    from film_campaign fc,
         agency,
         client
   where fc.campaign_no = @campaign_no and
         fc.agency_id = agency.agency_id and
		 fc.client_id = client.client_id


select @actual_attendance 'attendance',
       @last_generated_date 'generated_date',
       @data_valid 'data_valid',
        @disclaimer_1 'cinatt_disclaimer_1',
        @disclaimer_2 'cinatt_disclaimer_2',
		@product_desc 'product_desc',
		@start_date 'start_date',
		@end_date 'end_date',
        @agency_name 'agency_name',
        @client_name 'client_name'	

Return 0
GO
