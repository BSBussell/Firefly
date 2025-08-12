---
applyTo: '**'
---

# Firefly Project - AI Development Guidelines

## Project Overview

**Firefly** is a sophisticated 2D pixel-art platformer built in Godot 4.2.2 featuring a firefly character (Flyph) with dynamic glow mechanics, complex movement states, and multi-level progression. The game targets summer 2025 release and emphasizes precise platforming with visual spectacle.

### Core Game Mechanics
- **Glow System**: Central mechanic where player gains "glow points" through speed/movement, progressing through 3 movement levels with different physics properties
- **State-Based Movement**: 7 distinct movement states (Grounded, Aerial, Wall, Sliding, Gliding, Water, Wormed) each with unique physics
- **Dynamic Resolution**: Pixel-perfect rendering at 320x180 base resolution with scalable UI overlay at 1920x1080
- **Collection Mechanics**: Jars and gems as primary collectibles with persistent tracking across levels

## Architecture Overview

### Core Systems Architecture

#### 1. Dual Viewport System (`Core/Game/GameViewer.gd`)
```
GameViewer (Node2D)
├── LevelLoader (SubViewportContainer) - Game content at 320x180
│   └── GameViewPort (SubViewport) - Pixel-perfect game rendering
└── UILoader (SubViewportContainer) - UI overlay at 1920x1080
    └── UIViewPort (SubViewport) - Scalable UI rendering
```

**Key Responsibilities:**
- Resolution scaling and aspect ratio management
- Window mode switching (windowed/fullscreen)
- Real-time zoom controls (0.5x to 1.4x scale)
- Cross-platform display compatibility

#### 2. Global Singleton System (13 Autoloaded Managers)
```
Core Globals:
├── _globals.gd - Central references (ACTIVE_PLAYER, ACTIVE_LEVEL, etc.)
├── _loader.gd - Level loading with threading + loading screens
├── _persist.gd - Save/load system with callable registration
├── _viewports.gd - Viewport reference management
├── _config.gd - Settings and configuration management
├── _stats.gd - Game statistics and timing
├── _audio.gd - Audio management and effects
├── _debug.gd - Debug utilities and quick-save system
├── _logger.gd - Logging system (replace scattered print statements)
├── _jar_tracker.gd - Collectible tracking across levels
├── _meta.gd - Build information and metadata
├── _discord.gd - Discord Rich Presence integration
└── _gerblesh.gd - Utility math functions
```

#### 3. Level Management System
```
Level (Base Class)
├── PLAYER: Flyph - Player character reference
├── jar_manager: JarManager - Collectible spawn/tracking
├── gem_manager: GemManager - Gem system management
├── ui_components: Array[PackedScene] - Level-specific UI
└── spawn_points: SpawnPoints[] - Player respawn locations
```

**Level Loading Flow:**
1. `_loader.load_level()` initiates threaded loading
2. Loading screen displays during asset preparation
3. Current level cleanup via `level_free` signal
4. New level instantiation with spawn point positioning
5. UI component dependency injection and connection
6. Persistence system data restoration

#### 4. Player System (`Scripts/Player/Flyph.gd`)

**WARNING: This is the largest file (1400+ lines)**

**Movement States (State Machine):**
```
PlayerStateMachine
├── Grounded - Ground movement, friction, jumping
├── Aerial - Air physics, wall jump grace periods
├── Wall - Wall sliding, wall jumping (3 types)
├── Sliding - Crouching, slope sliding
├── Gliding - Wing-based flight mechanics
├── Water-ed - Underwater physics modifications
└── Wormed - Rope/climbing mechanics
```

**Key Components:**
- `GlowManager` - Handles glow progression and visual effects
- `MovementData` resources - Physics parameters per glow level
- State-specific physics calculations (jump arcs, friction, acceleration)
- Visual systems (squish effects, particles, wing trails)

#### 5. UI Component System (`Scripts/UI/UIComponent.gd`)

**Dependency Injection Pattern:**
```gdscript
# UI components declare dependencies
func define_dependencies() -> void:
    define_dependency("DialogueUiComponent", null)
    define_dependency("JarCounter", null)

# System auto-wires dependencies by class name
func connect_dependency(dep: UiComponent) -> void:
    dependencies[get_script_class_name(dep)] = dep
```

**UI Hierarchy:**
```
GlobalThemer (Control)
└── [Dynamic UI Components per level]
    ├── DialogueUiComponent - In-game dialogue system
    ├── JarCounter - Collectible display
    ├── GameTimer - Level timing
    ├── PauseMenu - Game pause interface
    └── [Level-specific components]
```

## Development Guidelines

### Code Organization Standards

#### File Structure Conventions
```
Core/ - Core game systems and managers
├── Game/ - GameViewer, loaders, UI management
├── CustomUIElements/ - Reusable UI components
└── GrassLevel/ - Level-specific core elements

Scripts/ - All GDScript files organized by domain
├── Globals/ - Singleton autoload scripts
├── Player/ - Player character and states
├── Level/ - Level management and transitions
├── UI/ - User interface components
├── Camera/ - Camera system and states
└── [Domain-specific folders]

Scenes/ - Scene files organized by type
├── Player/ - Player character scenes
├── Levels/ - Game level scenes
├── UI_Elements/ - Interface scenes
└── [Component scenes]

Assets/ - Game assets organized by type
├── Graphics/ - Sprites, textures, UI elements
├── Audio/ - Music, SFX, voice
├── Shaders/ - Custom shader files
└── [Other asset types]
```

