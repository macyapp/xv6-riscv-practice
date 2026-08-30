FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    gcc-riscv64-linux-gnu \
    binutils-riscv64-linux-gnu \
    qemu-system-misc \
    gdb-multiarch \
    git \
    make \
    sudo \
    passwd \
    && rm -rf /var/lib/apt/lists/*

# Host account information
ARG HOST_USERNAME
ARG UID
ARG GID

# Optional roll number.
# Empty = use HOST_USERNAME
ARG ROLLNO=""

RUN set -eux; \
    \
    if [ -n "$ROLLNO" ]; then \
        USERNAME="$ROLLNO"; \
    else \
        USERNAME="$HOST_USERNAME"; \
    fi; \
    \
    echo "Container username: $USERNAME"; \
    echo "UID: $UID"; \
    echo "GID: $GID"; \
    \
    EXISTING_GROUP="$(getent group "$GID" | cut -d: -f1 || true)"; \
    if [ -n "$EXISTING_GROUP" ]; then \
        if [ "$EXISTING_GROUP" != "$USERNAME" ]; then \
            groupmod -n "$USERNAME" "$EXISTING_GROUP"; \
        fi; \
    else \
        groupadd --gid "$GID" "$USERNAME"; \
    fi; \
    \
    EXISTING_USER="$(getent passwd "$UID" | cut -d: -f1 || true)"; \
    if [ -n "$EXISTING_USER" ]; then \
        if [ "$EXISTING_USER" != "$USERNAME" ]; then \
            usermod \
                --login "$USERNAME" \
                --home "/home/$USERNAME" \
                --move-home \
                "$EXISTING_USER"; \
        fi; \
    else \
        useradd \
            --uid "$UID" \
            --gid "$GID" \
            --create-home \
            --shell /bin/bash \
            "$USERNAME"; \
    fi; \
    \
    usermod --gid "$GID" --shell /bin/bash "$USERNAME"; \
    \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" \
        > "/etc/sudoers.d/$USERNAME"; \
    chmod 0440 "/etc/sudoers.d/$USERNAME"

WORKDIR /xv6

# Numeric UID/GID are deliberate.
# The username corresponding to this UID was configured above.
USER ${UID}:${GID}

CMD ["/bin/bash"]