local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local pkgRoot = script.Parent.Parent.Parent
local time = require(pkgRoot.shared.util.time)

local UPDATE_INTERVAL = 1 / 10

export type AnalogClockProps = {
	size: UDim2?,
	showSeconds: boolean?,
	getTime: () -> number?,
	style: { [string]: any }?,
}

local function AnalogClock(props: AnalogClockProps)
	local size = props.size or UDim2.fromScale(1, 1)
	local showSeconds = props.showSeconds ~= false
	local getTime = props.getTime or function()
		return 0
	end
	local style = props.style or {}

	local timeVal, setTime = React.useState(0)
	local mounted = React.useRef(true)

	React.useEffect(function()
		mounted.current = true
		local lastUpdate = 0
		local connection
		connection = RunService.Heartbeat:Connect(function()
			if not mounted.current then
				connection:Disconnect()
				return
			end
			local now = os.clock()
			if now - lastUpdate >= UPDATE_INTERVAL then
				lastUpdate = now
				local t = getTime()
				if t then
					setTime(t)
				end
			end
		end)
		return function()
			mounted.current = false
			connection:Disconnect()
		end
	end, { getTime })

	local t = time.secondsToTimeOfDay(timeVal)
	local angles = time.timeToAngles(t.hours, t.minutes, t.seconds)

	local faceColor = style.faceColor or Color3.fromRGB(250, 250, 250)
	local handColor = style.handColor or Color3.fromRGB(30, 30, 30)
	local secondHandColor = style.secondHandColor or Color3.fromRGB(200, 50, 50)

	return React.createElement("Frame", {
		Size = size,
		BackgroundColor3 = faceColor,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		HourHand = React.createElement("Frame", {
			Size = UDim2.new(0.02, 0, 0.35, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = handColor,
			BorderSizePixel = 0,
			Rotation = angles.hour,
		}),
		MinuteHand = React.createElement("Frame", {
			Size = UDim2.new(0.015, 0, 0.45, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = handColor,
			BorderSizePixel = 0,
			Rotation = angles.minute,
		}),
		SecondHand = showSeconds and React.createElement("Frame", {
			Size = UDim2.new(0.008, 0, 0.48, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = secondHandColor,
			BorderSizePixel = 0,
			Rotation = angles.second,
		}) or nil,
	})
end

return AnalogClock
