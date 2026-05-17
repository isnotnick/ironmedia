package main

import (
	"encoding/json"
	"html/template"
	"log"
	"net/http"

	"sync"

	"github.com/gorilla/mux"
)

var (
	downloadManager *DownloadManager
	parsedData      *ParsedData
	templates       *template.Template
	dataMutex       sync.RWMutex
)

func startServer(port string, dm *DownloadManager, pd *ParsedData) {
	downloadManager = dm
	parsedData = pd

	// Load templates
	templates = template.Must(template.ParseGlob("ui/templates/*.html"))

	r := mux.NewRouter()

	// Static files
	r.PathPrefix("/static/").Handler(http.StripPrefix("/static/", http.FileServer(http.Dir("ui/static/"))))

	// UI Routes
	r.HandleFunc("/", handleIndex).Methods("GET")
	r.HandleFunc("/series/{name}", handleSeries).Methods("GET")
	r.HandleFunc("/downloads", handleDownloads).Methods("GET")

	// API Routes
	r.HandleFunc("/api/download", handleApiDownload).Methods("POST")
	r.HandleFunc("/api/downloads", handleApiGetDownloads).Methods("GET")
	r.HandleFunc("/api/refresh", handleApiRefresh).Methods("POST")

	log.Printf("Server starting on http://localhost:%s\n", port)
	log.Fatal(http.ListenAndServe(":"+port, r))
}

func handleIndex(w http.ResponseWriter, r *http.Request) {
	dataMutex.RLock()
	err := templates.ExecuteTemplate(w, "index.html", parsedData)
	dataMutex.RUnlock()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func handleSeries(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	name := vars["name"]

	dataMutex.RLock()
	series, ok := parsedData.Series[name]
	dataMutex.RUnlock()

	if !ok {
		http.NotFound(w, r)
		return
	}

	err := templates.ExecuteTemplate(w, "series.html", series)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func handleDownloads(w http.ResponseWriter, r *http.Request) {
	err := templates.ExecuteTemplate(w, "downloads.html", nil)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

type DownloadRequest struct {
	Title   string        `json:"title"`
	URL     string        `json:"url"`
	Quality QualityPreset `json:"quality"`
}

func handleApiDownload(w http.ResponseWriter, r *http.Request) {
	var req DownloadRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if req.Quality == "" {
		req.Quality = QualityOriginal
	}

	task := downloadManager.AddTask(req.Title, req.URL, req.Quality)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(task)
}

func handleApiGetDownloads(w http.ResponseWriter, r *http.Request) {
	tasks := downloadManager.GetAllTasks()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(tasks)
}

func handleApiRefresh(w http.ResponseWriter, r *http.Request) {
	err := refreshPlaylist()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"success"}`))
}
