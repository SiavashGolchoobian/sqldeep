USE [msdb]
GO

/****** Object:  Alert [SqlDeep_Alert_Sev22_FatalErrorTableIntegritySuspect]    Script Date: 2/28/2021 9:36:51 AM ******/
EXEC msdb.dbo.sp_add_alert @name=N'SqlDeep_Alert_Sev22_FatalErrorTableIntegritySuspect', 
		@message_id=0, 
		@severity=22, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

