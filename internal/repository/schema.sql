-- jobs 테이블
CREATE TABLE jobs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    python_file_path TEXT NOT NULL,
    cron_expression TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    timeout_seconds INTEGER DEFAULT 300,
    max_retries INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- job_executions 테이블 (실행 이력)
CREATE TABLE job_executions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    job_id INTEGER NOT NULL,
    status TEXT NOT NULL, -- 'pending', 'running', 'success', 'failed', 'timeout'
    started_at DATETIME,
    finished_at DATETIME,
    output TEXT,
    error_message TEXT,
    exit_code INTEGER,
    FOREIGN KEY (job_id) REFERENCES jobs(id)
);

-- scheduler_state 테이블 (스케줄러 상태 관리)
CREATE TABLE scheduler_state (
    job_id INTEGER PRIMARY KEY,
    last_run DATETIME,
    next_run DATETIME,
    FOREIGN KEY (job_id) REFERENCES jobs(id)
);

-- distributed_locks 테이블 (분산 락)
CREATE TABLE distributed_locks (
    lock_key TEXT PRIMARY KEY,
    instance_id TEXT NOT NULL,
    acquired_at DATETIME NOT NULL,
    expires_at DATETIME NOT NULL,
    heartbeat_at DATETIME NOT NULL
);