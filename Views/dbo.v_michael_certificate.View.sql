/****** Object:  View [dbo].[v_michael_certificate]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_michael_certificate]
GO
/****** Object:  View [dbo].[v_michael_certificate]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_michael_certificate]
as
select e.exhibitor_name as 'exhibitor_name',
       c.complex_name as 'complex',
       c.complex_id as 'complexid',
       cg.screening_date as 'screening_date',
       fp.print_id as 'print_id',
       fp.print_name as 'print_name',
       fp.print_type as 'print_type',
       fp.duration 'duration',
       ci.spot_reference 'spot_id',
       count(fp.print_id) as 'prints'
  from certificate_item ci,
       certificate_group cg,
       certificate_source cs,
       film_print fp,
       complex c,
       exhibitor e,
       branch b
 where ci.certificate_group = cg.certificate_group_id and
       ci.certificate_source = cs.certificate_source_code and
       cg.screening_date >= "1-oct-2009" and
       certificate_source_code not in ('X', 'H', 'T') and
       cg.screening_date <= "30-sep-2010" and
       cg.complex_id = c.complex_id and
       c.exhibitor_id = e.exhibitor_id and
       c.branch_code = b.branch_code and
       b.country_code = "A" and
       ci.print_id = fp.print_id and
       --ci.print_medium = 'F' and
       fp.print_id not in (1,2,3,4,5,6,7,8) and
       fp.print_id not in (select distinct print_id from certificate_item, certificate_group where certificate_item.certificate_group = certificate_group.certificate_group_id and certificate_group.screening_date < "1-oct-2009" )
group by e.exhibitor_name,
       c.complex_name,
       c.complex_id,
       cg.screening_date,
       fp.print_id,
       fp.print_name,
       fp.print_type,
       fp.duration,
       ci.spot_reference
GO
