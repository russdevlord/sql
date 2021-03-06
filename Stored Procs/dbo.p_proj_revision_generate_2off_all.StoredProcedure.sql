/****** Object:  StoredProcedure [dbo].[p_proj_revision_generate_2off_all]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_proj_revision_generate_2off_all]
GO
/****** Object:  StoredProcedure [dbo].[p_proj_revision_generate_2off_all]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[p_proj_revision_generate_2off_all]	
with recompile
as

/*
 * Declare Variables
 */

declare     @error_num           int,
				@campaign_no			int,
				@retcode 				int


	/*
	 * Declare Cursors
	 */
	 
	declare campaign_cursor cursor static for
	select campaign_no 
	from film_campaign 
	where year ( end_date ) >= 2004
	for read only    

    
    open campaign_cursor
    fetch campaign_cursor into @campaign_no
    while(@@fetch_status=0)
    begin

		
		EXECUTE @retcode = p_proj_revision_generate_2off  @campaign_no  , 0  , 1 

		print convert(char(6),@campaign_no)

	   fetch campaign_cursor into @campaign_no

	 end 

	 update revision_transaction set delta_date = getdate() 
	 where revision_transaction_type not in ( 1,3,4,7)
		and delta_date > getdate() ;

return 0
GO
