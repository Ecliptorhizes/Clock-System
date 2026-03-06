local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Janitor = require(ReplicatedStorage.Packages.Janitor)

local REMOTE_NAME = "ClockSystem_TimeSync"

local RemoteBridge = {}
RemoteBridge.__index = RemoteBridge

function RemoteBridge.new(serverTimeProvider: (() -> { time: number, timeScale: number, dayLength: number })?): RemoteBridge
	local self = setmetatable({}, RemoteBridge)
	self._janitor = Janitor.new()
	self._serverTimeProvider = serverTimeProvider

	if RunService:IsServer() then
		if serverTimeProvider then
			self:_createServerRemotes()
		else
			warn("[ClockSystem] RemoteBridge: serverTimeProvider required on server")
		end
	else
		self:_createClientRemotes()
	end

	return self
end

function RemoteBridge:_createServerRemotes()
	local folder = Instance.new("Folder")
	folder.Name = "ClockSystem"
	folder.Parent = ReplicatedStorage

	local remote = Instance.new("RemoteFunction")
	remote.Name = REMOTE_NAME
	remote.Parent = folder

	remote.OnServerInvoke = function()
		return self._serverTimeProvider()
	end

	self._janitor:Add(folder, "Destroy")
	self._janitor:Add(folder)
end

function RemoteBridge:_createClientRemotes()
	local folder = ReplicatedStorage:WaitForChild("ClockSystem", 10)
	if not folder then
		warn("[ClockSystem] RemoteBridge: Could not find ClockSystem folder in ReplicatedStorage")
		return
	end

	local remote = folder:WaitForChild(REMOTE_NAME, 10)
	if not remote then
		warn("[ClockSystem] RemoteBridge: Could not find time sync RemoteFunction")
		return
	end

	self._remote = remote
end

function RemoteBridge:requestServerTime(): { time: number, timeScale: number, dayLength: number }?
	if not self._remote then
		return nil
	end
	return self._remote:InvokeServer()
end

function RemoteBridge:destroy()
	self._janitor:Cleanup()
end

return RemoteBridge
