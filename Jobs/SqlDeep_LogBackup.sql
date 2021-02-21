USE [msdb]
GO

/****** Object:  Job [SqlDeep_LogBackup]    Script Date: 2/21/2021 10:36:20 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [SqlDeep Jobs]    Script Date: 2/21/2021 10:36:20 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'SqlDeep Jobs' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'SqlDeep Jobs'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SqlDeep_LogBackup', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Take log backup', 
		@category_name=N'SqlDeep Jobs', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Take log backup]    Script Date: 2/21/2021 10:36:20 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Take log backup', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @DatabaseNames nvarchar(max)=''<ALL_DATABASES>''
DECLARE @LocalDestinationPath nvarchar(max)
DECLARE @BackupExtension nvarchar(3)=''bak''
DECLARE @BackupType nvarchar(4)=''LOG''
DECLARE @RetainDays int=7
DECLARE @SplitThresholdSizeGB bigint=80
DECLARE @DiffOrLogThresholdSizeGB bigint=0
DECLARE @BackupFileNamingType nvarchar(50)=''DATE''
DECLARE @PrintOnly bit=0

SELECT @LocalDestinationPath=CAST(value as nvarchar(max)) from [SqlDeep].[sys].[extended_properties] WHERE class=0 and name=N''_BackupLocation''

EXECUTE [dbo].[dbasp_maintenance_take_backup] 
   @DatabaseNames
  ,@LocalDestinationPath
  ,@BackupExtension
  ,@BackupType
  ,@RetainDays
  ,@SplitThresholdSizeGB
  ,@DiffOrLogThresholdSizeGB
  ,@BackupFileNamingType
  ,@PrintOnly', 
		@database_name=N'SqlDeep', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink log file]    Script Date: 2/21/2021 10:36:20 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Shrink log file', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @DatabaseNames nvarchar(max)
DECLARE @TargetSizeMB nvarchar(255)

SET @DatabaseNames=''<ALL_DATABASES>''
SET @TargetSizeMB=''EP:_ShrinkLogToSizeMB''
EXECUTE [dbo].[dbasp_maintenance_shrinklog] @DatabaseNames,@TargetSizeMB', 
		@database_name=N'SqlDeep', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SqlDeep.LogBackup', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20200725, 
		@active_end_date=99991231, 
		@active_start_time=14500, 
		@active_end_time=14459, 
		@schedule_uid=N'7959bb55-30dc-4032-936f-e59850106c4d'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

