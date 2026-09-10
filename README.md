# sort_files.sh

Automatically sort downloaded files into organized folders based on file type. Monitors a directory (default: `~/Downloads`) and moves files into the right place the moment they appear.

---

## What It Does

When a file lands in your source directory, `sort_files.sh` reads its extension and moves it to the appropriate category folder. For example, a `.pdf` goes to `~/Documents`, a `.mp4` goes to `~/Videos`, and so on.

**Supported categories and extensions:**

| Category | Extensions |
|---|---|
| **Documents** | `pdf doc docx odt rtf txt md csv xlsx xls pptx ppt json xml yaml log` (and more) |
| **EBooks** | `epub mobi azw3 fb2 djvu` |
| **Archives** | `zip tar gz 7z rar deb rpm dmg exe msi appimage jar` (and more) |
| **Videos** | `mp4 mkv avi mov webm m4v flv 3gp ts` (and more) |
| **Music** | `mp3 flac aac wav ogg opus m4a aiff mid` (and more) |
| **Images** | `jpg png gif webp svg bmp tiff heic psd raw` (and more) |
| **Fonts** | `ttf otf woff woff2 eot` |
| **Torrents** | `torrent` |
| **Subtitles** | `srt sub ass vtt` |
| **Disk Images** | `iso img vmdk qcow2` |

Files with no recognized extension (e.g. `Makefile`) and temporary download files (`.crdownload`, `.part`, `.tmp`) are skipped.

If a file with the same name already exists in the destination, the script appends a counter (`file_1.pdf`, `file_2.pdf`, etc.) to avoid overwriting.

---

## Prerequisites

- **bash** (version 4+ for associative arrays)
- **inotify-tools** (only needed for continuous daemon mode, not for `--once`)

```bash
# Install inotify-tools (Debian/Ubuntu)
sudo apt install inotify-tools

# Arch Linux
sudo pacman -S inotify-tools

# Fedora/RHEL
sudo dnf install inotify-tools
```

---

## Setup

### 1. Clone or copy the script

```bash
# Option A: Clone the repo
git clone <your-repo-url> && cd <repo-dir>

# Option B: Just grab the script
curl -o sort_files.sh <raw-file-url>
chmod +x sort_files.sh
```

### 2. Test it manually

```bash
# Sort all existing files in ~/Downloads once and exit
./sort_files.sh --once

# Watch ~/Downloads for new files (press Ctrl+C to stop)
./sort_files.sh

# Use a custom source directory
./sort_files.sh -d ~/tmp --once
```

### 3. Load it with .bashrc (optional)

You have two choices:

#### Option A: Run it manually when you want

Just run `sort_files.sh` whenever you need it. No setup required beyond making the file executable. This is best if you only sort files occasionally.

```bash
# Sort everything currently in ~/Downloads
./sort_files.sh --once

# Start monitoring (runs until you press Ctrl+C)
./sort_files.sh
```

#### Option B: Start it automatically from .bashrc

This adds a line to your `~/.bashrc` so the daemon starts every time you open a terminal. The script is smart enough to only run **one instance**; it checks if it's already running before starting a new one.

**To set this up, run:**

```bash
./sort_files.sh --install
```

This will:
1. Ask you to confirm whether you want to add it to your `.bashrc`.
2. Copy `sort_files.sh` to `~/.local/bin/sort_files.sh`.
3. Append a guarded one-liner to `~/.bashrc` that starts the daemon silently on shell open.

The added `.bashrc` line looks like this:

```bash
# Auto-sort downloads (only one instance)
pgrep -f "sort_files.sh" > /dev/null || nohup ~/.local/bin/sort_files.sh > /dev/null 2>&1 &
```

**To undo (remove from .bashrc):**

```bash
./sort_files.sh --uninstall
```

---

## Custom Rules

You can override or add extension mappings by creating a config file:

```
~/.config/sortfiles/rules.conf
```

**Format**: one rule per line:

```
extension=destination_path
```

**Example:**

```ini
# Send PDFs to a project-specific folder
pdf=/home/you/Work/Papers

# Send CSVs to a data folder
csv=/home/you/Data
```

Lines starting with `#` are comments. Custom rules take priority over the built-in ones.

---

## CLI Options

```
Usage: sort_files.sh [OPTIONS]

Options:
  -d DIR       Source directory to monitor (default: ~/Downloads)
  -o DIR       Base directory for output folders (default: $HOME)
  --once       Sort existing files once and exit (no continuous monitoring)
  --install    Add auto-start to ~/.bashrc and copy script to ~/.local/bin
  --uninstall  Remove auto-start from ~/.bashrc
  -h, --help   Show this help message and exit
```

---

## Examples

```bash
# Sort ~/Downloads once
./sort_files.sh --once

# Watch a different folder
./sort_files.sh -d ~/tmp

# Sort into a custom base directory
./sort_files.sh --once -o ~/Projects

# Install into .bashrc for auto-start
./sort_files.sh --install

# Remove from .bashrc
./sort_files.sh --uninstall
```

---

## License

Use it however you like.
