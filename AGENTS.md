# Workplace Battle Royale - AI Agent Guide

## Project Overview

**Workplace Battle Royale: The Last Worker** (《职场大逃杀：最后打工人》) is a Roguelike strategy survival game with a modern workplace theme.

| Property | Value |
|----------|-------|
| Engine | Godot 4.6 |
| Scripting | GDScript |
| Project Type | 2D Strategy Card Game |
| Main Scene | `menu.tscn` |
| Target Platforms | PC / Steam / Mobile (later) |

### Core Concept
Players take on the role of an ordinary office worker competing for survival in an "HC (Headcount)紧缩" environment. The game combines:
- Auto-chess style "circle shrinking" elimination mechanics
- Card-based strategic combat system
- Roguelike "Hex" (Hextech) power-up system

### Core Experience
- **Tension**: Quarterly headcount reduction pressure
- **Strategy Depth**: Hex combinations + workplace strategy card decks
- **Randomness**: Different Hex and events each round
- **Dark Humor**: Workplace memes and real-world satire

---

## Technology Stack

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| **Game Engine** | Godot | 4.2+ | Core game development |
| **Scripting** | GDScript | - | Game logic |
| **Data Storage** | SQLite + JSON | - | Local save + config |
| **Version Control** | Git + Git LFS | - | Code + asset management |
| **CI/CD** | GitHub Actions | - | Auto build |
| **Testing** | GUT | 9.0+ | Unit testing |
| **Publishing** | itch.io / Steam | - | Test/Official release |

### Why Godot?
- **Lightweight**: ~40MB download, fast startup
- **Open Source**: MIT license, no copyright concerns
- **GDScript**: Python-like, frontend-engineer friendly
- **2D First**: Mature 2D toolchain perfect for card games
- **Built-in Networking**: Easy multiplayer expansion
- **Node System**: Component-based, React-like architecture
- **One-click Export**: PC/Mac/Linux/Web/Mobile

---

## Project Structure

### Current Structure
```
.
├── project.godot          # Main project configuration
├── menu.tscn              # Main entry scene (Node2D)
├── icon.svg               # Project icon
├── icon.svg.import        # Godot import settings
├── .editorconfig          # Editor configuration
├── .gitignore             # Git ignore rules
├── .gitattributes         # Git line ending normalization
└── .godot/                # Godot internal cache (auto-generated)
```

### Planned Structure (to be implemented)
```
res://
├── autoload/              # Global singletons (AutoLoad)
│   ├── GameManager.gd    # Game state management
│   ├── PlayerData.gd     # Player data persistence
│   ├── Config.gd         # Configuration
│   ├── SaveManager.gd    # Save system
│   ├── EventBus.gd       # Global event bus
│   └── AudioManager.gd   # Audio management
│
├── core/                  # Pure game logic (unit testable)
│   ├── game_core.gd      # Core loop
│   ├── turn_manager.gd   # Turn management
│   ├── player.gd         # Player entity
│   ├── department.gd     # Department system
│   ├── profession.gd     # Profession definitions
│   ├── level_system.gd   # Level/rank system
│   ├── economy.gd        # Economy system
│   ├── elimination.gd    # Elimination mechanics
│   ├── card/             # Card system
│   ├── hex/              # Hex (Hextech) system
│   └── ai/               # AI system
│
├── resources/             # Configuration data
│   ├── cards/            # Card configs (JSON)
│   ├── hex/              # Hex configs (JSON)
│   ├── professions/      # Profession configs
│   ├── events/           # Random events
│   └── localization/     # Translations
│
├── scenes/                # Scenes (UI)
│   ├── main_menu/        # Main menu
│   ├── character_select/ # Character selection
│   ├── game/             # Main game scenes
│   └── components/       # Reusable components
│
├── assets/                # Game assets
│   ├── images/           # Images
│   ├── fonts/            # Fonts
│   ├── audio/            # Audio (BGM/SFX)
│   └── shaders/          # Shaders
│
├── tests/                 # Unit tests (GUT)
├── plugins/               # Third-party plugins
├── export/                # Export configs
└── docs/                  # Documentation
```

