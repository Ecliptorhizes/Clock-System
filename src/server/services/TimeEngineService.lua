local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local TimeEngine = require(script.Parent.Parent.TimeEngine)

local TimeEngineService = Knit.CreateService({
	Name = "TimeEngineService",
	Client = {},
})

function TimeEngineService.Client:GetTime(player)
	return {
		time = TimeEngine.getTime(),
		timeScale = TimeEngine.getTimeScale(),
		dayLength = TimeEngine.getDayLength(),
	}
end

function TimeEngineService:KnitInit()
end

function TimeEngineService:KnitStart()
	TimeEngine.start({
		dayLength = 24 * 60,
		timeScale = 1,
		initialTime = 0,
	})
end

return TimeEngineService
