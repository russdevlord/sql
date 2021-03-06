/****** Object:  StoredProcedure [dbo].[p_mediaunleashed_BLOAD_refresh]    Script Date: 12/03/2021 10:03:46 AM ******/
DROP PROCEDURE [dbo].[p_mediaunleashed_BLOAD_refresh]
GO
/****** Object:  StoredProcedure [dbo].[p_mediaunleashed_BLOAD_refresh]    Script Date: 12/03/2021 10:03:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[p_mediaunleashed_BLOAD_refresh] 

as

/*==============================================================*
 * DESC:- reads site BLOAD file and adds to                     *
 *            mediaunleashed_BLOAD_Sessions                     *
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

DECLARE @counter		smallint

CREATE TABLE #tmp_BLOAD
(
            ComplexId			INT,
            CinemaNo			VARCHAR(3),
            StartTime			VARCHAR(5),
            RunningTime			VARCHAR(5),
            SeatsSold			VARCHAR(5),
            SeatsRemaining		VARCHAR(5),
            Classification		VARCHAR(6),
            VistaCode			VARCHAR(12),
            MovieParameters		VARCHAR(30),
            TotalSeats			VARCHAR(45),
            FullTitle			VARCHAR(75),
            ConsumerAdvice		VARCHAR(255)
)

/* ACT Woden */
INSERT INTO #tmp_BLOAD (ComplexId,CinemaNo,StartTime,RunningTime,SeatsSold,SeatsRemaining,Classification,VistaCode,MovieParameters,TotalSeats,FullTitle,ConsumerAdvice)
	SELECT 742,c.[CinemaNo],c.[StartTime],c.[RunningTime],c.[SeatsSold],c.[SeatsRemaining],c.[Classification],c.[VistaCode],c.[MovieParameters],c.[TotalSeats],c.[FullTitle],c.[ConsumerAdvice]
	FROM OPENROWSET(
		BULK N'C:\MediaUnleashed\BLOAD\bload_742.txt', FORMATFILE = 'C:\MediaUnleashed\BLOAD\BLOADformat.xml'
	) c
SET @counter = @@ROWCOUNT

/* NSW Chatsfield */
INSERT INTO #tmp_BLOAD (ComplexId,CinemaNo,StartTime,RunningTime,SeatsSold,SeatsRemaining,Classification,VistaCode,MovieParameters,TotalSeats,FullTitle,ConsumerAdvice)
	SELECT 736,c.[CinemaNo],c.[StartTime],c.[RunningTime],c.[SeatsSold],c.[SeatsRemaining],c.[Classification],c.[VistaCode],c.[MovieParameters],c.[TotalSeats],c.[FullTitle],c.[ConsumerAdvice]
	FROM OPENROWSET(
		BULK N'C:\MediaUnleashed\BLOAD\bload_736.txt', FORMATFILE = 'C:\MediaUnleashed\BLOAD\BLOADformat.xml'
	) c
SET @counter = @counter + @@ROWCOUNT

/* NSW Mt Druitt */
INSERT INTO #tmp_BLOAD (ComplexId,CinemaNo,StartTime,RunningTime,SeatsSold,SeatsRemaining,Classification,VistaCode,MovieParameters,TotalSeats,FullTitle,ConsumerAdvice)
	SELECT 208,c.[CinemaNo],c.[StartTime],c.[RunningTime],c.[SeatsSold],c.[SeatsRemaining],c.[Classification],c.[VistaCode],c.[MovieParameters],c.[TotalSeats],c.[FullTitle],c.[ConsumerAdvice]
	FROM OPENROWSET(
		BULK N'C:\MediaUnleashed\BLOAD\bload_208.txt', FORMATFILE = 'C:\MediaUnleashed\BLOAD\BLOADformat.xml'
	) c
SET @counter = @counter + @@ROWCOUNT

