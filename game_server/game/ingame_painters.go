package game

import (
	"log"
	"time"

	"github.com/Unbreathable/a-pixel-game/gameserver/bridge"
)

// Config
const startHealth = 100
const maxMoveSpeed = 12

type IngameStateData struct {
	Start int64 `json:"start"` // Start (unix timestamp)

	BlueHealth int64 `json:"blue"`
	RedHealth  int64 `json:"red"`
}

func StartPaintersIngameState() {
	paintersCurrentMoveSpeed = maxMoveSpeed
	paintersTicks = 0
	bridge.ClearCanvas()
	bridge.ResetMana()

	// Get the current mana speed
	manaSpeed, ok := bridge.GetSetting(bridge.SettingManaRegen)
	if !ok {
		panic("mana speed setting not found")
	}

	// Set the mana multipliers
	log.Println("getting sizes")
	blueSize := bridge.GetTeamSize(bridge.TeamBlue)
	log.Println("red")
	redSize := bridge.GetTeamSize(bridge.TeamRed)

	log.Println("hello world")
	if manaSpeed == 4 /* (Unlimited) */ {
		bridge.SetTeamManaMultiplier(bridge.TeamBlue, 0)
		bridge.SetTeamManaMultiplier(bridge.TeamRed, 0)
	} else if blueSize > redSize && redSize != 0 {
		multiplier := float64(blueSize) / float64(redSize)
		bridge.SetTeamManaMultiplier(bridge.TeamBlue, multiplier)
	} else if redSize > blueSize && blueSize != 0 {
		multiplier := float64(redSize) / float64(blueSize)
		bridge.SetTeamManaMultiplier(bridge.TeamRed, multiplier)
	}

	NewGameState(GameStateIngame, IngameStateData{
		Start:      time.Now().UnixMilli(),
		BlueHealth: startHealth,
		RedHealth:  startHealth,
	}, paintersIngameTick)

}

var paintersCurrentMoveSpeed = maxMoveSpeed
var paintersTickCounter = 0
var paintersTicks = 0

func paintersIngameTick() {
	log.Println("tick")
	blueTeam, _ := bridge.GetTeam(bridge.TeamBlue)
	redTeam, _ := bridge.GetTeam(bridge.TeamRed)
	spectatorTeam, _ := bridge.GetTeam(bridge.TeamSpectator)
	currentState := GetCurrentStateData().(IngameStateData)

	// Lock all the mutexes
	action := "ingame state"
	blueTeam.LockMutex(action)
	redTeam.LockMutex(action)
	spectatorTeam.LockMutex(action)
	defer func() {
		blueTeam.UnlockMutex(action)
		redTeam.UnlockMutex(action)
		spectatorTeam.UnlockMutex(action)
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
	paintersTicks++
	move := false
	paintersTickCounter += 1
	if paintersTickCounter > paintersCurrentMoveSpeed {
		move = true
		paintersTickCounter = 0
	}

	// If 6 seconds are over, increase the speed
	if paintersTicks > 50*3 {
		paintersTicks = 0
		paintersCurrentMoveSpeed--

		// Get the mode setting
		modeSetting, ok := bridge.GetSetting(bridge.SettingGameSpeed)
		if !ok {
			panic("game speed setting not found")
		}

		// Set the minimum amount based on the mode
		minAmount := 8
		switch modeSetting {
		case 0: // Slow af
			minAmount = 10
		case 1: // Vanilla
			minAmount = 8
		case 2: // Fast
			minAmount = 5
		case 3: // Overdrive
			minAmount = 3
		}

		if paintersCurrentMoveSpeed < minAmount {
			paintersCurrentMoveSpeed = minAmount
		}
	}

	// Get the current mana speed
	manaSpeed, ok := bridge.GetSetting(bridge.SettingManaRegen)
	if !ok {
		panic("mana speed setting not found")
	}

	// Calculate mana speed
	manaTicks := 10
	manaAmount := float64(1)
	switch manaSpeed {
	case 0: // Slow af
		manaTicks = 20
		manaAmount = 1
	case 1: // Vanilla
		manaTicks = 10
		manaAmount = 1
	case 2: // Fast
		manaTicks = 10
		manaAmount = 2
	case 3: // Overdrive
		manaTicks = 5
		manaAmount = 4
	case 4: // Unlimited (doesn't really matter tbh)
		manaTicks = 10
		manaAmount = 1
	}

	// Add mana based on the settings
	if paintersTicks%manaTicks == 0 {
		bridge.ManaTick(manaAmount)
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
