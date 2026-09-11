#!/bin/bash
#
# sort_files.sh: Automatically sort downloaded files by extension
#
# Monitors a directory (default: ~/Downloads) using inotifywait and moves
# files into appropriate category folders. Also supports a single-run
# mode to sort all existing files at once.
#
# Usage:
#   sort_files.sh [OPTIONS]
#
# Options:
#   -d DIR       Source directory to monitor (default: ~/Downloads)
#   -o DIR       Output base directory (default: $HOME)
#   --once       Sort existing files once and exit (no daemon)
#   -h, --help   Show this help message
#
# Config:
#   Optionally create ~/.config/sortfiles/rules.conf to override destinations.
#   Format:  extension=destination_path
#   Example: pdf=/home/user/Work/Papers

set -euo pipefail

# Defaults
SOURCE_DIR="$HOME/Downloads"
OUTPUT_BASE="$HOME"
ONCE_MODE=false
CONFIG_FILE="$HOME/.config/sortfiles/rules.conf"

# CLI parsing
show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Monitor a directory and automatically sort files by extension into
category folders (Documents, Videos, Music, Pictures, etc.).

Options:
  -d DIR       Source directory to monitor (default: ~/Downloads)
  -o DIR       Base directory for output folders (default: \$HOME)
  --once       Sort all existing files in the source directory once,
               then exit (no continuous monitoring).
  --install    Copy script to ~/.local/bin and add auto-start to ~/.bashrc
  --uninstall  Remove auto-start entry from ~/.bashrc
  -h, --help   Show this help message and exit.

Config:
  Create ~/.config/sortfiles/rules.conf to override default destinations.
  Each line should be:  extension=destination_path
  Lines starting with '#' are comments.

Examples:
  $(basename "$0")                       # Monitor ~/Downloads (default)
  $(basename "$0") -d ~/tmp              # Monitor ~/tmp
  $(basename "$0") --once                # Sort ~/Downloads once and exit
  $(basename "$0") -d ~/tmp --once -o ~/Projects
  $(basename "$0") --install             # Install for auto-start on login
  $(basename "$0") --uninstall           # Remove auto-start from .bashrc
EOF
    exit 0
}

# Install / Uninstall helpers
do_install() {
    local install_dir="$HOME/.local/bin"
    local script_dest="$install_dir/sort_files.sh"
    local bashrc_line='pgrep -f "sort_files.sh" > /dev/null || nohup ~/.local/bin/sort_files.sh > /dev/null 2>&1 &'
    local marker="# Auto-sort downloads (only one instance)"

    # Create install directory if needed
    mkdir -p "$install_dir"

    # Copy the script
    cp "$0" "$script_dest"
    chmod +x "$script_dest"
    echo "Copied script to $script_dest"

    # Check if already in .bashrc
    if grep -qF "$marker" "$HOME/.bashrc" 2>/dev/null; then
        echo "Already installed in ~/.bashrc, skipping."
        return
    fi

    # Prompt the user
    read -rp "Add auto-start to ~/.bashrc? [y/N] " answer
    case "$answer" in
        [yY][eE][sS]|[yY])
            cat >> "$HOME/.bashrc" <<ENDBASHRC

$marker
$bashrc_line
ENDBASHRC
            echo "Added to ~/.bashrc. It will run automatically on next terminal open."
            echo "Start it now without restarting:  $script_dest"
            ;;
        *)
            echo "Skipped .bashrc setup. You can run it manually:"
            echo "  $script_dest"
            echo "  $script_dest --once"
            ;;
    esac
}

do_uninstall() {
    local marker="# Auto-sort downloads (only one instance)"
    local bashrc_line='pgrep -f "sort_files.sh" > /dev/null || nohup ~/.local/bin/sort_files.sh > /dev/null 2>&1 &'

    if ! grep -qF "$marker" "$HOME/.bashrc" 2>/dev/null; then
        echo "No auto-start entry found in ~/.bashrc."
        return
    fi

    # Remove the marker line and the command line from .bashrc
    sed -i "\|$marker|d" "$HOME/.bashrc"
    sed -i "\|$bashrc_line|d" "$HOME/.bashrc"

    echo "Removed auto-start from ~/.bashrc."
    echo "Note: The script is still installed at ~/.local/bin/sort_files.sh."
    echo "Kill any running instance with:  pkill -f sort_files.sh"
}


while [[ $# -gt 0 ]]; do
    case "$1" in
        -d)
            SOURCE_DIR="$2"
            shift 2
            ;;
        -o)
            OUTPUT_BASE="$2"
            shift 2
            ;;
        --once)
            ONCE_MODE=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        --install)
            do_install
            exit 0
            ;;
        --uninstall)
            do_uninstall
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'. Use -h for help." >&2
            exit 1
            ;;
    esac
done


# Ensure source directory exists
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist." >&2
    exit 1
fi

