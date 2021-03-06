/****** Object:  View [dbo].[v_hoyts_scert_audit]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP VIEW [dbo].[v_hoyts_scert_audit]
GO
/****** Object:  View [dbo].[v_hoyts_scert_audit]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create view [dbo].[v_hoyts_scert_audit]
as
    select e.exhibitor_name as 'Exhibitor Name',
           cg.screening_date as 'Screening Date',
           c.complex_name as 'Complex',
           cg.group_name as 'Movie',
           cg.is_movie as 'Is Movie',       
           count(fp.print_id) as 'Total Prints',
           sum(fp.actual_duration) as 'Total Duration'
      from certificate_item ci,
           certificate_group cg,
           film_print fp,
           complex c,
           exhibitor e,
           branch b
     where ci.certificate_group = cg.certificate_group_id and
           cg.complex_id = c.complex_id and
           c.exhibitor_id = e.exhibitor_id and
           c.branch_code = b.branch_code and
           b.country_code = 'A' and
           ci.print_id = fp.print_id and
           fp.print_id not in (1,2,3,4,5,6) and
           cg.screening_date >= '16-dec-2004'
    group by e.exhibitor_name,
           cg.screening_date,
           c.complex_name,
           cg.group_name,
           cg.is_movie
GO
