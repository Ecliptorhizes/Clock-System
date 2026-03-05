local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Packages.Janitor)

local DEFAULT_DAY_LENGTH = 24 * 60
local DEFAULT_TIME_SCALE = 1
local DEFAULT_INITIAL_TIME = 0

local state = {
	janitor = Janitor.new(),
	running = false,
	dayLength = DEFAULT_DAY_LENGTH,
	timeScale = DEFAULT_TIME_SCALE,
	time = DEFAULT_INITIAL_TIME,
	lastUpdateTime = 0,
}

local TimeChanged = Instance.new("BindableEvent")
state.janitor:Add(TimeChanged, "Destroy")

local TimeEngine = {}

function TimeEngine.start(config)
	if state.running then
		return
	end

	config = config or {}
	state.dayLength = config.dayLength or DEFAULT_DAY_LENGTH
	state.timeScale = config.timeScale or DEFAULT_TIME_SCALE
	state.time = config.initialTime or DEFAULT_INITIAL_TIME
	state.lastUpdateTime = os.clock()
	state.running = true

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not state.running then
			connection:Disconnect()
			return
		end

		local now = os.clock()
		local delta = now - state.lastUpdateTime
		state.lastUpdateTime = now

		local gameDelta = delta * state.timeScale
		state.time = (state.time + gameDelta) % state.dayLength

		TimeChanged:Fire(state.time)
	end)

	state.janitor:Add(connection)
end

function TimeEngine.stop()
	state.running = false
end

function TimeEngine.getTime(): number
	return state.time
end

function TimeEngine.getTimeOfDay(): { hours: number, minutes: number, seconds: number }
	local totalSeconds = state.time
	local hours = math.floor(totalSeconds / 3600)
	local remainder = totalSeconds % 3600
	local minutes = math.floor(remainder / 60)
	local seconds = remainder % 60

	return {
		hours = hours,
		minutes = minutes,
		seconds = seconds,
	}
end

function TimeEngine.setTimeScale(scale: number)
	state.timeScale = scale
end

function TimeEngine.setDayLength(seconds: number)
	state.dayLength = seconds
end

function TimeEngine.getTimeScale(): number
	return state.timeScale
end

function TimeEngine.getDayLength(): number
	return state.dayLength
end

TimeEngine.TimeChanged = TimeChanged

return TimeEngine
