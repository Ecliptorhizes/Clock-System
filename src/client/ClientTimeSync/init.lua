local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Promise = require(ReplicatedStorage.Packages.Promise)

local pkgRoot = script.Parent.Parent
local RemoteBridge = require(pkgRoot.shared.Core.RemoteBridge)

local RESYNC_INTERVAL = 30

local ClientTimeSync = {}
ClientTimeSync.__index = ClientTimeSync

function ClientTimeSync.new()
	local self = setmetatable({}, ClientTimeSync)

	self._janitor = Janitor.new()
	self._synced = false
	self._syncedGameTime = 0
	self._syncClientTime = 0
	self._timeScale = 1
	self._dayLength = 24 * 60
	self._bridge = nil

	return self
end

function ClientTimeSync:start(remoteBridge: RemoteBridge?): Promise.Promise
	self._bridge = remoteBridge or RemoteBridge.new(nil)

	return Promise.new(function(resolve, reject)
		local function doSync()
			local clientSendTime = os.clock()
			local result = self._bridge:requestServerTime()
			if result == nil then
				reject("Failed to get server time")
				return
			end
			local clientReceiveTime = os.clock()
			local rtt = clientReceiveTime - clientSendTime
			local serverTimeNow = result.time + (rtt / 2) * result.timeScale
			self._syncedGameTime = serverTimeNow
			self._syncClientTime = clientReceiveTime
			self._timeScale = result.timeScale
			self._dayLength = result.dayLength or (24 * 60)
			self._synced = true
			resolve()
		end

		doSync()

		if self._bridge then
			task.spawn(function()
				while true do
					task.wait(RESYNC_INTERVAL)
					if not self._bridge then
						break
					end
					doSync()
				end
			end)
		end
	end)
end

function ClientTimeSync:getSyncedTime(): number?
	if not self._synced then
		return nil
	end
	local elapsed = os.clock() - self._syncClientTime
	local time = self._syncedGameTime + elapsed * self._timeScale
	return time % self._dayLength
end

function ClientTimeSync:isSynced(): boolean
	return self._synced
end

function ClientTimeSync:destroy()
	self._janitor:Cleanup()
end

local _instance = nil

return {
	new = ClientTimeSync.new,
	getInstance = function()
		if not _instance then
			_instance = ClientTimeSync.new()
		end
		return _instance
	end,
}
