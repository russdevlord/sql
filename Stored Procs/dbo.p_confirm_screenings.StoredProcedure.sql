/****** Object:  StoredProcedure [dbo].[p_confirm_screenings]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_confirm_screenings]
GO
/****** Object:  StoredProcedure [dbo].[p_confirm_screenings]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_confirm_screenings] @screening_date datetime,
											@complex_id		 int
as

declare @error			int,
        @count			smallint,
        @cert_group	int

/*
 * Begin Transaction
 */

begin transaction

/*
 * Update Confirmed Status
 */

update 	complex_date 
set 	movies_confirmed = 1 
where 	complex_id = @complex_id
and 	screening_date = @screening_date

select @error = @@error
if ( @error !=0 )
begin
	rollback transaction
	raiserror ( 'Error', 16, 1) 
	return @error
end	

/*
 * Update No Shows
 */

-- no sessions cursor
declare 	no_sesssion_csr cursor static for
select 		certificate_group
from 		movie_history
where 		screening_date = @screening_date 
and			complex_id = @complex_id
group by 	certificate_group
having 		sum(sessions_held) = 0
order by 	certificate_group
for 		read only

open no_sesssion_csr
fetch no_sesssion_csr into @cert_group
while( @@fetch_status = 0)
begin

	update 	campaign_spot
	set 	spot_status = 'N'
	from 	certificate_group,
			certificate_item
	where 	certificate_group.certificate_group_id = @cert_group
	and		certificate_group.certificate_group_id = certificate_item.certificate_group
	and		certificate_item.spot_reference = campaign_spot.spot_id 


	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		close no_sesssion_csr
		deallocate no_sesssion_csr
		return @error
	end	

	fetch no_sesssion_csr into @cert_group

end
close no_sesssion_csr
deallocate no_sesssion_csr

/*
 * Update Do Shows
 */

-- have sessions 
declare 	have_session_csr cursor static for
select 		certificate_group
from 		movie_history 
where 		screening_date = @screening_date 
and			complex_id = @complex_id
group by 	certificate_group
having 		sum(sessions_held) > 0
order by 	certificate_group
for 		read only 

open have_session_csr
fetch have_session_csr into @cert_group
while( @@fetch_status = 0)
begin

	update 	campaign_spot
	set 	spot_status = 'X'
	from 	certificate_group,
			certificate_item
	where 	certificate_group.certificate_group_id = @cert_group 
	and		certificate_group.certificate_group_id = certificate_item.certificate_group 
	and		certificate_item.spot_reference = campaign_spot.spot_id 
	and		spot_status = 'N' 	
	and		campaign_spot.spot_redirect is null

	select @error = @@error
	if ( @error !=0 )
	begin
		rollback transaction
		raiserror ( 'Error', 16, 1) 
		close no_sesssion_csr
		deallocate have_session_csr
		return @error
	end	

	fetch have_session_csr into @cert_group

end
close have_session_csr
deallocate have_session_csr


/*
 * Commit and Return
 */

commit transaction
return 0
GO
