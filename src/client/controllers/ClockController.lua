local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ClockBootstrap = require(script.Parent.Parent.ui.ClockBootstrap)

local RESYNC_INTERVAL = 30

local ClockController = Knit.CreateController({
	Name = "ClockController",
})

function ClockController:KnitInit()
end

function ClockController:KnitStart()
	local timeEngineService = Knit.GetService("TimeEngineService")

	local function sync()
		return timeEngineService:GetTime():await()
	end

	local result = sync()
	if not result then
		warn("[ClockSystem] ClockController: Failed to sync time")
		return
	end

	local syncedGameTime = result.time
	local syncClientTime = os.clock()
	local timeScale = result.timeScale
	local dayLength = result.dayLength or (24 * 60)

	local function getTime()
		local elapsed = os.clock() - syncClientTime
		local time = syncedGameTime + elapsed * timeScale
		return time % dayLength
	end

	local bootstrap = ClockBootstrap.new(getTime)
	bootstrap:start()

	task.spawn(function()
		while true do
			task.wait(RESYNC_INTERVAL)
			local res = sync()
			if res then
				syncedGameTime = res.time
				syncClientTime = os.clock()
				timeScale = res.timeScale
				dayLength = res.dayLength or (24 * 60)
			end
		end
	end)
end

return ClockController
