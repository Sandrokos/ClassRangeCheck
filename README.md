I missed my range detection weakaura, so I threw this together as a learning exercise. 
CHATGPT was used in it's creation, if you find any bugs or issues please open an issue. 

# ClassRangeCheck (CRC)

ClassRangeCheck (CRC) displays a clear on screen warning when your target is out of range for your current specialization’s ability.

Each specialization can use a different spell so melee, ranged, and healer specs all work correctly.

## Features

Spec based range detection
Automatically detects your specialization and checks range using a configurable spell.

Custom warning display
Choose how the warning appears:

Text with adjustable size and color
Icon using UI textures - WIP

Movable warning frame
Unlock the warning display and drag it anywhere on screen.

Per spec configuration
Enable or disable specs and select the spell used for the range check.

Lightweight
Minimal CPU usage with a configurable update interval.

## Commands

/crc /classrangecheck
Open the configuration menu

/crc reset
Reset settings to defaults
