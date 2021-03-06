/****** Object:  UserDefinedFunction [dbo].[f_package_restricted_classification]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_package_restricted_classification]
GO
/****** Object:  UserDefinedFunction [dbo].[f_package_restricted_classification]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[f_package_restricted_classification] (@package_id int)
RETURNS varchar(max)
AS
BEGIN
   DECLARE  @restricted_classification    varchar(max),
            @long_name          varchar(50),
            @remove_comma		char(1)


    select  @remove_comma = 'N',
            @restricted_classification = ''
            
    declare			restricted_csr cursor for
    select			classification_desc
    from			classification 
	inner join		campaign_classification_rev on classification.classification_id = campaign_classification_rev.classification_id
	where			campaign_classification_rev.package_id = @package_id
    and				instruction_type = 3
    group by		classification_desc
    order by		classification_desc
    for				read only
            
    open restricted_csr
    fetch restricted_csr into @long_name
    while(@@fetch_status = 0)
    begin
        select @remove_comma = 'Y'
        select  @restricted_classification = @restricted_classification  + @long_name + ', '
        
        fetch restricted_csr into @long_name
    end
    
    deallocate restricted_csr

    if @remove_comma = 'Y'
        select @restricted_classification = left(@restricted_classification, len(@restricted_classification) - 1)
    
    return(@restricted_classification) 

   
END
GO
