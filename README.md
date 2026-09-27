# Evolution Man: FireRed

A standalone quality-of-life mod for FireRed on Gen1Recomp 0.3.22.

Evolution Man is a Gentleman on **Celadon Dept. Store 2F**. For **¥2000**, he
performs any trade evolution that the active FireRed ROM considers valid.

## Rules

- Ordinary trade evolutions are supported.
- Held-item trade evolutions require the correct held item and consume it.
- Everstone blocks evolution normally.
- FireRed's National Dex restrictions remain in force.
- The selected Pokemon does not need to know a special move.
- Money and held items are committed only after the native evolution scene
  successfully starts.
- A paid evolution cannot be canceled with B once it begins.

## Install

Import a supported Pokemon FireRed ROM into Gen1Recomp, install the packaged
ZIP through the mod manager, and enable **Evolution Man: FireRed** for the
FireRed cart.

## Compatibility

- Game: Pokemon FireRed
- Gen1Recomp: 0.3.22 through the 0.3.x line
- Mod API: 2
- Save migration: none

The package requests `engine_internals` because Gen1Recomp 0.3.22 does not yet
expose public runtime NPC spawning for FireRed. The service uses the native
FireRed evolution data, eligibility checks, animation, stat update, Pokedex
registration, and held-item trade behavior.
