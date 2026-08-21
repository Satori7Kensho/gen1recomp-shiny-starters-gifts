# Shiny Gifts & Starters for Gen1Recomp

A small quality-of-life companion mod for [Gen1Recomp](https://github.com/bryanthaboi/gen1recomp) that lets you force your starter — and optionally scripted story gift Pokémon — to be shiny.

**v1.2.0 adds support for both Gen 1 and the Gen 2 Gold beta.**

The mod must be enabled **before receiving the Pokémon** for it to be forced shiny.

> **Important:** If you enable this mod while Gen1Recomp is already running, **fully close and reopen Gen1Recomp before receiving your starter or gift Pokémon**. Enabling the mod mid-session without restarting may cause the Pokémon to be received normally instead of shiny.

## Supported Games

* Pokémon Red
* Pokémon Blue
* Pokémon Yellow
* Pokémon Gold 
* Pokémon Silver

## Options

* **SHINY STARTERS** – Forces the player's starter to be shiny when the mod is enabled before receiving it.

  * Gen 1: Bulbasaur, Charmander, Squirtle, and Pikachu
  * Gen 2: Chikorita, Cyndaquil, and Totodile

* **SHINY ALL GIFTS** – Forces scripted story gift Pokémon to be shiny when enabled before receiving them.

  * Includes gifts such as fossils, Lapras, Eevee, and other scripted gifts.
  * Gen 2 support also includes scripted gift eggs, including Togepi.

Wild Pokémon are **not** affected by this mod.

## How it works

The mod writes real shiny-compatible DVs to the Pokémon rather than only applying a visual shiny flag.

For Gen 1, the Pokémon will be shiny but without another mod to show its shiny (I used [Shiny Pokémon](https://github.com/masterwebx/gen1recomp-shiny-pokemon)), it will look normal. 

For Gen 2, this uses the native shiny DV rules, so gifted Pokémon remain genuinely shiny when their data is rebuilt from the save.


## Installation

### Mod Index

If available through the Gen1Recomp Mod Index, install or update the mod directly through the in-game mod manager.

### Manual Installation

1. Download the latest release ZIP.
2. Place/extract the `shiny_starters_gifts` folder into your Gen1Recomp `mods/` folder.
3. Enable the mod with **F10**.
4. **Fully close and reopen Gen1Recomp after enabling the mod.**
5. Make sure the desired option is enabled **before receiving the Pokémon**.

## Compatibility

The mod only intercepts the scripted commands used to give Pokémon to the player.

It does **not** alter:
- Wild encounter shiny rates
- Trainer Pokémon
- Random encounters
- Pokémon already owned by the player

It is designed to coexist with visual shiny mods, follower mods, voxel/battle-art mods, and other mods that display shininess.

Originally tested alongside the following mods:

* [Shiny Pokémon](https://github.com/masterwebx/gen1recomp-shiny-pokemon)
* [Wilds of Kanto / Overworld Wild Spawns](https://github.com/YoDrehDenSwagAuf/overworld-spawn-mod)
* [PokéPC Followers / PokePCFollowers VoxelMerge](https://github.com/gamecorner-033/PokePCFollowers)
* [Dramatic Shape Voxel Mod](https://github.com/DramaticShape/DramaticShapeVoxelMod)
* [Crystal Animated Sprites with Shiny Visuals](https://github.com/distilledorion-sketch/crystal_animated_sprites_with_shiny_visuals)

## v1.2.0

* Added support for the Gen 2 Gold and Silver beta.
* Added Chikorita, Cyndaquil, and Totodile starter support.
* Added cross-generation handling for scripted gift Pokémon.
* Added support for Gen 2 scripted gift eggs, including Togepi.
* Updated the mod to use Gen1Recomp's shared cross-generation scripting hooks.
* Preserves real shiny-compatible DVs rather than applying only a visual shiny flag.
* Preserves already-shiny Pokémon created by another mod.
* Identifies the exact newly received gift instead of modifying another Pokémon of the same species.
* Shiny Starters now defaults to **ON**.
* Shiny All Gifts now defaults to **ON**.
* Wild Pokémon remain unaffected.

## Notes

Gen 2 support targets the current **Gold beta** implementation of Gen1Recomp. Because Gen 2 support is still under active development, future Gen1Recomp updates may require corresponding updates to this mod.

## License

MIT

