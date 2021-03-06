/****** Object:  StoredProcedure [dbo].[p_sun_integration_package]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_sun_integration_package]
GO
/****** Object:  StoredProcedure [dbo].[p_sun_integration_package]    Script Date: 12/03/2021 10:03:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[p_sun_integration_package] @accounting_period DATETIME 
AS

DECLARE @DTSPackageObject 	int
DECLARE @HRESULT 			int
DECLARE @property 			varchar(255)
DECLARE @ErrDescription 	varchar(255)
DECLARE @ErrSource 			varchar(30)
DECLARE @ErrHelpId 			int
DECLARE @ErrHFile 			varchar(255)
DECLARE @sDTSPackagePath 	varchar(1000)
DECLARE @sDTSSpecialUser 	varchar(50)

-- Create a DTS Package object
EXEC @HRESULT = sp_OACreate 'DTS.Package', @DTSPackageObject OUTPUT
IF @HRESULT <> 0
BEGIN
	EXEC @HRESULT = sp_OAGetErrorInfo @DTSPackageObject, @ErrSource OUTPUT, @ErrDescription OUTPUT
	RAISERROR ( 'Error Creating DTS package', 11, 1)
	RETURN -1
END

-- Call the load Server method on the DTS Package object pass the path
--EXEC @HRESULT = sp_OAMethod @DTSPackageObject, 'LoadFromSqlServer', NULL, @ServerName='VML275', @PackageName='Data Extract', @Flags=256
--EXEC @HRESULT = sp_OAMethod @DTSPackageObject, 'LoadFromSqlServer', NULL, @ServerName='VML275', @PackageName='Run Data Feed', @Flags=256
EXEC @HRESULT = sp_OAMethod @DTSPackageObject, 'LoadFromSqlServer', NULL, @ServerName=@@SERVERNAME, @PackageName='Full Run', @Flags=256

IF @HRESULT <> 0
BEGIN
	EXEC @HRESULT = sp_OAGetErrorInfo @DTSPackageObject, @ErrSource OUTPUT, @ErrDescription OUTPUT
	RAISERROR( 'Error Loading DTS package', 11, 1)
	RETURN -1
END

--Set parameter to Accounting Period global variable
EXEC @HRESULT = sp_OASetProperty @DTSPackageObject, 'GlobalVariables("accounting_period").Value', @accounting_period
IF @HRESULT <> 0
BEGIN
	EXEC @HRESULT = sp_OAGetErrorInfo @DTSPackageObject, @ErrSource OUTPUT, @ErrDescription OUTPUT
	RAISERROR( 'Error Setting Global Variable', 11, 1)
	RETURN -1
END
 
--Set the FailOnError property to true
EXEC @HRESULT = sp_OASetProperty @DTSPackageObject, 'FailOnError', -1 --Set to true
IF @HRESULT <> 0
BEGIN
	EXEC @HRESULT = sp_OAGetErrorInfo @DTSPackageObject, @ErrSource OUTPUT, @ErrDescription OUTPUT
	RAISERROR( 'Error Setting DTS package', 11, 1)
	RETURN -1
END

-- Call the EXECute method
EXEC @HRESULT = sp_OAMethod @DTSPackageObject, 'Execute'
IF @HRESULT <> 0
BEGIN
	EXEC @HRESULT = sp_OAGetErrorInfo @DTSPackageObject, @ErrSource OUTPUT, @ErrDescription OUTPUT
	RAISERROR( 'Error Executing DTS package', 11, 1)
	RETURN
END

-- Unitialize the Package
EXEC @HRESULT = sp_OAMethod @DTSPackageObject, 'UnInitialize'
IF @HRESULT <> 0
BEGIN
	EXEC @HRESULT = sp_OAGetErrorInfo @DTSPackageObject, @ErrSource OUTPUT, @ErrDescription OUTPUT
	RAISERROR( 'Error UnInitialize DTS package', 11, 1)
	RETURN -1
END

-- Clean Up
EXEC @HRESULT = sp_OADestroy @DTSPackageObject
IF @HRESULT <> 0
BEGIN
	EXEC @HRESULT = sp_OAGetErrorInfo @DTSPackageObject, @ErrSource OUTPUT, @ErrDescription OUTPUT
	RAISERROR( 'Error Destroying DTS package', 11, 1)
	RETURN -1
END

RETURN 1
GO
