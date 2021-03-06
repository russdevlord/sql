/****** Object:  StoredProcedure [dbo].[p_get_previous_diary_entry]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_previous_diary_entry]
GO
/****** Object:  StoredProcedure [dbo].[p_get_previous_diary_entry]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_get_previous_diary_entry]  @campaign_no 	char(7),
													 @entry_date   datetime,
													 @diary_type   char(1)
as
set nocount on 

declare  @row_count  		integer,
		   @campaign		char(7),
		   @entry_no			integer,
		   @followup_user		integer,	
		   @followup_date		datetime,
		   @followup_comment	varchar(255),
			@action_user		integer,
			@action_date		datetime,
			@comm1		varchar(255),
			@comm2		varchar(255),
			@comm3		varchar(255),
			@comm4		varchar(255)

/*
 * Overview of script.
 * If @entry_date is null, return entry with max action date, and max entry no
 * otherwise return entry with max action date that is less than entry date and
 * with max entry no. This ensures the latest entry if multiple entries on that 
 * date.
 */

/* 
 * Diary Type C = Credit Diary
 */

if @diary_type = 'C'
begin
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
		 FROM credit_diary
		WHERE (credit_diary.action_flag = 'Y') AND  
				(credit_diary.campaign_no = @campaign_no) and
				(credit_diary.action_date = (select max(cd.action_date)
														 from credit_diary cd
														 where cd.campaign_no = @campaign_no and cd.action_flag = 'Y') ) AND  
				(credit_diary.entry_no =    (select max(cd.entry_no)
														  from credit_diary cd
													    where cd.campaign_no = @campaign_no and cd.action_flag = 'Y') ) 
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
		 FROM credit_diary
		WHERE (credit_diary.action_flag = 'Y') AND  
				(credit_diary.campaign_no = @campaign_no) and
				(credit_diary.action_date = (select max(cd.action_date)
														 from credit_diary cd
														 where cd.action_date < @entry_date and
																 cd.campaign_no = @campaign_no and cd.action_flag = 'Y') ) AND  
				(credit_diary.entry_no =    (select max(cd.entry_no)
														  from credit_diary cd
													    where cd.action_date < @entry_date and
																 cd.campaign_no = @campaign_no and cd.action_flag = 'Y') ) 
	end
end

/* 
 * Diary Type A = Action Diary
 */

else if @diary_type = 'A'
begin
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
		 FROM admin_diary
		WHERE (admin_diary.action_flag = 'Y') AND  
				(admin_diary.campaign_no = @campaign_no) and
				(admin_diary.action_date = (select max(ad.action_date)
														 from admin_diary ad
														 where ad.campaign_no = @campaign_no and ad.action_flag = 'Y') ) AND  
				(admin_diary.entry_no =    (select max(ad.entry_no)
														  from admin_diary ad
													    where ad.campaign_no = @campaign_no and ad.action_flag = 'Y') ) 

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
		 FROM admin_diary
		WHERE (admin_diary.action_flag = 'Y') AND  
				(admin_diary.campaign_no = @campaign_no) and
				(admin_diary.action_date = (select max(ad.action_date)
														 from admin_diary ad
														 where ad.action_date < @entry_date and
																 ad.campaign_no = @campaign_no and ad.action_flag = 'Y') ) AND  
				(admin_diary.entry_no =    (select max(ad.entry_no)
														  from admin_diary ad
													    where ad.action_date < @entry_date and
																 ad.campaign_no = @campaign_no and ad.action_flag = 'Y') ) 

	end
end

/* 
 * Diary Type S = Service Diary
 */

else if @diary_type = 'S'
begin
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
		 FROM service_diary
		WHERE (service_diary.action_flag = 'Y') AND  
				(service_diary.campaign_no = @campaign_no) and
				(service_diary.action_date = (select max(sd.action_date)
														 from service_diary sd
														 where sd.campaign_no = @campaign_no and sd.action_flag = 'Y') ) AND  
				(service_diary.entry_no =    (select max(sd.entry_no)
														  from service_diary sd
													    where sd.campaign_no = @campaign_no and sd.action_flag = 'Y') ) 

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
		 FROM service_diary
		WHERE (service_diary.action_flag = 'Y') AND  
				(service_diary.campaign_no = @campaign_no) and
				(service_diary.action_date = (select max(sd.action_date)
														 from service_diary sd
														 where sd.action_date < @entry_date and
																 sd.campaign_no = @campaign_no and sd.action_flag = 'Y') ) AND  
				(service_diary.entry_no =    (select max(sd.entry_no)
														  from service_diary sd
													    where sd.action_date < @entry_date and
																 sd.campaign_no = @campaign_no and sd.action_flag = 'Y') ) 


	end
end

/* 
 * Diary Type D = Dsp Diary
 */

else if @diary_type = 'D'
begin
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
		 FROM dsp_diary
		WHERE (dsp_diary.action_flag = 'Y') AND  
				(dsp_diary.campaign_no = @campaign_no) and
				(dsp_diary.action_date = (select max(ad.action_date)
														 from dsp_diary ad
														 where ad.campaign_no = @campaign_no and ad.action_flag = 'Y') ) AND  
				(dsp_diary.entry_no =    (select max(ad.entry_no)
														  from dsp_diary ad
													    where ad.campaign_no = @campaign_no and ad.action_flag = 'Y') ) 

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
		 FROM dsp_diary
		WHERE (dsp_diary.action_flag = 'Y') AND  
				(dsp_diary.campaign_no = @campaign_no) and
				(dsp_diary.action_date = (select max(ad.action_date)
														 from dsp_diary ad
														 where ad.action_date < @entry_date and
																 ad.campaign_no = @campaign_no and ad.action_flag = 'Y') ) AND  
				(dsp_diary.entry_no =    (select max(ad.entry_no)
														  from dsp_diary ad
													    where ad.action_date < @entry_date and
																 ad.campaign_no = @campaign_no and ad.action_flag = 'Y') ) 

	end
end

if @campaign is null
begin
	select @campaign_no = '      '
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
