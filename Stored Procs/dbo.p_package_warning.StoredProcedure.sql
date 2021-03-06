/****** Object:  StoredProcedure [dbo].[p_package_warning]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_package_warning]
GO
/****** Object:  StoredProcedure [dbo].[p_package_warning]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_package_warning]		@package_id			int,
																	@revision_no			int

as

declare			@error						int


create table #warnings
(	
	warning_message			varchar(max)
)

--package with too many restrictions on  TAP MAP
insert into	#warnings
select			'MAP or TAP Package with too many Classification Restrictions: ' + convert(varchar(6), inclusion.campaign_no) + ' - Inclusion: ' + convert(varchar(12), inclusion.inclusion_id) + ' - ' + inclusion_desc 
from				inclusion 
inner join		inclusion_cinetam_package on inclusion.inclusion_id = inclusion_cinetam_package.inclusion_id
where			inclusion_type in (24,32)
and				inclusion_cinetam_package.package_id  = @package_id
and				inclusion_cinetam_package.package_id in (	select			package_id
																						from				(select				package_id 
																											from					campaign_classification_rev
																											where				package_id = @package_id
																											and					revision_no = @revision_no
																											and					instruction_type = 2) as temp_table 
																						group by		package_id 
																						having			COUNT(package_id) > 2)
group by		inclusion.campaign_no,
					inclusion.inclusion_id,
					inclusion.inclusion_desc

insert into	#warnings
select			'MAP or TAP Package with too many Genre Restrictions: ' + convert(varchar(6), inclusion.campaign_no) + ' - Inclusion: ' + convert(varchar(12), inclusion.inclusion_id) + ' - ' + inclusion_desc 
from				inclusion 
inner join		inclusion_cinetam_package on inclusion.inclusion_id = inclusion_cinetam_package.inclusion_id
where			inclusion_type in (24,32)
and				inclusion_cinetam_package.package_id  = @package_id
and				inclusion_cinetam_package.package_id in (	select			package_id
																						from				(select				package_id 
																											from					campaign_category_rev 
																											where				package_id = @package_id
																											and					revision_no = @revision_no
																											and					instruction_type = 3
																											and					movie_category_code <> 'CA') as temp_table 
																						group by		package_id 
																						having			COUNT(package_id) > 3)
group by		inclusion.campaign_no,
					inclusion.inclusion_id,
					inclusion.inclusion_desc

insert into	#warnings
select			'MAP or TAP Package with too many Genre Preferences: ' + convert(varchar(6), inclusion.campaign_no) + ' - Inclusion: ' + convert(varchar(12), inclusion.inclusion_id) + ' - ' + inclusion_desc 
from				inclusion 
inner join		inclusion_cinetam_package on inclusion.inclusion_id = inclusion_cinetam_package.inclusion_id
where			inclusion_type in (24,32)
and				inclusion_cinetam_package.package_id  = @package_id
and				inclusion_cinetam_package.package_id in (	select			package_id
																						from				(select				package_id 
																											from					campaign_category_rev 
																											where				package_id = @package_id 
																											and					revision_no = @revision_no
																											and					instruction_type = 2) as temp_table 
																						group by		package_id 
																						having			COUNT(package_id) > 3)
group by		inclusion.campaign_no,
					inclusion.inclusion_id,
					inclusion.inclusion_desc

insert into	#warnings
select			'MAP or TAP Package with too many Title Restrictions: ' + convert(varchar(6), inclusion.campaign_no) + ' - Inclusion: ' + convert(varchar(12), inclusion.inclusion_id) + ' - ' + inclusion_desc 
from				inclusion 
inner join		inclusion_cinetam_package on inclusion.inclusion_id = inclusion_cinetam_package.inclusion_id
where			inclusion_type in (24,32)
and				inclusion_cinetam_package.package_id  = @package_id
and				inclusion_cinetam_package.package_id in (	select			package_id
																						from				(select				package_id
																											from					movie_screening_ins_rev
																											inner join			movie on movie_screening_ins_rev.movie_id = movie.movie_id 
																											where				instruction_type = 3 
																											and					package_id = @package_id
																											and					revision_no = @revision_no
																											group by			package_id, 
																																	case when RIGHT(long_name, 3) = ' 3D' then LEFT(long_name, len(long_name) - 3) else long_name end) as temp_table
																						group by		package_id
																						having			COUNT(package_id) > 3)
group by		inclusion.campaign_no,
					inclusion.inclusion_id,
					inclusion.inclusion_desc

select * from	
#warnings

return 0
GO
