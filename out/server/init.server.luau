-- Compiled with roblox-ts v3.0.0
local TS = require(game:GetService("ReplicatedStorage"):WaitForChild("TS"):WaitForChild("RuntimeLib"))
local _services = TS.import(script, game:GetService("ReplicatedStorage"), "TS", "node_modules", "@rbxts", "services")
local ReplicatedStorage = _services.ReplicatedStorage
local RunService = _services.RunService
local Workspace = _services.Workspace
-- ---------- TYPES ---------- 
-- ------- CONSTANTS ------- 
local DEFAULT_CONFIG = {
	dayLengthMinutes = 24 * 60,
	timescale = 60,
	initialMinutes = 8 * 60,
}
local REMOTE_NAME = "ClockGetSnapshot"
local CLOCK_MODEL_NAME = "Clock"
-- ------ MODULE ----- 
--[[
	*
	 * Authoritative clock service. Manages game time, exposes snapshot via RemoteFunction,
	 * and optionally drives a Clock model in Workspace (Clock.Main.CenterPivot) 
]]
local ClockServerService
do
	ClockServerService = setmetatable({}, {
		__tostring = function()
			return "ClockServerService"
		end,
	})
	ClockServerService.__index = ClockServerService
	function ClockServerService.new(...)
		local self = setmetatable({}, ClockServerService)
		return self:constructor(...) or self
	end
	function ClockServerService:constructor(config)
		self.startedAt = 0
		local _object = table.clone(DEFAULT_CONFIG)
		setmetatable(_object, nil)
		if config then
			for _k, _v in config do
				_object[_k] = _v
			end
		end
		self.config = _object
	end
	function ClockServerService:Start()
		self.startedAt = os.clock()
		local rf = self:ensureRemote()
		self.remote = rf
		rf.OnServerInvoke = function()
			return self:getSnapshot()
		end
		self.heartbeatConn = RunService.Heartbeat:Connect(function()
			return self:updateClockModel()
		end)
		print("[Clock] Server started")
	end
	function ClockServerService:Destroy()
		local _result = self.heartbeatConn
		if _result ~= nil then
			_result:Disconnect()
		end
		if self.remote then
			self.remote.OnServerInvoke = nil
		end
	end
	function ClockServerService:GetCurrentMinutes()
		local elapsedSeconds = os.clock() - self.startedAt
		local elapsedMinutes = (elapsedSeconds * self.config.timescale) / 60
		local raw = self.config.initialMinutes + elapsedMinutes
		return ((raw % self.config.dayLengthMinutes) + self.config.dayLengthMinutes) % self.config.dayLengthMinutes
	end
	function ClockServerService:GetSnapshot()
		return self:getSnapshot()
	end
	function ClockServerService:ensureRemote()
		local clockSnapshotRemote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
		if not clockSnapshotRemote then
			clockSnapshotRemote = Instance.new("RemoteFunction")
			clockSnapshotRemote.Name = REMOTE_NAME
			clockSnapshotRemote.Parent = ReplicatedStorage
		end
		return clockSnapshotRemote
	end
	function ClockServerService:getSnapshot()
		return {
			serverNowMinutes = self:GetCurrentMinutes(),
			dayLengthMinutes = self.config.dayLengthMinutes,
			timescale = self.config.timescale,
		}
	end
	function ClockServerService:toHands(totalMinutes)
		local totalSeconds = totalMinutes * 60
		local hour = (totalMinutes / 60) % 12
		local minute = totalMinutes % 60
		local second = totalSeconds % 60
		return {
			hourDeg = (hour / 12) * 360,
			minuteDeg = (minute / 60) * 360,
			secondDeg = (second / 60) * 360,
		}
	end
	function ClockServerService:resolveClockParts()
		local model = Workspace:FindFirstChild(CLOCK_MODEL_NAME)
		local _result = model
		if _result ~= nil then
			_result = _result:IsA("Model")
		end
		if not _result then
			return nil
		end
		local main = model:FindFirstChild("Main")
		local _result_1 = main
		if _result_1 ~= nil then
			_result_1 = _result_1:IsA("Folder")
		end
		if not _result_1 then
			return nil
		end
		local _centerPivotFolder = main
		if _centerPivotFolder ~= nil then
			_centerPivotFolder = _centerPivotFolder:FindFirstChild("CenterPivot")
		end
		local centerPivotFolder = _centerPivotFolder
		local _result_2 = centerPivotFolder
		if _result_2 ~= nil then
			_result_2 = _result_2:IsA("Folder")
		end
		if not _result_2 then
			return nil
		end
		local centerPivot = centerPivotFolder:FindFirstChild("CenterPivot")
		local hourHand = centerPivotFolder:FindFirstChild("HourHand")
		local minuteHand = centerPivotFolder:FindFirstChild("MinuteHand")
		local secondHand = centerPivotFolder:FindFirstChild("SecondHand")
		local _result_3 = centerPivot
		if _result_3 ~= nil then
			_result_3 = _result_3:IsA("BasePart")
		end
		local _condition = _result_3
		if _condition then
			local _result_4 = hourHand
			if _result_4 ~= nil then
				_result_4 = _result_4:IsA("BasePart")
			end
			_condition = _result_4
			if _condition then
				local _result_5 = minuteHand
				if _result_5 ~= nil then
					_result_5 = _result_5:IsA("BasePart")
				end
				_condition = _result_5
				if _condition then
					local _result_6 = secondHand
					if _result_6 ~= nil then
						_result_6 = _result_6:IsA("BasePart")
					end
					_condition = _result_6
				end
			end
		end
		local allValid = _condition
		if not allValid then
			return nil
		end
		return {
			centerPivot = centerPivot,
			hourHand = hourHand,
			minuteHand = minuteHand,
			secondHand = secondHand,
		}
	end
	function ClockServerService:getClockParts()
		local cached = self.clockParts
		local valid = cached and cached.centerPivot.Parent and cached.hourHand.Parent and cached.minuteHand.Parent and cached.secondHand.Parent
		if valid then
			return cached
		end
		self.clockParts = self:resolveClockParts()
		return self.clockParts
	end
	function ClockServerService:applyHandRotation(hand, pivotPos, base, deg)
		local _base = base
		local _arg0 = CFrame.Angles(0, math.rad(-deg), 0)
		local _position = hand.Position
		local _pivotPos = pivotPos
		hand.CFrame = _base * _arg0 + (_position - _pivotPos)
	end
	function ClockServerService:updateClockModel()
		local parts = self:getClockParts()
		if not parts then
			return nil
		end
		local hands = self:toHands(self:GetCurrentMinutes())
		local pivotPos = parts.centerPivot.Position
		local base = CFrame.fromMatrix(pivotPos, parts.centerPivot.CFrame.XVector, parts.centerPivot.CFrame.YVector, parts.centerPivot.CFrame.ZVector)
		self:applyHandRotation(parts.hourHand, pivotPos, base, hands.hourDeg)
		self:applyHandRotation(parts.minuteHand, pivotPos, base, hands.minuteDeg)
		self:applyHandRotation(parts.secondHand, pivotPos, base, hands.secondDeg)
		return nil
	end
end
-- ------ BOOTSTRAP ------ 
local ClockServer = ClockServerService.new()
ClockServer:Start()
