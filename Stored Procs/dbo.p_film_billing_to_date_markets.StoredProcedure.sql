/****** Object:  StoredProcedure [dbo].[p_film_billing_to_date_markets]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_billing_to_date_markets]
GO
/****** Object:  StoredProcedure [dbo].[p_film_billing_to_date_markets]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create PROC [dbo].[p_film_billing_to_date_markets]   @campaign_no	integer

as
                            

declare	@film_market_no	integer,
			@film_market_desc	varchar(30),
			@charge_rate		money	

create table #results
(
   film_market_no		integer				null,
	film_market_desc  varchar(100)		null,
	charge_rate			money					null,
)
                                          

declare film_mkt_csr cursor static for
 select fm.film_market_no,
		  fm.film_market_desc
   from film_market fm
	  for read only
                                


	open film_mkt_csr
   fetch film_mkt_csr into @film_market_no, @film_market_desc
	while(@@fetch_status=0)
	begin
						
			select @charge_rate = isnull(sum(charge_rate),0)
           from complex cplx,
                campaign_spot spot
          where cplx.film_market_no = @film_market_no and
                cplx.complex_id = spot.complex_id and
                spot.campaign_no = @campaign_no and
                spot.tran_id is not null

			insert into #results ( film_market_no,
										  film_market_desc,
										  charge_rate
										) values
										( @film_market_no,
										  @film_market_desc,
										  @charge_rate
										)			
	
			                                  
   fetch film_mkt_csr into @film_market_no, @film_market_desc

	end
	close film_mkt_csr
                                 
deallocate film_mkt_csr

select film_market_no,
	    film_market_desc,
	    charge_rate	
  from #results
                        
return 0
GO
