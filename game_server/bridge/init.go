package bridge

// Initializes all components of the bridge
// -> this is kept here so we can easily add to it without adding bloat to the main function
func Init() {
	initTeam()
	registerSettings()
}
