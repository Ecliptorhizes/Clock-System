import { ReplicatedStorage, RunService, Workspace } from "@rbxts/services";

/* ---------- TYPES ---------- */

export interface ClockConfig {
    dayLengthMinutes: number; // 1440 = full day
    timescale: number; // 60 => 1 real sec = 1 game minute
    initialMinutes: number; // 0...dayLengthMinutes
}

export interface ClockSnapshot {
    serverNowMinutes: number;
    dayLengthMinutes: number;
    timescale: number;
}

interface ClockHands {
    hourDeg: number;
    minuteDeg: number;
    secondDeg: number;
}

type ClockParts = {
    centerPivot: BasePart;
    hourHand: BasePart;
    minuteHand: BasePart;
    secondHand: BasePart;
};

/* ------- CONSTANTS ------- */

const DEFAULT_CONFIG: ClockConfig = {
    dayLengthMinutes: 24 * 60,
    timescale: 60,
    initialMinutes: 8 * 60,
};

const REMOTE_NAME = "ClockGetSnapshot";
const CLOCK_MODEL_NAME = "Clock";

/* ------ MODULE ----- */

/**
 * Authoritative clock service. Manages game time, exposes snapshot via RemoteFunction,
 * and optionally drives a Clock model in Workspace (Clock.Main.CenterPivot) */

class ClockServerService {
    private config: ClockConfig;
    private startedAt = 0;
    private remote?: RemoteFunction;
    private heartbeatConn?: RBXScriptConnection;
    private clockParts?: ClockParts;

    constructor(config?: Partial<ClockConfig>) {
        this.config = {
            ...DEFAULT_CONFIG,
            ...config,
        };
    }

    public Start() {
        this.startedAt = os.clock();
        const rf = this.ensureRemote();
        this.remote = rf;
        rf.OnServerInvoke = () => this.getSnapshot();
        this.heartbeatConn = RunService.Heartbeat.Connect(() => this.updateClockModel());
        print("[Clock] Server started");
    }

    public Destroy() {
        this.heartbeatConn?.Disconnect();
        if (this.remote) this.remote.OnServerInvoke = undefined;
    }

    public GetCurrentMinutes() {
        const elapsedSeconds = os.clock() - this.startedAt;
        const elapsedMinutes = (elapsedSeconds * this.config.timescale) / 60;
        const raw = this.config.initialMinutes + elapsedMinutes;
        return ((raw % this.config.dayLengthMinutes) + this.config.dayLengthMinutes) % this.config.dayLengthMinutes;
    }

    public GetSnapshot(): ClockSnapshot {
        return this.getSnapshot();
    }

    /* ------ PRIVATE ------ */
    private ensureRemote() {
        let clockSnapshotRemote = ReplicatedStorage.FindFirstChild(REMOTE_NAME) as RemoteFunction | undefined;
        if (!clockSnapshotRemote) {
            clockSnapshotRemote = new Instance("RemoteFunction");
            clockSnapshotRemote.Name = REMOTE_NAME;
            clockSnapshotRemote.Parent = ReplicatedStorage;
        }
        return clockSnapshotRemote;
    }

    private getSnapshot(): ClockSnapshot {
        return {
            serverNowMinutes: this.GetCurrentMinutes(),
            dayLengthMinutes: this.config.dayLengthMinutes,
            timescale: this.config.timescale,
        };
    }

/** Converts total minutes since midnight to hour/minutes/second hand angles (degrees). */
    private toHands(totalMinutes: number): ClockHands {
        const totalSeconds = totalMinutes * 60;
        const hour = (totalMinutes / 60) % 12;
        const minute = totalMinutes % 60;
        const second = totalSeconds % 60;

        return {
            hourDeg: (hour / 12) * 360,
            minuteDeg: (minute / 60) * 360,
            secondDeg: (second / 60) * 360,
        };
    }

    private resolveClockParts(): ClockParts | undefined {
        const model = Workspace.FindFirstChild(CLOCK_MODEL_NAME);
        if (!model?.IsA("Model")) return;

        const main = model.FindFirstChild("Main");
        if (!main?.IsA("Folder")) return;

        const centerPivotFolder = main?.FindFirstChild("CenterPivot");
        if (!centerPivotFolder?.IsA("Folder")) return;

        const centerPivot = centerPivotFolder.FindFirstChild("CenterPivot");
        const hourHand = centerPivotFolder.FindFirstChild("HourHand");
        const minuteHand = centerPivotFolder.FindFirstChild("MinuteHand");
        const secondHand = centerPivotFolder.FindFirstChild("SecondHand");

        const allValid = centerPivot?.IsA("BasePart") && hourHand?.IsA("BasePart") && minuteHand?.IsA("BasePart") && secondHand?.IsA("BasePart");
        if (!allValid) return;

        return {
        centerPivot: centerPivot as BasePart,
        hourHand: hourHand as BasePart,
        minuteHand: minuteHand as BasePart,
        secondHand: secondHand as BasePart,
        };
    }

    private getClockParts(): ClockParts | undefined {
        const cached = this.clockParts;
        const valid =
            cached &&
            cached.centerPivot.Parent &&
            cached.hourHand.Parent &&
            cached.minuteHand.Parent &&
            cached.secondHand.Parent;

        if (valid) return cached;

        this.clockParts = this.resolveClockParts();
        return this.clockParts;
    }

/** Rotates a hand part around pivot; deg is clockwise from 12 o'clock. */
    private applyHandRotation(hand: BasePart, pivotPos: Vector3, base: CFrame, deg: number) {
        hand.CFrame = base
            .mul(CFrame.Angles(0, math.rad(-deg), 0))
            .add(hand.Position.sub(pivotPos));
    }
    private updateClockModel() {
        const parts = this.getClockParts();
        if (!parts) return;

        const hands = this.toHands(this.GetCurrentMinutes());
        const pivotPos = parts.centerPivot.Position;
        const base = CFrame.fromMatrix(
            pivotPos,
            parts.centerPivot.CFrame.XVector,
            parts.centerPivot.CFrame.YVector,
            parts.centerPivot.CFrame.ZVector
        );

        this.applyHandRotation(parts.hourHand, pivotPos, base, hands.hourDeg);
        this.applyHandRotation(parts.minuteHand, pivotPos, base, hands.minuteDeg);
        this.applyHandRotation(parts.secondHand, pivotPos, base, hands.secondDeg);
        return;
    }
}

/* ------ BOOTSTRAP ------ */

const ClockServer = new ClockServerService();
ClockServer.Start();
