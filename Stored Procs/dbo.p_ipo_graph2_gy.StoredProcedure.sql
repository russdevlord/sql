/****** Object:  StoredProcedure [dbo].[p_ipo_graph2_gy]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_ipo_graph2_gy]
GO
/****** Object:  StoredProcedure [dbo].[p_ipo_graph2_gy]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_ipo_graph2_gy]         @start_date         datetime,
                                    @end_date           datetime
                                    
as

declare     @error                  int,
            @booking_period         datetime,                                    
            @benchmark_end          datetime,
            @revenue                money,
            @revenue_media          money,
            @revenue_cinelight      money,
            @revenue_marketing      money,
            @revenue_misc           money
            
set nocount on            
            
create table #revenue_fall
(
booking_period      datetime,
benchmark_end       datetime,
revenue             money,
revenue_media       money,
revenue_cinelight   money,
revenue_marketing   money,
revenue_misc        money
)  

declare     period_csr cursor static forward_only for
select      sales_period
from        film_sales_period
where       sales_period between @start_date and @end_date
order by    sales_period
for         read only

open period_csr
fetch period_csr into @booking_period
while(@@fetch_status = 0)
begin

    insert into #revenue_fall          
    SELECT      @booking_period,
                benchmark_end,
                revenue = sum ( cost ),
                revenue_media = sum ( cost * is_media ),
                revenue_cinelight = sum ( cost * is_cinelight ),
                revenue_marketing = sum ( cost * is_cinemarketing ),
                revenue_misc = sum ( cost * is_misc )
    FROM        campaign_revision, 
                film_campaign,   
                film_screening_date_xref,   
                revision_transaction,   
                revision_transaction_type,
                revision_group  
    WHERE       film_campaign.campaign_no = campaign_revision.campaign_no 
    and         revision_transaction.revision_id = campaign_revision.revision_id 
    and         revision_transaction.revision_transaction_type = revision_transaction_type.revision_transaction_type 
    and         film_screening_date_xref.screening_date = revision_transaction.billing_date 
    and         revision_transaction_type.revision_group = revision_group.revision_group 
    and         film_campaign.business_unit_id <> 6 
    and         EXISTS ( SELECT * FROM booking_figures bf 
                        WHERE	( campaign_revision.revision_id = bf.revision_id  ) 
                        and 	( bf.figure_type <> 'A' )
                        and	( bf.booking_period = @booking_period ) 
                        and 	( 0 IN (  0 , bf.rep_id)) 
                        and	( 0 = 0 OR 
                        EXISTS ( SELECT * FROM booking_figure_team_xref bx
                        WHERE bx.figure_id = bf.figure_id
                        AND bx.team_id = 0))
                        and   ( 'A' IN ('',bf.branch_code) OR 
                        'A' = 'A' AND bf.branch_code <> 'Z' )
                         )
    
    GROUP BY benchmark_end
    HAVING sum( cost) <> 0

    fetch period_csr into @booking_period
end

select * from #revenue_fall

return 0
GO
