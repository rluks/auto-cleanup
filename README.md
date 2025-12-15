# auto-cleanup
Script for automatically removing files on Linux

## Create service and timer
~/.config/systemd/user/rluks-auto-cleanup.service
~/.config/systemd/user/rluks-auto-cleanup.timer

## Enable and start
systemctl --user daemon-reload
systemctl --user enable --now rluks-auto-cleanup.timer

## Check timer status
systemctl --user status rluks-auto-cleanup.timer

## View logs
journalctl --user -u rluks-auto-cleanup.service -n 50

## Manually test
systemctl --user start rluks-auto-cleanup.service
journalctl --user -u rluks-auto-cleanup.service -n 20
