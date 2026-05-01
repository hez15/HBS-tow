# hbs-tow

Towing job for QBX with NPC missions, tow rope item, police wheel boot, and a drag-and-drop NUI dispatch tablet.

## Features

- Job-locked tow operator (`job = 'tow'`) with auto-generated NPC missions
- 4 mission variants (abandoned, illegal parking, accident, VIP recovery) gated by `nonstop-xp` `towing` level
- Drag-and-drop NUI dispatch tablet — vanilla HTML/CSS/JS, no build step
- `tow_rope` item — rigid attach with visual chain, toggle on/off, blocked on booted vehicles
- `wheel_boot` police item — DB-persisted, restored on stream-in, integrates with `hbs-mdt` via exports
- Auto-applied SQL migrations on first start

## Dependencies

- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [oxmysql](https://github.com/overextended/oxmysql)
- `nonstop-xp` *(recommended — payout multiplier and level gating require it)*
- `hbs-mdt` *(optional — for fine-paid boot removal flow)*

OneSync must be enabled (server-side vehicle spawning uses `CreateVehicleServerSetter`).

## Install

1. **Drop the resource** into your `resources/` directory.

2. **Add to `server.cfg`**, after qbx and the ox stack:
   ```cfg
   ensure hbs-tow
   ```

3. **SQL** auto-applies on first start. The schema lives in `sql/install.sql` if you want to inspect or run manually.

4. **Add the items to ox_inventory** (in `ox_inventory/data/items.lua`):
   ```lua
   ['tow_tablet'] = {
       label = 'Tow Dispatch Tablet',
       weight = 200,
       stack = false,
       close = true,
       client = { export = 'hbs-tow.useTowTablet' },
   },
   ['tow_rope'] = {
       label = 'Tow Rope',
       weight = 500,
       client = { export = 'hbs-tow.useTowRope' },
   },
   ['wheel_boot'] = {
       label = 'Wheel Boot',
       weight = 1500,
       client = { export = 'hbs-tow.useWheelBoot' },
   },
   ```

5. **Add a `tow` job** to `qbx_core` so players can be employed as tow operators.

6. **Add a `towing` track + `jobPayoutMult` perk** to your `nonstop-xp` config so XP/payouts wire up:
   ```lua
   Config.Tracks = {
       -- existing tracks...
       towing = { weight = 1.0 },
   }

   Config.PerksTrackEnabled = {
       -- existing entries...
       towing = true,
   }

   Config.PerksToggle = {
       -- existing entries...
       towing = { jobPayoutMult = true },
   }

   Config.Perks = {
       -- existing entries...
       towing = {
           jobPayoutMult = {
               { lvl = 0,  val = 1.00 },
               { lvl = 10, val = 1.05 },
               { lvl = 20, val = 1.10 },
           },
       },
   }
   ```

7. *(Optional)* **MDT integration** — call these from `hbs-mdt`:
   ```lua
   local ok, err = exports['hbs-tow']:ApplyBoot(plate, leoCitizenId, fine, reason)
   local ok, err = exports['hbs-tow']:RemoveBoot(plate, reason) -- e.g. on fine paid
   local row     = exports['hbs-tow']:GetBoot(plate)
   local rows    = exports['hbs-tow']:ListBoots()
   ```

   Listen on the server for state changes:
   ```lua
   AddEventHandler('hbs-tow:server:bootApplied',  function(plate, leoCid, fine) end)
   AddEventHandler('hbs-tow:server:bootRemoved', function(plate, reason) end)
   ```

## How it works

### Tow job loop

1. Walk up to the depot at `vec3(409.7, -1622.8, 29.3)` and use ox_target → **Toggle Duty**
2. **Take out tow truck** spawns a `towtruck`
3. Use the `tow_tablet` item to open the dispatch UI
4. Accept a call (locked variants need a higher towing level)
5. Drive to pickup → ox_target on the target vehicle → **Hook to Tow Truck**
6. Drive to the central impound at `vec3(403.7588, -1632.9202, 29.292)`
7. ox_target on the truck → **Detach & Complete** → cash + XP

### Mission variants

| Variant | Min level | Base pay | XP | Flavor |
|---|---|---|---|---|
| `abandoned` | 0 | $250 | 15 | Dirty, two flat tyres |
| `illegal_parking` | 5 | $325 | 20 | Parking ticket on the windshield |
| `accident` | 10 | $450 | 30 | Damaged vehicle + NPC driver on scene |
| `vip_recovery` | 15 | $700 | 50 | Clean high-end vehicle with VIP plate |

All values live in `shared/locations.lua`.

### Tow rope

Driver in any vehicle uses the `tow_rope` item with a target vehicle within 6 m. Item toggles: re-using detaches. Visual chain prop, speed cap (~40 mph), blocked on booted vehicles.

### Wheel boot

Police use `wheel_boot` via ox_target on any vehicle wheel area. State persists in `hbs_tow_boots`. On vehicle stream-in any nearby client re-asserts immobilization + the visible boot prop, so boots survive restarts and persistent parking respawns.

## Configuration

| File | Purpose |
|---|---|
| `shared/config.lua` | Theme, MDT/XP resource names, job/rope/boot tunables, required job |
| `shared/locations.lua` | Depot, impound, mission spawn pool, vehicle pool, mission variants |

## Commands

- `/towabandon` — abandon the active tow mission

## File map

```
fxmanifest.lua
sql/install.sql                 -- auto-applied on first start
shared/                         -- config + locations
client/                         -- main, job state machine, tablet bridge, attach, rope, boot
server/                         -- main + migrations, job, tablet, rope, boot
web-build/                      -- vanilla NUI bundle (drag-and-drop, no npm)
```
