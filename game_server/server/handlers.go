package wsserver

import (
	"log"

	"github.com/Unbreathable/a-pixel-game/gameserver/bridge"
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
}
