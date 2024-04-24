package bridge

import (
	"log"
	"sync"
)

// Constants
const SettingMode = "mode"
const SettingGameSpeed = "mode.speed"
const SettingManaRegen = "mana.speed"

type Setting struct {
	Mutex *sync.Mutex
	Name  string
	Value int
}

// Setting name -> *Setting
var settingsMap sync.Map = sync.Map{}

func registerSettings() {
	//* Add mode setting
	// 0 - Painters
	// 1 - Bouncers
	// 2 - Party
	storeSetting(SettingMode, 0)

	//* Add game speed setting
	// 0 - Slow af
	// 1 - Vanilla
	// 2 - Fast
	// 3 - Overdrive (really fucking fast)
	storeSetting(SettingGameSpeed, 1)

	//* Add mana regeneration speed setting
	// 0 - Slow af
	// 1 - Vanilla
	// 2 - Fast
	// 3 - Overdrive (really fucking fast)
	storeSetting(SettingManaRegen, 1)
}

// Register a new setting
func storeSetting(name string, defaultValue int) {
	settingsMap.Store(name, &Setting{
		Mutex: &sync.Mutex{},
		Name:  name,
		Value: defaultValue,
	})
}

// Change the value of a setting
func SetSetting(name string, value int) bool {
	obj, ok := settingsMap.Load(name)
	if !ok {
		return false
	}
	setting := obj.(*Setting)

	setting.Mutex.Lock()
	defer setting.Mutex.Unlock()

	setting.Value = value
	SendGlobalAction(SettingValueAction(name, value))
	log.Println("changed", name, "to", value)
	return true
}

// Get the value of a setting
func GetSetting(name string) (int, bool) {
	obj, ok := settingsMap.Load(name)
	if !ok {
		return 0, false
	}
	setting := obj.(*Setting)

	setting.Mutex.Lock()
	defer setting.Mutex.Unlock()

	return setting.Value, true
}
