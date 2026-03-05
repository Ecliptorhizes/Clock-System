export type TimeEngineConfig = {
	dayLength: number?,
	timeScale: number?,
	initialTime: number?,
}

export type TimeEngine = {
	start: (self: TimeEngine, config: TimeEngineConfig?) -> (),
	stop: (self: TimeEngine) -> (),
	getTime: (self: TimeEngine) -> number,
	getTimeOfDay: (self: TimeEngine) -> { hours: number, minutes: number, seconds: number },
	setTimeScale: (self: TimeEngine, scale: number) -> (),
	setDayLength: (self: TimeEngine, seconds: number) -> (),
	TimeChanged: RBXScriptSignal,
	destroy: (self: TimeEngine) -> (),
}

return {}
