# Clock System

A modular, server-authoritative clock system for Roblox. Distributed as a Wally package with support for builder-friendly auto-detection via CollectionService tags and a full developer API.

## Features

- **Server-authoritative time** with configurable day length and time scale
- **Client synchronization** with latency compensation
- **Analog and digital clock** React components
- **Builder workflow**: Add tags to Parts/Models—no code required
- **Developer API**: Full control over time engine and custom clock rendering

## Installation

Add to your `wally.toml`:

```toml
[dependencies]
ecliptorhizes/clock-system = "0.1.0"
```

Then run `wally install`.

## Quick Start

### Server (e.g. `ServerScriptService/Main.server.lua`)

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClockSystem = require(ReplicatedStorage.Packages.ecliptorhizes_clock_system)

ClockSystem.startServer({
	dayLength = 24 * 60,  -- 24 real minutes = 1 game day
	timeScale = 1,
	initialTime = 0,     -- seconds since midnight to start at
})
```

### Client (e.g. `StarterPlayerScripts/StarterPlayerScripts/Main.client.lua`)

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClockSystem = require(ReplicatedStorage.Packages.ecliptorhizes_clock_system)

ClockSystem.startClient():andThen(function()
	print("Clock system ready")
end)
```

### Builder Workflow

1. Create a Part or Model in the workspace
2. Add a CollectionService tag:
   - `ClockSystem_Analog` for analog clock
   - `ClockSystem_Digital` for digital clock
3. Optionally set attributes (see [Builder Guide](docs/BUILDER.md))

The clock will automatically appear on the tagged instance.

## API Overview

| Module | Description |
|--------|-------------|
| `TimeEngine` | Server-side time management |
| `ClientTimeSync` | Client time synchronization |
| `AnalogClock` | React analog clock component |
| `DigitalClock` | React digital clock component |
| `ClockBootstrap` | Auto-detect tagged instances |

See [API Documentation](docs/API.md) for full details.

## Project Structure

```
src/
├── init.lua              # Main entry, startServer/startClient
├── TimeEngine/           # Server time logic
├── ClientTimeSync/       # Client sync
├── Clocks/               # AnalogClock, DigitalClock, ClockBootstrap
└── Internal/             # RemoteBridge, JanitorMixin
```

## Rojo

This project uses Rojo. Sync `src/` to `ReplicatedStorage.ClockSystem` and include the `Packages` folder from Wally.

## License

MIT
