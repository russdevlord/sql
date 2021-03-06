/****** Object:  StoredProcedure [dbo].[p_film_market_legend]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_market_legend]
GO
/****** Object:  StoredProcedure [dbo].[p_film_market_legend]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_film_market_legend]        @country_code           char(1)

as

declare         @error              int,
                @markets            varchar(510),
                @markets2           varchar(255),
                @market_desc        varchar(50),
                @market_code        varchar(3)


set nocount on

declare     market_csr cursor forward_only static for
select      film_market_code,
            film_market_desc
from        film_market
where       film_market_no in (select distinct film_market_no from complex, branch where complex.branch_code = branch.branch_code and branch.country_code = @country_code)
order by    film_market_code

create table #market
(
market1      varchar(255)   null,
market_2     varchar(255)   null
)
select @markets = ''

open market_csr
fetch market_csr into @market_code, @market_desc
while(@@fetch_status=0)
begin

    
    select @markets = @markets + @market_code + ' : ' + @market_desc + '   '
    
    fetch market_csr into @market_code, @market_desc
end

insert into #market values(substring(@markets, 1, 255), substring(@markets, 256, 510))

select * from #market

return 0
GO
