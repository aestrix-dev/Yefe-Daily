package service

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/robfig/cron/v3"
	"github.com/sirupsen/logrus"
)

// JobStatus represents the status of a job
type JobStatus string

const (
	StatusPending   JobStatus = "pending"
	StatusRunning   JobStatus = "running"
	StatusCompleted JobStatus = "completed"
	StatusFailed    JobStatus = "failed"
	StatusCancelled JobStatus = "cancelled"
)

// Job represents a scheduled job
type Job struct {
	ID          string                      `json:"id"`
	Name        string                      `json:"name"`
	Schedule    string                      `json:"schedule"`
	Function    func(context.Context) error `json:"-"`
	Status      JobStatus                   `json:"status"`
	LastRun     *time.Time                  `json:"last_run,omitempty"`
	NextRun     *time.Time                  `json:"next_run,omitempty"`
	RunCount    int                         `json:"run_count"`
	ErrorCount  int                         `json:"error_count"`
	LastError   string                      `json:"last_error,omitempty"`
	CreatedAt   time.Time                   `json:"created_at"`
	IsRecurring bool                        `json:"is_recurring"`
	cronID      cron.EntryID                `json:"-"`
	cancelFunc  context.CancelFunc          `json:"-"`
}

// JobResult represents the result of a job execution
type JobResult struct {
	JobID     string    `json:"job_id"`
	Status    JobStatus `json:"status"`
	StartTime time.Time `json:"start_time"`
	EndTime   time.Time `json:"end_time"`
	Error     string    `json:"error,omitempty"`
}

// Scheduler manages scheduled jobs
type Scheduler struct {
	cron     *cron.Cron
	jobs     map[string]*Job
	results  []JobResult
	mu       sync.RWMutex
	resultMu sync.RWMutex
	ctx      context.Context
	cancel   context.CancelFunc
	logger   *logrus.Logger
}

// NewScheduler creates a new scheduler instance
func NewScheduler(logger *logrus.Logger, ctx context.Context, cancel context.CancelFunc) *Scheduler {

	scheduler := &Scheduler{
		cron:    cron.New(cron.WithSeconds()),
		jobs:    make(map[string]*Job),
		results: make([]JobResult, 0),
		ctx:     ctx,
		cancel:  cancel,
		logger:  logger,
	}

	scheduler.logger.Info("Scheduler instance created")
	return scheduler
}

// Start starts the scheduler
func (s *Scheduler) Start() {
	s.logger.Info("Starting scheduler...")
	s.cron.Start()
	s.logger.Info("Scheduler started successfully")
}

// Stop stops the scheduler
func (s *Scheduler) Stop() {
	s.logger.Info("Stopping scheduler...")
	s.cancel()
	s.cron.Stop()
	s.logger.Info("Scheduler stopped successfully")
}

// AddJob adds a new job to the scheduler
func (s *Scheduler) AddJob(id, name, schedule string, fn func(context.Context) error) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.jobs[id]; exists {
		return fmt.Errorf("job with ID %s already exists", id)
	}

	job := &Job{
		ID:          id,
		Name:        name,
		Schedule:    schedule,
		Function:    fn,
		Status:      StatusPending,
		CreatedAt:   time.Now(),
		IsRecurring: schedule != "",
	}

	if schedule != "" {
		// Recurring job
		cronID, err := s.cron.AddFunc(schedule, s.wrapJobFunction(job))
		if err != nil {
			return fmt.Errorf("failed to add cron job: %w", err)
		}
		job.cronID = cronID

		// Set next run time
		entries := s.cron.Entries()
		for _, entry := range entries {
			if entry.ID == cronID {
				nextRun := entry.Next
				job.NextRun = &nextRun
				break
			}
		}
	} else {
		// One-time job, run immediately
		go s.runJob(job)
	}

	s.jobs[id] = job
	return nil
}

// AddOneTimeJob adds a job that runs once at a specific time
func (s *Scheduler) AddOneTimeJob(id, name string, runAt time.Time, fn func(context.Context) error) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.logger.WithFields(logrus.Fields{
		"job_id":   id,
		"job_name": name,
		"run_at":   runAt,
	}).Info("Adding one-time job")

	if _, exists := s.jobs[id]; exists {
		s.logger.WithField("job_id", id).Error("Job already exists")
		return fmt.Errorf("job with ID %s already exists", id)
	}

	job := &Job{
		ID:          id,
		Name:        name,
		Schedule:    "",
		Function:    fn,
		Status:      StatusPending,
		NextRun:     &runAt,
		CreatedAt:   time.Now(),
		IsRecurring: false,
	}

	s.jobs[id] = job

	// Schedule the job to run at the specified time
	go func() {
		waitDuration := time.Until(runAt)
		s.logger.WithFields(logrus.Fields{
			"job_id":        id,
			"wait_duration": waitDuration,
		}).Info("Waiting for job execution time")

		timer := time.NewTimer(waitDuration)
		defer timer.Stop()

		select {
		case <-timer.C:
			s.logger.WithField("job_id", id).Info("Executing scheduled one-time job")
			s.runJob(job)
		case <-s.ctx.Done():
			s.logger.WithField("job_id", id).Info("One-time job cancelled due to scheduler shutdown")
			s.cancelJob(id)
			return
		}
	}()

	s.logger.WithField("job_id", id).Info("One-time job scheduled successfully")
	return nil
}

