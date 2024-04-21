package wsserver

import (
	"errors"

	"github.com/Unbreathable/a-pixel-game/gameserver/bridge"
	"github.com/Unbreathable/a-pixel-game/gameserver/game"
)

// Config
const drawingAreaBlueStart = 2
const drawingAreaBlueEnd = 11
const drawingAreaRedStart = 22
const drawingAreaRedEnd = 31

func startLine(ctx *Context) error {

	if game.GetCurrentState() != game.GameStateIngame {
		return errors.New("can't join team during ingame or end phase")
	}

	// Grab variables
	x := uint(ctx.Data["x"].(float64))
	y := uint(ctx.Data["y"].(float64))

	// Lock the player mutex
	ctx.Player.Mutex.Lock()
	defer ctx.Player.Mutex.Unlock()

	// Check if there is enough mana
	if bridge.GetMana(ctx.Player) <= 2 {
		bridge.EndLine(ctx.Player)
		return errors.New("not enough mana")
	}

	// Check if line positions is valid for team
	if err := validatePosition(x, y, ctx.Player.Team); err != nil {
		bridge.EndLine(ctx.Player)
		return err
	}

	// Start line
	direction := -1
	if ctx.Player.Team == bridge.TeamBlue {
		direction = 1
	}
	result := bridge.StartLine(ctx.Player, direction, bridge.PixelPosition{
		X: x,
		Y: y,
	})
	if !result {
		bridge.EndLine(ctx.Player)
		return errors.New("couldn't create line")
	}

	return nil
}

func addToLine(ctx *Context) error {

	if game.GetCurrentState() != game.GameStateIngame {
		return errors.New("can't join team during ingame or end phase")
	}

	// Grab variables
	x := uint(ctx.Data["x"].(float64))
	y := uint(ctx.Data["y"].(float64))

	if bridge.GetMana(ctx.Player) <= 1 {
		bridge.EndLine(ctx.Player)
		return errors.New("not enough mana")
	}

	// Lock the player mutex
	ctx.Player.Mutex.Lock()
	defer ctx.Player.Mutex.Unlock()

	// Check if line positions is valid for team
	if err := validatePosition(x, y, ctx.Player.Team); err != nil {
		bridge.EndLine(ctx.Player)
		return err
	}

	// Add position to line
	if !bridge.AddPointToLine(ctx.Player, bridge.PixelPosition{X: x, Y: y}) {
		bridge.EndLine(ctx.Player)
		return errors.New("couldn't add position to line")
	}
	return nil
}

func endLine(ctx *Context) error {

	if game.GetCurrentState() != game.GameStateIngame {
		return errors.New("can't join team during ingame or end phase")
	}

	// End the line
	if !bridge.EndLine(ctx.Player) {
		bridge.CancelLine(ctx.Player)
		return errors.New("couldn't end line")
	}
	return nil
}

// Check if line position is valid for team
func validatePosition(x uint, y uint, team uint) error {
	if team == bridge.TeamSpectator {
		return errors.New("spectators can't draw")
	}

	if y > 16 || y == 0 {
		return errors.New("line out of bounds (y)")
	}

	if team == bridge.TeamBlue && (x < drawingAreaBlueStart || x > drawingAreaBlueEnd) {
		return errors.New("line out of bounds (x, blue)")
	}

	if team == bridge.TeamRed && (x < drawingAreaRedStart || x > drawingAreaRedEnd) {
		return errors.New("line out of bounds (x, red)")
	}

	return nil
}
