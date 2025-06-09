#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Alberto Careccia (acareccia)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/icloud-photos-downloader/icloud_photos_downloader

# Import Functions und Setup
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Setup Python3"
$STD apt-get install -y \
  python3 \
  python3-pip
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "Setup Python3"

msg_info "Installing icloudpd"
$STD pip install icloudpd
msg_ok "Installed icloudpd"

# Setup App
msg_info "Setup ${APPLICATION}"
RELEASE=$(curl -fsSL https://api.github.com/repos/icloud-photos-downloader/icloud_photos_downloader/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
curl -fsSL -o "${RELEASE}.zip" "https://github.com/icloud-photos-downloader/icloud_photos_downloader/archive/refs/tags/${RELEASE}.zip"
unzip -q "${RELEASE}.zip"
mv "${APPLICATION}-${RELEASE}/" "/opt/${APPLICATION}"
#
#
#
echo "${RELEASE}" >/opt/"${APPLICATION}"_version.txt
msg_ok "Setup ${APPLICATION}"

msg_info "Creating Configuration"


msg_info "Configure Application"
var_user_name="default"
read -r -p "${TAB3}Type the iCloud username/email: " var_user_name
echo "iCloud username/email: '${var_user_name}'"
icloudpd --username '${var_user_name}' --auth-only

msg_ok "Application Configured"

mkdir -p /icloud/photos
mkdir -p /etc/icloudpd
cat <<EOF >/etc/icloudpd/main.env
USERNAME=${var_user_name}
DIRECTORY=/icloud/photos
SMTP_HOST=
SMTP_PORT=25
LIBRARY=
EOF

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/"${APPLICATION}"@.service
Unit]
Description=iCloud Photos Downloader for %i
After=network.target

[Service]
EnvironmentFile=/etc/icloudpd/%i.env
ExecStart=/usr/local/bin/icloudpd \
  --directory ${DIRECTORY} \
  --username ${USERNAME} \
  --log-level info \
  --recent 10
  --watch-with-interval 3600 \
  $LIBRARY
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now "${APPLICATION}"
msg_ok "Created Service"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
rm -f "${RELEASE}".zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
