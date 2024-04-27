package bridge

import (
	"errors"
	"slices"
	"sync"

	"github.com/Unbreathable/a-pixel-game/gameserver/util"
)

// Config
const DrawingAreaBlueStart = 2
const DrawingAreaBlueEnd = 11
const DrawingAreaRedStart = 22
const DrawingAreaRedEnd = 31

type pixel struct {
	X    uint `json:"x"`
	Y    uint `json:"y"`
	Type uint `json:"t"`
}

type Frame = map[uint]map[uint]pixel // X -> Y -> Pixel

// Pixel types
const (
	PixelTypeAir      = 0
	PixelTypeBlue     = 1
	PixelTypeRed      = 2
	PixelTypeCollided = 3
)

type PixelPosition struct {
	X uint
	Y uint
}

type Line struct {
	CustomId  string
	Id        string // Used as a token to verify the drawer
	Finished  bool
	Direction int              // -1 or 1 (left or right)
	Points    []*PixelPosition // The entire line (not stored with relative positions cause individual parts can be destroyed)

	DirectionChanged bool // Data for bouncers
}

//* Frame drawing logic

// Concurrent line storage
var linesMutex = &sync.Mutex{}
var lines []*Line
var deletedPixels []PixelPosition // For marking collided/deleted pixels

// Clear the entire canvas
func ClearCanvas() {
	linesMutex.Lock()
	defer linesMutex.Unlock()

	lines = []*Line{}
	deletedPixels = []PixelPosition{}
}

// Draws a new frame that can be returned as JSON to the client
func ConstructFrame(shouldMove bool) (Frame, int64, int64) {
	linesMutex.Lock()
	defer linesMutex.Unlock()

	blueScore := 0
	redScore := 0

	if shouldMove {

		// Get the game mode
		modeSetting, valid := GetSetting(SettingMode)
		if !valid {
			panic("mode setting not found")
		}

		// Clear all deleted pixels
		deletedPixels = []PixelPosition{}

		//* Move all the lines by 1
		for _, line := range lines {
			line.DirectionChanged = false

			// Don't move the pixels if the line isn't finished yet
			if !line.Finished {
				continue
			}

			// Move every point by the line direction
			for _, point := range line.Points {
				point.X = uint(int(point.X) + line.Direction)
			}
		}

		//* Compute which pixels should be deleted
		deletions := map[*Line][]*PixelPosition{} // Line -> Pixel positions that should be deleted
		for _, line1 := range lines {
			for _, line2 := range lines {
				if line2.CustomId == line1.CustomId {
					continue
				}
				for _, point1 := range line1.Points {
					for _, point2 := range line2.Points {

						// If the pixels are on the same location, delete them
						if point1.X == point2.X && point1.Y == point2.Y {
							addToDeletions(&deletions, line1, point1)
							addToDeletions(&deletions, line2, point2)
						}

						// If two pixels went through each other, delete them
						if uint(int(point1.X)-line1.Direction) == point2.X && point1.Y == point2.Y && line1.Direction != line2.Direction {
							addToDeletions(&deletions, line1, point1)
							addToDeletions(&deletions, line2, point2)
						}
					}
				}
			}

			// Check for points in the goal
			for _, point := range line1.Points {

				// Check if it reached the goal
				if point.X > DrawingAreaRedEnd {
					addToDeletions(&deletions, line1, point)
					blueScore++
				}
				if point.X < DrawingAreaBlueStart {
					addToDeletions(&deletions, line1, point)
					redScore++
				}
			}
		}

		//* Actually delete the points from the lines
		for line, points := range deletions {
			for _, point := range points {
				line.Points = slices.DeleteFunc(line.Points, func(p *PixelPosition) bool {
					return p.X == point.X && p.Y == point.Y
				})

				// Check if the line should change direction (for bouncers gamemode)
				if modeSetting == 1 && !line.DirectionChanged && (point.X <= DrawingAreaBlueStart || point.X >= DrawingAreaRedEnd) {
					if line.Direction == -1 {
						line.Direction = 1
					} else {
						line.Direction = -1
					}
					line.DirectionChanged = true
				}
			}

			// Delete the line if it is empty
			if len(line.Points) == 0 {
				lines = slices.DeleteFunc(lines, func(l *Line) bool {
					return l.CustomId == line.CustomId
				})
			}
		}
	}

	//* Draw the actual frame
	frame := Frame{}
	for _, line := range lines {
		for _, point := range line.Points {

			// If there is no row, add one
			if frame[point.X] == nil {
				frame[point.X] = map[uint]pixel{}
			}

			// Draw the pixel as solid
			if line.Direction == -1 {
				frame[point.X][point.Y] = pixel{
					X:    point.X,
					Y:    point.Y,
					Type: PixelTypeRed,
				}
			} else {
				frame[point.X][point.Y] = pixel{
					X:    point.X,
					Y:    point.Y,
					Type: PixelTypeBlue,
				}
			}
		}
	}

	// Draw the deleted pixels
	for _, point := range deletedPixels {

		// If there is no row, add one
		if frame[point.X] == nil {
			frame[point.X] = map[uint]pixel{}
		}

		// Draw the pixel as collided
		frame[point.X][point.Y] = pixel{
			X:    point.X,
			Y:    point.Y,
			Type: PixelTypeCollided,
		}
	}

	return frame, int64(blueScore), int64(redScore)
}

