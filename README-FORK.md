# MM2-CreepFork (Creep.cc UI lib + fixes)

Forked from `Creep.cc` (visnoukkk). Only `Source.lua` + `Example.lua` changed.
`addons/` are untouched.

## What was fixed (all in `Source.lua`, tagged `-- MM2FORK`)

1. **Searchable dropdowns** — `AddDropdown(..., { Searchable = true })`
   adds a "Search..." box at the top of the open list; typing filters
   options case-insensitively. Works with `SetValues` / `SetValue` /
   multi-select. Ignored when not passed (old behavior untouched).
2. **`MaxItems`** — `AddDropdown(..., { MaxItems = 12 })` controls how many
   rows are visible before scrolling (was hardcoded to 8).
3. **`ExcludeLocalPlayer`** — `AddDropdown(...,
   { SpecialType = 'Player', ExcludeLocalPlayer = true })` hides your own
   name from that player dropdown, including on join/leave refresh.

`Example.lua` has a "Fork Features Demo" groupbox under Misc showing all three.

## How to host it (so executors can `HttpGet` it)

1. Create a new public GitHub repo, e.g. `MM2-CreepFork`.
2. Upload this folder's contents to the repo root:
   `Source.lua`, `Example.lua`, `addons/ThemeManager.lua`,
   `addons/SaveManager.lua` (keep the `addons/` folder structure).
3. Your URLs become:
   - `https://raw.githubusercontent.com/YOURNAME/MM2-CreepFork/refs/heads/main/Source.lua`
   - `.../addons/ThemeManager.lua`
   - `.../addons/SaveManager.lua`
4. In `MM2-Unlock-All.lua`, set `UILIB` at the top to your URL
   (it must end with `/`). Test with the fork's `Example.lua` first:
   run it and check the Misc tab demo.

No GitHub? Any static host that serves raw text over HTTPS works
(gist, rentry, pastebin raw, your own server) — just keep the 3 files
at stable URLs.
