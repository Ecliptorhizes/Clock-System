local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local pkgRoot = script.Parent.Parent.Parent
local time = require(pkgRoot.shared.util.time)

local UPDATE_INTERVAL = 1 / 20

local function findCenterPivot(root: Instance): BasePart?
	local center = root:FindFirstChild("CenterPivot", true)
	if not center then
		return nil
	end
	if center:IsA("BasePart") then
		return center
	end
	if center:IsA("Folder") then
		return center:FindFirstChild("CenterPivot") or center:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local function findHand(root: Instance, name: string): BasePart?
	local pivotFolder = root:FindFirstChild("CenterPivot", true)
	if pivotFolder and pivotFolder:IsA("Folder") then
		local hand = pivotFolder:FindFirstChild(name)
		if hand and hand:IsA("BasePart") then
			return hand
		end
	end
	local hand = root:FindFirstChild(name, true)
	if hand and hand:IsA("BasePart") then
		return hand
	end
	return nil
end

local function findClockParts(root: Instance): { pivot: BasePart, hour: BasePart, minute: BasePart, second: BasePart? }?
	local pivot = findCenterPivot(root)
	local hour = findHand(root, "HourHand")
	local minute = findHand(root, "MinuteHand")
	local second = findHand(root, "SecondHand")

	if not pivot or not hour or not minute then
		return nil
	end

	return {
		pivot = pivot,
		hour = hour,
		minute = minute,
		second = second,
	}
end

local function has3DHands(root: Instance): boolean
	local parts = findClockParts(root)
	return parts ~= nil
end

local TEST_CYCLE_DURATION = 12
local function getTestHourAngle(): number
	local t = os.clock() % TEST_CYCLE_DURATION
	local step = t / TEST_CYCLE_DURATION * 12
	local hourIndex = math.floor(step) % 12
	return hourIndex * 30
end

local _clocks = {}
local _connection = nil
local function updateAllClocks()
	for i = #_clocks, 1, -1 do
		local entry = _clocks[i]
		if not entry.model:IsDescendantOf(game) then
			table.remove(_clocks, i)
		else
			local pivotCFrame = entry.pivot.CFrame
			local axis = pivotCFrame.UpVector

			local function setHandRotation(hand: BasePart, angleDeg: number, handRelativeCFrame: CFrame, handZeroAngle: number)
				local deltaAngle = angleDeg - handZeroAngle
				local angleRad = math.rad(deltaAngle)
				local rot = CFrame.fromAxisAngle(axis, angleRad)
				hand.CFrame = pivotCFrame * rot * handRelativeCFrame
			end

			if entry.testMode then
				local hourAngle = getTestHourAngle()
				setHandRotation(entry.hour, hourAngle, entry.hourRelative, entry.hourZeroAngle)
				setHandRotation(entry.minute, 0, entry.minuteRelative, entry.minuteZeroAngle)
				if entry.showSeconds and entry.second then
					setHandRotation(entry.second, 0, entry.secondRelative, entry.secondZeroAngle)
				end
			else
				local timeVal = entry.getTime and entry.getTime()
				if timeVal then
					local t = time.secondsToTimeOfDay(timeVal)
					local angles = time.timeToAngles(t.hours, t.minutes, t.seconds)
					setHandRotation(entry.hour, angles.hour, entry.hourRelative, entry.hourZeroAngle)
					setHandRotation(entry.minute, angles.minute, entry.minuteRelative, entry.minuteZeroAngle)
					if entry.showSeconds and entry.second then
						setHandRotation(entry.second, angles.second, entry.secondRelative, entry.secondZeroAngle)
					end
				end
			end
		end
	end

	if #_clocks == 0 and _connection then
		_connection:Disconnect()
		_connection = nil
	end
end

local function ensureConnection()
	if _connection then
		return
	end
	local lastUpdate = 0
	_connection = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastUpdate >= UPDATE_INTERVAL then
			lastUpdate = now
			updateAllClocks()
		end
	end)
end

local function getHandZeroAngle(handRelativeCFrame: CFrame): number
	local pos = handRelativeCFrame.Position
	local dir = handRelativeCFrame.LookVector
	if pos.Magnitude > 0.01 then
		return math.deg(math.atan2(pos.X, -pos.Z))
	end
	return math.deg(math.atan2(dir.X, -dir.Z))
end

local function register(root: Instance, getTime: () -> number?, showSeconds: boolean, testMode: boolean?): boolean
	local parts = findClockParts(root)
	if not parts then
		return false
	end

	local pivot = parts.pivot
	local hourRelative = pivot.CFrame:ToObjectSpace(parts.hour.CFrame)
	local minuteRelative = pivot.CFrame:ToObjectSpace(parts.minute.CFrame)
	local secondRelative = parts.second and pivot.CFrame:ToObjectSpace(parts.second.CFrame) or nil

	table.insert(_clocks, {
		model = root,
		pivot = pivot,
		hour = parts.hour,
		minute = parts.minute,
		second = parts.second,
		hourRelative = hourRelative,
		minuteRelative = minuteRelative,
		secondRelative = secondRelative,
		hourZeroAngle = getHandZeroAngle(hourRelative),
		minuteZeroAngle = getHandZeroAngle(minuteRelative),
		secondZeroAngle = secondRelative and getHandZeroAngle(secondRelative) or 0,
		getTime = getTime,
		showSeconds = showSeconds,
		testMode = testMode or false,
	})

	ensureConnection()
	return true
end

local function unregister(root: Instance)
	for i = #_clocks, 1, -1 do
		if _clocks[i].model == root then
			table.remove(_clocks, i)
			break
		end
	end
end

return {
	findClockParts = findClockParts,
	has3DHands = has3DHands,
	register = register,
	unregister = unregister,
}
