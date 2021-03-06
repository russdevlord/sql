/****** Object:  StoredProcedure [dbo].[p_reset_all_certificates]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_reset_all_certificates]
GO
/****** Object:  StoredProcedure [dbo].[p_reset_all_certificates]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_reset_all_certificates] @screening_date    datetime

as
set nocount on 
declare @error          int,
        @errorode          int,
        @complex_id     int,
        @branch_code    char(2)
        
  
begin transaction

declare complex_csr cursor static for
 select complex_id 
   from complex_date
  where screening_date = @screening_date
   and certificate_generation is not null
order by complex_id
   for read only

open complex_csr
fetch complex_csr into @complex_id
while(@@fetch_status=0)              
begin

    select @branch_code = branch_code 
      from complex
     where complex_id = @complex_id
     
     /*if @branch_code != 'Z'
     begin*/
        exec @errorode = p_certificate_reset @complex_id,@screening_date

        if @errorode != 0
        begin
            raiserror ('Error resetting', 16, 1)
            rollback transaction
            close complex_csr
            deallocate  complex_csr
            return -100    
        end
    --end
                                
    fetch complex_csr into @complex_id
end

close complex_csr
deallocate  complex_csr


commit transaction 
return 0
GO
