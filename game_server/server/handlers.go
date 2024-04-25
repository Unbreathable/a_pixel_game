package wsserver

import (
	"errors"
	"log"

	"github.com/Unbreathable/a-pixel-game/gameserver/bridge"
	"github.com/Unbreathable/a-pixel-game/gameserver/game"
	"github.com/Unbreathable/a-pixel-game/gameserver/util"
)

type Context struct {
	Player *bridge.Player
	Data   map[string]interface{}
}

var handlers map[string]func(*Context) error

// Execute an action
func execute(action string, ctx *Context) {
	defer func() {
		if err := recover(); err != nil {
			log.Println("error with executing action:", err)
		}
	}()

	if handlers[action] == nil {
		return
	}

	if err := handlers[action](ctx); err != nil {
		log.Println("error on", action, ":", err)
	}
}

// Register all the handlers required for the game
func RegisterHandlers() {
	handlers = make(map[string]func(*Context) error)

	handlers["team_join"] = teamJoin
	handlers["change"] = changeUsername
	handlers["start_line"] = startLine
	handlers["line_add"] = addToLine
	handlers["end_line"] = endLine
	handlers["update_setting"] = updateSetting
}

// Action: update_setting
func updateSetting(ctx *Context) error {

	if game.GetCurrentState() != game.GameStateLobby {
		return errors.New("can't change setting value during game")
	}

	// Extract variables
	name := ctx.Data["id"].(string)
	value := int(ctx.Data["value"].(float64))

	if !bridge.SetSetting(name, value) {
		return errors.New("unsupported setting: " + name)
	}
	return nil
}

// Action: team_join
func teamJoin(ctx *Context) error {

	if game.GetCurrentState() != game.GameStateLobby {
		return errors.New("can't join team during ingame or end phase")
	}

	// Extract all variables
	team := uint(ctx.Data["team"].(float64))
	if team > 2 {
		return errors.New("team is invalid")
	}

	if bridge.GetTeamSize(team) >= 4 && team != bridge.TeamSpectator {
		return errors.New("team too big")
	}

	bridge.JoinTeam(ctx.Player.Id, team)
	return nil
}

// Action: change
func changeUsername(ctx *Context) error {

	if game.GetCurrentState() != game.GameStateLobby {
		return errors.New("can't join team during ingame or end phase")
	}

	// Change username
	name := ctx.Data["name"].(string)
	bridge.SetUsername(ctx.Player.Id, name)
	return nil
}

func startLine(ctx *Context) error {

	if !game.IsIngame() {
		return errors.New("can't start line in lobby or end phase")
	}

	// Grab variables
	x, err := util.ParseUIntFromMap(ctx.Data, "x")
	if err != nil {
		return errors.New("couldn't parse x")
	}
	y, err := util.ParseUIntFromMap(ctx.Data, "y")
	if err != nil {
		return errors.New("couldn't parse y")
	}

	// Lock the player mutex
	ctx.Player.Mutex.Lock()
	defer ctx.Player.Mutex.Unlock()

	// Check if there is enough mana
	if bridge.GetMana(ctx.Player) <= 1 {
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
	err = bridge.StartLine(ctx.Player, direction, bridge.PixelPosition{
		X: x,
		Y: y,
	})
	if err != nil {
		bridge.EndLine(ctx.Player)
		return errors.New("couldn't create line: " + err.Error())
	}

	return nil
}

func addToLine(ctx *Context) error {

	if !game.IsIngame() {
		return errors.New("can't add to line in lobby or end phase")
	}

	// Grab variables
	x, err := util.ParseUIntFromMap(ctx.Data, "x")
	if err != nil {
		return errors.New("couldn't parse x")
	}
	y, err := util.ParseUIntFromMap(ctx.Data, "y")
	if err != nil {
		return errors.New("couldn't parse y")
	}

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
	if err := bridge.AddPointToLine(ctx.Player, bridge.PixelPosition{X: x, Y: y}); err != nil {
		bridge.EndLine(ctx.Player)
		return errors.New("couldn't add position: " + err.Error())
	}
	return nil
}

func endLine(ctx *Context) error {

	if !game.IsIngame() {
		return errors.New("can't end line in lobby or end phase")
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

	if team == bridge.TeamBlue && (x < bridge.DrawingAreaBlueStart || x > bridge.DrawingAreaBlueEnd) {
		return errors.New("line out of bounds (x, blue)")
	}

	if team == bridge.TeamRed && (x < bridge.DrawingAreaRedStart || x > bridge.DrawingAreaRedEnd) {
		return errors.New("line out of bounds (x, red)")
	}

	return nil
}
