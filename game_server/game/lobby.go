package game

import (
	"log"
	"time"

	"github.com/Unbreathable/a-pixel-game/gameserver/bridge"
)

// Config
const lobbyCountdown = 10

type LobbyStateData struct {
	Countdown    bool  `json:"started"`
	CountdownEnd int64 `json:"count"` // Unix timestamp for countdown end
}

// Start the lobby state
func StartLobbyState() {
	bridge.ResetTeams()
	NewGameState(GameStateLobby, LobbyStateData{
		Countdown:    false,
		CountdownEnd: time.Now().UnixMilli(),
	}, lobbyTick)
}

// Runs every (1000 / ticksPerSecond) few milliseconds to update the current game
func lobbyTick() {
	blueTeam, _ := bridge.GetTeam(bridge.TeamBlue)
	redTeam, _ := bridge.GetTeam(bridge.TeamRed)
	spectatorTeam, _ := bridge.GetTeam(bridge.TeamSpectator)
	currentState := GetCurrentStateData().(LobbyStateData)

	// Lock all the mutexes
	action := "lobby state"
	blueTeam.LockMutex(action)
	redTeam.LockMutex(action)
	spectatorTeam.LockMutex(action)
	defer func() {
		blueTeam.UnlockMutex(action)
		redTeam.UnlockMutex(action)
		spectatorTeam.UnlockMutex(action)
	}()

	// Check if the teams are empty
	if len(blueTeam.Players) == 0 || len(redTeam.Players) == 0 {

		// Stop the countdown
		if currentState.Countdown {
			log.Println("countdown end")
			currentState.Countdown = false
			UpdateGameState(currentState)
		}

		return
	}

	// Start the countdown
	if !currentState.Countdown {
		log.Println("starting countdown")
		currentState.Countdown = true
		currentState.CountdownEnd = time.Now().Add(time.Second * lobbyCountdown).UnixMilli()
		UpdateGameState(currentState)
	}

	if time.Now().After(time.UnixMilli(currentState.CountdownEnd)) {

		// Get the mode setting
		modeSetting, ok := bridge.GetSetting(bridge.SettingMode)
		if !ok {
			panic("game speed setting not found")
		}

		log.Println(modeSetting)
		go StartPaintersIngameState()
	}
}
