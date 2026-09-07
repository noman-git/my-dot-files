#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# This is for changing kb_layouts. Set input.kb_layout in ~/.config/hypr/lua/settings.lua
# The list is read from the running compositor, so it works with either parser.

layout_file="$HOME/.cache/kb_layout"
# The config is Lua now, so the layout list is read live rather than grepped
# out of a .conf file.
read_layouts() { hyprctl -j getoption input:kb_layout | jq -r '.str // ""'; }
notif_icon="$HOME/.config/swaync/images/ja.png"

# Refined ignore list with patterns or specific device names
ignore_patterns=(
  "--(avrcp)" 
  "Bluetooth Speaker" 
  "Other Device 
  Name"
  )


# Create layout file with default layout if it does not exist
if [ ! -f "$layout_file" ]; then
  echo "Creating layout file..."
  default_layout=$(read_layouts | cut -d ',' -f 1)
  default_layout=${default_layout:-"us"} # Default to 'us' layout
  echo "$default_layout" > "$layout_file"
  echo "Default layout set to $default_layout"
fi

current_layout=$(cat "$layout_file")
echo "Current layout: $current_layout"

# Read available layouts from the running compositor
kb_layout_line=$(read_layouts | tr -d '[:space:]')
if [ -z "$kb_layout_line" ]; then
  echo "Could not read input:kb_layout from hyprctl!"
  exit 1
fi
IFS=',' read -r -a layout_mapping <<< "$kb_layout_line"

layout_count=${#layout_mapping[@]}
echo "Number of layouts: $layout_count"

# Find current layout index and calculate next layout
for ((i = 0; i < layout_count; i++)); do
  if [ "$current_layout" == "${layout_mapping[i]}" ]; then
    current_index=$i
    break
  fi
done

next_index=$(( (current_index + 1) % layout_count ))
new_layout="${layout_mapping[next_index]}"
echo "Next layout: $new_layout"

# Function to get keyboard names
get_keyboard_names() {
    hyprctl devices -j | jq -r '.keyboards[].name'
}

# Function to check if a device matches any ignore pattern
is_ignored() {
    local device_name=$1
    for pattern in "${ignore_patterns[@]}"; do
        if [[ "$device_name" == *"$pattern"* ]]; then
            return 0 # Device matches ignore pattern
        fi
    done
    return 1 # Device does not match any ignore pattern
}

# Function to change keyboard layout
change_layout() {
    local error_found=false

    while read -r name; do
        if is_ignored "$name"; then
            echo "Skipping ignored device: $name"
            continue
        fi
        
        echo "Switching layout for $name to $new_layout..."
	      hyprctl switchxkblayout "$name" "$next_index"
        if [ $? -ne 0 ]; then
            echo "Error while switching layout for $name." >&2
            error_found=true
        fi
    done <<< "$(get_keyboard_names)"

    $error_found && return 1
    return 0
}

# Execute layout change and notify
if ! change_layout; then
    notify-send -u low -t 2000 'kb_layout' " Error:" " Layout change failed"
    echo "Layout change failed." >&2
    exit 1
else
    notify-send -u low -i "$notif_icon" " kb_layout: $new_layout"
    echo "Layout change notification sent."
fi

echo "$new_layout" > "$layout_file"
