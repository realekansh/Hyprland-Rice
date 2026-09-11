#!/bin/sh

killall -q waybar || true
waybar &
