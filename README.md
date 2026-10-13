F1 Terminal Race Simulator 

A terminal-based Formula 1 race simulator written in Bash/zsh. This project was built to demonstrate core Operating Systems concepts, specifically focusing on concurrent process management and inter-process communication in a Linux/macOS terminal environment.

Technical Highlights (OS Concepts)
- Concurrent Execution: Each driver's lap is simulated as a parallel background process (`&`).
- Process Synchronization: Utilizes the `wait` command to ensure the main script halts until all child processes complete their execution.
- Mutex Locks & Critical Sections:* Implements `flock` to safely lock the shared temporary results file, preventing race conditions and data corruption when multiple processes attempt to write their lap times simultaneously.
- Dynamic State Management: Uses `mktemp` for temporary data storage during runtime and dynamically parses the output to generate final standings.

How It Works
The script calculates lap times based on a combination of base driver performance, user-selected tire strategy, and environmental factors.

1. Environment Setup: Users select weather conditions (Dry, Light Rain, Heavy Rain) and track surface grip (Grippy, Slippery, Wet).
2. Tire Strategy: Assign specific tires (Soft, Medium, Hard, Intermediate, Wet) to drivers like Verstappen, Hamilton, Leclerc, or Norris.
3. Simulation Logic: The script calculates a dynamic score based on tire suitability for the weather, introduces random "chaos" factors based on track grip, and rolls for potential DNF (Did Not Finish) events.
4. Results: Processes write their final times to a locked file, which is then sorted to display the final grid and award official FIA points.

How to Run
Clone this repository and run the script in any Bash/zsh environment (macOS Terminal, Linux, or WSL):

```bash
# Make the script executable
chmod +x f1.sh

# Run the simulator
./f1.sh