// wrapJobFunction wraps a job function for cron execution
func (s *Scheduler) wrapJobFunction(job *Job) func() {
	return func() {
		s.runJob(job)
	}
}

// runJob executes a job
func (s *Scheduler) runJob(job *Job) {
	ctx, cancel := context.WithCancel(s.ctx)
	job.cancelFunc = cancel

	result := JobResult{
		JobID:     job.ID,
		StartTime: time.Now(),
	}

	s.logger.WithFields(logrus.Fields{
		"job_id":   job.ID,
		"job_name": job.Name,
	}).Info("Starting job execution")

	s.mu.Lock()
	job.Status = StatusRunning
	now := time.Now()
	job.LastRun = &now
	s.mu.Unlock()

	err := job.Function(ctx)

	s.mu.Lock()
	job.RunCount++
	if err != nil {
		job.Status = StatusFailed
		job.ErrorCount++
		job.LastError = err.Error()
		result.Status = StatusFailed
		result.Error = err.Error()

		s.logger.WithFields(logrus.Fields{
			"job_id":    job.ID,
			"job_name":  job.Name,
			"error":     err.Error(),
			"run_count": job.RunCount,
		}).Error("Job execution failed")
	} else {
		job.Status = StatusCompleted
		job.LastError = ""
		result.Status = StatusCompleted

		s.logger.WithFields(logrus.Fields{
			"job_id":    job.ID,
			"job_name":  job.Name,
			"run_count": job.RunCount,
			"duration":  time.Since(result.StartTime),
		}).Info("Job executed successfully")
	}

	// Update next run time for recurring jobs
	if job.IsRecurring {
		entries := s.cron.Entries()
		for _, entry := range entries {
			if entry.ID == job.cronID {
				nextRun := entry.Next
				job.NextRun = &nextRun
				s.logger.WithFields(logrus.Fields{
					"job_id":   job.ID,
					"next_run": nextRun,
				}).Debug("Updated next run time for recurring job")
				break
			}
		}
	} else {
		job.NextRun = nil
	}

	s.mu.Unlock()

	result.EndTime = time.Now()
	s.addResult(result)
}

// addResult adds a job result to the history
func (s *Scheduler) addResult(result JobResult) {
	s.resultMu.Lock()
	defer s.resultMu.Unlock()

	s.results = append(s.results, result)

	// Keep only last 100 results
	if len(s.results) > 100 {
		s.results = s.results[len(s.results)-100:]
	}
}

// RemoveJob removes a job from the scheduler
func (s *Scheduler) RemoveJob(id string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.logger.WithField("job_id", id).Info("Removing job")

	job, exists := s.jobs[id]
	if !exists {
		s.logger.WithField("job_id", id).Error("Job not found for removal")
		return fmt.Errorf("job with ID %s not found", id)
	}

	if job.IsRecurring {
		s.cron.Remove(job.cronID)
		s.logger.WithField("job_id", id).Debug("Removed recurring job from cron")
	}

	if job.cancelFunc != nil {
		job.cancelFunc()
		s.logger.WithField("job_id", id).Debug("Cancelled job context")
	}

	delete(s.jobs, id)
	s.logger.WithField("job_id", id).Info("Job removed successfully")
	return nil
}

// cancelJob cancels a running job
func (s *Scheduler) cancelJob(id string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.logger.WithField("job_id", id).Info("Cancelling job")

	job, exists := s.jobs[id]
	if !exists {
		s.logger.WithField("job_id", id).Error("Job not found for cancellation")
		return fmt.Errorf("job with ID %s not found", id)
	}

	if job.cancelFunc != nil {
		job.cancelFunc()
		s.logger.WithField("job_id", id).Debug("Cancelled job context")
	}

	job.Status = StatusCancelled
	s.logger.WithField("job_id", id).Info("Job cancelled successfully")
	return nil
}

// GetJobs returns all jobs
func (s *Scheduler) GetJobs() map[string]*Job {
	s.mu.RLock()
	defer s.mu.RUnlock()

	jobs := make(map[string]*Job)
	for id, job := range s.jobs {
		jobs[id] = job // TODO replace with maps.copy
	}
	return jobs
}

// GetJob returns a specific job
func (s *Scheduler) GetJob(id string) (*Job, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	job, exists := s.jobs[id]
	return job, exists
}

// GetResults returns job execution results
func (s *Scheduler) GetResults(limit int) []JobResult {
	s.resultMu.RLock()
	defer s.resultMu.RUnlock()

	if limit <= 0 || limit > len(s.results) {
		limit = len(s.results)
	}

	results := make([]JobResult, limit)
	copy(results, s.results[len(s.results)-limit:])
	return results
}
