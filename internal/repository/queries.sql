-- name: CreateJob :one
INSERT INTO jobs (
    name,
    description,
    python_file_path,
    cron_expression,
    is_active,
    timeout_seconds,
    max_retries
) VALUES (
    ?, ?, ?, ?, ?, ?, ?
) RETURNING *;

-- name: GetJob :one
SELECT * FROM jobs
WHERE id = ? LIMIT 1;

-- name: GetJobByName :one
SELECT * FROM jobs
WHERE name = ? LIMIT 1;

-- name: ListJobs :many
SELECT * FROM jobs
ORDER BY created_at DESC;

-- name: ListActiveJobs :many
SELECT * FROM jobs
WHERE is_active = true
ORDER BY created_at DESC;

-- name: UpdateJob :one
UPDATE jobs
SET 
    name = ?,
    description = ?,
    python_file_path = ?,
    cron_expression = ?,
    is_active = ?,
    timeout_seconds = ?,
    max_retries = ?,
    updated_at = CURRENT_TIMESTAMP
WHERE id = ?
RETURNING *;

-- name: UpdateJobStatus :exec
UPDATE jobs
SET 
    is_active = ?,
    updated_at = CURRENT_TIMESTAMP
WHERE id = ?;

-- name: DeleteJob :exec
DELETE FROM jobs
WHERE id = ?;

-- name: CreateJobExecution :one
INSERT INTO job_executions (
    job_id,
    status,
    started_at
) VALUES (
    ?, ?, ?
) RETURNING *;

-- name: GetJobExecution :one
SELECT * FROM job_executions
WHERE id = ? LIMIT 1;

-- name: ListJobExecutions :many
SELECT * FROM job_executions
WHERE job_id = ?
ORDER BY started_at DESC
LIMIT ? OFFSET ?;

-- name: ListRecentJobExecutions :many
SELECT * FROM job_executions
WHERE job_id = ?
ORDER BY started_at DESC
LIMIT 10;

-- name: UpdateJobExecution :one
UPDATE job_executions
SET 
    status = ?,
    finished_at = ?,
    output = ?,
    error_message = ?,
    exit_code = ?
WHERE id = ?
RETURNING *;

-- name: GetRunningExecutions :many
SELECT * FROM job_executions
WHERE status = 'running'
ORDER BY started_at ASC;

-- name: GetJobExecutionStats :one
SELECT 
    COUNT(*) as total_executions,
    COUNT(CASE WHEN status = 'success' THEN 1 END) as success_count,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_count,
    COUNT(CASE WHEN status = 'timeout' THEN 1 END) as timeout_count,
    AVG(
        CASE 
            WHEN finished_at IS NOT NULL AND started_at IS NOT NULL 
            THEN (julianday(finished_at) - julianday(started_at)) * 86400 
        END
    ) as avg_duration_seconds
FROM job_executions
WHERE job_id = ?;

-- name: UpsertSchedulerState :exec
INSERT INTO scheduler_state (job_id, last_run, next_run)
VALUES (?, ?, ?)
ON CONFLICT(job_id) DO UPDATE SET
    last_run = excluded.last_run,
    next_run = excluded.next_run;

-- name: GetSchedulerState :one
SELECT * FROM scheduler_state
WHERE job_id = ? LIMIT 1;

-- name: ListSchedulerStates :many
SELECT 
    s.*,
    j.name as job_name,
    j.cron_expression,
    j.is_active
FROM scheduler_state s
JOIN jobs j ON s.job_id = j.id
WHERE j.is_active = true
ORDER BY s.next_run ASC;

-- name: GetJobsReadyToRun :many
SELECT 
    j.*,
    s.next_run
FROM jobs j
JOIN scheduler_state s ON j.id = s.job_id
WHERE j.is_active = true 
  AND s.next_run <= ?
ORDER BY s.next_run ASC;

-- name: DeleteSchedulerState :exec
DELETE FROM scheduler_state
WHERE job_id = ?;

-- name: AcquireDistributedLock :one
INSERT INTO distributed_locks (
    lock_key,
    instance_id,
    acquired_at,
    expires_at,
    heartbeat_at
) VALUES (
    ?, ?, ?, ?, ?
) ON CONFLICT(lock_key) DO UPDATE SET
    instance_id = excluded.instance_id,
    acquired_at = excluded.acquired_at,
    expires_at = excluded.expires_at,
    heartbeat_at = excluded.heartbeat_at
WHERE expires_at < CURRENT_TIMESTAMP
RETURNING *;

-- name: RenewDistributedLock :exec
UPDATE distributed_locks
SET 
    expires_at = ?,
    heartbeat_at = ?
WHERE lock_key = ? AND instance_id = ?;

-- name: ReleaseDistributedLock :exec
DELETE FROM distributed_locks
WHERE lock_key = ? AND instance_id = ?;

-- name: CleanupExpiredLocks :exec
DELETE FROM distributed_locks
WHERE expires_at < CURRENT_TIMESTAMP;

-- name: GetDistributedLock :one
SELECT * FROM distributed_locks
WHERE lock_key = ? LIMIT 1;

-- name: CleanupOldExecutions :exec
DELETE FROM job_executions
WHERE started_at < ? 
  AND status IN ('success', 'failed', 'timeout');

-- name: GetSystemStats :one
SELECT 
    COUNT(DISTINCT j.id) as total_jobs,
    COUNT(CASE WHEN j.is_active = true THEN 1 END) as active_jobs,
    COUNT(CASE WHEN je.status = 'running' THEN 1 END) as running_executions,
    COUNT(CASE WHEN je.started_at > ? THEN 1 END) as executions_last_24h
FROM jobs j
LEFT JOIN job_executions je ON j.id = je.job_id;