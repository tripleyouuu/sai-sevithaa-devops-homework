#!/bin/bash

current_date=$(date)
current_host=$(hostname)
current_user=$(whoami)

echo "Date: $current_date"
echo "Hostname: $current_host"
echo "Username: $current_user"

echo "Disk Usage:"
df -h

read -p "Enter a name for your output directory: " dir_name
read -p "Enter a name for your output file: " file_name

mkdir -p "$dir_name"
touch "$dir_name/$file_name"

ps aux > "$dir_name/$file_name"

echo "Running processes saved to $dir_name/$file_name"
