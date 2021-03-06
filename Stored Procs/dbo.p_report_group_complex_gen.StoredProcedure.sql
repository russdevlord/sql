/****** Object:  StoredProcedure [dbo].[p_report_group_complex_gen]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_report_group_complex_gen]
GO
/****** Object:  StoredProcedure [dbo].[p_report_group_complex_gen]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[p_report_group_complex_gen]

as

declare			@error			int
set nocount on

begin transaction

/*
 * Delete Complex Groupings for Revenue Reporting
 */
 
delete report_group_complexes where group_no in (10,20,30,40,50,60,70,80,90,100,105,106,110)

select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error - failed to delete report_group_complexes', 16, 1)
	return -1
end

/*
 * Insert Complex Groupings - Hoyts
 */
 
insert into report_group_complexes
select c.complex_id,
		10
  from complex c,
       exhibitor e
 where c.exhibitor_id = e.exhibitor_id and
       e.exhibitor_id in (205)
       
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error - failed to insert hoyts complexes.', 16, 1)
	return -1
end

/*
 * Insert Complex Groupings - GU/BCC
 */
 
insert into report_group_complexes
select 
       c.complex_id,20
  from complex c,
       exhibitor e
 where c.exhibitor_id = e.exhibitor_id and
       e.exhibitor_id in (129,156)

       
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error - failed to insert gu complexes.', 16, 1)
	return -1
end

/*
 * Insert Complex Groupings - Village
 */
 
insert into report_group_complexes
select 
       c.complex_id,30
  from complex c,
       exhibitor e
 where c.exhibitor_id = e.exhibitor_id and
       e.exhibitor_id in (581)

       
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error - failed to insert village complexes.', 16, 1)
	return -1
end

/*
 * Insert Complex Groupings - Reading
 */
 
insert into report_group_complexes
select 
       c.complex_id,40
  from complex c,
       exhibitor e
 where c.exhibitor_id = e.exhibitor_id and
       e.exhibitor_id in (187)

       
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error - failed to insert reading complexes.', 16, 1)
	return -1
end

/*
 * Insert Complex Groupings - AMC
 */
 
insert into report_group_complexes
select 
       c.complex_id,50
  from complex c,
       exhibitor e
 where c.exhibitor_id = e.exhibitor_id and
       e.exhibitor_id in (468)

       
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error - failed to insert amc complexes.', 16, 1)
	return -1
end

/*
 * Insert Complex Groupings - Ace Cinemas
 */
 
insert into report_group_complexes
select 
       c.complex_id,60
  from complex c,
       exhibitor e
 where c.exhibitor_id = e.exhibitor_id and
       e.exhibitor_id in (405,520,522,623)

       
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error - failed to insert ace complexes.', 16, 1)
	return -1
end

/*
 * Insert Complex Groupings - Grand
 */
 
insert into report_group_complexes
select 
       c.complex_id,70
  from complex c,
       exhibitor e
 where c.exhibitor_id = e.exhibitor_id and
       e.exhibitor_id in (185)

       
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error - failed to insert grand complexes.', 16, 1)
	return -1
end

/*
 * Insert Complex Groupings - Wallis
 */
 
insert into report_group_complexes
select 
       c.complex_id,80
  from complex c,
       exhibitor e
 where c.exhibitor_id = e.exhibitor_id and
       e.exhibitor_id in (174)

       
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error - failed to insert wallis complexes.', 16, 1)
	return -1
end

/*
 * Insert Complex Groupings - Peninsula
 */
 
insert into report_group_complexes
select 
       c.complex_id,90
  from complex c,
       exhibitor e
 where c.exhibitor_id = e.exhibitor_id and
       e.exhibitor_id in (480,222,463,636)

       
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error - failed to insert peninsula complexes.', 16, 1)
	return -1
end

/*
 * Insert Complex Groupings - Mustaca
 */
 
insert into report_group_complexes
select 
       c.complex_id,100
  from complex c,
       exhibitor e
 where c.exhibitor_id = e.exhibitor_id and
       e.exhibitor_id in (108)

       
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error - failed to insert mustaca complexes.', 16, 1)
	return -1
end

/*
 * Insert Complex Groupings - Palace
 */
 
insert into report_group_complexes
select 
       c.complex_id,105
  from complex c,
       exhibitor e
 where c.exhibitor_id = e.exhibitor_id and
       c.complex_id in (222,223,817,254,253,226,231,123,142,214,145,834,457,672,461,443,802)
       
       
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error - failed to insert palace complexes.', 16, 1)
	return -1
end


/*
 * Insert Complex Groupings - New Palace
 */
 
insert into report_group_complexes
select 
       c.complex_id,106
  from complex c,
       exhibitor e
 where c.exhibitor_id = e.exhibitor_id and
       c.complex_id in (1164, 1165, 1166, 1167, 1169, 1170, 1171, 1172, 1173, 1174, 1175)
       
       
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error - failed to insert palace complexes.', 16, 1)
	return -1
end

/*
 * Insert Complex Groupings - Others
 */
 
insert into report_group_complexes
select 
       c.complex_id,110
  from complex c,
       exhibitor e
 where c.exhibitor_id = e.exhibitor_id and
       c.complex_id not in (select complex_id from report_group_complexes)

       
select @error = @@error
if @error <> 0
begin
	rollback transaction
	raiserror ('Error - failed to insert others complexes.', 16, 1)
	return -1
end

commit transaction
return 0
GO
