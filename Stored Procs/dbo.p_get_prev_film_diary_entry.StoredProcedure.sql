/****** Object:  StoredProcedure [dbo].[p_get_prev_film_diary_entry]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_prev_film_diary_entry]
GO
/****** Object:  StoredProcedure [dbo].[p_get_prev_film_diary_entry]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_get_prev_film_diary_entry]  @campaign_no 	integer,
													 		@entry_date   datetime
as
set nocount on 

declare  @row_count  		integer,
	@campaign		integer,
	@entry_no		integer,
	@followup_user		integer,	
	   @followup_date	datetime,
	   @followup_comment	varchar(255),
	@action_user		integer,
	@action_date		datetime,
	@comm1			varchar(255),
	@comm2			varchar(255),
	@comm3			varchar(255),
	@comm4			varchar(255)

/*
 * Overview of script.
 * If @entry_date is null, return entry with max action date, and max entry no
 * otherwise return entry with max action date that is less than entry date and
 * with max entry no. This ensures the latest entry if multiple entries on that 
 * date.
 */

/* 
 * Diary Type F = Film Diary
 */

if (@entry_date is null) 
begin

  SELECT @campaign  = campaign_no,
			@entry_no =  entry_no,
			@followup_date = followup_date,
			@followup_comment = followup_comment,
			@followup_user = followup_user,
			@action_date = action_date,
			@action_user = action_user,
			@comm1 = isnull(action_comm1,''),
			@comm2 = isnull(action_comm2,''),
			@comm3 = isnull(action_comm3,''),
			@comm4 = isnull(action_comm4,'')
	 FROM film_diary
	WHERE (film_diary.action_flag = 'Y') AND  
			(film_diary.campaign_no = @campaign_no) and
			(film_diary.action_date = (select max(fd.action_date)
													 from film_diary fd
													 where fd.campaign_no = @campaign_no and fd.action_flag = 'Y') ) AND  
			(film_diary.entry_no =    (select max(fd.entry_no)
													  from film_diary fd
													 where fd.campaign_no = @campaign_no and fd.action_flag = 'Y') ) 
end
else
begin
  SELECT @campaign  = campaign_no,
			@entry_no =  entry_no,
			@followup_date = followup_date,
			@followup_comment = followup_comment,
			@followup_user = followup_user,
			@action_date = action_date,
			@action_user = action_user,
			@comm1 = isnull(action_comm1,''),
			@comm2 = isnull(action_comm2,''),
			@comm3 = isnull(action_comm3,''),
			@comm4 = isnull(action_comm4,'')
	 FROM film_diary
	WHERE (film_diary.action_flag = 'Y') AND  
			(film_diary.campaign_no = @campaign_no) and
			(film_diary.action_date = (select max(fd.action_date)
													 from film_diary fd
													 where fd.action_date < @entry_date and
															 fd.campaign_no = @campaign_no and fd.action_flag = 'Y') ) AND  
			(film_diary.entry_no =    (select max(fd.entry_no)
													  from film_diary fd
													 where fd.action_date < @entry_date and
															 fd.campaign_no = @campaign_no and fd.action_flag = 'Y') ) 
end

SELECT @campaign  as campaign_no,
		@entry_no as  entry_no,
		@followup_date as followup_date,
		@followup_comment as followup_comment,
		@followup_user as followup_user,
		@action_date as action_date,
		@action_user as action_user,
		@comm1 as action_comm1,
		@comm2 as action_comm2,
		@comm3 as action_comm3,
		@comm4 as action_comm4,
		' ' as diary_type

return 0
GO
