# GateGuardian Usage Examples

This enhanced GateGuardian extends DialogueArea2D while maintaining compatibility with existing dialogue files. It adds persistence, dynamic dialogue selection, and shared guardian awareness.

## Key Features:

### 1. **Persistent Conversations**
- Remembers if player has talked before
- Tracks conversation count
- Adds return greetings as NEW dialogue lines (not modifying existing ones)

### 2. **Shared Guardian Awareness**
- Tracks how many other guardians the player has encountered
- Adds contextual comments about "others like me"
- Different responses for meeting 1 vs multiple other guardians

### 3. **Dynamic Dialogue Selection**
- Automatically chooses between `gate_dialog` and `pass_dialog` based on jar count
- Prepends personalized lines for returning players and guardian awareness

### 4. **Modular Signal System**
- `player_can_pass()` - Emitted when player has enough jars
- `player_denied_passage()` - Emitted when player lacks jars
- `guardian_talked_to(talk_count, jar_count)` - Emitted on every interaction

## Example Dialogue Flow:

### First Visit (0 jars):
```
"I am the guardian of this gate."
"To pass through, you must prove your worth..."
```

### Return Visit (5 jars, no other guardians met):
```
"Hello again, traveler."
"I see you've been busy collecting more jars."
"I am the guardian of this gate."
"To pass through, you must prove your worth..."
```

### Return Visit (15 jars, met 1 other guardian):
```
"Back so soon?"
"You're getting closer to your goal."
"What others like me? I don't know what you're talking about."
"I am the guardian of this gate."
"To pass through, you must prove your worth..."
```

### Return Visit (15 jars, met 3+ other guardians):
```
"Good to see you again!"
"Almost there! Keep up the good work."
"Wait... you've spoken to more of us? How many are there?"
"I am the guardian of this gate."
"To pass through, you must prove your worth..."
```

## Setup in Editor:

1. **Set Export Variables:**
   ```gdscript
   required_jars = 20
   gate_dialog = "res://Assets/DialogueData/GG/gate_dialogue.json"
   pass_dialog = "res://Assets/DialogueData/GG/pass_dialogue.json"
   guardian_type = "gate_guardian"  # Unique identifier for this type of guardian
   ```

2. **Customize Guardian-Specific Dialogue:**
   ```gdscript
   return_greetings = [
       "Welcome back, friend!",
       "Oh, it's you again!",
       "Hello there, traveler!"
   ]
   
   other_guardian_comments = [
       "Others like me? That's impossible!",
       "You speak of mysteries, traveler.",
       "I know of no others with my duty."
   ]
   
   multiple_guardian_comments = [
       "This news troubles me greatly...",
       "How many of us are there?",
       "Something is not right about this."
   ]
   ```

## Creating Different Guardian Types:

Each guardian can have its own type for unique tracking:

```gdscript
# Forest Guardian
guardian_type = "forest_guardian"
other_guardian_comments = [
    "Other forest guardians? The trees have said nothing...",
    "You speak of mysteries unknown to the woodland spirits."
]

# Mountain Guardian  
guardian_type = "mountain_guardian"
other_guardian_comments = [
    "Others who guard the peaks? The stone speaks of none.",
    "The mountains keep their secrets well, it seems."
]
```

## Connecting to Other Objects:

Same as before - the signal system remains unchanged:

```gdscript
func _ready():
    var guardian = $GateGuardian
    var gate_collider = $Gate/CollisionShape2D
    
    # Connect guardian to gate collider
    guardian.player_can_pass.connect(func(): gate_collider.disabled = true)
    
    # Track guardian interactions across the game
    guardian.guardian_talked_to.connect(_on_any_guardian_interaction)

func _on_any_guardian_interaction(talk_count: int, jar_count: int):
    print("Guardian interaction: ", talk_count, " talks, ", jar_count, " jars")
    # Could trigger achievements, update UI, etc.
```

## Global Guardian Data:

The system automatically tracks:
- Total number of unique guardians encountered
- Guardian types for cross-referencing
- Persistent data across game sessions

This creates a living world where guardians become aware of the player's journey and other encounters, making each conversation feel more connected to the overall game experience.
