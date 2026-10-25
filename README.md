# ORBITAL: The Last Engineer

[![Godot Engine](https://img.shields.io/badge/Godot_Engine-v4.7.2-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Build Status](https://img.shields.io/badge/Automated_Tests-877_PASSED-brightgreen.svg)]()
[![Platform](https://img.shields.io/badge/Platform-Windows_PC-blue.svg)]()
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

> *"The ship is not a collection of rooms with decorative props. It is one interconnected machine."*

**ORBITAL: The Last Engineer** is a first-person 3D science-fiction spacecraft engineering, survival, and psychological horror game built in **Godot Engine 4.7.2** (GDScript). 

As the Lead Scientist docking at the *Astraea Biological Research Facility*, you discover the station dark, the primary fusion generators tripped, the life support scrubbers offline, and the entire research team dead. An unauthorized genetic experiment in the lower observatory chambers has spawned an aggressive apex predator that now stalks the vessel. You must restore the station's dying systems, investigate the mystery through the environment, and tactically lure the entity into a containment chamber before purging it with lethal decontamination gas.

---

## Key Features

### 1. The Ship is a Living Machine
- **Deterministic Subsystem Simulation**: A unified physical network connecting Power Generation, Life Support ($O_2$, $CO_2$, temperature, barometric pressure), Coolant Loops, Fuel Storage, Communications, Avionics, and Pneumatic Bulkheads.
- **Interconnected Dependency Chains**: Damaged coolant pumps overheat the fusion turbine $\rightarrow$ reactor thermal throttling drops electrical generation $\rightarrow$ secondary circuits depower $\rightarrow$ atmospheric scrubbers cease $\rightarrow$ hypoxia and cognitive drift set in.
- **Tactical Schematic Blueprint (`[M]` key)**: Live 13-compartment spatial map spanning Deck 1 and Lower Subdeck with real-time pressure, oxygen, and power status, allowing direct bus rerouting.

### 2. Diagnosis Before Repair
- **Hands-On Engineering Tools**:
  - **Diagnostic Scanner (`[1]`)**: Scans machinery and encrypted data slates for operating efficiency, heat, fault codes, and tool requirements (drains 10% battery per scan).
  - **Multitool / Welder (`[2]`)**: 3-mode utility device (`CALIBRATE` for electrical circuitry, `CUT_WELD` for metal slicing and breach patching, `TIGHTEN` for high-torque pneumatic clamps). Cycle modes with `[Q]`.
  - **Consumable Supplies**: Spare fuse packs (`[3]`), portable battery cells (`[4]`), replacement filter cartridges, and coolant canisters.
- **Physical Workstations**: Interactive supply lockers for item storage and engineering workbenches for component inspection and battery inductive recharging.
- **5-Stage Servicing Workflow**: `DIAGNOSE` $\rightarrow$ `UNCLAMP` $\rightarrow$ `REPLACE` $\rightarrow$ `CALIBRATE / TIGHTEN` $\rightarrow$ `TEST`.

### 3. Survival Horror & Physical Alien Stalker
- **3D Predatory Specimen (`CharacterBody3D`)**: An apex biological entity with segmented chitin armor, mantis scythe claws, dorsal spine ridges, and pulsing crimson eye omni-lights.
- **Psychological Horror & Stalking**: Dynamic station lighting flickers, ambient red blackout strobes, duct scraping sounds, and sub-bass growls.
- **Cinematic Boss Jumpscare Zoom**: The creature materializes in front of the player and executes a high-speed camera zoom rush down to 1.8 meters, punching camera FOV from 75° to 51° with screen trauma shake and a piercing biological shriek.
- **Tactical Chamber Trap**: Lure the organism into the interlocking **Airlock Chamber** and turn the physical **Decontamination Poison Gas Valve** to flood the chamber with toxic gas and eliminate the threat.

### 4. 13 Explorable Compartments Across 2 Decks
1. **Command Bridge**: Navigation holotable, avionics terminal, and orbital departure thruster controls.
2. **Research Observatory**: Panoramic glass dome overlooking Kepler-442b with observation consoles.
3. **Avionics Bay**: Server racks, optical data bus, and flight computer relay banks.
4. **Crew Quarters**: Bunks, crew lockers, hydroponic planters, and water recycler pump.
5. **Medical Infirmary**: Bio-diagnostic bed, trauma supplies, and medical oxygen booster.
6. **Central Corridor**: Spine thoroughfare with motorized pressure bulkheads.
7. **Life Support Module**: Solid-state oxygen generator, secondary amine scrubbers, and coolant manifold.
8. **Main Cargo Bay**: Heavy pallets, hydraulic hoist junction, and torchable salvage crates.
9. **Airlock & EVA Staging**: Dual-door interlocking airlock (`AirlockInner`, `AirlockOuter`), manual pressure cycle panel, and the Decontamination Poison Gas Valve.
10. **Engineering Bay**: Main 150 kW fusion turbine generator, distribution bus, workbench, and supply locker.
11. **Reactor Subdeck**: Lower deck fuel vault with manual fuel flow valve and auxiliary battery bank.
12. **Specimen Vault**: Lower containment sector with shattered incubation pods and elevated bio-contaminant $CO_2$.
13. **Maintenance Crawlway**: Low-clearance transit bypass with an active hull breach decompression hazard ($0.3\text{ kPa/s}$).

### 5. Streamlined HUD & Paused Tactical INFO Dashboard
- **Clean Gameplay Screen**: Unobstructed first-person view with no distracting gauges during active movement.
- **Immediate Task Display**: Upper-left corner displays the concise mission title with the immediate actionable step directly beneath it (e.g., `CURRENT TASK: RESTORE GENERATOR BREAKER`).
- **Pausable Operations Dashboard (`[Tab]` / `[Esc]`)**: Pauses the game to present a 3-column tactical overview:
  - **Left**: Live Atmospheric Telemetry ($O_2$, $CO_2$, temperature, pressure).
  - **Center**: Scientist Mission Directive and complete storyline briefing.
  - **Right**: Scientist Gear, tool charges, and inventory quantities.
- **Non-Intrusive Prompts**: Interaction labels are anchored below targeted 3D objects with scaled-down 11px typography.

### 6. Environmental Storyline & 3 Major Revelations
- **10 Physical In-World Datapads**: Recoverable audio/text slates requiring scanner decryption or regional subsystem power restoration.
- **3 Synthesized Revelations**:
  - **Revelation I — The Harmonic Anomaly**: Unlocks reactor harmonic damping (`-15%` thermal accumulation, `+10 kW` capacity).
  - **Revelation II — Protocol Zero-Nine**: Unlocks scrubber purge optimization (`+20%` $O_2$ generation and $CO_2$ scrubbing efficiency).
  - **Revelation III — The Last Engineer's Directive**: Unlocks Commander Hayes's clearance code (`7394-OMEGA`), clears quarantine lockouts, and boosts thruster efficiency (`1.25x`).

---

## Controls

| Action | Primary Input | Secondary / Laptop Input |
| :--- | :--- | :--- |
| **Move** | `W` `A` `S` `D` | `Arrow Keys` |
| **Sprint** | `Shift` (Hold) | `Shift` (Hold) |
| **Look / Aim** | `Mouse Look` | `Arrow Keys` / `PageUp` / `PageDown` |
| **Interact** | `E` | `Enter` / `Left Click` |
| **Equip Scanner** | `1` | `1` (Left Click to Scan / Decrypt) |
| **Equip Multitool** | `2` | `2` (Toggle Mode with `Q`) |
| **Equip Spare Fuse** | `3` | `3` |
| **Equip Battery Cell** | `4` | `4` |
| **Tactical Schematic Map** | `M` | `M` |
| **Tactical INFO Dashboard** | `Tab` / `Esc` | `Info Button` (Top-Right / Bottom-Left) |

---

## Technical Specifications

- **Engine Version**: Godot Engine 4.7.2 Stable (Forward+ / Mobile compatible)
- **Language**: 100% Native GDScript
- **Hardware Profile**: Optimized for stable 60 FPS on integrated graphics (Intel UHD / 8GB RAM) using procedural BoxMesh/CylinderMesh geometry and PBR materials.
- **Audio Engine**: Custom procedural 16-bit PCM waveform synthesis (`AudioStreamWAV`) for zero external audio asset bloat.
- **Automated Test Suite**: 877 automated assertions across 38 unit and integration test suites with zero external test framework dependencies.

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.  
Copyright (c) 2026 Oldest_dream08.

---
