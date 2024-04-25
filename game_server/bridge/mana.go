package bridge

import (
	"sync"
)

// Config
const maxMana float64 = 20

// Player ID -> Amount of mana (float64)
var manaMap sync.Map = sync.Map{}

func ResetMana() {
	manaMap = sync.Map{}
}

// Called every mana tick to add mana to players who don't have max
func ManaTick(manaAmount float64) {
	manaMap.Range(func(key, value any) bool {
		player, ok := GetPlayer(key.(string))
		if !ok {
			return true
		}
		AddMana(player, manaAmount)
		return true
	})
}

// Get the current mana of a player
func GetMana(player *Player) float64 {
	obj, ok := manaMap.Load(player.Id)
	currentMana := float64(0)
	if !ok {
		manaMap.Store(player.Id, maxMana)
		currentMana = maxMana
	} else {
		currentMana = obj.(float64)
	}
	return currentMana
}

// Add (or remove) mana from a player
func AddMana(player *Player, toAdd float64) {
	toAdd = toAdd * player.ManaMultiplier
	obj, ok := manaMap.Load(player.Id)
	currentMana := float64(0)
	if !ok {
		manaMap.Store(player.Id, maxMana)
		currentMana = maxMana
	} else {
		currentMana = obj.(float64)
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
