package wsserver

import (
	"encoding/json"
	"log"

	"github.com/Unbreathable/a-pixel-game/gameserver/bridge"
	"github.com/Unbreathable/a-pixel-game/gameserver/game"
	"github.com/gofiber/contrib/websocket"
	"github.com/gofiber/fiber/v2"
)

type Action struct {
	Name string                 `json:"n"`
	Data map[string]interface{} `json:"d"`
}

func StartServer() {
	app := fiber.New()

	app.Use("/", func(c *fiber.Ctx) error {
		// IsWebSocketUpgrade returns true if the client
		// requested upgrade to the WebSocket protocol.
		if websocket.IsWebSocketUpgrade(c) {
			c.Locals("allowed", true)
			return c.Next()
		}
		return fiber.ErrUpgradeRequired
	})

	app.Get("/", websocket.New(func(c *websocket.Conn) {

		// Load the player
		log.Println("Player connected, generating data..")
		player := bridge.NewPlayer(c, game.GetCurrentState(), game.GetCurrentStateData())

		// Add disconnection handler
		defer func() {
			if err := recover(); err != nil {
				log.Println("error with connection:", err)
			}
			log.Println(player.Username, "disconnected")
			bridge.PlayerDisconnect(player)
		}()

		// Start listening to messages
		var (
			mt  int
			msg []byte
			err error
		)
		for {
			if mt, msg, err = c.ReadMessage(); err != nil {
				log.Println("read:", err)
				break
			}

			// Don't read as a json if it's not a text message
			if mt != websocket.TextMessage {
				log.Println("no text message")
				continue
			}

			// Parse the action
			var action Action
			if err := json.Unmarshal(msg, &action); err != nil {
				log.Println("couldn't parse action")
				break
			}

			// Handle the action
			log.Println("Handling action", action.Name)
			execute(action.Name, &Context{
				Player: player,
				Data:   action.Data,
			})
		}

	}))

	log.Fatal(app.Listen("localhost:54321"))
}
