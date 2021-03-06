/****** Object:  StoredProcedure [dbo].[p_complex_print_analysis]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_complex_print_analysis]
GO
/****** Object:  StoredProcedure [dbo].[p_complex_print_analysis]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_complex_print_analysis]    @start_date         datetime,
                                        @end_date           datetime,
                                        @country_code       char(1)
                                        
as
set nocount on 
declare         @error                  int,
                @exhibitor_id           int,
                @exhibitor_name         varchar(50),
                @complex_id             int,
                @complex_name           varchar(100),
                @no_of_campaigns        int,
                @no_of_prints           int,
                @no_of_shell_prints     int,
                @insert_row             int
                
/*
 * Create Temp Table
 */
 
create table #complex_anlaysis
(
    exhibitor_id           int              null,
    exhibitor_name         varchar(50)      null,
    complex_id             int              null,
    complex_name           varchar(100)     null,
    no_of_campaigns        int              null,
    no_of_prints           int              null,
    no_of_shell_prints     int              null
)                 
             
/*
 * Declare Cursor
 */
 
declare     complex_csr cursor static for
select      c.complex_id,
            c.complex_name,
            e.exhibitor_id,
            e.exhibitor_name
from        complex c,
            exhibitor e,
            branch b
where       e.exhibitor_id = c.exhibitor_id
and         c.branch_code = b.branch_code
and         b.country_code = @country_code
order by    e.exhibitor_name,
            c.complex_name
for         read only

/*
 * Begin Processing Report
 */
 
open complex_csr
fetch complex_csr into @complex_id, @complex_name, @exhibitor_id, @exhibitor_name
while(@@fetch_status=0)
begin

    select  @insert_row = 0,
            @no_of_campaigns = 0,
            @no_of_prints = 0,
            @no_of_shell_prints = 0
    
    select  @no_of_campaigns = count(distinct cs.campaign_no)
    from    campaign_spot cs,
            certificate_item ci
    where   cs.spot_id = ci.spot_reference
    and     cs.complex_id = @complex_id
    and     cs.screening_date >= @start_date
    and     cs.screening_date <= @end_date
            
    select  @no_of_prints = count(distinct ci.print_id)
    from    campaign_spot cs,
            certificate_item ci
    where   cs.spot_id = ci.spot_reference
    and     cs.complex_id = @complex_id
    and     cs.screening_date >= @start_date
    and     cs.screening_date <= @end_date
            
    select  @no_of_shell_prints = count(distinct ci.print_id)
    from    certificate_group cg,
            certificate_item ci
    where   cg.certificate_group_id = ci.certificate_group
    and     cg.complex_id = @complex_id
    and     cg.screening_date >= @start_date
    and     cg.screening_date <= @end_date
    and     ci.print_id in (select print_id from film_shell_print, film_shell_xref where film_shell_print.shell_code = film_shell_xref.shell_code and film_shell_xref.complex_id = @complex_id )
            
    select @insert_row = @no_of_shell_prints + @no_of_prints + @no_of_campaigns      

    if @insert_row > 0
    begin
        insert into #complex_anlaysis
        (
        exhibitor_id,
        exhibitor_name,
        complex_id,
        complex_name,
        no_of_campaigns,
        no_of_prints,
        no_of_shell_prints
        )  values
        (
        @exhibitor_id,
        @exhibitor_name,
        @complex_id,
        @complex_name,
        @no_of_campaigns,
        @no_of_prints,
        @no_of_shell_prints
        )
    end      
    
    fetch complex_csr into @complex_id, @complex_name, @exhibitor_id, @exhibitor_name
end

deallocate  complex_csr

select #complex_anlaysis.exhibitor_id, #complex_anlaysis.exhibitor_name, #complex_anlaysis.complex_id, #complex_anlaysis.complex_name, #complex_anlaysis.no_of_campaigns, #complex_anlaysis.no_of_prints, #complex_anlaysis.no_of_shell_prints from #complex_anlaysis order by exhibitor_name, complex_name
return 0
GO
