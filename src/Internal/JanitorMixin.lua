local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local JanitorMixin = {}

function JanitorMixin.create(): (any, () -> ())
	local janitor = Janitor.new()
	local function cleanup()
		janitor:Cleanup()
	end
	return janitor, cleanup
end

return JanitorMixin
