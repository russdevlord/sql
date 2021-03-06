/****** Object:  StoredProcedure [dbo].[p_add_shell_emergency]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_add_shell_emergency]
GO
/****** Object:  StoredProcedure [dbo].[p_add_shell_emergency]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_add_shell_emergency]

as

declare     @complex_id             int,
            @shell_code             char(7),
            @print_id               int,
            @certificate_group_id   int,
            @certificate_item_id    int,
            @sequence_no            int,
            @print_check            int,
            @prints_used            int,
            @prints_avail           int,
            @errorode                  int,
            @ignore_print_tracking  char(1)
            
            
set nocount on

declare shell_csr cursor forward_only for
select  film_shell.shell_code,
        complex_id,
        print_id,
        shell_ignore_prints
from    film_shell,
        film_shell_xref,
        film_shell_print,
        film_shell_dates
where   film_shell.shell_code = film_shell_xref.shell_code
and     film_shell.shell_code = film_shell_print.shell_code
and     film_shell.shell_code = film_shell_dates.shell_code
and     film_shell.shell_expired = 'N'        
and     film_shell_dates.screening_date = '8-jul-2010'
and     film_shell.shell_code in ('FSA0227','FSA0233','FSA0245','FSA0251','FSA0254','FSA0255')
order by film_shell.shell_code,
        complex_id,
        print_id,
        sequence_no
for     read only

begin transaction

open shell_csr
fetch shell_csr into @shell_code, @complex_id, @print_id, @ignore_print_tracking
while(@@fetch_status=0)
begin

    select  @prints_used = 0

    select  @prints_avail = isnull(sum(cinema_qty),0)
    from    print_transactions
    where   campaign_no is null 
    and     print_id = @print_id 
    and     complex_id = @complex_id 
    and     ptran_status = 'C'
    
    print   @shell_code

    declare certificate_group_csr cursor for
    select  certificate_group_id
    from    certificate_group
    where   complex_id = @complex_id
    and     screening_date = '8-jul-2010'
    and     premium_cinema <> 'Y'
    order by certificate_group_id
    

    open certificate_group_csr
    fetch certificate_group_csr into @certificate_group_id
    while(@@fetch_status = 0)
    begin
        
        select  @print_check = count(print_id)
        from    certificate_item
        where   certificate_group = @certificate_group_id     
        and     print_id = @print_id

        print @print_check
        print @prints_avail
        print @prints_used
        

        if @print_check = 0 and ((@prints_avail >= @prints_used) or @ignore_print_tracking = 'Y')
        begin
            select  @sequence_no = sequence_no
            from    certificate_item 
            where   certificate_group = @certificate_group_id     
            and     print_id = 5
            
            print @sequence_no
            
            update  certificate_item
            set     sequence_no = sequence_no + 1
            where   certificate_group = @certificate_group_id     
            and     sequence_no >= @sequence_no
            
            select @errorode = @@error
            if (@errorode !=0)
            begin
                raiserror ('Error', 16, 1)
                rollback transaction
                return -1
            end
            
            
            execute @errorode = p_get_sequence_number 'certificate_item',5,@certificate_item_id OUTPUT
            if (@errorode !=0)
            begin
                raiserror ('Error', 16, 1)
                rollback transaction
                return -1
            end
            
                         
                         
            insert into certificate_item
            (certificate_item_id,
            certificate_group,
            print_id,
            sequence_no,
            item_comment,
            item_show,
            certificate_auto_create,
            certificate_source,
            campaign_summary,
            premium_cinema)
            values
            (@certificate_item_id,
            @certificate_group_id,
            @print_id,
            @sequence_no,
            '',
            'Y',
            'N',
            'X',
            'N',
            'N')

            select @errorode = @@error
            if (@errorode !=0)
            begin
                raiserror ('Error', 16, 1)
                rollback transaction
                return -1
            end

            select @prints_used = @prints_used + 1
        end        

        fetch certificate_group_csr into @certificate_group_id
    end
    
    deallocate certificate_group_csr


    fetch shell_csr into @shell_code, @complex_id, @print_id, @ignore_print_tracking
end

commit transaction
return 0
GO
