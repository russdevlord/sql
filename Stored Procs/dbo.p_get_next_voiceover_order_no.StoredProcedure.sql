/****** Object:  StoredProcedure [dbo].[p_get_next_voiceover_order_no]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_get_next_voiceover_order_no]
GO
/****** Object:  StoredProcedure [dbo].[p_get_next_voiceover_order_no]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_get_next_voiceover_order_no]	@artwork_id		integer

as
set nocount on 
/*
 * Declare Procedure Variables
 */

declare  @order_no			integer


select @order_no = max(order_no) 
from 	artwork_voiceover
where artwork_id = @artwork_id

if @order_no = null 
begin
	select @order_no = 1
end else begin
     select @order_no = @order_no + 1
end

/*
 * Return
 */

select @order_no as order_no

return 0
GO
