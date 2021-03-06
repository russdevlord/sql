/****** Object:  StoredProcedure [dbo].[p_shell_allert_report]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_shell_allert_report]
GO
/****** Object:  StoredProcedure [dbo].[p_shell_allert_report]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROC [dbo].[p_shell_allert_report]

as
set nocount on 
/*
 * Create Temporary Table
 */

create table #report_items (
	shell_code		char(7)				null,
	shell_desc		varchar(50) 		null,
	shell_expiry	datetime			null,
	shell_type		varchar(30)			null,
	reason			varchar(60)			null
)

/* 
 * Insert Permanent Shells that have Expired
 */
insert into #report_items (
		shell_code,
		shell_desc,
		shell_expiry,
		shell_type,
		reason )
select	shell.shell_code,
		shell.shell_desc,
		shell.shell_expiry_date,
		shell_type.shell_type_desc,
		'Shell has Expired.'
from	shell,
		shell_type
where	shell.shell_type = shell_type.shell_type_code and
		shell.shell_permanent = 'Y' and
		( shell.shell_expired = 'Y' or
		( shell.shell_expiry_date is not null and
		shell.shell_expiry_date <= getdate() ))

/* 
 * Insert Non Permanent Shells that have No Screenings Defined
 */
insert into #report_items (
		shell_code,
		shell_desc,
		shell_expiry,
		shell_type,
		reason )
SELECT	shell.shell_code, 
		shell.shell_desc, 
		shell.shell_expiry_date, 
		shell_type.shell_type_desc, 
		'No Defined Screening Dates.'
FROM	shell INNER JOIN
		shell_type ON shell.shell_type = shell_type.shell_type_code LEFT OUTER JOIN
		shell_dates ON shell.shell_code = shell_dates.shell_code
WHERE	(shell.shell_permanent = 'N')
GROUP BY shell.shell_code, shell.shell_desc, shell.shell_expiry_date, shell_type.shell_type_desc
HAVING	(COUNT(shell_dates.screening_date) = 0)

/* 
 * Insert Non Permanent Shells that have Expired
 */
insert into #report_items (
		shell_code,
		shell_desc,
		shell_expiry,
		shell_type,
		reason )
select	shell.shell_code,
		shell.shell_desc,
		shell.shell_expiry_date,
		shell_type.shell_type_desc,
		'Shell Dates have Expired.'
FROM	shell INNER JOIN
		shell_type ON shell.shell_type = shell_type.shell_type_code LEFT OUTER JOIN
		shell_dates ON shell.shell_code = shell_dates.shell_code
WHERE	(shell.shell_permanent = 'N')         
group by shell.shell_code,
		shell.shell_desc,
		shell.shell_expiry_date,
		shell_type.shell_type_desc
having	count(screening_date) > 0 and
		max(screening_date) < getdate()

/*
 * Insert Shells NOT linked to a Carousel
 */
insert into #report_items (
		shell_code,
		shell_desc,
		shell_expiry,
		shell_type,
		reason )
select	shell.shell_code,
		shell.shell_desc,
		shell.shell_expiry_date,
		shell_type.shell_type_desc,
		'Shell has No Link to any Carousels.'
from	shell,
		shell_type
where	shell.shell_type = shell_type.shell_type_code and
		not exists ( select shell_xref.shell_code 
					from shell_xref
					where shell.shell_code = shell_xref.shell_code)

/*
 * Insert Shells with NO Defined Artworks
 */
insert into #report_items (
		shell_code,
		shell_desc,
		shell_expiry,
		shell_type,
		reason )
select	shell.shell_code,
		shell.shell_desc,
		shell.shell_expiry_date,
		shell_type.shell_type_desc,
		'Shell has No Artworks Defined.'
from	shell,
		shell_type
where	shell.shell_type = shell_type.shell_type_code and
		not exists ( select shell_artwork.shell_code 
					from shell_artwork
					where shell.shell_code = shell_artwork.shell_code)

/*
 * Return Dataset
 */
select * from #report_items

return 0
GO
