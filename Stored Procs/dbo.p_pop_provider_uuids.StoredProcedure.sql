/****** Object:  StoredProcedure [dbo].[p_pop_provider_uuids]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_pop_provider_uuids]
GO
/****** Object:  StoredProcedure [dbo].[p_pop_provider_uuids]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE   proc [dbo].[p_pop_provider_uuids]		@data_provider_id              int,
																			@start_date						datetime,
																			@end_date							datetime

as

select		distinct uuid
from			data_provider
inner join	exhibitor on data_provider.exhibitor_id = exhibitor.exhibitor_id
inner join complex on exhibitor.exhibitor_id = complex.exhibitor_id
inner join certificate_group on complex.complex_id = certificate_group.complex_id
inner join certificate_item on certificate_group.certificate_group_id = certificate_item.certificate_group
inner join	film_print_file_locations on certificate_item.print_id = film_print_file_locations.print_id
where		certificate_group.screening_date between dateadd(dd,-6, @start_date) and @end_date
and			data_provider.data_provider_id = @data_provider_id


return 0
GO
