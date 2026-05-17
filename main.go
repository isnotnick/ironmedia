package main

import (
	"flag"
	"fmt"
	"log"
)

var globalUrl string

func main() {
	urlFlag := flag.String("url", "", "URL of the M3U playlist")
	portFlag := flag.String("port", "8080", "Port to run the web server on")
	flag.Parse()

	globalUrl = *urlFlag

	if globalUrl != "" {
		err := fetchPlaylist(globalUrl)
		if err != nil {
			log.Fatalf("Failed to fetch playlist: %v", err)
		}
	}

	playlist, err := parseCachedPlaylist()
	if err != nil {
		log.Fatalf("Failed to parse cached playlist: %v\nPlease provide a valid -url flag to fetch it.", err)
	}

	parsedData := ProcessPlaylist(playlist)
	log.Printf("Successfully parsed playlist. Found %d VODs, %d Series, %d Groups.", len(parsedData.VODs), len(parsedData.Series), len(parsedData.Groups))

	// Initialize Download Manager with 3 workers
	dm := NewDownloadManager(3)

	// Start Web Server
	startServer(*portFlag, dm, parsedData)
}

func refreshPlaylist() error {
	if globalUrl == "" {
		return fmt.Errorf("no URL provided at startup to refresh from")
	}

	err := fetchPlaylist(globalUrl)
	if err != nil {
		return err
	}

	playlist, err := parseCachedPlaylist()
	if err != nil {
		return err
	}

	// Update the global parsed data safely
	dataMutex.Lock()
	*parsedData = *ProcessPlaylist(playlist)
	dataMutex.Unlock()

	log.Printf("Playlist refreshed. Found %d VODs, %d Series, %d Groups.", len(parsedData.VODs), len(parsedData.Series), len(parsedData.Groups))
	return nil
}
