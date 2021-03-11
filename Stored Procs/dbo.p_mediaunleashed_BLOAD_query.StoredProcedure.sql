USE [production]
GO
/****** Object:  StoredProcedure [dbo].[p_mediaunleashed_BLOAD_query]    Script Date: 11/03/2021 2:30:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[p_mediaunleashed_BLOAD_query] @vistacodes VARCHAR(50)

as

/*==============================================================*
 * DESC:- reads BLOAD_Sessions info for a selected Vista Code   *
 *                                                              *
 *                       CHANGE HISTORY                         *
 *                       ==============                         *
 *                                                              *
 * Ver    DATE     BY   DESCRIPTION                             *
 * === =========== ===  ===========                             *
 *  1  02-Aug-2016 DH   Initial Build                           *
 *                                                              *
 *==============================================================*/

SET NOCOUNT ON

SELECT StartTime FROM mediaunleashed_BLOAD_Sessions WHERE ComplexId = 545 AND VistaCode IN (@vistacodes) ORDER BY StartTime
GO
