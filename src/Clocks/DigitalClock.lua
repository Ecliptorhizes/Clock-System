local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local shared = require(script.Parent.shared)

local UPDATE_INTERVAL = 1 / 10

export type DigitalClockProps = {
	size: UDim2?,
	format: string?,
	getTime: () -> number?,
	style: { [string]: any }?,
}

local function DigitalClock(props: DigitalClockProps)
	local size = props.size or UDim2.fromScale(1, 1)
	local format = props.format or "HH:MM"
	local getTime = props.getTime or function()
		return 0
	end
	local style = props.style or {}

	local time, setTime = React.useState(0)
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

	local text = shared.formatTime(time, format)
	local textColor = style.textColor or Color3.fromRGB(255, 255, 255)
	local fontSize = style.fontSize or 24

	return React.createElement("TextLabel", {
		Size = size,
		Text = text,
		TextColor3 = textColor,
		TextSize = fontSize,
		Font = Enum.Font.GothamBold,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})
end

return DigitalClock