/* NSW Mt Druitt */
INSERT INTO #tmp_BLOAD (ComplexId,CinemaNo,StartTime,RunningTime,SeatsSold,SeatsRemaining,Classification,VistaCode,MovieParameters,TotalSeats,FullTitle,ConsumerAdvice)
	SELECT 208,c.[CinemaNo],c.[StartTime],c.[RunningTime],c.[SeatsSold],c.[SeatsRemaining],c.[Classification],c.[VistaCode],c.[MovieParameters],c.[TotalSeats],c.[FullTitle],c.[ConsumerAdvice]
	FROM OPENROWSET(
		BULK N'C:\MediaUnleashed\BLOAD\bload_208.txt', FORMATFILE = 'C:\MediaUnleashed\BLOAD\BLOADformat.xml'
	) c
SET @counter = @counter + @@ROWCOUNT

/* NSW Penrith */
INSERT INTO #tmp_BLOAD (ComplexId,CinemaNo,StartTime,RunningTime,SeatsSold,SeatsRemaining,Classification,VistaCode,MovieParameters,TotalSeats,FullTitle,ConsumerAdvice)
	SELECT 547,c.[CinemaNo],c.[StartTime],c.[RunningTime],c.[SeatsSold],c.[SeatsRemaining],c.[Classification],c.[VistaCode],c.[MovieParameters],c.[TotalSeats],c.[FullTitle],c.[ConsumerAdvice]
	FROM OPENROWSET(
		BULK N'C:\MediaUnleashed\BLOAD\bload_547.txt', FORMATFILE = 'C:\MediaUnleashed\BLOAD\BLOADformat.xml'
	) c
SET @counter = @counter + @@ROWCOUNT

/* NSW Warringah */
INSERT INTO #tmp_BLOAD (ComplexId,CinemaNo,StartTime,RunningTime,SeatsSold,SeatsRemaining,Classification,VistaCode,MovieParameters,TotalSeats,FullTitle,ConsumerAdvice)
	SELECT 107,c.[CinemaNo],c.[StartTime],c.[RunningTime],c.[SeatsSold],c.[SeatsRemaining],c.[Classification],c.[VistaCode],c.[MovieParameters],c.[TotalSeats],c.[FullTitle],c.[ConsumerAdvice]
	FROM OPENROWSET(
		BULK N'C:\MediaUnleashed\BLOAD\bload_107.txt', FORMATFILE = 'C:\MediaUnleashed\BLOAD\BLOADformat.xml'
	) c
SET @counter = @counter + @@ROWCOUNT

/* SA Tea Tree */
INSERT INTO #tmp_BLOAD (ComplexId,CinemaNo,StartTime,RunningTime,SeatsSold,SeatsRemaining,Classification,VistaCode,MovieParameters,TotalSeats,FullTitle,ConsumerAdvice)
	SELECT 423,c.[CinemaNo],c.[StartTime],c.[RunningTime],c.[SeatsSold],c.[SeatsRemaining],c.[Classification],c.[VistaCode],c.[MovieParameters],c.[TotalSeats],c.[FullTitle],c.[ConsumerAdvice]
	FROM OPENROWSET(
		BULK N'C:\MediaUnleashed\BLOAD\bload_423.txt', FORMATFILE = 'C:\MediaUnleashed\BLOAD\BLOADformat.xml'
	) c
SET @counter = @counter + @@ROWCOUNT

/* WA Carousel */
INSERT INTO #tmp_BLOAD (ComplexId,CinemaNo,StartTime,RunningTime,SeatsSold,SeatsRemaining,Classification,VistaCode,MovieParameters,TotalSeats,FullTitle,ConsumerAdvice)
	SELECT 450,c.[CinemaNo],c.[StartTime],c.[RunningTime],c.[SeatsSold],c.[SeatsRemaining],c.[Classification],c.[VistaCode],c.[MovieParameters],c.[TotalSeats],c.[FullTitle],c.[ConsumerAdvice]
	FROM OPENROWSET(
		BULK N'C:\MediaUnleashed\BLOAD\bload_450.txt', FORMATFILE = 'C:\MediaUnleashed\BLOAD\BLOADformat.xml'
	) c
SET @counter = @counter + @@ROWCOUNT

if @counter > 0
BEGIN
	DELETE FROM mediaunleashed_BLOAD_Sessions -- WHERE ComplexId IN (736)
	INSERT mediaunleashed_BLOAD_Sessions SELECT * FROM #tmp_BLOAD
END

DROP table #tmp_BLOAD
GO
