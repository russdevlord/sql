/****** Object:  StoredProcedure [dbo].[p_loop_op_player]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_loop_op_player]
GO
/****** Object:  StoredProcedure [dbo].[p_loop_op_player]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_loop_op_player]

as

declare     @player_name        varchar(100), 
            @r_code             int


declare op_pl_loop cursor static for
select player_name
from outpost_player
order by player_name

open op_pl_loop
fetch op_pl_loop into @player_name
while(@@fetch_status = 0)
begin

    exec @r_code = p_op_player_date_activation @player_name
    
    fetch op_pl_loop into @player_name

end

return 0
GO
