/****** Object:  UserDefinedFunction [dbo].[f_gl_account]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_gl_account]
GO
/****** Object:  UserDefinedFunction [dbo].[f_gl_account]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[f_gl_account] (@trantype_id as int, @gl_prefix as varchar(4), @business_unit_id as int, @complex_id as int, @media_product_id as int = null)
RETURNS varchar(15)
AS
BEGIN
   DECLARE  @GL_Account                 varchar(15),
            @GL_code                    varchar(4),
            @rowcount                   int,
            @exhibitor_group_id         int,
            @media_product              char(2),
            @business_unit              char(2)

	/* 
	 * TranType_ID
	 */				            
	select  @GL_code = gl_code
	from    transaction_type
	where   trantype_id = @trantype_id

	if @@error <> 0 
		goto error

	/* 
	 * GL Prefix
	 */	
	if isnull(@GL_code, '') = ''
		/* if trantype_id is not specified - check the  @gl_prefix is*/
		begin
--			if isnull(@gl_prefix, 0) = 0 
--				goto error
		
			select @gl_code = ltrim(rtrim(isnull(@gl_prefix, '')))    
		end

    
	/*
     * Media Product Code
     */
     
    if ( not isnull(@media_product_id, 0)  = 0 ) and len(@gl_prefix) = 2
	    begin
	    
--	        if len(@gl_prefix) != 2 
--	            goto error
	            
	        select @media_product = (case @media_product_id
	            when 1 then '15'
	            when 2 then '25'
	            when 5 then '35'        
	            else convert(varchar,@media_product_id) end)
--	            else 'XX' end)
	            
--	        if @media_product = 'XX'
--	            goto error
	            
	        select @gl_code = @gl_code + ltrim(rtrim(@media_product))                        
	    end

    
    select @business_unit =  (case @business_unit_id
            when 1 then '70'
            when 2 then '10' --Agency Team
            when 3 then '20' --Direct Team    
			when 5 then '30' --Showcase Team    
            when 4 then '70' 
            when 6 then '90'
			else convert(varchar, @business_unit_id )
            end)

    /*
	 * Complex, Exhibitor Group
	 */    
	if not isnull(@complex_id, 0)  = 0
	    begin
-- 	        select  @exhibitor_group_id = accpac_exhibitor_group_id
-- 	        from    accpac_exhibitor_complex        
-- 	        where   accpac_exhibitor_complex.complex_id = @complex_id            
	        select  @exhibitor_group_id = accpac_exhibitor_group_id
	        from    complex
	        where   complex_id = @complex_id            
	
	        if @@error <> 0 
	            goto error
	    
--	         if isnull(@exhibitor_group_id, 0) = 0
--	            goto error

	         select @exhibitor_group_id = isnull(@exhibitor_group_id, 0) 

	    end                    
	else
	    /*
	    * Allow complex_id to be 0
	    */
	    begin                
	        select @exhibitor_group_id = 0
	    end      
        
        select @GL_Account = right( '0000' + ltrim(rtrim(convert(varchar, @gl_code))), 4) + '-' +
                             right( '00' + @business_unit, 2) + '-' +
                             right( '00' + convert(varchar, @exhibitor_group_id), 2) + '-' +
                             right( '0000' + convert(varchar, isnull(@complex_id,0)), 4)
    
        return(@GL_Account)
   
   error:
        return('0000-00-00-0000')
   
END

GO
