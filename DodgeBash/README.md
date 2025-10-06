Here is a README.md draft for the DodgeBash game, based on the structure and features of main.sh:

---

# DodgeBash

DodgeBash is a terminal-based mini-game written entirely in Bash. It challenges you to dodge "errors," collect "fixes," and react to "intruder" and "virus" events—all while typing real-world Linux and SysAdmin commands as micro-challenges. It's both a reflex game and a way to practice your command-line skills!

## Features

- **Terminal Graphics:** Uses ANSI colors and optional emoji for a visually engaging experience.
- **WASD Movement:** Navigate your character across the game map using standard WASD keys.
- **Dynamic Difficulty:** The game increases in difficulty based on score and elapsed time.
- **Live Micro-Challenges:** Encounter random Bash, SysAdmin, and security-related commands to type, scaling from beginner to "hacker" tiers.
- **Intruder & Virus Rounds:** Special events trigger rapid-fire challenges under time pressure.
- **Score & Lives:** Track your score and remaining lives. The game ends when you run out of lives.
- **Color and Emoji Support:** Auto-detects terminal capabilities for best visual effect.

## Gameplay

- **Goal:** Survive as long as possible by dodging moving errors (💥), collecting fixes (🛠️), and responding to special intruder (💀) and virus (🦠) events.
- **Controls:**  
  - `W`: Move up  
  - `A`: Move left  
  - `S`: Move down  
  - `D`: Move right  
  - `Q`: Quit the game
- **Challenges:**  
  - Colliding with a fix or special event will present a real-world command to type. Speed and accuracy are rewarded with extra points.
  - Intruder and virus rounds bring several commands to type under a countdown.

## How to Play

1. Clone this repository or copy `main.sh` from the `DodgeBash` folder.
2. Open a terminal that supports Bash and ANSI/256 colors.
3. Run the game:
   ```bash
   bash main.sh
   ```
4. Use WASD to move. Try to avoid errors and viruses, collect fixes, and be ready to type commands when prompted.

## Example Screenshot

```
=== DodgeBash ===
Lives: 3  Score: 101

###################################### TRAINER SIM #######################################
#.........................................................................................#
#.........................................................................................#
#...................💀.....................................................................#
#.........................................🦠...............................................#
#.........................................................................................#
#...........💻............................................................................#
#.........................................................................................#
#....................🛠️.....................................................................#
#.........................................................................................#
#.........................................................................................#
##########################################################################################
(WASD to move, Q to quit)
```

## Code Structure

- **Color & Emoji Setup:** Detects terminal support and sets up color codes and emoji icons.
- **Game State:** Manages map, player position, score, lives, and moving game elements (errors, fixes, intruders, viruses).
- **Rendering:** Efficiently draws the game map and status in the terminal.
- **Spawning & Movement:** Controls how errors, fixes, intruders, and viruses appear and move across the map.
- **Challenges:** Pools of beginner, sysadmin, hacker, and special event command challenges.
- **Game Loop:** Main loop for rendering, input handling, spawning, and event triggers.

## Requirements

- Bash shell (v4+ recommended)
- Terminal with ANSI color support (256 colors and emoji recommended but not required)

## License

MIT License