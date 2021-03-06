/****** Object:  UserDefinedFunction [dbo].[f_cinetam_movie_match_group_xref]    Script Date: 12/03/2021 10:03:48 AM ******/
DROP FUNCTION [dbo].[f_cinetam_movie_match_group_xref]
GO
/****** Object:  UserDefinedFunction [dbo].[f_cinetam_movie_match_group_xref]    Script Date: 12/03/2021 10:03:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create  function [dbo].[f_cinetam_movie_match_group_xref] (@movie_id integer) returns @movie_ids table (movie_id integer) 
as
begin
							
	insert into @movie_ids
		select	movie_id
		from	cinetam_movie_match_group_xref
		where	cinetam_movie_match_group_id in ( select		cinetam_movie_match_group_id 
																						from		cinetam_movie_match_group_xref 
																						where		movie_id = @movie_id )	
		and		movie_id <> @movie_id
	

	return
end

GO
