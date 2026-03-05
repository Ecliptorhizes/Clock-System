local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local root = script
local Promise = require(ReplicatedStorage.Packages.Promise)

local TimeEngine = require(root.TimeEngine)
local ClientTimeSync = require(root.ClientTimeSync)
local ClockBootstrap = require(root.Clocks.ClockBootstrap)
local RemoteBridge = require(root.Internal.RemoteBridge)

local _serverStarted = false
local _clientStarted = false

local function startServer(config)
	if not RunService:IsServer() then
		warn("[ClockSystem] startServer must be called on server")
		return
	end
	if _serverStarted then
		return
	end
	_serverStarted = true

	TimeEngine.start(config or {})

	RemoteBridge.new(function()
		return {
			time = TimeEngine.getTime(),
			timeScale = TimeEngine.getTimeScale(),
			dayLength = TimeEngine.getDayLength(),
		}
	end)
end

local function startClient()
	if RunService:IsServer() then
		warn("[ClockSystem] startClient must be called on client")
		return Promise.resolve()
	end
	if _clientStarted then
		return Promise.resolve()
	end

	local sync = ClientTimeSync.getInstance()
	local bridge = RemoteBridge.new(nil)
	local promise = sync:start(bridge)

	promise:andThen(function()
		_clientStarted = true
		local bootstrap = ClockBootstrap.new(function()
			return sync:getSyncedTime() or 0
		end)
		bootstrap:start()
	end)

	return promise
end

return {
	TimeEngine = TimeEngine,
	ClientTimeSync = ClientTimeSync,
	AnalogClock = require(root.Clocks.AnalogClock),
	DigitalClock = require(root.Clocks.DigitalClock),
	ClockBootstrap = ClockBootstrap,
	shared = require(root.Clocks.shared),
	startServer = startServer,
	startClient = startClient,
}
