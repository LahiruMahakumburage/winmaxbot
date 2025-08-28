#!/bin/bash
set -e

echo "=== WinMaxBot VPS Installer ==="

# --- 1. Install dependencies ---
apt update && apt upgrade -y
apt install -y python3 python3-venv python3-pip git ufw

# --- 2. Add winmaxbot user if not exists ---
if ! id "winmaxbot" &>/dev/null; then
  adduser --disabled-password --gecos "" winmaxbot
  usermod -aG sudo winmaxbot
fi

# --- 3. Create project directory ---
mkdir -p /opt/winmaxbot
chown -R winmaxbot:winmaxbot /opt/winmaxbot

# --- 4. Ask for secrets ---
read -p "Enter your Telegram API_ID: " API_ID
read -p "Enter your Telegram API_HASH: " API_HASH
read -p "Enter your Telegram BOT_TOKEN: " BOT_TOKEN

# --- 5. Create .env file ---
cat <<EOF > /opt/winmaxbot/.env
API_ID=$API_ID
API_HASH=$API_HASH
BOT_TOKEN=$BOT_TOKEN
EOF

chmod 600 /opt/winmaxbot/.env
chown winmaxbot:winmaxbot /opt/winmaxbot/.env

# --- 6. Setup Python virtual environment & install requirements ---
sudo -u winmaxbot bash <<'EOSU'
cd /opt/winmaxbot
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install telethon python-dotenv
deactivate
EOSU

# --- 7. Save full bot code ---
cat <<'EOF' > /opt/winmaxbot/bot.py
import os
from telethon import TelegramClient, events

# Load environment variables
api_id = int(os.environ["API_ID"])
api_hash = os.environ["API_HASH"]
bot_token = os.environ["BOT_TOKEN"]

# Default groups (can be changed via commands)
destination_groups = [-1003045034143]
source_groups = [
    -1002860677525, -1003022572344, -1002974728259,
    -1002919434260, -1002828051510, -1003005335315, -1003016603654
]

footer_text = "\n\nOffered by Gold Hunter VIP"
footer_enabled = True

# Start user client
client = TelegramClient('user_session', api_id, api_hash)
client.start()

# Start bot client
bot = TelegramClient('bot_session', api_id, api_hash)
bot.start(bot_token=bot_token)

# =================== FORWARDING ===================
@client.on(events.NewMessage)
async def forward_messages(event):
    global destination_groups, source_groups, footer_text, footer_enabled

    if event.chat_id not in source_groups:
        return

    try:
        original_text = event.message.message or ""
        for dest in destination_groups + [-1002867515314]:
            if event.message.media:
                await bot.send_file(dest, event.message.media, caption=original_text)
            else:
                final_text = f"{original_text}{footer_text}" if footer_enabled else original_text
                await bot.send_message(dest, final_text)

    except Exception as e:
        print("Error sending message:", e)

# =================== BOT COMMANDS ===================
@bot.on(events.NewMessage(pattern='/start'))
async def start_command(event):
    await event.reply("👋 Hello! I am your WinMaxBot.\nI forward messages from source groups to destination groups.\nUse /help to see commands.")

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
    await event.reply("WinMaxBot v1.0\nDeveloped by Lahiru Mahakumburage\nFrom Future World Solution")

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
        f"📌 Sources:\n{source_groups}\n\n📌 Destinations:\n{destination_groups}\n"
    )

print("WinMaxBot running... Forwarding messages now!")
client.run_until_disconnected()
EOF

chown winmaxbot:winmaxbot /opt/winmaxbot/bot.py

# --- 8. Create systemd service ---
cat <<EOF > /etc/systemd/system/winmaxbot.service
[Unit]
Description=WinMaxBot Telegram Service
After=network.target

[Service]
User=winmaxbot
WorkingDirectory=/opt/winmaxbot
EnvironmentFile=/opt/winmaxbot/.env
ExecStart=/opt/winmaxbot/venv/bin/python /opt/winmaxbot/bot.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# --- 9. Enable & start service ---
systemctl daemon-reload
systemctl enable winmaxbot
systemctl start winmaxbot

echo "=== Installation Complete! ==="
echo "Check logs with: journalctl -u winmaxbot -f"
