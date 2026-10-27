# ORBITAL: The Last Engineer

[![Godot Engine](https://img.shields.io/badge/Godot_Engine-v4.7.2-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Automated Tests](https://img.shields.io/badge/Automated_Tests-1033_PASSED-brightgreen.svg)]()
[![Game Modes](https://img.shields.io/badge/Game_Modes-Feel_%7C_Logical-9cf.svg)]()
[![Controls](https://img.shields.io/badge/Controls-Mouse_360%C2%B0_%7C_Arrow_Keys-orange.svg)]()
[![Platform](https://img.shields.io/badge/Platform-Windows_PC-blue.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> *"The ship is not a collection of rooms with decorative props. It is one interconnected machine."*

**ORBITAL: The Last Engineer** is a first-person 3D science-fiction spacecraft engineering, survival, and psychological horror game built in **Godot Engine 4.7.2** (100% native GDScript).

As the Lead Engineer docking at the orbital *Astraea Biological Research Facility*, you discover the station dark, the primary fusion generators tripped, atmospheric scrubbers offline, and the entire research crew dead. An unauthorized genetic experiment in the lower containment sector has unleashed an apex biological predator that stalks the vessel. You must restore the station's dying systems, investigate the tragedy through environmental clues, withstand the hunt, and tactically lure the entity into a containment chamber before purging it with lethal decontamination gas.

---

## 🎮 Dual Experience Modes

To deliver both a cinematic narrative journey and an exacting systems simulator, *ORBITAL* features two dedicated gameplay modes switchable at any time from the Main Menu or Pause Settings:

```
                    ┌──────────────────────────────────────────────┐
                    │               GAME EXPERIENCE                │
                    └──────────────────────┬───────────────────────┘
                                           │
                 ┌─────────────────────────┴─────────────────────────┐
                 ▼                                                   ▼
     ┌───────────────────────┐                           ┌───────────────────────┐
     │       FEEL MODE       │                           │     LOGICAL MODE      │
     │ (Atmospheric Horror)  │                           │  (Hard Sci-Fi Sim)    │
     ├───────────────────────┤                           ├───────────────────────┤
     │ • Clean, minimal HUD  │                           │ • Live telemetry HUD  │
     │ • Pure tension & dread│                           │ • Engineering metrics │
     │ • Streamlined pause UI│                           │ • Full diagnostic logs│
     │ • Direct goal focus   │                           │ • Physical equations  │
     └───────────────────────┘                           └───────────────────────┘
```

### 1. Feel Mode (Atmospheric & Narrative Focus)
- **Cinematic Immersion**: Tailored for players who want to experience the atmosphere, exploration, and visceral sci-fi horror without cognitive overload from complex technical telemetry.
- **Minimalist HUD**: Gauges and scientific formulas are hidden, surfacing only vital suit integrity, oxygen reserve status, inventory counts, and the immediate mission objective.
- **Uncluttered Operations**: The pause screen removes raw subsystem graphs and data matrices, keeping the focus squarely on story progression and survival.

### 2. Logical Mode (Hard Sci-Fi Engineering Simulation)
- **Deep Technical Telemetry**: Designed for hardcore engineering and systems simulation fans.
- **Live Diagnostics**: Complete atmospheric telemetry ($O_2$ partial pressure, $CO_2$ ppm toxicity, temperature gradients, barometric pressure), electrical load curves, and coolant thermal throttling metrics.
- **Full Operational Dossier**: Pause interface unlocks comprehensive technical slates, circuit routing diagrams, and environmental science logs.

---

## 👁️ 360° Viewing & Adaptive Controls

- **Free 360° Mouse Look**: Full orbital camera rotation with mouse capture, fine smoothing, and adjustable sensitivity.
- **Keyboard / Laptop Navigation**: Full support for arrow keys and keyboard pan for players on trackpads or laptops.
- **Instant Configuration**: Seamlessly toggle between mouse look and arrow-key viewing from the Settings menu or in-game pause screen.

---

## 👾 The Apex Predator: Alien Stalker & Horror Mechanics

```
               [ 4 Core Repairs Complete ]
                            │
                            ▼
               [ Environmental Vibrations ]
               (Tremors, flickering lighting)
                            │
                            ▼
               [ Apex Predator Emergence ]
                            │
            ┌───────────────┴───────────────┐
            ▼                               ▼
    [ Open Chambers ]               [ Safe Room Sanctuary ]
    (Autonomous pursuit,            (Airtight bulkheads,
     duct crawling, bypass)          zero stalker detection)
            │                               │
            ▼                               ▼
    [ 3-Hit Lethal Combat ]          [ Tactical Regrouping ]
    (Camera trauma, shake)
            │
            ▼
    [ Lure to Airlock Chamber ]
            │
            ▼
    [ Decontamination Gas Purge ]
```

### 1. Paced Emergence
The apex stalker remains dormant in the lower containment sector during initial station repairs. This gives the player space to explore the darkened vessel, learn its layout, and restore basic power before the threat awakens.

### 2. Vibration Alerts & Awakening
Upon completing all four core subsystem repairs (Primary Fusion Generator, Distribution Bus, Life Support Scrubbers, and Communications Array), low-frequency environmental tremors, sub-bass audio cues, and lighting flickers alert the player that the predator has broken containment and begun hunting.

### 3. Safe Room Sanctuary
The **Research Observatory** serves as an impenetrable safe haven. When the player retreats inside and seals the bulkheads, the alien cannot detect, enter, or attack the player, providing a tactical sanctuary to check schematics and plan movement.

### 4. 3-Hit Lethal Combat & Violent Screen Trauma
To eliminate frustrating instant-kill mechanics while maintaining peak tension, encounters feature a multi-stage damage system:
- **Hit 1 (35% Damage)**: Sharp impact cue, red directional blood vignette, and moderate camera trauma.
- **Hit 2 (70% Cumulative Damage)**: Heavy trauma surge, critical health warnings, and severe camera screen shaking.
- **Hit 3 (Fatal Blow)**: Lethal claw takedown triggering the player death scream and terminal creature fatality sequence.

### 5. Autonomous Stalker AI
- **Dynamic Deck Routing**: Traverses both Deck 1 and Lower Subdeck using spatial waypoints, circumventing large machinery like the fusion turbine.
- **Door Unlocking**: The entity unlatches and forces open standard doors in its path, preventing players from easily trapping it behind normal bulkheads.
- **Proximity Audio**: Spatial proximity audio detection emits guttural clicks, duct scrapes, and bass rumbles whenever the stalker is within 9 meters.

### 6. The Tactical Purge
The stalker cannot be killed with handheld tools. The player must lure the entity into the dual-door **Airlock Chamber** (`AirlockInner`, `AirlockOuter`), seal the bulkheads, and activate the physical **Decontamination Poison Gas Valve** to flood the chamber with toxic gas and eliminate the specimen.

---

## 🚢 Interconnected Ship Architecture

The *Astraea* features 13 explorable, fully sealed, and physically connected compartments spanning two structural decks:

```
                            DECK 1 (UPPER DECK)
 ┌──────────────────────┐   ┌──────────────────────┐   ┌──────────────────────┐
 │ Research Observatory │◄──┤    Command Bridge    ├──►│     Avionics Bay     │
 │  (Panoramic Dome)    │   │  (Armored Cockpit)   │   │  (Optical Server Bus)│
 └──────────────────────┘   └──────────┬───────────┘   └──────────────────────┘
                                       │
                            ┌──────────┴───────────┐
                            │   Central Corridor   │
                            │ (Spine Thoroughfare) │
                            └──────────┬───────────┘
                                       │
         ┌─────────────────────────────┼─────────────────────────────┐
         ▼                             ▼                             ▼
┌──────────────────┐          ┌──────────────────┐          ┌──────────────────┐
│  Crew Quarters   │          │   Life Support   │          │ Medical Infirmary│
│(Living Bunks/O2) │          │(Scrubbers/Manif.)│          │ (Surgical Suite) │
└──────────────────┘          └────────┬─────────┘          └──────────────────┘
                                       │
         ┌─────────────────────────────┴─────────────────────────────┐
         ▼                                                           ▼
┌──────────────────┐                                        ┌──────────────────┐
│  Main Cargo Bay  │                                        │  Airlock Chamber │
│ & Annex Repairs  │                                        │ (Gas Purge Trap) │
└────────┬─────────┘                                        └──────────────────┘
         │
         ▼ (Maintenance Crawlway Bypass - Decompression Hazard)
         │
┌──────────────────┐
│ Engineering Bay  │
│ (Fusion Turbine) │
└────────┬─────────┘
         │
         ▼ (Subdeck Ramp Incline)
════════════════════════════════════════════════════════════════════════════════
                            DECK 2 (LOWER DECK)
┌──────────────────────────────────────┐    ┌──────────────────────────────────┐
│           Reactor Subdeck            ├───►│          Specimen Vault          │
│   (Fuel Throttle / Battery Bank)     │    │  (Containment / Incubation Pods) │
└──────────────────────────────────────┘    └──────────────────────────────────┘
```

### Deck 1 (Upper Deck)
1. **Command Bridge**: Reinforced cockpit viewport with structural mullions, navigation holotable, avionics link, and thruster console.
2. **Research Observatory**: Panoramic glass dome overlooking Kepler-442b; acts as the primary safe room sanctuary.
3. **Avionics Bay**: Optical data bus, server stacks, and flight computer relay banks.
4. **Crew Quarters**: Bunks, crew lockers, hydroponics planter, and water recycler pump.
5. **Medical Infirmary**: Bio-diagnostic surgical bed, trauma medical kits, and oxygen booster.
6. **Central Corridor**: High-clearance central spine with motorized bulkheads connecting all main compartments.
7. **Life Support Module**: Solid-state oxygen generator, secondary amine scrubbers, and coolant distribution manifold.
8. **Main Cargo Bay & Aux Cargo Annex**: Heavy cargo pallets, hydraulic hoist, crawlway cargo hatch, auxiliary coolant bypass valve, auxiliary junction repair panel, and salvage cache.
9. **Airlock Chamber & EVA Staging**: Dual-door interlocking airlock (`AirlockInner`, `AirlockOuter`), manual pressure cycle panel, and the physical Decontamination Poison Gas Valve.
10. **Engineering Bay**: 150 kW fusion turbine generator with visible primary breaker unit, main bus breaker, workbench, and supply locker.

### Deck 2 (Lower Deck)
11. **Reactor Subdeck**: Reached via the sloped Subdeck Ramp from Engineering; houses the fuel throttle valve and auxiliary battery bank.
12. **Specimen Vault**: Heavy security bulkhead door (`DoorVault`) and seamless sloped access ramp leading to shattered cryogenic incubation pods with elevated bio-contaminant $CO_2$.
13. **Maintenance Crawlway**: Low-clearance utility transit bypass connecting Cargo Bay to Engineering with an active hull breach decompression hazard ($0.3\text{ kPa/s}$).

---

## 🔧 Hands-On Engineering Toolset

- **Diagnostic Scanner (`[1]`)**: Multichannel scanner that analyzes machinery, circuits, and encrypted data slates for operating efficiency, heat, fault codes, and tool requirements (drains 10% battery per scan).
- **Multitool / Welder (`[2]`)**: 3-mode utility device cycled with `[Q]`:
  - `CALIBRATE`: Electronic relay tuning and circuit alignment.
  - `CUT_WELD`: Metal cutting and hull breach sealing.
  - `TIGHTEN`: High-torque pneumatic clamp fastening.
- **Consumable Supplies**: Spare fuse packs (`[3]`), portable battery cells (`[4]`), replacement filter cartridges, and coolant canisters.
- **Physical Workstations**: Supply lockers for inventory management and engineering workbenches for component inspection and inductive tool recharging.

---

## 🖥️ Polished Glass HUD & Interface

- **Frosted Glass Aesthetic**: Modern, semi-translucent glass panels with subtle cyan accent borders.
- **Vital Telemetry Gauges**:
  - **Suit Integrity (HP)**: Color-coded health bar (100% Green $\to$ <60% Amber $\to$ <30% Flashing Red).
  - **Oxygen Reserve ($O_2$)**: Atmospheric life support meter tracking breathable air in unpressurized or compromised sectors.
- **Dynamic Interactive Reticle**: Default semi-transparent white reticle dot that dynamically enlarges and tints cyan when focused on interactable consoles, valves, or items.
- **Objective Tracker**: High-contrast, top-left task directive clearly displaying the primary mission and immediate actionable step.

---

## ⌨️ Controls & Input Mapping

| Action | Primary Input | Secondary / Laptop Input |
| :--- | :--- | :--- |
| **Move** | `W` `A` `S` `D` | `Arrow Keys` |
| **Sprint** | `Shift` (Hold) | `Shift` (Hold) |
| **Look / Aim (360°)** | `Mouse Look` | `Arrow Keys` / `PageUp` / `PageDown` |
| **Interact / Use** | `E` | `Enter` / `Left Click` |
| **Equip Scanner** | `1` | `1` (Left Click to Scan / Decrypt) |
| **Equip Multitool** | `2` | `2` (Cycle Mode with `Q`) |
| **Equip Spare Fuse** | `3` | `3` |
| **Equip Battery Cell** | `4` | `4` |
| **Ship Schematic Map** | `M` | `M` |
| **Tactical Operations / Pause** | `Tab` / `Esc` | `Info Button` (UI Header) |

---

## 🔬 Technical Architecture & Quality Assurance

```
tests/test_runner.tscn
├── 43 Automated Test Suites
├── 1,033 Passing Assertions
├── 0 Failures / 0 Regressions
└── 100% Headless Execution Support
```

- **Engine**: Godot Engine 4.7.2 Stable (Forward+ / Mobile compatible renderer).
- **Language**: 100% Native GDScript with strict typing.
- **Rendering & Performance**: Clean 60 FPS performance on integrated graphics (Intel UHD / 8GB RAM) through procedural BoxMesh/CylinderMesh geometry and PBR materials.
- **Audio Architecture**: Custom procedural 16-bit PCM waveform synthesis (`AudioStreamWAV`) paired with dedicated high-impact audio samples for footsteps, creature shrieks, and proximity heartbeat cues.
- **Automated Verification**: Comprehensive automated test runner executing in headless mode verifying ship systems, environmental life support, save/load persistence, door physics, alien pathfinding, 3-hit combat, and 360° view controls.

---

## 🚀 Running the Project

### Running in Godot Engine
1. Clone the repository:
   ```bash
   git clone https://github.com/Ghostofzenin08/Orbital-the-last-engineer.git
   ```
2. Open **Godot Engine 4.7.2**.
3. Import the `project.godot` file.
4. Press **F5** (or click **Play**) to launch the game.

### Executing the Headless Automated Test Suite
To run all 1,033 automated unit and integration tests headlessly:
```bash
godot --headless "res://tests/test_runner.tscn"
```

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.  
Copyright (c) 2026 Oldest_dream08.
