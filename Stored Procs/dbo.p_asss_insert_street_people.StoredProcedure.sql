/****** Object:  StoredProcedure [dbo].[p_asss_insert_street_people]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_asss_insert_street_people]
GO
/****** Object:  StoredProcedure [dbo].[p_asss_insert_street_people]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create  proc [dbo].[p_asss_insert_street_people]

as

declare @error                  int,
        @complex_id             int,
        @seq_no                 int,
        @certificate_item_id    int,
        @certificate_group_id   int,
        @print_qty              int,
        @screening_date         datetime

set nocount on
        
declare complex_csr cursor forward_only static for
select  distinct complex_id 
from    film_shell_xref
where   shell_code = 'FSA0138'
order by complex_id

select @screening_date = '8-sep-2005'

begin transaction

open complex_csr
fetch complex_csr into @complex_id
while(@@fetch_status=0)
begin

    select @print_qty = sum(cinema_qty)
		  from print_transactions
		 where	 print_id = 7903 and
				 complex_id = @complex_id and
				 ptran_status = 'C'
 

    declare certificate_csr cursor forward_only static for
    select  certificate_group_id 
    from    certificate_group
    where   complex_id = @complex_id
    and     screening_date = @screening_date
    order by certificate_group_id
    
    open certificate_csr
    fetch certificate_csr into @certificate_group_id
    while(@@fetch_status=0 and @print_qty>0)
    begin
    
        execute @error = p_get_sequence_number 'certificate_item', 5, @certificate_item_id OUTPUT
        if (@error !=0)
        begin
	        rollback transaction
            raiserror ('Error: Failed to get seq_no', 16, 1)
            return -1
        end

        select @seq_no = sequence_no + 1
        from certificate_item 
        where certificate_group = @certificate_group_id
        and   print_id = 1   
        
            update certificate_item 
            set     sequence_no = sequence_no + 1 
            where   certificate_group = @certificate_group_id
            and     sequence_no >= @seq_no
            
            select @error = @@error
            if @error != 0
            begin
	            rollback transaction
                raiserror ('Error: Failed to get seq_no', 16, 1)
                return -1
            end

        insert into certificate_item (  certificate_item_id,
                                        certificate_group,
                                        print_id,
                                        sequence_no,
                                        item_show,
                                        certificate_auto_create,
                                        certificate_source,
                                        campaign_summary
                                        ) values
                                        (@certificate_item_id,
                                        @certificate_group_id,
                                        7903,
                                        @seq_no,
                                        'Y',
                                        'Y',
                                        'X',
                                        'Y'
                                        )
                                        
            select @error = @@error
            if @error != 0
            begin
	            rollback transaction
                raiserror ('Error: Failed to get seq_no', 16, 1)
                return -1
            end
                                                    
                                        
            

        select @print_qty = @print_qty - 1

        fetch certificate_csr into @certificate_group_id
    end
    
    deallocate certificate_csr

    fetch complex_csr into @complex_id
end

deallocate complex_csr 
commit transaction
return 0
GO
