# Clock System

A modular, server-authoritative clock system for Roblox. Distributed as a Wally package with support for builder-friendly auto-detection via CollectionService tags and a full developer API.

## Features

- **Server-authoritative time** with configurable day length and time scale
- **Client synchronization** with latency compensation
- **Analog and digital clock** React components (UI overlay)
- **3D clock support** for models with CenterPivot, HourHand, MinuteHand, SecondHand
- **Knit integration** via TimeEngineService and ClockController
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

### Option A: With Knit (recommended)

Add Knit and Clock System to your `wally.toml`:

```toml
[dependencies]
Knit = "sleitnick/knit@^1.7"
ecliptorhizes/clock-system = "0.1.0"
```

Then:

**Server** (`ServerScriptService/Main.server.lua`):

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local ClockSystem = require(ReplicatedStorage.Packages.ecliptorhizes_clock_system)

Knit.AddServices(ClockSystem.KnitServices)
Knit.Start():catch(warn)
```

**Client** (`StarterPlayerScripts/StarterPlayerScripts/Main.client.lua`):

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local ClockSystem = require(ReplicatedStorage.Packages.ecliptorhizes_clock_system)

Knit.AddControllers(ClockSystem.KnitControllers)
Knit.Start():catch(warn):await()
```

### Option B: Without Knit

**Server** (`ServerScriptService/Main.server.lua`):

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClockSystem = require(ReplicatedStorage.Packages.ecliptorhizes_clock_system)

ClockSystem.startServer({
	dayLength = 24 * 60,
	timeScale = 1,
	initialTime = 0,
})
```

**Client** (`StarterPlayerScripts/StarterPlayerScripts/Main.client.lua`):

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClockSystem = require(ReplicatedStorage.Packages.ecliptorhizes_clock_system)

ClockSystem.startClient():andThen(function()
	print("Clock system ready")
end)
```

### 3D Clocks

For 3D clock models (e.g. wall clocks with physical hands), ensure your model has:

- **CenterPivot** – Part or Folder containing the pivot Part
- **HourHand**, **MinuteHand**, **SecondHand** – BaseParts (inside CenterPivot folder or as siblings)

Add the `ClockSystem_Analog` tag to the model. The system auto-detects 3D hands and rotates them via CFrame instead of showing a UI overlay.

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
| `AnalogClock` | React analog clock component (UI) |
| `AnalogClock3D` | 3D hand rotation for models |
| `DigitalClock` | React digital clock component |
| `ClockBootstrap` | Auto-detect tagged instances |
| `KnitServices` | Folder for Knit.AddServices (server.services) |
| `KnitControllers` | Folder for Knit.AddControllers (client.controllers) |

See [API Documentation](docs/API.md) for full details.

## Project Structure

```
src/
├── init.lua              # Main entry, startServer/startClient
├── shared/               # Shared between client and server
│   ├── Core/             # RemoteBridge, core infrastructure
│   ├── Data/             # Types and data structures
│   └── util/             # Time/angle utilities
├── server/               # Server-only
│   ├── TimeEngine/       # Server time logic
│   └── services/         # Knit services (TimeEngineService)
└── client/               # Client-only
    ├── ClientTimeSync/   # Client sync
    ├── controllers/      # Knit controllers (ClockController)
    └── ui/               # AnalogClock, AnalogClock3D, DigitalClock, ClockBootstrap
```

## Rojo

This project uses Rojo. Sync `src/` to `ReplicatedStorage.ClockSystem` and include the `Packages` folder from Wally.

## License

MIT
