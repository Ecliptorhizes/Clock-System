local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local root = script.Parent
local Promise = require(ReplicatedStorage.Packages.Promise)

local TimeEngine = require(root.server.TimeEngine)
local ClientTimeSync = require(root.client.ClientTimeSync)
local ClockBootstrap = require(root.client.ui.ClockBootstrap)
local RemoteBridge = require(root.shared.Core.RemoteBridge)

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
	AnalogClock = require(root.client.ui.AnalogClock),
	AnalogClock3D = require(root.client.ui.AnalogClock3D),
	DigitalClock = require(root.client.ui.DigitalClock),
	ClockBootstrap = ClockBootstrap,
	shared = require(root.shared.util.shared),
	KnitServices = root.server:FindFirstChild("services"),
	KnitControllers = root.client:FindFirstChild("controllers"),
	startServer = startServer,
	startClient = startClient,
}
