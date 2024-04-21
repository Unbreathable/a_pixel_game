package bridge

import "log"

//* Action sending logic

// Send an action to the player
func (player *Player) SendAction(action Action) error {
	player.ConnMutex.Lock()
	defer player.ConnMutex.Unlock()

	return player.Connection.WriteJSON(action)
}

// Send an action to all players in the server
func SendGlobalAction(action Action) {
	playersMap.Range(func(key, value any) bool {
		player := value.(*Player)

		err := player.SendAction(action)
		if err != nil {
			log.Println("error while sending action to player", player.Username, err)
		}
		return true
	})
}

//* Actual actions

// Used for server/client communication
type Action struct {
	Name string                 `json:"n"`
	Data map[string]interface{} `json:"d"`
}

func SetupAction(id string, username string, gameState uint, gameStateData interface{}) Action {
	return Action{
		Name: "setup",
		Data: map[string]interface{}{
			"id":    id,
			"name":  username,
			"state": gameState,
			"data":  gameStateData,
		},
	}
}

func PlayerLeaveAction(id string) Action {
	return Action{
		Name: "player_leave",
		Data: map[string]interface{}{
			"id": id,
		},
	}
}

func PlayerJoinAction(id string, username string) Action {
	return Action{
		Name: "player_join",
		Data: map[string]interface{}{
			"id":   id,
			"name": username,
		},
	}
}

func PlayerChangeAction(id string, username string) Action {
	return Action{
		Name: "player_change",
		Data: map[string]interface{}{
			"id":   id,
			"name": username,
		},
	}
}

func PlayerTeamAction(id string, team uint) Action {
	return Action{
		Name: "player_team",
		Data: map[string]interface{}{
			"id":   id,
			"team": team,
		},
	}
}

func NewGameStateAction(id uint, data interface{}) Action {
	return Action{
		Name: "game_new",
		Data: map[string]interface{}{
			"state": id,
			"data":  data,
		},
	}
}

func GameStateUpdateAction(id uint, data interface{}) Action {
	return Action{
		Name: "game_update",
		Data: map[string]interface{}{
			"state": id,
			"data":  data,
		},
	}
}

func GameFrameAction(frame Frame) Action {
	return Action{
		Name: "game_frame",
		Data: map[string]interface{}{
			"frame": frame,
		},
	}
}

func LineFailedAction() Action {
	return Action{
		Name: "line_failed",
		Data: map[string]interface{}{},
	}
}

func LineFinishedAction() Action {
	return Action{
		Name: "line_finished",
		Data: map[string]interface{}{},
	}
}

func ManaUpdateAction(newAmount int) Action {
	return Action{
		Name: "mana_update",
		Data: map[string]interface{}{
			"mana": newAmount,
		},
	}
}
