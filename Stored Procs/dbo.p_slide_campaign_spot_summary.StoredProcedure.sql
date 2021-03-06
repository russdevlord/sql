/****** Object:  StoredProcedure [dbo].[p_slide_campaign_spot_summary]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_slide_campaign_spot_summary]
GO
/****** Object:  StoredProcedure [dbo].[p_slide_campaign_spot_summary]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_slide_campaign_spot_summary]	@campaign_no		char(7)
as

set nocount on 
declare		@error			integer,
			@sqlstatus		integer

create table #spot_summary
(
	spot_id						integer		null,
	spot_no						integer		null,
	spot_status					char(1)		null,
	spot_type					char(1)		null,
	billing_status				char(1)		null,
	screening_date				datetime		null,
	nett_rate					money			null,
	credit_value				money			null,
	ssd_screening_cycle			integer		null,
	br_screening_cycle			integer		null,
	scheduled_screenings		integer		null,
	bonus_screenings			integer		null,
	unassigned_screenings		integer		null
)

insert into #spot_summary
select scs.spot_id,
       scs.spot_no,
       scs.spot_status,
       scs.spot_type,
       scs.billing_status,
       scs.screening_date,
       scs.nett_rate,
       scs.credit_value,
       ssd.screening_cycle,
       br.screening_cycle,
       0,
       0,
       0
FROM	slide_campaign_spot AS scs LEFT OUTER JOIN
		slide_screening_dates AS ssd ON scs.screening_date = ssd.screening_date INNER JOIN
		slide_campaign AS sc ON scs.campaign_no = sc.campaign_no INNER JOIN
		branch AS br ON sc.branch_code = br.branch_code
WHERE	(scs.campaign_no = @campaign_no)

-- Set 'Scheduled' Screening Count
update #spot_summary
   set #spot_summary.scheduled_screenings = isnull((select count(*)
                                                      from slide_campaign_screening scs
                                                     where scs.spot_id = #spot_summary.spot_id and
                                                           scs.screening_type = 'S'), 0)

-- Set 'Bonus' Screening Count
update #spot_summary
   set #spot_summary.bonus_screenings = isnull((select count(*)
                                                      from slide_campaign_screening scs
                                                     where scs.spot_id = #spot_summary.spot_id and
                                                           scs.screening_type = 'B'), 0)

-- Set Unassigned Screening Count
update #spot_summary
   set #spot_summary.unassigned_screenings = isnull((select count(*)
                                                       from slide_campaign_screening scs
                                                      where scs.spot_id = #spot_summary.spot_id and
                                                            scs.carousel_id is null), 0)

select spot_id,
       spot_no,
       spot_status,
       spot_type,
       billing_status,
       screening_date,
       nett_rate,
       credit_value,
       ssd_screening_cycle,
       br_screening_cycle,
       scheduled_screenings,
       bonus_screenings,
       unassigned_screenings
  from #spot_summary

return 0
GO
