/****** Object:  StoredProcedure [dbo].[p_activity_create_benchmarks]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_activity_create_benchmarks]
GO
/****** Object:  StoredProcedure [dbo].[p_activity_create_benchmarks]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_activity_create_benchmarks]    @branch_code    char(2),
                                            @finyear    datetime
as

declare @error          integer

if exists ( select  1 
            from    activity_benchmarks 
            where   branch_code = @branch_code
            and     finyear_end = @finyear)
return 0

begin transaction

    insert into activity_benchmarks(branch_code,
                                    benchmark_type,
                                    finyear_end,
                                    value)
    select  @branch_code,
            benchmark_type,
            @finyear,
            0.0
    from    activity_benchmark_types
    where   active = 'Y'

    select @error = @@error
    if ( @error !=0 )
    begin
    	rollback transaction
    	raiserror ('Error generating activity benchmarks.', 16, 1)
        return @error
    end

commit transaction

return 0
GO
