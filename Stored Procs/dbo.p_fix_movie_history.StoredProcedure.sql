/****** Object:  StoredProcedure [dbo].[p_fix_movie_history]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_fix_movie_history]
GO
/****** Object:  StoredProcedure [dbo].[p_fix_movie_history]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_fix_movie_history]

as

declare     @error          int,
            @rowcount       int,
            @complex_id     int,
            @movie_id       int,
            @date           datetime,
            @screening_date           datetime,
            @attendance     int
            
set nocount on




declare     screen_csr cursor static forward_only for
select      distinct screening_date
from        attendance_raw
group by    screening_date
order by    screening_date
for         read only


open screen_csr
fetch screen_csr into @screening_date
while(@@fetch_status=0)
begin
    begin transaction
    declare     att_csr cursor static forward_only for
    select      complex_id,
                movie_id, 
                screening_date,
                attendance
    from        attendance_raw
    where       movie_id is not null
    and         screening_Date = @screening_date
    group by    complex_id,
                movie_id, 
                screening_date,
                attendance
    order by    complex_id,
                movie_id, 
                screening_date,
                attendance 
    for         read only



    open att_csr 
    fetch att_csr into @complex_id, @movie_id, @date, @attendance
    while(@@fetch_status=0)
    begin

        select      @rowcount = count(*) 
        from        movie_history
        where       movie_id = @movie_id
        and         complex_id = @complex_id
        and         screening_date = @date
    
        select @error = @@error
        if @error != 0
        begin
            raiserror ('Error 1' , 16, 1)
            rollback transaction
            return -1
        end
    
        if @rowcount > 0 
        begin
            update      movie_history
            set         attendance = @attendance / @rowcount,
                        attendance_type = 'A'
            where       movie_id = @movie_id
            and         complex_id = @complex_id
            and         screening_date = @date
    
            if @@rowcount <= 0
            begin
                raiserror ('Error 3' , 16, 1)
                rollback transaction
                return -1
            end
        
            select @error = @@error
            if @error != 0
            begin
                raiserror ('Error 2' , 16, 1)
                rollback transaction
                return -1
            end
        end
        
        fetch att_csr into @complex_id, @movie_id, @date, @attendance
    end

    deallocate att_csr

    commit transaction
    
    checkpoint
    
    
    print convert(char(15), @screening_date, 104)

    fetch screen_csr into @screening_date
end
return 0
GO
