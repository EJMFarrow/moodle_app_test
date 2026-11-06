FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-server git curl ca-certificates less procps php-cli php-curl php-intl php-mbstring php-xml php-zip unzip \
    && useradd --create-home --shell /bin/bash --uid 1000 stackdev \
    && echo 'stackdev:stackdev' | chpasswd \
    && mkdir -p /run/sshd /workspace /opt/moodle /etc/skel/.codex \
    && printf '%s\n' 'Port 2222' 'PasswordAuthentication yes' 'PermitRootLogin no' 'UsePAM no' 'AllowUsers stackdev' 'X11Forwarding no' 'AllowTcpForwarding yes' 'PermitTunnel no' 'Subsystem sftp internal-sftp' > /etc/ssh/sshd_config \
    && ssh-keygen -A \
    && rm -rf /var/lib/apt/lists/*

COPY config.toml /etc/skel/.codex/config.toml
COPY entrypoint.sh /usr/local/bin/workbench-entrypoint
RUN chmod 755 /usr/local/bin/workbench-entrypoint

EXPOSE 2222
ENTRYPOINT ["/usr/local/bin/workbench-entrypoint"]
