package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"github.com/jamesnetherton/m3u"
)

const cacheFile = "cache/playlist.m3u"

func fetchPlaylist(url string) error {
	log.Printf("Fetching playlist from %s...", url)
	resp, err := http.Get(url)
	if err != nil {
		return fmt.Errorf("failed to fetch playlist: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	err = os.MkdirAll(filepath.Dir(cacheFile), 0755)
	if err != nil {
		return fmt.Errorf("failed to create cache directory: %v", err)
	}

	out, err := os.Create(cacheFile)
	if err != nil {
		return fmt.Errorf("failed to create cache file: %v", err)
	}
	defer out.Close()

	_, err = io.Copy(out, resp.Body)
	if err != nil {
		return fmt.Errorf("failed to save playlist: %v", err)
	}

	log.Println("Playlist fetched and cached successfully.")
	return nil
}

func parseCachedPlaylist() (m3u.Playlist, error) {
	if _, err := os.Stat(cacheFile); os.IsNotExist(err) {
		return m3u.Playlist{}, fmt.Errorf("cached playlist not found")
	}

	playlist, err := m3u.Parse(cacheFile)
	if err != nil {
		return m3u.Playlist{}, fmt.Errorf("failed to parse playlist: %v", err)
	}

	return playlist, nil
}
