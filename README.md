# Mission Archive

Mission Archive is a Darktide Mod Framework add-on that saves the built-in end-of-mission stats locally and lets you browse them in an in-game UI.

## Prerequisites

- Warhammer 40,000: Darktide for PC
- Darktide Mod Framework (DMF), installed and enabled

## What it saves

- Mission name, result, difficulty, mission type, start time, and duration
- The local player's values and strike-team totals for the 14 session-stat rows displayed by Darktide
- Up to 10 recent missions
- Two clearly marked demo missions are seeded once on first use so you can preview the mission selector

History is stored in the mod settings in Darktide's local user settings; it is not uploaded or exported.

## Install

1. Copy the `MissionArchive` folder into Darktide's `mods` folder.
2. Add `MissionArchive` to `mods/mod_load_order.txt`.
3. Reload mods or restart Darktide.
4. In the mod options, set the **Open mission archive** keybind if you want a different key. It defaults to **F8**.

Press the keybind to open or close the archive. Use the Up/Down arrows or W/S to browse missions, or select one with the mouse. Escape always closes the archive. The footer shows the current keybind used to close the archive.
