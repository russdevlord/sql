/****** Object:  StoredProcedure [dbo].[p_cinetrailers_trailers]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_cinetrailers_trailers]
GO
/****** Object:  StoredProcedure [dbo].[p_cinetrailers_trailers]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_cinetrailers_trailers]
	
	@type			varchar(10),
	@movie_id		int,
	@uuid			varchar(250),
	@trailer_name	varchar(100),
	@trailer_desc	varchar(800),
	@title			varchar(250)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    if @type = 'insert'
    begin
		insert into cinetam_trailers_trailers(movie_id,uuid, trailer_name, trailer_desc, title) 
		values(@movie_id ,@uuid,@trailer_name, @trailer_desc, @title)
    end
    
    else if @type = 'edit'
    begin
		update cinetam_trailers_trailers
		set movie_id = @movie_id,
			uuid =	@uuid,
			trailer_name = @trailer_name,
			trailer_desc = @trailer_desc,
			title = @title
		where movie_id = @movie_id
		and uuid = @uuid 
    end
    
    else if @type = 'delete'
    begin
		delete cinetam_trailers_trailers
		where movie_id = @movie_id
		and uuid = @uuid
    end 
END
GO