---

## Game Systems

### Core Mechanics

#### 1. Dual Resource System
| Resource | Description |
|----------|-------------|
| **Health (HP)** | Starts at 100, hidden from others. Consumed by overtime, traps, hunger. Restored by food/items. |
| **Performance (KPI)** | Calculated monthly from work output + Hex bonuses. Resets quarterly. Hidden until quarterly settlement. |

#### 2. Salary System
- **Visibility**: Private (only visible to self)
- **Inheritance**: Permanent, never resets
- **Initial Salary**: Determined by rank (P1-P12)
- **Usage**: Buy food (HP recovery), strategy cards, special skills

#### 3. Rank System (P1-P12)
| Tier | Ranks | Population | Initial Salary | Strategy Cards |
|------|-------|------------|----------------|----------------|
| Junior | P1-P3 | 50% | Low | 3 cards |
| Backbone | P4-P6 | 30% | Medium | 4 cards |
| Expert | P7-P9 | 15% | High | 5 cards |
| Executive | P10-P12 | 5% | Very High | 6 cards |

#### 4. Time System
| Cycle | Events |
|-------|--------|
| **Monthly** | HP deduction → Action phase → Work output → Salary settlement → Shop |
| **Quarterly** | Performance reset → HC review (shrink + elimination) → Promotion review → Draw Hex |
| **Yearly** | Special events (layoff wave, merger, etc.) |

### Profession System

| Profession | Position | Core Feature |
|------------|----------|--------------|
| **Programmer** | Tech Core | High performance output, low social, prone to burnout |
| **HR Admin** | Interpersonal Manipulation | Information advantage, trap expert, medium performance |
| **Finance** | Economic Control | Salary bonus, resource control, conservative |
| **Operations** | All-rounder | Balanced development, adaptable, no weaknesses |
| **Sales** | High Risk High Return | Performance fluctuation, social dominance, stress resistant |

### Hex (Hextech) System

#### Rarity Levels
| Rarity | Color | Chance | Feature |
|--------|-------|--------|---------|
| Common | White | 60% | Basic effects, stable |
| Rare | Blue | 30% | Strong effects, side effects |
| Epic | Purple | 9% | Powerful, gameplay changing |
| Legendary | Gold | 1% | Core build, game-defining |

#### Categories
- **Survival**: HP recovery, damage reduction
- **Performance**: KPI boost, work efficiency
- **Strategy**: Information gathering, trap enhancement
- **Economy**: Salary boost, shop discounts

### Card System

#### Card Types
| Type | Description |
|------|-------------|
| **Work Cards** | Normal work, overtime, slacking |
| **Trap Cards** | Frame colleagues (blame, report, steal credit) |
| **Alliance Cards** | Form alliances, mutual assistance |
| **Special Cards** | Job hop (alt victory), labor arbitration, etc. |

### AI Types
| Type | Characteristic |
|------|----------------|
| Grinder | High performance, low HP |
| Wellness | High HP, low performance |
| Deceiver | Medium stats, loves traps |
| Social | Loves alliances, low betrayal |
| Promotion-focused | Pursues high rank |
| Lurker | Hides strength, bursts at key moments |

### Victory Conditions
| Victory Type | Condition |
|--------------|-----------|
| Standard | Last one standing |
| Financial Freedom | Have "Wealth Freedom" Hex + 5000+ salary |
| Job Hop | Use "Job Hop Opportunity" card |
| Arbitration | Eliminate 5+ with "Labor Arbitration" |
| Pacifist | No traps, survive on performance only |
| P12 Legend | Reach P12 and survive |
| Lurker Master | Stay P1-P3, win in the end |

---

## Art & Visual Style

### Visual Direction
- **Theme**: Late-night office (blue-purple tones)
- **UI Style**: Flat design + workplace meme emoticons
- **Characters**: Q-version office workers, customizable

