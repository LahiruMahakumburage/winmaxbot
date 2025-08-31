#!/bin/bash

# Variables
USER="botuser"
BOT_DIR="/home/botuser/winmaxbot"
PYTHON_PATH="$BOT_DIR/venv/bin/python3"
BOT_SCRIPT="$BOT_DIR/bot.py"
SERVICE_FILE="/etc/systemd/system/winmaxbot.service"

API_ID="21232438"
API_HASH="e85e50c2228e36a2893c9a66304595b8"
BOT_TOKEN="8431260258:AAHqzAIJB23y5uEWRoV0tgXHVhhudgB3FgA"

# Create systemd service file
sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=WinMax Bot
After=network.target

[Service]
User=$USER
WorkingDirectory=$BOT_DIR
ExecStart=$PYTHON_PATH $BOT_SCRIPT
Restart=always
Environment=API_ID=$API_ID
Environment=API_HASH=$API_HASH
Environment=BOT_TOKEN=$BOT_TOKEN

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd, enable and start service
sudo systemctl daemon-reload
sudo systemctl enable winmaxbot
sudo systemctl start winmaxbot

# Show status
sudo systemctl status winmaxbot --no-pager
