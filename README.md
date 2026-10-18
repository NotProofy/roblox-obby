# Red Line Challenge (Roblox)

Stay inside the red line, train until you're 100% fit, and grow the prize pool with
challenges. If you cross the line early, you lose it all. See [GAME_DESIGN.md](GAME_DESIGN.md).

## What's in here
```
src/shared/   Config.luau (all numbers to tweak), Remotes.luau
src/server/   Main, PlayerData (saving), MapBuilder (auto map), Track, Activities,
              RedLine, Challenges
src/client/   Main (HUD + popups), Minigames (push-ups / hang / pull-up), UI helpers
blender/      make_assets.py + export/*.fbx (dumbbell, money bag, treadmill, bench, hoop)
```

## Get it into Roblox Studio (Windows)

### Option A: one place file (easiest)
1. Download **rojo.exe** from https://github.com/rojo-rbx/rojo/releases (the `windows` zip for 7.4.x).
   Put it in this folder.
2. In this folder, run:
   ```
   .\rojo.exe build -o RedLineChallenge.rbxlx
   ```
3. Double-click **RedLineChallenge.rbxlx** to open it in Roblox Studio, then press **Play**.
   The map builds itself when the game starts.

### Option B: live sync (best while you keep editing code)
1. In Roblox Studio, open **Plugins → Manage Plugins**, search **Rojo** and install it.
2. Run `.\rojo.exe serve` in this folder.
3. In Studio, click the **Rojo** plugin and choose **Connect**. Code changes now show up instantly.

### Turn on saving
Go to **Game Settings → Security** and enable **Enable Studio Access to API Services**.
Without this, Bank and Wins won't save while you test in Studio. The game still works.

## How to play
- **Treadmill**: walk forward on the belt. Gives Fitness and Stamina.
- **Weight bench**: hold E to lift. Gives Strength and Fitness.
- **Basketball**: press E to shoot. A made shot gives double rewards.
- **Running track**: run a full lap through the start line. Gives Fitness and Stamina.
- **Healthy meal**: restores Energy. **Junk food** restores more Energy but lowers Fitness.
- **Bed**: sleep to restore all Energy (60-second cooldown).
- At **15 / 30 / 45 / 60 / 75% Fitness** there's a check-in and a challenge unlocks. Press **START CHALLENGE**.
- At **100%** the line turns green. Walk across it to bank the whole prize pool.

## Using your Blender models
The FBX files are already exported to `blender/export/`. To regenerate or change them:
```
blender --background --python blender/make_assets.py
```
In Studio: **Avatar tab → Import 3D** (or File → Import 3D), pick an FBX, then place it.
To make a model *work* in the game, add a tag to one of its parts:
**View → Tag Editor** (or the Properties panel's Tags section) and add the tag below.

| Tag | What it does |
|---|---|
| `Treadmill` | Conveyor belt surface you run on |
| `Bench` | Lift prompt |
| `Hoop` | Shoot prompt |
| `HealthyFood` / `JunkFood` | Eat prompts |
| `Bed` | Sleep prompt |
| `PushUpSpot` | Where the push-up challenge happens |
| `CraneSpot` | Platform for the hang and pull-up challenges |
| `RedLine` | Invisible trigger (put it on tall, transparent, CanCollide-off parts) |
| `RedLineVisual` | Glowing line that turns green when you reach the goal |
| `TrackCP` | Track checkpoints. Also add a number attribute `Order` = 1, 2, 3... in order around the track |

**Building your own map:** make a Model named **Compound** in Workspace. The auto-builder then
stays off, and only your tagged parts are used.

## Tweak the game
Every number lives in `src/shared/Config.luau`: prize amounts, energy costs, how fast Fitness
goes up, challenge difficulty, map size and more.

## Publish
File → **Publish to Roblox**, then set the game to Public in Game Settings.
