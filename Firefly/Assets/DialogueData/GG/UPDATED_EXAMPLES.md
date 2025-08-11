# Updated GateGuardian Examples

## New Features:

### 1. **Jar Count Display**
- Toggle between level jars and total jars with `show_level_jars_only`
- Dynamic jar count insertion in dialogue using templates
- Real-time progress tracking

### 2. **Awkward Bookworm Personality**
- Nervous, enthusiastic, and endearingly dorky
- References to handbooks, paperwork, and organizational systems
- Excited reactions to jar collection progress

### 3. **Template Variables in Dialogue**
Available placeholders:
- `{jar_count}` - Current jar count (level or total based on setting)
- `{required_jars}` - Number of jars needed to pass
- `{remaining_jars}` - Jars still needed
- `{jars_needed}` - Difference from last visit
- `{jar_type}` - "level" or "total" based on setting

## Example Dialogue Flows:

### First Visit (3 total jars, 1 level jar, needs 20):
```
"Let's see here... *squints at clipboard* ...you've got 3 total jars, but I need 20 for passage. That's 17 more to go!"
"Um, hi there! *shuffles through papers nervously* I'm supposed to be the guardian of this gate thingy!"
"So like, according to my very official handbook here... *waves crumpled papers* ...you need to prove your jar-collecting prowess!"
"The rules say you need 20 firefly jars to pass through. It's all very scientific and guardian-y, I promise!"
"Come back when you've got enough glowy things! I'll be here... reading... and guarding... and stuff!"
```

### Return Visit (8 jars, met 1 other guardian):
```
"Oh hey! You're back! That's... that's pretty neat actually!"
"Ooh, I can see you've got 8 jars now! That's 5 more than last time I think? Math is hard..."
"Wait, others like me? That's... that's impossible! I mean, I read all the guardian manuals and there was definitely no mention of... others... OH NO."
"Let's see here... *squints at clipboard* ...you've got 8 total jars, but I need 20 for passage. That's 12 more to go!"
"Um, hi there! *shuffles through papers nervously* I'm supposed to be the guardian of this gate thingy!"
[...rest of dialogue...]
```

### Success Visit (25 jars):
```
"Well well well, if it isn't my favorite jar collector person!"
"MULTIPLE others?! *panicked flipping through papers* This is NOT in the manual! What chapter covers this?!"
"Oh wow! You've got 25 total jars! That's totally enough! *excited shuffling of papers*"
"OH WOW! *drops papers everywhere* You actually did it! You got all the jars!"
"This is so exciting! I've never had someone actually complete the jar quest before!"
[...rest of dialogue...]
```

## Setup Options:

### For Level-Only Jar Requirements:
```gdscript
required_jars = 10
show_level_jars_only = true
```

### For Total Jar Requirements:
```gdscript
required_jars = 50
show_level_jars_only = false
```

### Custom Awkward Dialogue:
```gdscript
return_greetings = [
    "Oh! You're back! *accidentally drops clipboard*",
    "Hey hey hey! My favorite jar person!",
    "Well hello there, jar enthusiast!"
]

progress_comments = [
    "You've got {jar_count} jars now! That's... *counting on fingers* ...yeah, more!",
    "Ooh, {jar_count} shiny jars! Only {remaining_jars} more to go!",
    "Your jar collection has increased by... *frantically checking notes* ...numbers!"
]
```

The guardian now feels like an enthusiastic, slightly overwhelmed bookworm who gets genuinely excited about your progress while maintaining his quirky, nervous personality!
