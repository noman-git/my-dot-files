#!/usr/bin/env bash
# Set the volume from a click or drag on the slider in the volume menu.

[ "$SENDER" = "mouse.clicked" ] && osascript -e "set volume output volume $PERCENTAGE"
