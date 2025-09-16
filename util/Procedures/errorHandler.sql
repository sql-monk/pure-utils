ALTER PROCEDURE util.errorHandler
    @attachment NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    DECLARE @ErrorNumber INT = ERROR_NUMBER();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    DECLARE @ErrorProcedure NVARCHAR(128) = ERROR_PROCEDURE();
    DECLARE @ErrorLine INT = ERROR_LINE();
    DECLARE @ErrorLineText NVARCHAR(max) = (SELECT line FROM util.modulesSplitToLines(@ErrorProcedure, DEFAULT) WHERE ordinal = @ErrorLine);
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @OriginalLogin NVARCHAR(128) = ORIGINAL_LOGIN();
    DECLARE @SessionId SMALLINT = @@SPID;
    DECLARE @HostName NVARCHAR(128) = HOST_NAME();
    DECLARE @ProgramName NVARCHAR(128) = PROGRAM_NAME();
    DECLARE @DatabaseName NVARCHAR(128) = DB_NAME();
    DECLARE @UserName NVARCHAR(128) = USER_NAME();

    DECLARE @SessionInfo XML = NULL;
    

    
    -- Collect detailed session information
    BEGIN TRY
        SELECT @SessionInfo = (
            SELECT 
                s.session_id,
                s.login_time,
                s.host_name,
                s.program_name,
                s.client_interface_name,
                s.login_name,
                s.nt_domain,
                s.nt_user_name,
                s.original_login_name,
                s.status,
                s.context_info,
                s.cpu_time,
                s.memory_usage,
                s.total_scheduled_time,
                s.total_elapsed_time,
                s.endpoint_id,
                s.last_request_start_time,
                s.last_request_end_time,
                s.reads,
                s.writes,
                s.logical_reads,
                CASE 
                    WHEN r.session_id IS NOT NULL THEN
                        (SELECT 
                            r.request_id,
                            r.start_time,
                            r.status AS request_status,
                            r.command,
                            r.database_id,
                            r.blocking_session_id,
                            r.wait_type,
                            r.wait_time,
                            r.wait_resource,
                            r.open_transaction_count,
                            r.open_resultset_count,
                            r.transaction_id,
                            r.percent_complete,
                            r.estimated_completion_time,
                            r.cpu_time AS request_cpu_time,
                            r.total_elapsed_time AS request_elapsed_time,
                            r.reads AS request_reads,
                            r.writes AS request_writes,
                            r.logical_reads AS request_logical_reads,
                            r.row_count,
                            r.granted_query_memory,
                            r.executing_managed_code
                        FOR XML PATH('request'), TYPE)
                    ELSE NULL
                END AS current_request
            FROM sys.dm_exec_sessions s WITH (NOLOCK)
            LEFT JOIN sys.dm_exec_requests r WITH (NOLOCK) ON s.session_id = r.session_id
            WHERE s.session_id = @SessionId
            FOR XML PATH('session'), TYPE
        );
    END TRY
    BEGIN CATCH
        SET @SessionInfo = NULL;
    END CATCH
    
    -- Insert error information into log table
    BEGIN TRY
        INSERT INTO util.ErrorLog (
            ErrorNumber,
            ErrorSeverity,
            ErrorState,
            ErrorProcedure,
            ErrorLine,
            ErrorLineText,
            ErrorMessage,
            OriginalLogin,
            SessionId,
            HostName,
            ProgramName,
            DatabaseName,
            UserName,
            Attachment,
            SessionInfo
        )
        VALUES (
            @ErrorNumber,
            @ErrorSeverity,
            @ErrorState,
            @ErrorProcedure,
            @ErrorLine,
						@ErrorLineText,
            @ErrorMessage,
            @OriginalLogin,
            @SessionId,
            @HostName,
            @ProgramName,
            @DatabaseName,
            @UserName,
            @attachment,
            @SessionInfo
        );
        

    END TRY
    BEGIN CATCH
        -- If we can't log the error, at least output the original error information
        SELECT 
            @ErrorNumber AS ErrorNumber,
            @ErrorSeverity AS ErrorSeverity,
            @ErrorState AS ErrorState,
            @ErrorProcedure AS ErrorProcedure,
            @ErrorLine AS ErrorLine,
            @ErrorMessage AS ErrorMessage,
            'Failed to log error: ' + ERROR_MESSAGE() AS LoggingError;
    END CATCH
     
END;