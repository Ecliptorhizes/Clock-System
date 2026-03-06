local time = {}

function time.secondsToTimeOfDay(totalSeconds: number): { hours: number, minutes: number, seconds: number }
	local hours = math.floor(totalSeconds / 3600)
	local remainder = totalSeconds % 3600
	local minutes = math.floor(remainder / 60)
	local seconds = remainder % 60
	return { hours = hours, minutes = minutes, seconds = seconds }
end

function time.formatTime(totalSeconds: number, format: string?): string
	local t = time.secondsToTimeOfDay(totalSeconds)
	format = format or "HH:MM"

	local h = string.format("%02d", t.hours)
	local m = string.format("%02d", t.minutes)
	local s = string.format("%02d", t.seconds)

	return (format
		:gsub("HH", h)
		:gsub("MM", m)
		:gsub("SS", s))
end

function time.timeToAngles(hours: number, minutes: number, seconds: number): { hour: number, minute: number, second: number }
	local secondAngle = seconds * 6
	local minuteAngle = minutes * 6 + seconds * 0.1
	local hourAngle = (hours % 12) * 30 + minutes * 0.5 + seconds * (0.5 / 60)
	return { hour = hourAngle, minute = minuteAngle, second = secondAngle }
end

return time
