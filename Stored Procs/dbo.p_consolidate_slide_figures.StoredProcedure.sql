/****** Object:  StoredProcedure [dbo].[p_consolidate_slide_figures]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_consolidate_slide_figures]
GO
/****** Object:  StoredProcedure [dbo].[p_consolidate_slide_figures]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_consolidate_slide_figures] @current_origin datetime,
                                   		 @new_origin datetime
as
set nocount on 
declare @error				integer,
		@figure_csr_open	tinyint,
		@slide_figure_id	integer,
		@origin_period		datetime


/*
 * Initialise Variables
 */

select @figure_csr_open = 0

/*
 * Declare Cursor
 */ 
 declare figure_csr cursor static for
  select figure_id,
			origin_period
    from slide_figures
   where origin_period = @current_origin
     for read only
/*
 * Loop through Figures
 */
open figure_csr
fetch figure_csr into @slide_figure_id, 
							 @origin_period

while(@@fetch_status=0)
begin

	update slide_figures
		set origin_period = @new_origin
	 where figure_id = @slide_figure_id

	/*
    * Fetch Next Spot
    */

	fetch figure_csr into @slide_figure_id, 
								 @origin_period							  

end

close figure_csr
deallocate figure_csr

/*
 * Return Success
 */

return 0

/*
 * Error Handler
 */

error:

	if (@figure_csr_open = 1)
   begin
		close figure_csr
		deallocate figure_csr
	end
	return -1
GO
