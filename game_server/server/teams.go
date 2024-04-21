package wsserver

import (
	"errors"

	bridge "github.com/Unbreathable/a-pixel-game/gameserver/bridge"
	"github.com/Unbreathable/a-pixel-game/gameserver/game"
)

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
