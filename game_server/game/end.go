package game

import (
	"time"
)

// Config
const endCountdown = 15

type EndStateData struct {
	WinnerTeam   uint  `json:"team"`  // Id of the winner team
	CountdownEnd int64 `json:"count"` // Unix timestamp for countdown end
}

func StartEndState(winner uint) {
	NewGameState(GameStateEnd, EndStateData{
		WinnerTeam:   winner,
		CountdownEnd: time.Now().Add(time.Second * endCountdown).UnixMilli(),
	}, endTick)
}

func endTick() {
	currentState := GetCurrentStateData().(EndStateData)

	if time.Now().After(time.UnixMilli(currentState.CountdownEnd)) {
		StartLobbyState()
	}
}
