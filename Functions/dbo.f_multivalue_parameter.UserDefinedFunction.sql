/****** Object:  UserDefinedFunction [dbo].[f_multivalue_parameter]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_multivalue_parameter]
GO
/****** Object:  UserDefinedFunction [dbo].[f_multivalue_parameter]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



create  function [dbo].[f_multivalue_parameter] (@parameter_to_be_split nvarchar(max), @delimiter char(1)= ',') returns @split_values table (param nvarchar(max)) 
as
begin
	declare		@delimiter_find			int,
						@parameter_piece		nvarchar(100)
							
	select @delimiter_find = 1 
	
	while @delimiter_find > 0
	begin
	
		select @delimiter_find = charindex(@delimiter, @parameter_to_be_split)
		
		if @delimiter_find  > 0
			select @parameter_piece = left(@parameter_to_be_split, @delimiter_find - 1)
		else
			select @parameter_piece = @parameter_to_be_split
		
		insert		@split_values(param)  values		(cast(@parameter_piece as varchar))
		
		select @parameter_to_be_split = right(@parameter_to_be_split,len(@parameter_to_be_split) - @delimiter_find)
		
		if len(@parameter_to_be_split) = 0 
			break
			
	end	

	return
end

GO
