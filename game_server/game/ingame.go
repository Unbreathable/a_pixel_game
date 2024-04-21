package game

import (
	"log"
	"time"

	"github.com/Unbreathable/a-pixel-game/gameserver/bridge"
)

// Config
const startHealth = 100
const maxMoveSpeed = 12
const minMoveSpeed = 8

type IngameStateData struct {
	Start int64 `json:"start"` // Start (unix timestamp)

	BlueHealth int64 `json:"blue"`
	RedHealth  int64 `json:"red"`
}

func StartIngameState() {
	currentMoveSpeed = maxMoveSpeed
	ticks = 0
	bridge.ClearCanvas()
	bridge.ResetMana()
	NewGameState(GameStateIngame, IngameStateData{
		Start:      time.Now().UnixMilli(),
		BlueHealth: startHealth,
		RedHealth:  startHealth,
	}, ingameTick)
}

var currentMoveSpeed = maxMoveSpeed
var tickCounter = 0
var ticks = 0

func ingameTick() {
	blueTeam, _ := bridge.GetTeam(bridge.TeamBlue)
	redTeam, _ := bridge.GetTeam(bridge.TeamRed)
	spectatorTeam, _ := bridge.GetTeam(bridge.TeamSpectator)
	currentState := GetCurrentStateData().(IngameStateData)

	// Lock all the mutexes
	blueTeam.Mutex.Lock()
	redTeam.Mutex.Lock()
	spectatorTeam.Mutex.Lock()
	defer func() {
		blueTeam.Mutex.Unlock()
		redTeam.Mutex.Unlock()
		spectatorTeam.Mutex.Unlock()
	}()

	// Check if the teams are empty (and go to end state, cause no players anymore)
	if len(blueTeam.Players) == 0 || len(redTeam.Players) == 0 {
		if len(blueTeam.Players) == 0 {
			StartEndState(bridge.TeamRed)
		}
		if len(redTeam.Players) == 0 {
			StartEndState(bridge.TeamBlue)
		}
		return
	}

	// Calculate if it should move or not
	ticks++
	move := false
	tickCounter += 1
	if tickCounter > currentMoveSpeed {
		move = true
		tickCounter = 0
	}

	// If 3 seconds are over, increase the speed
	if ticks > 50*3 {
		ticks = 0
		log.Println("SPEED INCREASE")
		currentMoveSpeed--
		if currentMoveSpeed < minMoveSpeed {
			currentMoveSpeed = minMoveSpeed
		}
	}

	// Add new mana every 200ms
	if ticks%10 == 0 {
		bridge.ManaTick()
	}

	// Send a new frame to all users
	frame, blue, red := bridge.ConstructFrame(move)
	bridge.SendGlobalAction(bridge.GameFrameAction(frame))

	// Get everything that's in a goal and potentially decrease health
	if move {
		currentState.BlueHealth -= red
		currentState.RedHealth -= blue
		UpdateGameState(currentState)

		if currentState.BlueHealth <= 0 {
			StartEndState(bridge.TeamRed)
		}

		if currentState.RedHealth <= 0 {
			StartEndState(bridge.TeamBlue)
		}
	}
}
