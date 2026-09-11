#!/usr/bin/env bash

[ -z "$1" ] && exit 1
hyprctl dispatch workspace "$1"
