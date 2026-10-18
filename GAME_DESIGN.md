# Red Line Challenge — Game Design

*A Roblox game inspired by the format of the video "Lose 100 LBs, Win $250,000!" No real
names, faces, logos or branding from the video are used.*

## 1. How the video works (analysis)

| Video element | What happens | Why it's fun to watch |
|---|---|---|
| **The deal** | Contestant lives in a compound for up to a year. Hit the goal → win $250,000. | One giant, simple goal. |
| **The red line** | Step over the red line before the goal and you lose *everything*. | Constant temptation; one mistake ends it. |
| **Everything provided** | Personal gym, track, basketball hoop, healthy food, a trainer. | Clear tools to make progress. |
| **Monthly weigh-ins** | Progress is hidden until a big reveal every 30 days (324 → 303 → 286 → 271 → 246 → 234 → goal). | Suspense + reward moments. |
| **Micro-challenges** | Every check-in unlocks a challenge that *adds* to the prize pool: push-ups ($1k each), money carry (keep what you carry, drop anything = lose it), mile under a target time (+$25k), dead hang from a crane ($1k/sec), one pull-up (+$10k). | Short, intense skill tests that grow the pot from $250k to $417k+. |
| **Risk vs greed** | Money carry: carry more = more money, but more chance to drop it all. | Player choice with real stakes. |
| **Milestones** | New clothes one size smaller, visitors, gifts. | Visible progress between big moments. |
| **Daily grind** | Steps, workouts, cooking, sleep schedule; motivation dips mid-way. | The "journey" — habits build up. |
| **Finale** | Final check-in, full transformation reveal, walk out across the line. | Big payoff. |

## 2. Game concept

**You are locked inside a training compound surrounded by a glowing red line.
Reach 100% Fitness to win the Prize Pool. Cross the red line early and you lose it all.**

Framed around **fitness and strength**, not body weight, so it's positive and safe for Roblox's audience.

### Core loop (every in-game day ≈ 2 real minutes)
1. **Train**: treadmill, weight bench, basketball hoop, running track. Each costs **Energy** and raises stats.
2. **Eat**: healthy food restores Energy. Junk food restores more Energy but *lowers* Fitness (temptation).
3. **Sleep**: the bed skips to the next day and refills Energy.
4. **Check-in** every 5 days: a dramatic Fitness reveal, a new shirt tier, and a new **micro-challenge** unlocks.
5. **Micro-challenges** add cash to the **Prize Pool**.
6. Reach **100% Fitness** → walk out the gate → Prize Pool goes to your **Bank** (permanent, leaderboard). Start a new run, harder.

### Stats
- **Fitness** 0–100%: the main goal. All training raises it; junk food lowers it.
- **Strength**: from bench and push-ups. Helps the push-up, money-carry and hang challenges.
- **Stamina**: from treadmill and track. Makes you run faster in the mile challenge.
- **Energy** 0–100: spent by training, refilled by food and sleep.

### Micro-challenges (unlocked in order at check-ins)
| # | Challenge | Mechanic | Reward |
|---|---|---|---|
| 1 | **Push-Up Payday** | Timing game: press SPACE when the marker is in the green zone. The zone shrinks every rep. Miss = done. | $1,000 per rep |
| 2 | **Cash Carry** | Pick how many $10k bags to carry, then walk a lap. Each bag slows you and adds drop risk (Strength lowers it). Drop one = lose it all. | Keep what you carry |
| 3 | **Beat the Mile** | Run the track checkpoints before the timer runs out. Stamina = speed. | $25,000 |
| 4 | **Crane Hang** | On a platform high up, mash SPACE to keep your grip meter up. Strength slows the drain. | $1,000 per second |
| 5 | **The Pull-Up** | One hard timing press with a tiny window (Strength widens it). | $10,000 |

### The red line
- A glowing ring around the compound with a gate.
- Touching it opens a warning: **"Leave now and forfeit $X?"** Confirm = run over, Prize Pool lost.
- Once Fitness hits 100%, the gate turns green and crossing it **wins**.

### Progress rewards
- Shirt tier changes color at every check-in (3XL → 2XL → XL → L → M feel, shown as colors and names).
- Leaderboard: **Bank** (lifetime winnings) and **Wins**.

## 3. What's built in this project
- Rojo project in `src/` (Luau): data saving, stats, day/night clock, activities, red line, check-ins, all 5 challenges, HUD, popups.
- **Auto map builder**: if your place has no map, the game builds a playable compound on start. Delete or replace it later with your own Blender/Studio models, tagged the same way.
- `blender/make_assets.py`: generates low-poly props (dumbbell, money bag, treadmill, bench, hoop) as FBX for Roblox's 3D Importer.
