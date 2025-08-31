#!/bin/bash
set -e

# ================= CONFIG =================
BOT_USER="botuser"
BOT_DIR="/home/$BOT_USER/winmaxbot"
BOT_FILE="bot.py"
SERVICE_NAME="winmaxbot"
PYTHON_BIN="$BOT_DIR/venv/bin/python"

# ==== CHANGE THESE TO YOUR REAL VALUES ====
API_ID="21232438"
API_HASH="e85e50c2228e36a2893c9a66304595b8"
BOT_TOKEN="8431260258:AAHqzAIJB23y5uEWRoV0tgXHVhhudgB3FgA"

# ==========================================

echo "=== 1. Updating system & installing dependencies ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-venv python3-pip git tmux

echo "=== 2. Creating bot user & directories ==="
sudo adduser --disabled-login --gecos "" $BOT_USER || true
sudo mkdir -p $BOT_DIR
sudo chown -R $BOT_USER:$BOT_USER $BOT_DIR

echo "=== 3. Creating virtual environment & installing Telethon ==="
sudo -u $BOT_USER bash <<EOF
cd $BOT_DIR
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install telethon
deactivate
EOF

echo "=== 4. Creating environment file with credentials ==="
sudo tee /etc/$SERVICE_NAME.env > /dev/null <<EOL
API_ID=$API_ID
API_HASH=$API_HASH
BOT_TOKEN=$BOT_TOKEN
EOL
sudo chmod 600 /etc/$SERVICE_NAME.env

echo "=== 5. Writing bot.py code ==="
sudo tee $BOT_DIR/$BOT_FILE > /dev/null <<'EOL'
import os
from telethon import TelegramClient, events

api_id = int(os.environ.get("API_ID", "0"))
api_hash = os.environ.get("API_HASH", "")
bot_token = os.environ.get("BOT_TOKEN", "")

destination_groups = [-1003045034143,-1003066964851,-1002944391131]
source_groups = [
    -1002860677525, -1002376878955
]

footer_text = "\n\nOffered by Gold Hunter VIP"
footer_enabled = True

# =================== TELETHON CLIENTS ===================
user_session_path = os.path.join(os.path.dirname(__file__), "user_session")
bot_session_path = os.path.join(os.path.dirname(__file__), "bot_session")

client = TelegramClient(user_session_path, api_id, api_hash)
bot = TelegramClient(bot_session_path, api_id, api_hash)

# ================== INTERACTIVE LOGIN ==================
if not os.path.exists(user_session_path + ".session"):
    print("=== First run: please enter your phone number and Telegram code ===")
    client.start()
else:
    client.start()
bot.start(bot_token=bot_token)

# =================== FORWARDING LOGIC ===================
@client.on(events.NewMessage)
async def forward_messages(event):
    global destination_groups, source_groups, footer_text, footer_enabled
    if event.chat_id not in source_groups:
        return
    try:
        original_text = event.message.message or ""
        final_text = f"{original_text}{footer_text}" if footer_enabled else original_text
        for dest in destination_groups + [-1002867515314]:
            if event.message.media:
                await bot.send_file(dest, event.message.media, caption=final_text)
            else:
                await bot.send_message(dest, final_text)
    except Exception as e:
        print("Error sending message:", e)

# =================== BOT COMMANDS ===================
@bot.on(events.NewMessage(pattern='/start'))
async def start_command(event):
    await event.reply(
        "👋 Hello! I am your WinMaxBot.\n"
        "I forward messages from source groups to destination groups.\n"
        "Use /help to see commands."
    )


@bot.on(events.NewMessage(pattern='/help'))
async def help_command(event):
    await event.reply(
        "📌 **WinMaxBot Commands:**\n"
        "/start - Start the bot\n"
        "/help - Show commands\n"
        "/about - Bot info\n"
        "/setfooter <text> - Change footer text\n"
        "/togglefooter - Enable/Disable footer\n"
        "/adddestination <chat_id> - Add destination\n"
        "/removedestination <chat_id> - Remove destination\n"
        "/addsource <chat_id> - Add source\n"
        "/removesource <chat_id> - Remove source\n"
        "/listsources - Show sources & destinations"
    )


@bot.on(events.NewMessage(pattern='/about'))
async def about_command(event):
    await event.reply("WinMaxBot v1.0\nDeveloped by Lahiru Mahakumburage ")


