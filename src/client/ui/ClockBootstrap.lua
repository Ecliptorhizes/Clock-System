local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Janitor = require(ReplicatedStorage.Packages.Janitor)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local AnalogClock = require(script.Parent.AnalogClock)
local AnalogClock3D = require(script.Parent.AnalogClock3D)
local DigitalClock = require(script.Parent.DigitalClock)

local TAG_ANALOG = "ClockSystem_Analog"
local TAG_DIGITAL = "ClockSystem_Digital"

local CLOCK_SIZE = 4
local CLOCK_OFFSET = 1

local function getAttachmentPart(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
	end
	if instance:IsA("Folder") then
		return instance:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function createClockGui(parent: BasePart, clockType: "analog" | "digital", config: { [string]: any })
	local existing = parent:FindFirstChild("ClockSystem_Clock")
	if existing then
		existing:Destroy()
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ClockSystem_Clock"
	billboard.Size = UDim2.new(0, 256, 0, 256)
	billboard.StudsOffset = Vector3.new(0, 0, CLOCK_OFFSET)
	billboard.AlwaysOnTop = config.AlwaysOnTop or false
	billboard.Parent = parent

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Parent = billboard

	return billboard, container
end

local function mountClock(
	container: Instance,
	clockType: "analog" | "digital",
	config: { [string]: any },
	getTime: () -> number?
)
	local ClockComponent = if clockType == "analog" then AnalogClock else DigitalClock

	local root = ReactRoblox.createRoot(container)
	root:render(React.createElement(ClockComponent, {
		size = UDim2.fromScale(1, 1),
		showSeconds = config.ShowSeconds,
		format = config.Format or "HH:MM",
		getTime = getTime,
		style = {
			faceColor = config.FaceColor,
			handColor = config.HandColor,
			secondHandColor = config.SecondHandColor,
			textColor = config.TextColor,
			fontSize = config.FontSize,
		},
	}))

	return root
end

local function readConfig(instance: Instance): { [string]: any }
	local showSeconds = instance:GetAttribute("ShowSeconds")
	if showSeconds == nil then
		showSeconds = true
	end

	return {
		ShowSeconds = showSeconds,
		TestMode = instance:GetAttribute("TestMode") or false,
		Format = instance:GetAttribute("Format") or "HH:MM",
		FaceColor = instance:GetAttribute("FaceColor") or Color3.fromRGB(250, 250, 250),
		HandColor = instance:GetAttribute("HandColor") or Color3.fromRGB(30, 30, 30),
		SecondHandColor = instance:GetAttribute("SecondHandColor") or Color3.fromRGB(200, 50, 50),
		TextColor = instance:GetAttribute("TextColor") or Color3.fromRGB(255, 255, 255),
		FontSize = instance:GetAttribute("FontSize") or 24,
		AlwaysOnTop = instance:GetAttribute("AlwaysOnTop") or false,
	}
end

local ClockBootstrap = {}
ClockBootstrap.__index = ClockBootstrap

function ClockBootstrap.new(getTime: () -> number?)
	local self = setmetatable({}, ClockBootstrap)
	self._janitor = Janitor.new()
	self._getTime = getTime or function()
		return 0
	end

	return self
end

function ClockBootstrap:start()
	local function setupClock(instance: Instance, clockType: "analog" | "digital")
		if clockType == "analog" and (instance:IsA("Model") or instance:IsA("Folder")) and AnalogClock3D.has3DHands(instance) then
			local config = readConfig(instance)
			local ok = AnalogClock3D.register(instance, self._getTime, config.ShowSeconds, config.TestMode)
			if ok then
				instance.AncestryChanged:Connect(function()
					if not instance:IsDescendantOf(game) then
						AnalogClock3D.unregister(instance)
					end
				end)
			end
			return
		end

		local part = getAttachmentPart(instance)
		if not part then
			local msg = "[ClockSystem] ClockBootstrap: Cannot attach clock to " .. instance:GetFullName() .. " - not a Part, Model, or Folder"
			warn(msg)
			return
		end

		local config = readConfig(instance)
		local billboard, container = createClockGui(part, clockType, config)

		local root = mountClock(container, clockType, config, self._getTime)

		local janitor = Janitor.new()
		janitor:Add(billboard, "Destroy")
		janitor:Add(function()
			root:unmount()
		end)

		instance.AncestryChanged:Connect(function()
			if not instance:IsDescendantOf(game) then
				janitor:Cleanup()
			end
		end)

		self._janitor:Add(janitor, "Cleanup")
	end

	for _, instance in CollectionService:GetTagged(TAG_ANALOG) do
		setupClock(instance, "analog")
	end

	for _, instance in CollectionService:GetTagged(TAG_DIGITAL) do
		setupClock(instance, "digital")
	end

	CollectionService:GetInstanceAddedSignal(TAG_ANALOG):Connect(function(instance)
		setupClock(instance, "analog")
	end)

	CollectionService:GetInstanceAddedSignal(TAG_DIGITAL):Connect(function(instance)
		setupClock(instance, "digital")
	end)
end

function ClockBootstrap:destroy()
	self._janitor:Cleanup()
end

return ClockBootstrap