### Color Palette
| Element | Color |
|---------|-------|
| Primary | Deep blue-purple (#1a1a2e, #16213e) |
| Accent | Neon blue (#0f4c75), Orange (#f39c12) |
| Common (Hex) | White/Gray |
| Rare (Hex) | Blue |
| Epic (Hex) | Purple |
| Legendary (Hex) | Gold |

### Profession Visuals
| Profession | Visual Traits | Color |
|------------|---------------|-------|
| Programmer | Glasses, plaid shirt, coffee | Blue-green |
| HR | Formal wear, folder, smile | Purple |
| Finance | Glasses, calculator, serious | Dark blue |
| Operations | Casual wear, data charts | Orange |
| Sales | Suit, phone, confident | Red |

### Recommended Free Asset Sources
- **Kenney Assets** (CC0): UI packs, card templates, characters
- **Game-icons.net** (CC-BY): Status icons
- **Unsplash**: Background photos
- **OpenGameArt**: Various 2D assets

---

## Development Setup

### Prerequisites
- **Godot 4.6** installed (located at `/Applications/Godot.app` on macOS)
- Git for version control

### Opening the Project
1. Launch Godot Engine
2. Click "Import" and navigate to the `project.godot` file
3. Alternatively, open directly with: `godot --editor --path /Users/Zhuanz/workplace-battle-royale`

### Running the Project
From Godot Editor:
- Press F5 or click the Play button to run the main scene

From Command Line (if Godot is in PATH):
```bash
godot --path /Users/Zhuanz/workplace-battle-royale
```

---

## Code Style Guidelines

### File Organization
- Scene files (`.tscn`) should be placed in logical folders (`scenes/`, `ui/`, `levels/`)
- Script files (`.gd`) should be co-located with their scenes or organized in a `scripts/` folder
- Assets should be organized by type: `assets/sprites/`, `assets/audio/`, `assets/fonts/`, etc.

### GDScript Conventions
- Follow the [official GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- Use `snake_case` for variables and functions
- Use `PascalCase` for class names and node names
- Use `UPPER_SNAKE_CASE` for constants
- Indent with tabs (Godot default)

### Scene Organization
- Name root nodes descriptively (e.g., `MainMenu`, `Player`, `GameLevel`)
- Use unique names for nodes that need to be referenced in code (`unique_name_in_owner = true`)
- Group related nodes under appropriate parent nodes

---

## Version Control

### What's Tracked
- All `.tscn`, `.tres`, `.gd`, `.cs` files
- `project.godot`
- `icon.svg` and other assets
- Configuration files (`.editorconfig`, `.gitattributes`)
- All files in `doc/` directory

### What's Ignored
- `.godot/` - Engine cache and temporary files
- `/android/` - Android build output

### Important Notes
- **Never commit the `.godot/` folder** - it contains machine-specific cache data
- Scene files are text-based and merge-friendly
- Binary assets (images, audio) should use Git LFS if the repository grows large

---

## Development Roadmap

### MVP (3 months)
- [ ] Core dual resource system (monthly HP deduction + quarterly performance reset)
- [ ] 20 Hex technologies
- [ ] 15 workplace strategy cards
- [ ] Basic AI colleagues
- [ ] Single game flow

### Full Version (6 months)
- [ ] 80+ Hex technologies
- [ ] 40+ workplace strategy cards
- [ ] Multiple AI types
- [ ] Achievement system
- [ ] Data statistics

### Multiplayer Version (12 months)
- [ ] Online PvP (4-8 players)
- [ ] Season system
- [ ] Spectator mode
- [ ] Custom rooms

---

## Resources

### Documentation
- [Godot 4.6 Documentation](https://docs.godotengine.org/en/4.6/)
- [GDScript Reference](https://docs.godotengine.org/en/4.6/tutorials/scripting/gdscript/index.html)
- [Scene Organization Best Practices](https://docs.godotengine.org/en/4.6/tutorials/best_practices/scene_organization.html)

### Project Documents
- `doc/游戏策划案_职场大逃杀_完整版.md` - Complete game design document
- `doc/技术栈选型_职场大逃杀.md` - Technical stack selection
- `doc/美术资源推荐_职场大逃杀.md` - Art asset recommendations

---

*Last Updated: 2026-03-25*
