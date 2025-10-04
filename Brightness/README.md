# Brightness Control Script 🌕

This Bash script provides an easy way to **view and control screen brightness** on Linux systems that expose brightness settings via `/sys/class/backlight/`.

It adjusts brightness in steps, sets specific values, and displays a **visual icon** representing the current brightness level.

---

## Features ✨

* 🔧 **Set brightness directly** with a given value.
* ➕ **Increase brightness** in increments (10% of max).
* ➖ **Decrease brightness** in decrements (10% of max).
* 🌑🌒🌓🌔🌕 **Shows an icon** corresponding to brightness level.
* 📊 Displays the brightness percentage alongside the icon.

---

## Usage ⚡

```bash
./brightness.sh [command] [value]
```

### Commands:

* `set <value>` → Set brightness to a specific raw value (0 → max).

  ```bash
  ./brightness.sh set 500
  ```
* `+` → Increase brightness by 10%.

  ```bash
  ./brightness.sh +
  ```
* `-` → Decrease brightness by 10%.

  ```bash
  ./brightness.sh -
  ```
* *(no argument)* → Just display the current brightness and icon.

  ```bash
  ./brightness.sh
  ```

---

## Output Example

```bash
🌔 73%
```

---

## Icon Mapping 🌟

| Percentage | Icon | Meaning            |
| ---------- | ---- | ------------------ |
| 0–10%      | 🌑   | Very dim           |
| 11–40%     | 🌒   | Low brightness     |
| 41–70%     | 🌓   | Medium brightness  |
| 71–90%     | 🌔   | Bright             |
| 91–100%    | 🌕   | Maximum brightness |

---

## Requirements 🛠️

* Linux system with brightness exposed at:

  ```
  /sys/class/backlight/intel_backlight
  ```
* `sudo` privileges (writing to brightness requires root).

---

## Notes ⚠️

* The script assumes your device is `intel_backlight`. If you use another driver (e.g., `amdgpu_bl0` or `acpi_video0`), update the `DEVICE` path inside the script.
* Brightness values are **raw values**, not percentages. The script calculates percentages for display.
