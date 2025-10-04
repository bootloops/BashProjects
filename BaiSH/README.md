# BaiSH – Bash AI with Local Ollama + Command Dictionary

🤖 **BaiSH** is a modern, local Bash assistant that combines an AI engine (via Ollama) with an optional command dictionary. It helps you discover, navigate, and run Linux commands directly from your terminal.

---
# Screenshot
```
  ██████     ▄▄▄▄    ▄▄  ▒██████  ██░ ██ 
  ▓█   ▒▄  ▒██  ▒█▄     ▒██    ▒ ▓██░ ██▒
  ▒█████▄    ▄▄▄▒█▄ ▒██▒░ ▓██▄   ▒██▀▀██░
  ▒▓█   ▒▄ ░██  ▒██ ░██░  ▒   ██▒░▓█ ░██ 
  ░▒████▒ ░██▄▄▄▓██▒░██░▒██████▒▒░▓█▒░██▓
  ░░ ▒░ ░  ▒▒   ▓▒█░░▓  ▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒
   ░ ░  ░   ▒   ▒▒ ░ ▒ ░░ ░▒  ░ ░ ▒ ░▒░ ░
     ░      ░   ▒    ▒ ░░  ░  ░   ░  ░░ ░
     ░  ░       ░  ░ ░        ░   ░  ░  ░
┌──────────────────────────────────────────────────────┐
│  User: bootloops @ Host: potatoe                │
│  AI Status: Ollama running.                    │
│  Uptime: up 6 hours, 0 minutes                │
│  CPU Load: 0.77, 0.60, 0.56                    │
│  Memory Usage: 3.8Gi used / 15Gi total         │
│  Type 'exit' or 'quit' to leave.               │
└──────────────────────────────────────────────────────┘

    ▌ BaiSH ▌ bootloops ▶  /home/bootloops ▶  
     ⌬ Host: potatoe ▌ Uptime: up 6 hours, 0 minutes ▌ CPU:  0.77, 0.60, 0.56  
    ❯  how do i use dff to compare to files

cat file1 > comparison_output && cat file2 >> comparison_output && diff -u comparison_output comparison_output
    
    ▌ BaiSH ▌ bootloops ▶  /home/bootloops ▶  
     ⌬ Host: potatoe ▌ Uptime: up 6 hours, 15 minutes ▌ CPU:  0.43, 0.32, 0.38  
    ❯  how do i install steam

sudo apt-get update && sudo apt-get install steam libnss3:amd64 | echo "Steam installation complete."

    ▌ BaiSH ▌ bootloops ▶  /home/bootloops ▶  
     ⌬ Host: potatoe ▌ Uptime: up 6 hours, 15 minutes ▌ CPU:  0.43, 0.32, 0.38  
    ❯  $echo "hello"
Executing: echo "Hello"
Hello

    ▌ BaiSH ▌ bootloops ▶  /home/bootloops ▶  
     ⌬ Host: potatoe ▌ Uptime: up 6 hours, 15 minutes ▌ CPU:  0.43, 0.32, 0.38  
    ❯ 

```

---



# Folder Structure

```
baish/
├── auto_dictionary.json       # output by dictionary_generator.py (optional)
├── bai.sh                     # main loop
├── baish                      # wrapper to run bai.sh
├── dictionary_generator.py    # optional, requires Python/JQ
└── README.md                  # this file
```

---

# BEFORE YOU START

⚠ **OLLAMA**

You need to have Ollama running locally to use BaiSH AI features. You can modify the model in `bai.sh` via the `MODEL` variable.

⚠ **Dictionary (Optional)**

The dictionary is optional. If `auto_dictionary.json` is not present, BaiSH will run AI-only mode. Python and JQ are only required if you want to generate or query the dictionary.

---

## Features

* ✅ **Command-only responses** – BaiSH only outputs valid Bash commands.
* 🧠 **Local AI integration** – Queries Ollama locally for complex commands.
* 📖 **Optional command dictionary** – Provides descriptions and examples without AI.
* 💡 **Example commands** – Each dictionary entry includes ready-to-run examples.
* 🖍 **Syntax highlighting** – Color-coded output for easier readability using `awk`.
* 🛡 **Safe execution** – Optional prompt before executing AI-suggested commands.
* ⌨ **Multi-line input support** – Enter long commands or queries seamlessly.
* 🏃 **Quick execution** – `$ <command>` syntax runs commands directly.
* 🧮 **Debug mode** – Enable logs for troubleshooting with `DEBUG=1`.
* 🚪 **Exit easily** – Use `exit` or `quit` to leave BaiSH.

---

## Installation

1. Clone the repository:

```bash
git clone https://github.com/bootloops/BashProjects/baish.git
cd baish
```

2. Ensure **Python 3**, **jq**, and **curl** are installed if you plan to use the dictionary.

3. Optional: Generate the local command dictionary:

```bash
python3 dictionary_generator.py
```

4. Make the main script executable:

```bash
chmod +x bai.sh
```

5. Start BaiSH:

```bash
./baish
```

---

## Usage

### Query Commands

Ask BaiSH naturally about commands:

```bash
BaiSH> help with starting brave-browser
```

BaiSH will first look up the dictionary (if present). If no match is found, it falls back to AI.

### Run Commands Directly

Use `$` followed by the command:

```bash
BaiSH> $ brave-browser --help
```

### Debug Mode

Enable debug logs:

```bash
DEBUG=1 ./baish
```

### Exit BaiSH

```bash
BaiSH> exit
👋 Exiting BaiSH...
```

---

## Dictionary Structure (Optional)

The JSON dictionary (`auto_dictionary.json`) is structured as:

```json
[
  {
    "title": "ls",
    "description": "list directory contents",
    "example": "ls -la",
    "tags": ["filesystem", "list"]
  },
  {
    "title": "brave-browser",
    "description": "Brave Browser",
    "example": "brave-browser --help",
    "tags": ["browser", "web"]
  }
]
```

---

## Development

* Update or regenerate the dictionary with `dictionary_generator.py`.
* Modify `bai.sh` to customize AI prompts, PS1 prompt styles, or syntax highlighting.
* Use `DEBUG=1` to inspect query processing, tokenization, and AI integration.

---

## Safety

⚠ **Warning:** Executing AI-suggested commands can modify your system. Always verify commands before running. BaiSH provides `$ <command>` syntax for direct execution, but caution is advised.

---

## Notes

* `dictionary_generator.py`, Python, and JQ usage are **optional**.
* By default, dictionary lookups are commented out in `bai.sh`. You can enable them if you want faster command suggestions without AI.
* BaiSH supports multi-line prompts and custom color-coded PS1 prompts for a modern, cyberpunk-inspired terminal experience.
