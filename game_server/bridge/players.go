package bridge

import (
	"log"
	"slices"
	"sync"

	"github.com/Unbreathable/a-pixel-game/gameserver/util"
	"github.com/gofiber/contrib/websocket"
)

type Team struct {
	Mutex   *sync.Mutex
	Id      uint
	Players []*Player
}

type Player struct {
	Mutex      *sync.Mutex     `json:"-"`
	ConnMutex  *sync.Mutex     `json:"-"`
	Id         string          `json:"id"`
	Username   string          `json:"name"`
	Team       uint            `json:"team"`
	Connection *websocket.Conn `json:"-"`
}

// Team IDs
const (
	TeamSpectator uint = 0
	TeamBlue      uint = 1
	TeamRed       uint = 2
	TeamNone      uint = 3
)

var teamsMap sync.Map = sync.Map{}   // Team ID -> Team struct
var playersMap sync.Map = sync.Map{} // Player ID -> Player

//* Player stuff

// Register a new player
func NewPlayer(conn *websocket.Conn, state uint, data interface{}) *Player {
	player := &Player{
		Id:         util.RandomString(8),
		Username:   "user #" + util.RandomString(5),
		Mutex:      &sync.Mutex{},
		ConnMutex:  &sync.Mutex{},
		Connection: conn,
		Team:       TeamNone,
	}
	playersMap.Store(player.Id, player)
	JoinTeam(player.Id, TeamSpectator) // Add to spectator team

	// Send player an action to setup
	player.SendAction(SetupAction(player.Id, player.Username, state, data))

	// Send a global player join action
	SendGlobalAction(PlayerJoinAction(player.Id, player.Username))

	// Send the player the current state of things
	teamsMap.Range(func(key, value any) bool {
		t := value.(*Team)

		log.Println("initializing for team", t.Id)

		t.Mutex.Lock()
		defer t.Mutex.Unlock()

		for _, p := range t.Players {
			log.Println(p.Id)
			if p.Id == player.Id {
				log.Println("self")
				continue
			}
			p.Mutex.Lock()

			// Initialize player for new player
			log.Println("intializing", p.Id)
			player.SendAction(PlayerJoinAction(p.Id, p.Username))
			player.SendAction(PlayerTeamAction(p.Id, p.Team))

			p.Mutex.Unlock()
		}

		return true
	})

	return player
}

// Set the username of a player
func SetUsername(id string, username string) bool {
	obj, ok := playersMap.Load(id)
	if !ok {
		return false
	}
	player := obj.(*Player)
	player.Mutex.Lock()
	defer player.Mutex.Unlock()

	// Send global action for username change
	player.Username = username
	SendGlobalAction(PlayerChangeAction(player.Id, player.Username))
	return true
}

// Get a player from the map
func GetPlayer(id string) (*Player, bool) {
	obj, ok := playersMap.Load(id)
	if !ok {
		return nil, false
	}
	return obj.(*Player), true
}

// Handle the disconnection of a player
func PlayerDisconnect(player *Player) {
	DeletePlayerTeam(player.Id, player.Team)
	playersMap.Delete(player.Id)
	player.Connection.Close()
	SendGlobalAction(PlayerLeaveAction(player.Id))
}

//* Team stuff

// Move all players to the spectator team
func ResetTeams() {
	playersMap.Range(func(key, value any) bool {
		player := value.(*Player)
		JoinTeam(player.Id, TeamSpectator)
		return true
	})
}

// Get a team from the map
func GetTeam(id uint) (*Team, bool) {
	obj, ok := teamsMap.Load(id)
	if !ok {
		return nil, false
	}
	return obj.(*Team), true
}

// Add all teams to the map
func InitTeam() {
	teamsMap.Store(TeamSpectator, &Team{
		Id:      TeamSpectator,
		Mutex:   &sync.Mutex{},
		Players: []*Player{},
	})
	teamsMap.Store(TeamBlue, &Team{
		Id:      TeamBlue,
		Mutex:   &sync.Mutex{},
		Players: []*Player{},
	})
	teamsMap.Store(TeamRed, &Team{
		Id:      TeamRed,
		Mutex:   &sync.Mutex{},
		Players: []*Player{},
	})
}

// Add a player to a team
func JoinTeam(id string, teamId uint) bool {

	// Get the team
	obj, ok := teamsMap.Load(teamId)
	if !ok {
		return false
	}
	team := obj.(*Team)

	// Lock the mutex and unlock after returning
	team.Mutex.Lock()
	defer team.Mutex.Unlock()

	// Load the player and add to team
	player, ok := GetPlayer(id)
	if !ok {
		return false
	}

	// Check if player is already in the team (prevents deadlock)
	if teamId == player.Team {
		return true
	}

	// Lock the player mutex and unlock after returning
	player.Mutex.Lock()
	defer player.Mutex.Unlock()

	team.Players = append(team.Players, player)
	DeletePlayerTeam(id, player.Team)
	player.Team = team.Id

	// Send a global event for the player changing team
	SendGlobalAction(PlayerTeamAction(player.Id, player.Team))
	return true
}

// Remove a player from a team
func DeletePlayerTeam(id string, teamId uint) bool {

	// Get the team
	obj, ok := teamsMap.Load(teamId)
	if !ok {
		return false
	}
	team := obj.(*Team)

	// Lock the mutex and unlock after returning
	team.Mutex.Lock()
	defer func() {
		log.Println("team mutex unlocked")
		team.Mutex.Unlock()
	}()

	log.Println("team mutex")

	// Load the player and add to team
	player, ok := GetPlayer(id)
	if !ok {
		return false
	}
	team.Players = slices.DeleteFunc(team.Players, func(p *Player) bool {
		return player == p
	})

	return true
}

// Stops looping if the function returns false
func IteratePlayers(fun func(player *Player) bool) {
	playersMap.Range(func(key, value any) bool {
		return fun(value.(*Player))
	})

}

// Stops looping if the function returns false
func IterateTeams(fun func(player *Team) bool) {
	teamsMap.Range(func(key, value any) bool {
		return fun(value.(*Team))
	})
}