// Add a position on a line to the deletions map
func addToDeletions(deletions *map[*Line][]*PixelPosition, line *Line, position *PixelPosition) {

	// Add to deleted pixels list
	if !slices.ContainsFunc(deletedPixels, func(pos PixelPosition) bool {
		return position.X == pos.X && position.Y == pos.Y
	}) {
		deletedPixels = append(deletedPixels, PixelPosition{position.X, position.Y})
	}

	// Remove from the line
	deletionsMap := *deletions
	if deletionsMap[line] == nil {
		deletionsMap[line] = []*PixelPosition{}
	}
	deletionsMap[line] = append(deletionsMap[line], position)

	*deletions = deletionsMap
}

// Check if a pixel can be drawn at a certain location
func CanPixelBePlaced(position PixelPosition) bool {
	for _, line := range lines {
		for _, point := range line.Points {

			// If the pixels are on the same location, can't be placed
			if point.X == position.X && point.Y == position.Y {
				return false
			}
		}
	}
	return true
}

// Draw a pixel as a line
func DrawPixel(id string, direction int, position PixelPosition) error {
	linesMutex.Lock()
	defer linesMutex.Unlock()

	if !CanPixelBePlaced(position) {
		return errors.New("pixel can't be placed here")
	}

	// Start a new line
	line := &Line{
		CustomId:  util.RandomString(10),
		Id:        id,
		Finished:  true,
		Direction: direction,
		Points:    []*PixelPosition{&position},
	}
	lines = append(lines, line)

	return nil
}

//* Line drawing

// Start drawing a new line (also performs checks)
func StartLine(player *Player, direction int, position PixelPosition) error {
	linesMutex.Lock()
	defer linesMutex.Unlock()

	// Check if the position is valid
	if !CanPixelBePlaced(position) {
		return errors.New("pixel can't be placed")
	}

	// Consume the mana
	AddMana(player, -5)

	// Start a new line
	line := &Line{
		CustomId:  util.RandomString(10),
		Id:        player.Id,
		Finished:  false,
		Direction: direction,
		Points:    []*PixelPosition{&position},
	}
	lines = append(lines, line)

	return nil
}

// Add a point to a line (also performs checks on the position)
func AddPointToLine(player *Player, position PixelPosition) error {
	linesMutex.Lock()
	defer linesMutex.Unlock()

	// Check if the position is valid
	if !CanPixelBePlaced(position) {
		return errors.New("pixel can't be placed")
	}

	// Get the index of the line in the lines slice
	lineIndex := slices.IndexFunc(lines, func(line *Line) bool {
		return line.Id == player.Id && !line.Finished
	})
	if lineIndex == -1 {
		return errors.New("line doesn't exist")
	}

	// Consume the mana
	AddMana(player, -1)

	// Add the point to the line
	line := lines[lineIndex]
	line.Points = append(line.Points, &position)

	return nil
}

// Finish drawing a line (also performs checks (only exists check))
func EndLine(player *Player) bool {
	linesMutex.Lock()
	defer linesMutex.Unlock()

	// Get the index of the line in the lines slice
	lineIndex := slices.IndexFunc(lines, func(line *Line) bool {
		return line.Id == player.Id && !line.Finished
	})
	if lineIndex == -1 {
		return false
	}

	// Mark the line as finished
	lines[lineIndex].Finished = true
	player.SendAction(LineFinishedAction())
	return true
}

// Cancel a line during drawing
func CancelLine(player *Player) bool {
	linesMutex.Lock()
	defer linesMutex.Unlock()

	// Get the index of the line in the lines slice
	lineIndex := slices.IndexFunc(lines, func(line *Line) bool {
		return line.Id == player.Id && !line.Finished
	})
	if lineIndex == -1 {
		return false
	}

	// Delete the line
	lines = slices.DeleteFunc(lines, func(l *Line) bool {
		return l.Id == player.Id && !l.Finished
	})
	player.SendAction(LineFailedAction())
	return true
}
