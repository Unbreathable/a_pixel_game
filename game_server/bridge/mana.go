package bridge

import (
	"sync"
)

// Config
const maxMana = 20
const regenPerMove = 1

// Player ID -> Amount of mana
var manaMap sync.Map = sync.Map{}

func ResetMana() {
	manaMap = sync.Map{}
}

// Called every mana tick to add mana to players who don't have max
func ManaTick() {
	manaMap.Range(func(key, value any) bool {
		player, ok := GetPlayer(key.(string))
		if !ok {
			return true
		}
		AddMana(player, regenPerMove)
		return true
	})
}

// Get the current mana of a player
func GetMana(player *Player) int {
	obj, ok := manaMap.Load(player.Id)
	currentMana := 0
	if !ok {
		manaMap.Store(player.Id, maxMana)
		currentMana = maxMana
	} else {
		currentMana = obj.(int)
	}
	return currentMana
}

// Add (or remove) mana from a player
func AddMana(player *Player, toAdd int) {
	obj, ok := manaMap.Load(player.Id)
	currentMana := 0
	if !ok {
		manaMap.Store(player.Id, maxMana)
		currentMana = maxMana
	} else {
		currentMana = obj.(int)
	}

	// Clamp the new amount to the max and min
	newAmount := currentMana + toAdd
	if newAmount > maxMana {
		newAmount = maxMana
	} else if newAmount < 0 {
		newAmount = 0
	}
	manaMap.Store(player.Id, newAmount)

	if newAmount != currentMana {
		player.SendAction(ManaUpdateAction(newAmount))
	}
}
