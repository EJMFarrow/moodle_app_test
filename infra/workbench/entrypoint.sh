#!/bin/sh
set -eu

mkdir -p /run/sshd
if [ ! -f /home/stackdev/.codex/config.toml ]; then
    su -s /bin/sh -c 'cp /etc/skel/.codex/config.toml /home/stackdev/.codex/config.toml' stackdev
fi
if [ ! -f /home/stackdev/.bash_profile ]; then
    su -s /bin/sh -c "printf '%s\\n' '# Open an ordinary SSH login in the STACK checkout.' 'cd /workspace/stack' > /home/stackdev/.bash_profile" stackdev
fi
exec /usr/sbin/sshd -D -e
