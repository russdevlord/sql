/****** Object:  StoredProcedure [dbo].[p_screening_cert_auto_confirm]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_screening_cert_auto_confirm]
GO
/****** Object:  StoredProcedure [dbo].[p_screening_cert_auto_confirm]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create	proc [dbo].[p_screening_cert_auto_confirm]

as

declare			@error			int

set nocount on

/*Insert Screening Confirmations where there are none*/

begin transaction

insert into	screening_confirmations
select			certificate_group_id, -1, null, 'auto confirm', 'system', 'Y', getdate()
from			(select			min(cg.certificate_group_id) as certificate_group_id,
											v_cert.complex_id,
											v_cert.screening_date
						from			v_screening_cert_auto_confirm v_cert,
											certificate_group	cg		
						where			v_cert.complex_id = cg.complex_id
						and				v_cert.screening_date = cg.screening_date
						group by		v_cert.complex_id,
											v_cert.screening_date) as temp_table
where			certificate_group_id not in (select certificate_group_id from screening_confirmations where certificate_item_id = -1 )

select @error = @@error
if @error <> 0
begin
	raiserror ('Error Insert Screening Confirmations where there are none', 16, 1)
	rollback transaction
	return -1
end

/*Update Screening Confirmations where there are some*/
update		screening_confirmations
set				HO_processed_flag = 'Y'
from			(select		min(cg.certificate_group_id) as certificate_group_id,
										v_cert.complex_id,
										v_cert.screening_date
					from			v_screening_cert_auto_confirm v_cert,
										certificate_group	cg		
					where			v_cert.complex_id = cg.complex_id
					and				v_cert.screening_date = cg.screening_date
					group by		v_cert.complex_id,
										v_cert.screening_date) as temp_table
where			temp_Table.certificate_group_id = screening_confirmations.certificate_group_id
and				certificate_item_id = -1				

select @error = @@error
if @error <> 0
begin
	raiserror ('Error Update Screening Confirmations where there are some', 16, 1)
	rollback transaction
	return -1
end


/*Update Complex Date*/
update		complex_date
set				movies_confirmed = 1
from			v_screening_cert_confirmed_portal
where			complex_date.complex_id = v_screening_cert_confirmed_portal.complex_id
and				complex_date.screening_date = v_screening_cert_confirmed_portal.screening_date	


select @error = @@error
if @error <> 0
begin
	raiserror ('Error Update Complex Date', 16, 1)
	rollback transaction
	return -1
end

commit transaction
return 0
GO
