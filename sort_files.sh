#!/bin/bash

targeted_dir="$HOME/Downloads"

if command -v inotifywait >/dev/null 2>&1; then
	inotifywait -m -e moved_to --format '%f' "$targeted_dir" 2>/dev/null | while read -r filename; do
		if [[ "$filename" == *.crdownload ]]; then
			continue
		fi

		ext="${filename##*.}"
		case "$ext" in 
			pdf|txt|html|md)
				destination="$HOME/Documents"
				mv "$targeted_dir/$filename" "$destination"
				echo "$filename now in $destination"
			;;
			mp4|mov|mkv|avi|webm)
				destination="$HOME/Videos"
				mv "$targeted_dir/$filename" "$destination"
				echo "$filename now in $destination"
			;;
			mp3|aac|flac|wav|ogg|aiff)
				destination="$HOME/Music"
				mv "$targeted_dir/$filename" "$destination"
				echo "$filename now in $destination"
			;;
			jpeg|jpg|png|gif|webp|svg)
				destination="$HOME/Pictures"
				mv "$targeted_dir/$filename" "$destination"
				echo "$filename now in $destination"
			;;
			*)
				echo "No directory to teleport the $ext file into"
			;;
		esac
	done
else
	echo "please, install inotify to continue"
	sudo apt install inotify-tools
fi
