if [[ "$REBOOT_FORCE" = false ]]; then
  source roles/hook_after.sh
fi

REBOOT_LINE="<%= @sun.DONE.sub(@sun.DONE_ARG, 'reboot') %>"
if [[ -z $(grep -Fx "$REBOOT_LINE" "$HOME/<%= @sun.MANIFEST_LOG %>") ]]; then
  sun.done "reboot"
fi

echo 'Running "unattended-upgrade"'
unattended-upgrade -d

sun.ensure
trap - EXIT

echo 'Rebooting...'

sleep 5

reboot
