/****** Object:  StoredProcedure [dbo].[p_cag_eom_main]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_eom_main]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_eom_main]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_eom_main]      @mode char(1),
                                @accounting_period    datetime,
                                @cinema_agreement_id  int = null
as
/* Proc name:   p_cag_eom_main
 * Author:      Grant Carlson
 * Date:        24/11/2003
 * Description: Main proc for EOM processing of each Cinema Agreement
 *
 * Changes: 
 *            28/1/2004 GC, Added Mode. E=Entitlements, P=Payments
 *                                      S=Statements, T=Payments and Statements, A=All
 *
 * ********* GC 29/7/2004 TEMP CODE TO BE REMOVED FOR PROCESSING NZ ********
*/ 

declare @error        				int,
        @err_msg                    varchar(150),
     --   @error                         int,
        @csr_cinema_agreement_id        int


select @error = 0

/* Pre-processing activates/de-activates policies, closes agreements, etc */
exec @error = p_cag_eom_pre_processing @accounting_period,@cinema_agreement_id
if @error != 0
    goto error

/* Agreement cursor static for all active agreements */
/* Only agreements with a valid mailing address can be processed */
declare cinagree_csr cursor static for
select  ca.cinema_agreement_id
from    cinema_agreement ca, address_xref, address
where   ca.agreement_status ='A'
and     ((cinema_agreement_id = @cinema_agreement_id) or (@cinema_agreement_id is null))
and     address_xref.address_owner_pk_int = ca.cinema_agreement_id
and     address_xref.address_category_code = 'AAP' -- cheque mailing address
and     address_xref.address_type_code = 'CAG' -- cinema agreement
and     address_xref.address_id = address.address_id
and     address_xref.version_no = address.version_no
and     address.active = 'Y'
order by ca.cinema_agreement_id
for read only
--and ca.currency_code != 'NZD' -- ********* TEMP TO BE REMOVED FOR PROCESSING NZ ********

open cinagree_csr
fetch cinagree_csr into @csr_cinema_agreement_id
while @@fetch_status = 0
begin
--select 'Processing Agreement # ' + convert(varchar(5),@csr_cinema_agreement_id)

    exec @error = p_cag_process_cinagree   @mode,
                                        @csr_cinema_agreement_id,
                                        @accounting_period

    if @error != 0
    begin
        exec @error = p_cag_eom_log    @mode,
                                    @accounting_period,
                                    @csr_cinema_agreement_id,
                                    'F'
        goto error_csr
    end

    exec @error = p_cag_eom_log    @mode,
                                @accounting_period,
                                @csr_cinema_agreement_id,
                                'Y'

    fetch cinagree_csr into @csr_cinema_agreement_id
end /*while*/

deallocate cinagree_csr

return 0

error_csr:
    deallocate cinagree_csr
error:
    if @error >= 50000
        raiserror (@err_msg, 16, 1)

    return -1
GO
