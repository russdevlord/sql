/****** Object:  StoredProcedure [dbo].[p_film_campaign_status_change]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_status_change]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_status_change]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_film_campaign_status_change]	@campaign_no	 	int,
											@mode				char(1),
											@type				char(1)
as

declare		@error		int
			
set nocount on

begin transaction

if @mode = 'C'
begin
	if @type = 'C'
	begin
		update 	cinelight_spot
		set    	spot_status = 'A'
		where  	screening_date is not null
		and		campaign_no = @campaign_no
		and		spot_status = 'P'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	

		update 	cinelight_spot
		set    	spot_status = 'C'
		where  	screening_date is  null
		and		campaign_no = @campaign_no
		and		spot_status = 'P'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	

		update 	cinelight_package
		set    	cinelight_package_status = 'L'
		where  	campaign_no = @campaign_no
		and		cinelight_package_status = 'P'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	

		update 	film_campaign
		set    	cinelight_status = 'L'
		where  	campaign_no = @campaign_no
		and		cinelight_status = 'P'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	
	end
	else if @type = 'I'
	begin
		update 	inclusion_spot
		set    	spot_status = 'A'
		where  	screening_date is not null
		and		campaign_no = @campaign_no
		and		spot_status = 'P'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	

		update 	inclusion_spot
		set    	spot_status = 'C'
		from	inclusion
		where  	screening_date is  null
		and		inclusion_spot.campaign_no = @campaign_no
		and		spot_status = 'P'
		and		inclusion.inclusion_id = inclusion_spot.inclusion_id
		and		inclusion_format= 'C'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	

		update 	inclusion_spot
		set    	spot_status = 'A'
		from	inclusion
		where  	screening_date is  null
		and		inclusion_spot.campaign_no = @campaign_no
		and		spot_status = 'P'
		and		inclusion.inclusion_id = inclusion_spot.inclusion_id
		and		inclusion_format<> 'C'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	

		update 	inclusion
		set    	inclusion_status = 'L'
		where  	campaign_no = @campaign_no
		and		inclusion_status = 'P'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	

		update 	film_campaign
		set    	inclusion_status = 'L'
		where  	campaign_no = @campaign_no
		and		inclusion_status = 'P'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	
	end
	else if @type = 'O'
	begin
		update 	outpost_spot
		set    	spot_status = 'A'
		where  	screening_date is not null
		and		campaign_no = @campaign_no
		and		spot_status = 'P'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	

		update 	outpost_spot
		set    	spot_status = 'C'
		where  	screening_date is  null
		and		campaign_no = @campaign_no
		and		spot_status = 'P'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	

		update 	outpost_package
		set    	package_status = 'L'
		where  	campaign_no = @campaign_no
		and		package_status = 'P'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	

		update 	film_campaign
		set    	outpost_status = 'L'
		where  	campaign_no = @campaign_no
		and		outpost_status = 'P'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	
	end
end
else if @mode = 'U'
begin
	if @type = 'C'
	begin
		update 	film_campaign
		set    	cinelight_status = 'P'
		where  	campaign_no = @campaign_no
		and		cinelight_status = 'L'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	
	end
	else if @type = 'I'
	begin
		update 	film_campaign
		set    	inclusion_status = 'P'
		where  	campaign_no = @campaign_no
		and		inclusion_status = 'L'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	
	end
	else if @type = 'O'
	begin
		update 	film_campaign
		set    	outpost_status = 'P'
		where  	campaign_no = @campaign_no
		and		outpost_status = 'L'
	
		select @error = @@error
		if @error <> 0
		begin
			raiserror ('', 16, 1)
			rollback transaction
			return -1
		end	
	end
end

commit transaction
return 0
GO
