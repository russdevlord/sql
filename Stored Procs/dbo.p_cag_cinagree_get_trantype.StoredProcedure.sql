/****** Object:  StoredProcedure [dbo].[p_cag_cinagree_get_trantype]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cag_cinagree_get_trantype]
GO
/****** Object:  StoredProcedure [dbo].[p_cag_cinagree_get_trantype]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_cag_cinagree_get_trantype]     @agreement_type         char(1),
                                            @tran_category          char(1),
                                            @revenue_source         char(1),
                                            @trantype_id            int OUTPUT,
                                            @tran_desc              varchar(255) OUTPUT

as
/* Proc name:   p_cag_cinagree_get_trantype
 * Author:      Grant Carlson
 * Date:        7/10/2003
 * Description: Returns a trantype_id and tran_desc based on rent_mode and revenue_source
 *
 * Changes:
*/                              

declare @error        				int,
        @err_msg                    varchar(150),
        --@error                         int,
        @trantype_code              varchar(5)

-- Determine trantype_code
if @tran_category = 'E' -- entitlement
begin
    if @agreement_type = 'V' -- variable
        select @trantype_code = 'CAGVE'

    if @agreement_type = 'F' -- fixed
        select @trantype_code = 'CAGFE'
        
    if @agreement_type = 'M' -- Min Guarantee
        select @trantype_code = 'CAGME'
end

if @tran_category = 'M' -- minumum guarantee overage entitlement
begin
    select @trantype_code = 'CAGEE'
end

if @tran_category = 'P' -- Rent Payment
begin
    if @agreement_type = 'V' -- variable
        select @trantype_code = 'CAGRP'

    if @agreement_type = 'F' -- fixed
        select @trantype_code = 'CAGFP'
        
    if @agreement_type = 'M' -- Min Guarantee
        select @trantype_code = 'CAGMP'
end

if @tran_category = 'X' -- Excess Rent Payment
begin
    select @trantype_code = 'CAGXP'
end

if @tran_category = 'A' -- entitlement adjustment
begin
    select @trantype_code = 'CAGEJ'
end

if @tran_category = 'J' -- payment adjustment
begin
    select @trantype_code = 'CAGPJ'
end

-- Get id and description
select  @trantype_id = isnull(trantype_id,0),
        @tran_desc = isnull(trantype_desc,'')
from    transaction_type
where   trantype_code = @trantype_code

-- Add any additional text to tran description
if @tran_category = 'E'
begin
    if @revenue_source = 'S'
       select @tran_desc = @tran_desc + ' for Slide Advertising'
       
    if @revenue_source = 'F'
       select @tran_desc = @tran_desc + ' for Film Advertising'
       
    if @revenue_source = 'D'
       select @tran_desc = @tran_desc + ' for DMG Advertising'
   
--REMOVE THIS FOR NOW       
--     if @revenue_source = 'P'
--        select @tran_desc = '(Fixed Amount) ' + @tran_desc          
 
end

return 0
GO
