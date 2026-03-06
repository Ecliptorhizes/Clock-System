-- Re-exports time utilities for backward compatibility
local time = require(script.Parent.time)
return {
	secondsToTimeOfDay = time.secondsToTimeOfDay,
	formatTime = time.formatTime,
	timeToAngles = time.timeToAngles,
}
