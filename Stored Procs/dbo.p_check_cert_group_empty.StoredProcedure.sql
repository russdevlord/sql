/****** Object:  StoredProcedure [dbo].[p_check_cert_group_empty]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_check_cert_group_empty]
GO
/****** Object:  StoredProcedure [dbo].[p_check_cert_group_empty]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_check_cert_group_empty] @complex_id			integer,
                                      @screening_date		datetime
as

declare @empty_groups		integer,
		  @no_of_groups		integer

/*
 * Count Empty Groups
 */

select @empty_groups = count(certificate_group_id)
  from certificate_group
 where complex_id = @complex_id and
       screening_date = @screening_date and
       not exists ( select certificate_item_id
                      from certificate_item citem
                     where citem.certificate_group = certificate_group.certificate_group_id )

/*
 * Count All Groups
 */

select @no_of_groups = count(certificate_group_id)
  from certificate_group
 where complex_id = @complex_id and
       screening_date = @screening_date


if @empty_groups <> @no_of_groups
	select 0
else
	select 1

/*
 * Return
 */

return 0
GO
