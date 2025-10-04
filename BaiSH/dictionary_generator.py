#!/usr/bin/env python3
import os
import json
import subprocess
import shutil

# Directories to scan for executables
BIN_DIRS = ["/bin", "/usr/bin", "/usr/local/bin", "/sbin", "/usr/sbin"]

# Common verbs for GUI apps / launchable apps
COMMON_TAGS = ["start", "open", "launch", "run", "service", "daemon"]

# Collect unique command names
commands = set()
for directory in BIN_DIRS:
    if os.path.exists(directory):
        for filename in os.listdir(directory):
            full_path = os.path.join(directory, filename)
            if os.access(full_path, os.X_OK) and not os.path.isdir(full_path):
                commands.add(filename)

print(f"Discovered {len(commands)} commands. Fetching descriptions...")

entries = []

def get_whatis(cmd):
    """Return short whatis summary if available."""
    try:
        result = subprocess.run(["whatis", cmd], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        output = result.stdout.strip()
        if "nothing appropriate" in output.lower() or output == "":
            return ""
        # Format: "ls (1) - list directory contents"
        parts = output.split(" - ", 1)
        if len(parts) == 2:
            return parts[1].strip()
        return ""
    except Exception:
        return ""

def get_man_name(cmd):
    """Return man page NAME section for the command, if available."""
    try:
        result = subprocess.run(["man", cmd], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        output = result.stdout
        lines = output.splitlines()
        name_sec = ""
        in_name = False
        for line in lines:
            if line.strip().upper() == "NAME":
                in_name = True
                continue
            if in_name:
                if line.strip() == "":
                    break
                name_sec += line.strip() + " "
        return name_sec.strip()
    except Exception:
        return ""

def get_example(cmd):
    """Return a usage example, either from SYNOPSIS or fallback --help."""
    example = f"{cmd} --help"
    try:
        result = subprocess.run(["man", cmd], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        lines = result.stdout.splitlines()
        synopsis_started = False
        for l in lines:
            if l.strip().upper() == "SYNOPSIS":
                synopsis_started = True
                continue
            if synopsis_started:
                if l.strip() == "":
                    break
                if l.strip().startswith(cmd):
                    example = l.strip()
                    break
    except Exception:
        pass
    return example

for cmd in sorted(commands):
    try:
        desc = get_whatis(cmd)
        man_name = get_man_name(cmd)
        if not desc:
            desc = man_name
        if not desc:
            continue  # skip if no description

        example = get_example(cmd)
        # Automatically add tags for GUI or known verbs
        tags = COMMON_TAGS.copy()

        entry = {
            "title": cmd,
            "description": desc,
            "example": example,
            "tags": tags
        }
        entries.append(entry)
    except Exception as e:
        print(f"Error processing {cmd}: {e}")

# Save JSON dictionary
with open("auto_dictionary.json", "w") as f:
    json.dump(entries, f, indent=2)

print(f"✅ Generated {len(entries)} entries in auto_dictionary.json")
