package main

import (
	"fmt"

	"github.com/Unbreathable/a-pixel-game/gameserver/bridge"
	"github.com/Unbreathable/a-pixel-game/gameserver/game"
	wsserver "github.com/Unbreathable/a-pixel-game/gameserver/server"
)

func main() {
	fmt.Println("Starting server..")

	// Initialize server
	wsserver.RegisterHandlers()

	// Initialize game
	bridge.Init()
	game.StartLobbyState()

	wsserver.StartServer()
}