# Load custom rules (if config exists)
# Custom rules override the built-in mapping.
# Format: extension=destination_path
declare -A CUSTOM_RULES=()
if [[ -f "$CONFIG_FILE" ]]; then
    while IFS='=' read -r ext dest; do
        # Skip comments and blank lines
        [[ "$ext" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$ext" ]] && continue
        ext="$(echo "$ext" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
        dest="$(echo "$dest" | xargs)"  # trim whitespace
        if [[ -n "$ext" && -n "$dest" ]]; then
            CUSTOM_RULES["$ext"]="$dest"
        fi
    done < "$CONFIG_FILE"
fi

# Extension to destination mapping
get_destination() {
    local ext="$1"
    local dest=""

    # Check custom rules first
    if [[ -n "${CUSTOM_RULES[$ext]+_}" ]]; then
        echo "${CUSTOM_RULES[$ext]}"
        return
    fi

    case "$ext" in
        # Documents & Text
        pdf|doc|docx|odt|rtf|txt|md|markdown|tex|latex|\
        csv|tsv|xlsx|xls|ods|pptx|ppt|odp|pages|numbers|keynote|\
        json|xml|yaml|yml|toml|ini|conf|cfg|log)
            dest="$OUTPUT_BASE/Documents"
            ;;

        # eBooks
        epub|mobi|azw|azw3|fb2|djvu|lit)
            dest="$OUTPUT_BASE/Documents/Ebooks"
            ;;

        # Code & Archives
        zip|tar|gz|bz2|xz|7z|rar|zst|lz|lzma|tgz|tbz2|txz|\
        deb|rpm|dmg|exe|msi|appimage|flatpak|snap|apk|war|jar|ear)
            dest="$OUTPUT_BASE/Archives"
            ;;

        # Videos
        mp4|mkv|avi|mov|wmv|flv|webm|m4v|mpg|mpeg|3gp|ts|vob|ogv|mxf|asf|divx)
            dest="$OUTPUT_BASE/Videos"
            ;;

        # Music & Audio
        mp3|flac|aac|wav|ogg|opus|wma|m4a|aiff|alac|ape|mid|midi|\
        amr|ra|ac3|dts)
            dest="$OUTPUT_BASE/Music"
            ;;

        # Images
        jpg|jpeg|png|gif|webp|svg|bmp|tiff|tif|ico|heic|heif|avif|\
        raw|cr2|nef|arw|dng|psd|ai|eps|xcf)
            dest="$OUTPUT_BASE/Pictures"
            ;;

        # Fonts
        ttf|otf|woff|woff2|eot)
            dest="$OUTPUT_BASE/Fonts"
            ;;

        # Torrents
        torrent)
            dest="$OUTPUT_BASE/Torrents"
            ;;

        # Subtitles
        srt|sub|ass|ssa|vtt|idx)
            dest="$OUTPUT_BASE/Videos/Subtitles"
            ;;

        # Disk images
        iso|img|vmdk|vhd|vhdx|qcow2)
            dest="$OUTPUT_BASE/DiskImages"
            ;;

        # No match
        *)
            dest=""
            ;;
    esac

    echo "$dest"
}

# Core: move a single file
sort_file() {
    local filename="$1"
    local filepath="$SOURCE_DIR/$filename"

    # Skip Chrome/Temp download files
    [[ "$filename" == *.crdownload ]] && return
    [[ "$filename" == *.part ]] && return
    [[ "$filename" == *.tmp ]] && return
    [[ "$filename" == .DS_Store ]] && return

    # Skip if not a regular file (ignore directories, symlinks to dirs, etc.)
    [[ -f "$filepath" ]] || return

    # Extract extension, lowercase
    local ext="${filename##*.}"
    ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

    # If the file has no real extension (e.g. "Makefile"), skip it
    [[ "$ext" == "$filename" ]] && return

    local dest
    dest="$(get_destination "$ext")"

    if [[ -n "$dest" ]]; then
        mkdir -p "$dest"
        # Avoid overwriting: if a file with the same name exists, append a counter
        local target="$dest/$filename"
        if [[ -e "$target" ]]; then
            local base="${filename%.*}"
            local counter=1
            while [[ -e "$dest/${base}_${counter}.${ext}" ]]; do
                counter=$((counter + 1))
            done
            target="$dest/${base}_${counter}.${ext}"
        fi
        mv "$filepath" "$target"
        echo "[sort] $filename → $target"
    else
        echo "[sort] Skipped $filename (no matching category for .$ext)"
    fi
}

# Daemon mode: watch for new files
run_daemon() {
    if ! command -v inotifywait &>/dev/null; then
        echo "Error: 'inotifywait' is required for daemon mode." >&2
        echo "Install it with:  sudo apt install inotify-tools" >&2
        echo "" >&2
        echo "Tip: Use --once to sort files without inotifywait." >&2
        exit 1
    fi

    echo "Monitoring '$SOURCE_DIR' for new files... (press Ctrl+C to stop)"
    inotifywait -m -e close_write -e moved_to --format '%f' "$SOURCE_DIR" 2>/dev/null | while read -r filename; do
        sort_file "$filename"
    done
}

# Once mode: sort all existing files then exit
run_once() {
    echo "Sorting files in '$SOURCE_DIR'..."
    local count=0
    for filepath in "$SOURCE_DIR"/*; do
        [[ -f "$filepath" ]] || continue
        local filename
        filename="$(basename "$filepath")"
        sort_file "$filename"
        count=$((count + 1))
    done
    echo "Done. Processed $count file(s)."
}

# Main
if [[ "$ONCE_MODE" == true ]]; then
    run_once
else
    run_daemon
fi
