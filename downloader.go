package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
)

type DownloadStatus string

const (
	StatusQueued      DownloadStatus = "Queued"
	StatusDownloading DownloadStatus = "Downloading"
	StatusTranscoding DownloadStatus = "Transcoding"
	StatusCompleted   DownloadStatus = "Completed"
	StatusFailed      DownloadStatus = "Failed"
)

type QualityPreset string

const (
	QualityOriginal QualityPreset = "Original"
	Quality1080p    QualityPreset = "1080p"
	Quality720p     QualityPreset = "720p"
)

type DownloadTask struct {
	ID          string         `json:"id"`
	Title       string         `json:"title"`
	URL         string         `json:"url"`
	Status      DownloadStatus `json:"status"`
	Progress    float64        `json:"progress"`
	Quality     QualityPreset  `json:"quality"`
	Error       string         `json:"error,omitempty"`
	OutputFile  string         `json:"output_file,omitempty"`
	AddedAt     time.Time      `json:"added_at"`
	CompletedAt time.Time      `json:"completed_at,omitempty"`
	ctx         context.Context
	cancel      context.CancelFunc
}

type DownloadManager struct {
	tasks      map[string]*DownloadTask
	taskQueue  chan *DownloadTask
	mutex      sync.RWMutex
	maxWorkers int
	ffmpegPath string
}

func NewDownloadManager(maxWorkers int) *DownloadManager {
	manager := &DownloadManager{
		tasks:      make(map[string]*DownloadTask),
		taskQueue:  make(chan *DownloadTask, 100),
		maxWorkers: maxWorkers,
	}

	manager.findFFmpeg()

	// Start workers
	for i := 0; i < maxWorkers; i++ {
		go manager.worker()
	}

	return manager
}

func (m *DownloadManager) findFFmpeg() {
	// Check local directory first
	if _, err := os.Stat("./ffmpeg"); err == nil {
		m.ffmpegPath = "./ffmpeg"
		return
	}

	// Fallback to system PATH
	path, err := exec.LookPath("ffmpeg")
	if err == nil {
		m.ffmpegPath = path
		return
	}

	log.Println("WARNING: ffmpeg not found. Transcoding will not be available.")
}

func (m *DownloadManager) AddTask(title, url string, quality QualityPreset) *DownloadTask {
	ctx, cancel := context.WithCancel(context.Background())

	task := &DownloadTask{
		ID:       uuid.New().String(),
		Title:    title,
		URL:      url,
		Status:   StatusQueued,
		Progress: 0,
		Quality:  quality,
		AddedAt:  time.Now(),
		ctx:      ctx,
		cancel:   cancel,
	}

	m.mutex.Lock()
	m.tasks[task.ID] = task
	m.mutex.Unlock()

	m.taskQueue <- task

	return task
}

func (m *DownloadManager) GetTask(id string) (*DownloadTask, bool) {
	m.mutex.RLock()
	defer m.mutex.RUnlock()
	task, ok := m.tasks[id]
	return task, ok
}

func (m *DownloadManager) GetAllTasks() []DownloadTask {
	m.mutex.RLock()
	defer m.mutex.RUnlock()

	tasks := make([]DownloadTask, 0, len(m.tasks))
	for _, task := range m.tasks {
		tasks = append(tasks, *task)
	}
	return tasks
}

func (m *DownloadManager) worker() {
	for task := range m.taskQueue {
		m.processTask(task)
	}
}

func (m *DownloadManager) updateTaskStatus(task *DownloadTask, status DownloadStatus, progress float64) {
	m.mutex.Lock()
	defer m.mutex.Unlock()
	task.Status = status
	task.Progress = progress
}

func (m *DownloadManager) failTask(task *DownloadTask, err error) {
	m.mutex.Lock()
	defer m.mutex.Unlock()
	task.Status = StatusFailed
	task.Error = err.Error()
	log.Printf("Task %s failed: %v", task.ID, err)
}

func (m *DownloadManager) processTask(task *DownloadTask) {
	log.Printf("Starting task %s: %s", task.ID, task.Title)

	// Create downloads directory
	err := os.MkdirAll("downloads", 0755)
	if err != nil {
		m.failTask(task, fmt.Errorf("failed to create downloads directory: %v", err))
		return
	}

	// For simplicity, we'll stream directly into ffmpeg if we're transcoding,
	// or use ffmpeg to copy the stream if original quality

	m.updateTaskStatus(task, StatusDownloading, 0)

	if m.ffmpegPath == "" {
		m.failTask(task, fmt.Errorf("ffmpeg not found, cannot download/transcode"))
		return
	}

	outputFileName := fmt.Sprintf("%s.mp4", sanitizeFileName(task.Title))
	outputPath := filepath.Join("downloads", outputFileName)

	var args []string

	// Input URL
	args = append(args, "-i", task.URL)

	// Quality presets
	switch task.Quality {
	case Quality1080p:
		args = append(args, "-vf", "scale=-2:1080", "-b:v", "4000k", "-c:v", "libx264", "-c:a", "aac")
	case Quality720p:
		args = append(args, "-vf", "scale=-2:720", "-b:v", "2000k", "-c:v", "libx264", "-c:a", "aac")
	case QualityOriginal:
		fallthrough
	default:
		// Just copy streams
		args = append(args, "-c", "copy")
	}

	// Overwrite existing and format
	args = append(args, "-y", outputPath)

	cmd := exec.CommandContext(task.ctx, m.ffmpegPath, args...)

	// FFmpeg outputs progress to stderr. We could parse this to get progress,
	// but for now we'll just show it's active.
	// For accurate progress, we'd need to know the duration of the stream first.
	// We'll set a basic "in progress" state.
	m.updateTaskStatus(task, StatusTranscoding, 50)

	err = cmd.Run()

	if err != nil {
		if task.ctx.Err() == context.Canceled {
			m.failTask(task, fmt.Errorf("task canceled"))
		} else {
			m.failTask(task, fmt.Errorf("ffmpeg error: %v", err))
		}
		return
	}

	m.mutex.Lock()
	task.Status = StatusCompleted
	task.Progress = 100
	task.OutputFile = outputPath
	task.CompletedAt = time.Now()
	m.mutex.Unlock()

	log.Printf("Completed task %s: %s", task.ID, task.Title)
}

func sanitizeFileName(name string) string {
	// Simple sanitizer, you might want a more robust one
	invalidChars := []string{"/", "\\", "?", "%", "*", ":", "|", "\"", "<", ">"}
	result := name
	for _, char := range invalidChars {
		result = filepath.Clean(strings.ReplaceAll(result, char, "_"))
	}
	return result
}
