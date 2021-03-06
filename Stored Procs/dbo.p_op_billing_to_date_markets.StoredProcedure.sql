/****** Object:  StoredProcedure [dbo].[p_op_billing_to_date_markets]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_op_billing_to_date_markets]
GO
/****** Object:  StoredProcedure [dbo].[p_op_billing_to_date_markets]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_op_billing_to_date_markets]   @campaign_no	integer

as
                            

declare	@market_no	integer,
			@film_market_desc	varchar(30),
			@charge_rate		money	

create table #results
(
   market_no		integer				null,
	film_market_desc  varchar(100)		null,
	charge_rate			money					null,
)
                                          

declare film_mkt_csr cursor static for
 select fm.film_market_no,
		  fm.film_market_desc
   from film_market fm
	  for read only
                                

	open film_mkt_csr
   fetch film_mkt_csr into @market_no, @film_market_desc
	while(@@fetch_status=0)
	begin
						
			select 	@charge_rate = isnull(sum(charge_rate),0)
			from 	outpost_venue cplx,
					outpost_spot spot,
					outpost_panel cl
			where 	cplx.market_no = @market_no and
					cplx.outpost_venue_id = cl.outpost_venue_id and
					cl.outpost_panel_id = spot.outpost_panel_id and
					spot.campaign_no = @campaign_no and
					spot.tran_id is not null

			insert into #results ( market_no,
										  film_market_desc,
										  charge_rate
										) values
										( @market_no,
										  @film_market_desc,
										  @charge_rate
										)			
	
			                                  
   fetch film_mkt_csr into @market_no, @film_market_desc

	end
	close film_mkt_csr
                                 
deallocate film_mkt_csr

select market_no,
	    film_market_desc,
	    charge_rate	
  from #results
                        
return 0
GO