#### Class Naming Conventions
- **Player Character**: `Flyph` (main player class)
- **Base Classes**: `Level`, `UiComponent`, `PlayerState`
- **Managers**: `[Domain]Manager` (JarManager, GemManager)
- **Globals**: `_[domain].gd` (underscore prefix for autoloads)
- **States**: Descriptive names (Grounded, Aerial, Gliding)

### Physics and Movement Constants

#### Base Game Constants
```gdscript
const BASE_RENDER: Vector2i = Vector2i(320, 180)  # Core game resolution
const BASE_UI_RENDER: Vector2i = Vector2i(1920, 1080)  # UI overlay resolution
const TILE_SIZE: int = 16  # Base tile size for calculations
```

#### Movement System
- **Movement Data Resources**: Store physics parameters per glow level
- **State Machine**: Each state handles its own physics and transitions
- **Projectile Motion**: Calculated jump arcs with configurable rise/fall times
- **Wall Mechanics**: 3 types of wall jumps (neutral, upward, downward)

### Save System Architecture

#### Persistence Pattern
```gdscript
# Registration during _ready()
func _ready():
    var save_func: Callable = Callable(self, "save_data")
    var load_func: Callable = Callable(self, "load_data")
    _persist.register_persistent_class("ClassName", save_func, load_func)

# Implementation pattern
func save_data() -> Dictionary:
    return {"property": value, "state": current_state}

func load_data(data: Dictionary) -> void:
    property = data.get("property", default_value)
    current_state = data.get("state", default_state)
```

#### Save Data Flow
1. Level transition triggers `_persist.save_values()`
2. All registered classes serialize their state
3. Data written to `user://saves/` directory
4. New level loads and calls `_persist.load_values()`
5. All registered classes restore their state

### Performance Considerations

#### Known Performance Areas
- **GameViewer**: Complex resolution calculations - consider caching
- **Player Physics**: Heavy calculations per frame - profile regularly
- **Shader Usage**: Extensive custom shaders - monitor GPU performance
- **Particle Systems**: Multiple concurrent particle effects - manage counts

#### Optimization Guidelines
- Use `call_deferred()` for non-critical operations
- Cache frequently accessed global references
- Pool particle effects and temporary objects
- Profile physics calculations in complex levels

### Platform-Specific Notes

#### Current Platform Issues
- **macOS**: Hardcoded workaround for Silicon Mac displays (needs improvement)
- **Linux**: Window scaling requires fullscreen flush workaround
- **Web**: Special handling for HTML5 exports in window management

#### Cross-Platform Considerations
- Avoid hardcoded screen size assumptions
- Test resolution scaling on various aspect ratios
- Validate input handling across different devices
- Consider mobile/controller input future-proofing

### Debugging and Development Tools

#### Debug Systems
- **Quick Save/Load**: F5/F6 for rapid iteration (`_debug.gd`)
- **Glow Level Debug**: Up/Down arrows to change movement levels
- **Resolution Scaling**: +/- keys for real-time zoom testing
- **Logger System**: Use `_logger` instead of scattered `print()` statements

#### Development Workflow
- **Loading Screens**: Automatic during level transitions
- **Error Handling**: Mix of error returns and print statements (needs standardization)
- **Config System**: Settings managed through `_config.gd` singleton

### Current Technical Debt

#### Known Issues to Address
1. **Large Files**: `Flyph.gd` (1400+ lines), `GameViewer.gd` (400+ lines)
2. **Debug Statements**: 100+ scattered `print()` calls need cleanup
3. **Platform Hacks**: Hardcoded fixes for specific systems
4. **Magic Numbers**: Resolution calculations scattered throughout code
5. **Error Handling**: Inconsistent patterns across codebase

#### Refactoring Priorities
1. Extract player components from monolithic `Flyph.gd`
2. Centralize resolution management in dedicated system
3. Implement consistent error handling patterns
4. Replace debug prints with proper logging system
5. Create configuration resources for magic numbers

### Best Practices for AI Assistance

#### When Suggesting Code Changes
- **Respect Architecture**: Work within existing patterns (state machines, singletons, UI components)
- **Maintain Style**: Follow established naming conventions and file organization
- **Consider Performance**: This is a real-time game targeting 60fps
- **Test Integration**: Ensure changes work with complex interconnected systems
- **Preserve Features**: Don't break existing glow mechanics, save system, or level transitions

#### When Reviewing Code
- Check for proper singleton usage via `_globals` references
- Verify state machine transitions follow established patterns
- Ensure UI components properly declare dependencies
- Validate persistence system integration for new features
- Consider impact on resolution scaling and cross-platform compatibility

#### Common Development Tasks
- **Adding New Levels**: Extend `Level` base class, configure spawn points, set UI components
- **Player Abilities**: Add states to state machine, update physics calculations
- **UI Features**: Create `UiComponent` subclass, declare dependencies, add to level
- **Collectibles**: Integrate with `JarManager`/`GemManager` and persistence system
- **Audio**: Use `_audio` singleton for consistent audio management

### Version Control and Build Notes
- **Engine**: Godot 4.2+ (gl_compatibility renderer for broad support)
- **Target Platforms**: Windows, macOS, Linux, Web
- **Release Timeline**: Fall 2025 target
- **Asset Pipeline**: Custom UI themes, extensive shader usage
- **Build Config**: Custom user directory, HDR 2D enabled, pixel-perfect settings

This documentation should be referenced for all code suggestions, architectural decisions, and feature implementations to maintain consistency with the existing sophisticated but complex codebase.