# =================== FOOTER COMMANDS ===================
@bot.on(events.NewMessage(pattern='/setfooter'))
async def set_footer(event):
    global footer_text
    new_footer = event.message.message.replace("/setfooter", "").strip()
    if new_footer:
        footer_text = f"\n\n{new_footer}"
        await event.reply(f"✅ Footer updated:\n{footer_text.strip()}")
    else:
        await event.reply("⚠️ Usage: /setfooter Your footer text")


@bot.on(events.NewMessage(pattern='/togglefooter'))
async def toggle_footer(event):
    global footer_enabled
    footer_enabled = not footer_enabled
    status = "enabled ✅" if footer_enabled else "disabled ❌"
    await event.reply(f"Footer is now {status}")


# =================== DESTINATION COMMANDS ===================
@bot.on(events.NewMessage(pattern='/adddestination'))
async def add_destination(event):
    global destination_groups
    try:
        new_dest = int(event.message.message.replace("/adddestination", "").strip())
        if new_dest not in destination_groups:
            destination_groups.append(new_dest)
            await event.reply(f"✅ Destination added: {new_dest}")
        else:
            await event.reply("⚠️ Already in list.")
    except:
        await event.reply("⚠️ Usage: /adddestination <chat_id>")


@bot.on(events.NewMessage(pattern='/removedestination'))
async def remove_destination(event):
    global destination_groups
    try:
        rem_dest = int(event.message.message.replace("/removedestination", "").strip())
        if rem_dest in destination_groups:
            destination_groups.remove(rem_dest)
            await event.reply(f"✅ Destination removed: {rem_dest}")
        else:
            await event.reply("⚠️ Not in list.")
    except:
        await event.reply("⚠️ Usage: /removedestination <chat_id>")


# =================== SOURCE COMMANDS ===================
@bot.on(events.NewMessage(pattern='/addsource'))
async def add_source(event):
    global source_groups
    try:
        new_source = int(event.message.message.replace("/addsource", "").strip())
        if new_source not in source_groups:
            source_groups.append(new_source)
            await event.reply(f"✅ Source added: {new_source}")
        else:
            await event.reply("⚠️ Already in list.")
    except:
        await event.reply("⚠️ Usage: /addsource <chat_id>")


@bot.on(events.NewMessage(pattern='/removesource'))
async def remove_source(event):
    global source_groups
    try:
        rem_source = int(event.message.message.replace("/removesource", "").strip())
        if rem_source in source_groups:
            source_groups.remove(rem_source)
            await event.reply(f"✅ Source removed: {rem_source}")
        else:
            await event.reply("⚠️ Not in list.")
    except:
        await event.reply("⚠️ Usage: /removesource <chat_id>")


# =================== LIST SOURCES ===================
@bot.on(events.NewMessage(pattern='/listsources'))
async def list_sources(event):
    await event.reply(
        f"📌 Sources:\n{source_groups}\n\n"
        f"📌 Destinations:\n{destination_groups}\n"
    )

print("WinMaxBot running... Forwarding messages now!")
client.run_until_disconnected()
EOL

echo "=== 6. Run first interactive login in tmux ==="
sudo -u $BOT_USER tmux new-session -d -s firstlogin "$PYTHON_BIN $BOT_DIR/$BOT_FILE"

echo "=== 7. Waiting 20 seconds for you to complete login in tmux ==="
echo "Attach to tmux if needed: sudo -u $BOT_USER tmux attach -t firstlogin"
sleep 20
echo "=== Detaching first login tmux session ==="
sudo -u $BOT_USER tmux detach -s firstlogin || true

echo "=== 8. Creating systemd service ==="
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOL
[Unit]
Description=WinMaxBot Telegram Bot
After=network.target

[Service]
Type=simple
User=$BOT_USER
WorkingDirectory=$BOT_DIR
EnvironmentFile=/etc/$SERVICE_NAME.env
ExecStart=$PYTHON_BIN $BOT_DIR/$BOT_FILE
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOL

echo "=== 9. Reloading systemd and starting service ==="
sudo systemctl daemon-reload
sudo systemctl enable --now $SERVICE_NAME.service

echo "=== Setup complete! ==="
echo "Logs: sudo journalctl -u $SERVICE_NAME.service -f"
echo "If prompted for phone/code, attach tmux: sudo -u $BOT_USER tmux attach -t firstlogin"
