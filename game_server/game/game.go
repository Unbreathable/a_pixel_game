package game

import (
	"log"
	"sync"
	"time"

	"github.com/Unbreathable/a-pixel-game/gameserver/bridge"
)

// Config
const ticksPerSecond = 50

var stateMutex = &sync.Mutex{}
var currentState uint = 0
var currentStateData interface{}

const (
	GameStateLobby  uint = 0
	GameStateIngame uint = 1
	GameStateEnd    uint = 2
)

// Call a new game state
func NewGameState(id uint, data interface{}, runner func()) {

	// Lock the mutex for access
	stateMutex.Lock()
	defer stateMutex.Unlock()

	// change the current state and send an action
	currentState = id
	currentStateData = data
	bridge.SendGlobalAction(bridge.NewGameStateAction(id, data))

	// Run the state runner in a goroutine every ticksPerSecond
	go func(id uint, runner func()) {
		lastDuration := 0 * time.Millisecond
		for {
			time.Sleep(time.Millisecond*(1000/ticksPerSecond) - lastDuration) // We should update this to a proper ticker, but for now this one is probably fine
			stateMutex.Lock()

			current := time.Now()
			if id != currentState {
				log.Println("different state")
				stateMutex.Unlock()
				break
			}
			stateMutex.Unlock()

			runner()

			lastDuration = time.Since(current)
		}
	}(id, runner)
}

// Update the game state data
func UpdateGameState(data interface{}) {

	// Lock the mutex for access
	stateMutex.Lock()
	defer stateMutex.Unlock()

	// Set the new game state
	currentStateData = data
	bridge.SendGlobalAction(bridge.GameStateUpdateAction(currentState, data))
}

func GetCurrentState() uint {
	stateMutex.Lock()
	defer stateMutex.Unlock()

	return currentState
}

func GetCurrentStateData() interface{} {
	stateMutex.Lock()
	defer stateMutex.Unlock()

	return currentStateData
}
