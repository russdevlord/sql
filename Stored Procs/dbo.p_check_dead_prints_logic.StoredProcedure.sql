/****** Object:  StoredProcedure [dbo].[p_check_dead_prints_logic]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_check_dead_prints_logic]
GO
/****** Object:  StoredProcedure [dbo].[p_check_dead_prints_logic]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create proc [dbo].[p_check_dead_prints_logic] @complex_id   int

as

declare         @error              int

create table #dodgy_prints
(
print_id            int         null,
complex_id          int         null,
dodgy_type          varchar(10) null
)       


declare complex_csr cursor for
select  complex_id
from    complex
where   film_complex_status <> 'C'
order by complex_id

open complex_csr
fetch complex_csr into @complex_id
while(@@fetch_status = 0)
begin

    insert into #dodgy_prints
    select  distinct print_id,
            complex_id,
            'Print'
    from    campaign_spot,
            print_package
    where   campaign_spot.package_id = print_package.package_id
    and     campaign_spot.complex_id = @complex_id
    and     screening_date = '4-aug-2011'
    and     spot_status <> 'P'
    and     print_id in (select print_no
                        from    v_xml_prints 
                        where   print_no not in (   SELECT  DISTINCT fp.print_id
                                                    FROM    film_campaign_complex fcc, 
                                                            campaign_package cp, 
                                                            print_package pp, 
                                                            film_print fp
                                                    WHERE   fcc.complex_id = @complex_id
                                                    and     fcc.campaign_no = cp.campaign_no    
                                                    and     (cp.used_by_date is null 
                                                    or      cp.used_by_date >= '7-jul-2011')
                                                    AND     cp.campaign_package_status <> 'P' 
                                                AND     pp.package_id = cp.package_id
                                                AND     fp.print_id = pp.print_id 
                                                AND     fp.print_id = pp.print_id)
                    and     print_no in (       select  distinct print_id
                                                from    campaign_spot,
                                                        print_package
                                                where   campaign_spot.package_id = print_package.package_id
                                                and     campaign_spot.complex_id = @complex_id
                                                and     screening_date < '7-jul-2011'
                                                and     spot_status <> 'P'))
                                                
    select @error = @@error
    if @error <> 0
        return -100                                                

    insert into #dodgy_prints
    select  distinct print_package.package_id,
            complex_id,
            'Package'
    from    print_package,
            campaign_package,
            film_campaign_complex fcc
    where   campaign_package.package_id = print_package.package_id
    and     campaign_package.campaign_no = fcc.campaign_no
    and     fcc.complex_id = @complex_id
    and     used_by_date >= '4-aug-2011'
    AND     campaign_package_status <> 'P'
    and     print_id in (select print_no
                        from    v_xml_prints 
                        where   print_no not in (   SELECT  DISTINCT fp.print_id
                                                    FROM    film_campaign_complex fcc, 
                                                            campaign_package cp, 
                                                            print_package pp, 
                                                            film_print fp
                                                    WHERE   fcc.complex_id = @complex_id
                                                    and     fcc.campaign_no = cp.campaign_no    
                                                    and     (cp.used_by_date is null 
                                                    or      cp.used_by_date >= '7-jul-2011')
                                                    AND     cp.campaign_package_status <> 'P' 
                                                    AND     pp.package_id = cp.package_id
                                                    AND     fp.print_id = pp.print_id 
                                                    AND     fp.print_id = pp.print_id)
                        and     print_no in (       select  distinct print_id
                                                    from    campaign_spot,
                                                            print_package
                                                    where   campaign_spot.package_id = print_package.package_id
                                                    and     campaign_spot.complex_id = @complex_id
                                                    and     screening_date < '7-jul-2011'
                                                    and     spot_status <> 'P'))                                          

    select @error = @@error
    if @error <> 0
        return -100                                                

    fetch complex_csr into @complex_id
end

select * from #dodgy_prints

return 0
GO
