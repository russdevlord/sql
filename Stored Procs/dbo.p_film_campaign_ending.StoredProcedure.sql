/****** Object:  StoredProcedure [dbo].[p_film_campaign_ending]    Script Date: 12/03/2021 10:03:47 AM ******/
DROP PROCEDURE [dbo].[p_film_campaign_ending]
GO
/****** Object:  StoredProcedure [dbo].[p_film_campaign_ending]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[p_film_campaign_ending] @rep int,
												@fromStartDate datetime, @toStartDate datetime
	 ,@fromEndDate datetime, @toEndDate datetime
	 
	
AS
BEGIN
	declare @selectStatement  nvarchar(4000)
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	--for testing
	--DECLARE @selectStatement  nvarchar(4000)
	--DECLARE @fromStartDate datetime, @toStartDate datetime
	--DECLARE @fromEndDate datetime, @toEndDate datetime
	--DECLARE @rep int--VARCHAR(100)

	--SET @rep = 100--'''Paul Booth'''
	--SET @fromStartDate = '2010-01-01'
	--SET @toStartDate = '2010-12-30'

	----set @fromEndDate = '2011-01-01'
	----set @toEndDate = '2013-12-01'

	SET @selectStatement = 'select 
		fc.campaign_no
		,fc.product_desc
		,fc.start_date
		,fc.end_date
		,fc.makeup_deadline
		,fc.branch_code
		,fc.client_id 
		,sr.first_name
		,sr.last_name
		from film_campaign as fc
		inner join campaign_type as ct on ct.campaign_type_code = fc.campaign_type
		inner join campaign_status as cs on cs.campaign_status_code = fc.campaign_status
		inner join film_campaign_category as fcc on fcc.campaign_category_code = fc.campaign_category
		inner join sales_rep as sr on sr.rep_id = fc.rep_id
		where campaign_status not in (''P'') and 1=1 '

	IF @rep <> 0
	BEGIN 
		SET @selectStatement = @selectStatement + ' and sr.rep_id = ' + convert(varchar(10),@rep) 
	end
	
	IF @fromStartDate is not null and @toStartDate is not null and @fromStartDate <> '1-jan-1900' and @toStartDate <> '1-jan-1900'
	BEGIN 
		SET @selectStatement = @selectStatement + ' and fc.start_date between ''' 
		 + CONVERT(VARCHAR,@fromStartDate ,120)
		 + ''' and ''' + CONVERT(VARCHAR,@toStartDate,120) + ''''  
	END 
																												
	IF @fromEndDate is not null and @toEndDate is not null and @fromEndDate <> '1-jan-1900' and @toEndDate <> '1-jan-1900'
	BEGIN 
		SET @selectStatement = @selectStatement + ' and fc.end_date between ''' 
		+ CONVERT(VARCHAR,@fromEndDate,120) 
		+ ''' and '''  + CONVERT(VARCHAR,@toEndDate,120)  + '''' 
	END										


	PRINT @selectStatement
	EXEC sp_executesql  @selectStatement


END
GO
