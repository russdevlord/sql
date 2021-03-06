/****** Object:  StoredProcedure [dbo].[p_agreement_complex_validate]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_agreement_complex_validate]
GO
/****** Object:  StoredProcedure [dbo].[p_agreement_complex_validate]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_agreement_complex_validate]    @agreement_id   integer,
                                            @complex_id     integer,
                                            @complex_name   varchar(50),
                                            @rent_inc_start     datetime,
                                            @rent_inc_end       datetime,
                                            @rent_contrib_expiry    datetime
as
                             

declare @error        		    integer,
       -- @error                     integer,
        @result                 integer,
        @validate_msg           varchar(255),
        @cursor_agreement_no    char(6),
        @cursor_agreement_desc  varchar(50),
        @cursor_inclusion_start datetime,
        @cursor_inclusion_end   datetime,
		  @agr_exhibitor_cat		  char(1),
		  @cplx_exhibitor_cat	  char(1),
		  @csr_open					  integer



select  @result = 1
select  @csr_open = 0
select  @validate_msg = 'OK'
select  @rent_inc_end = isnull(@rent_inc_end,'31-dec-3999')

select @cplx_exhibitor_cat = exhibitor_category_code
  from complex
 where complex_id = @complex_id

select @agr_exhibitor_cat = exhibitor_category_code
  from cinema_agreement
 where cinema_agreement_id = @agreement_id

if @cplx_exhibitor_cat <> @agr_exhibitor_cat
begin
	select @result = -2
	goto error
end

/* Check agreement overlap */

select @csr_open = 1
declare complex_csr cursor static for
select  cinema_agreement.agreement_no,
        cinema_agreement.agreement_desc,
        cinema_agreement_complex.rent_inclusion_start,
        isnull(cinema_agreement_complex.rent_inclusion_end,'31-dec-3999') 'rent_inclusion_end'
from    cinema_agreement, cinema_agreement_complex
where   cinema_agreement.cinema_agreement_id = cinema_agreement_complex.cinema_agreement_id
and     cinema_agreement_complex.cinema_agreement_id != @agreement_id
and     cinema_agreement_complex.complex_id = @complex_id
for read only
open complex_csr
fetch complex_csr into @cursor_agreement_no, @cursor_agreement_desc, @cursor_inclusion_start, @cursor_inclusion_end
while(@@fetch_status = 0)
begin
    if  @rent_inc_start >= @cursor_inclusion_start and
        @rent_inc_start <= @cursor_inclusion_end
    begin
        select @result = -1
        goto error
    end

    if  @rent_inc_end >= @cursor_inclusion_end and
        @rent_inc_end <= @cursor_inclusion_end
    begin
        select @result = -1
        goto error
    end


    if  @rent_inc_start <= @cursor_inclusion_start and
        @rent_inc_end >= @cursor_inclusion_end
    begin
        select @result = -1
        goto error
    end

    fetch complex_csr into @cursor_agreement_no, @cursor_agreement_desc, @cursor_inclusion_start, @cursor_inclusion_end
end /*while*/

error:
if @csr_open = 1
begin
	close complex_csr
	deallocate complex_csr
end

if @result = -1
select  @validate_msg = 'ERROR: The period defined for this complex overlaps with another agreement. The Complex ' + @complex_name + 
                        ' also belongs to the Cinema Agreement: ' + @cursor_agreement_no + ', ' + @cursor_agreement_desc
if @result = -2
begin
	select  @validate_msg = 'ERROR: The Complex ' + @complex_name + ' does not have the same exhibitor category as this agreement.  You cannot add it this agreement.'
	select @result = -1
end

select  @result         'validation_result',
        @validate_msg   'validation_msg'

return 0
GO
