package main

import (
	"fmt"
	"regexp"
	"strings"

	"github.com/jamesnetherton/m3u"
)

type SeriesItem struct {
	Track   m3u.Track
	Season  int
	Episode int
}

type Series struct {
	Name    string
	Seasons map[int][]SeriesItem
}

type ParsedData struct {
	VODs   []m3u.Track
	Series map[string]*Series
	Groups map[string][]m3u.Track
}

var seriesRegex = regexp.MustCompile(`(?i)(.+?)\s*[S]?(\d{1,2})[E|x](\d{1,3})`)

func ProcessPlaylist(playlist m3u.Playlist) *ParsedData {
	data := &ParsedData{
		VODs:   make([]m3u.Track, 0),
		Series: make(map[string]*Series),
		Groups: make(map[string][]m3u.Track),
	}

	for _, track := range playlist.Tracks {
		// Use tags if available, otherwise default
		group := "Uncategorized"
		for _, tag := range track.Tags {
			if tag.Name == "group-title" {
				group = tag.Value
				break
			}
		}

		data.Groups[group] = append(data.Groups[group], track)

		title := track.Name

		// Attempt to match Series/Season/Episode
		matches := seriesRegex.FindStringSubmatch(title)
		if len(matches) == 4 {
			seriesName := strings.TrimSpace(matches[1])

			// Simple fallback for cleanup (remove typical junk from names if needed)
			if strings.Contains(seriesName, " - ") {
				parts := strings.Split(seriesName, " - ")
				seriesName = strings.TrimSpace(parts[0])
			}

			season, _ := parseToInt(matches[2])
			episode, _ := parseToInt(matches[3])

			if _, ok := data.Series[seriesName]; !ok {
				data.Series[seriesName] = &Series{
					Name:    seriesName,
					Seasons: make(map[int][]SeriesItem),
				}
			}

			data.Series[seriesName].Seasons[season] = append(data.Series[seriesName].Seasons[season], SeriesItem{
				Track:   track,
				Season:  season,
				Episode: episode,
			})
		} else {
			// Assume VOD or general item if it doesn't match series pattern
			data.VODs = append(data.VODs, track)
		}
	}

	return data
}

func parseToInt(s string) (int, error) {
	var n int
	_, err := fmt.Sscanf(s, "%d", &n)
	return n, err
}
