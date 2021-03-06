/****** Object:  StoredProcedure [dbo].[p_certificate_cineads_constraints]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_certificate_cineads_constraints]
GO
/****** Object:  StoredProcedure [dbo].[p_certificate_cineads_constraints]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_certificate_cineads_constraints]	@complex_id			int

as

declare			@error				int,
				@branch_code		char(2),
				@exhibitor_id		int
				
create table #capacity
(
max_ads				int,
max_time			int
)

/*select			@branch_code = branch_code,
				@exhibitor_id = exhibitor_id
from			complex
where			complex_id = @complex_id

if (@branch_code = 'S' or @branch_code = 'W') and @complex_id not in (124,456,462,593,602,604,1038, 1250,1251,1253,1254, 1479, 684, 1164,1165,1166,1169,1171,1172,1173,1174,1175,1246,1259,1413,1551, 1569, 1589, 710, 485)
begin
	insert into #capacity values (16, 240)
	
	select @error = @@error 
	if @error <> 0
	begin
		raiserror ('Failed to load CINEads capacity settings', 16, 1)
		return -1
	end
end
else if (@branch_code = 'N' or @branch_code = 'V' or @branch_code = 'Q') and @exhibitor_id = 205
begin
	insert into #capacity values (10, 150)
	
	select @error = @@error 
	if @error <> 0
	begin
		raiserror ('Failed to load CINEads capacity settings', 16, 1)
		return -1
	end
end
else
begin
	if @complex_id  in  (124,456,462,593,602,604,1038, 1250,1251,1253,1254, 1479, 684, 1564, 1569, 710, 485)
	begin
		insert into #capacity values (12, 180)
		
		select @error = @@error 
		if @error <> 0
		begin
			raiserror ('Failed to load CINEads capacity settings', 16, 1)
			return -1
		end
	end
	else
	begin
		insert into #capacity values (8, 120)
		
		select @error = @@error 
		if @error <> 0
		begin
			raiserror ('Failed to load CINEads capacity settings', 16, 1)
			return -1
		end
	end
end*/

insert into #capacity select * from dbo.f_cineads_constraints(@complex_id)

	
select @error = @@error 
if @error <> 0
begin
	raiserror ('Failed to load CINEads capacity settings', 16, 1)
	return -1
end


select max_ads, max_time from #capacity
return 0
GO
