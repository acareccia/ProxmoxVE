#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/acareccia/ProxmoxVE/refs/heads/feature/icloudpd/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Alberto Careccia (acareccia)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/icloud-photos-downloader/icloud_photos_downloader

APP="icloudpd"
var_tags="${var_tags:-backup}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-1}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f  /usr/local/bin/icloudpd ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # Crawling the new version and checking whether an update is required
  RELEASE=$(curl -fsSL https://api.github.com/repos/icloud-photos-downloader/icloud_photos_downloader/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    # Stopping Services
    msg_info "Stopping $APP"
    systemctl stop $APP.service
    msg_ok "Stopped $APP"

    # TODO: Creating Backup
#    msg_info "Creating Backup"
#    tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" [IMPORTANT_PATHS]
#    msg_ok "Backup Created"

    # Execute Update
    msg_info "Updating $APP to v${RELEASE}"
    $STD apt update -y
    pip install icloudpd --upgrade
    msg_ok "Updated $APP to v${RELEASE}"

    # Starting Services
    msg_info "Starting $APP"
    systemctl start $APP.service
    msg_ok "Started $APP"

    # TODO: Cleaning up
#    msg_info "Cleaning Up"
#    rm -rf [TEMP_FILES]
#    msg_ok "Cleanup Completed"

    # Last Action
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Update Successful"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:[PORT]${CL}"
