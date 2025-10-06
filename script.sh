#!/bin/bash
# Vault Raft snapshot backup script


DATE=$(date +"%Y%m%d-%H%M%S")

#change addres of the nodes
VAULT_ADDR="https://CHANGEMEPLS:8200"
export VAULT_ADDR

BACKUP_DIR="/opt/vault/snapshots"
SNAPSHOT_FILE="$BACKUP_DIR/vault-snapshot-$DATE.snap"

ROLE_ID=$(cat /opt/vault/auth/role_id)
SECRET_ID=$(cat /opt/vault/auth/secret_id)

VAULT_TOKEN=$(vault write -format=json auth/approle/login role_id="$ROLE_ID" secret_id="$SECRET_ID" | jq -r '.auth.client_token')
export VAULT_TOKEN

IS_STANDBY=$(vault status -format=json | jq -r ".performance_standby")
if [ "$IS_STANDBY" == "true" ]; then
  echo "[$DATE] This node is a performance standby, skipping snapshot."
  exit 0
fi

mkdir -p "$BACKUP_DIR"

vault operator raft snapshot save "$SNAPSHOT_FILE"

if [ $? -eq 0 ]; then
  echo "[$DATE] Backup created: $SNAPSHOT_FILE"
  # change number of snapshots if needed 
  ls -1t $BACKUP_DIR/vault-snapshot-*.snap | tail -n +51 | xargs -r rm -f
  exit 0
else
  echo "[$DATE] Backup failed!" >&2
  exit 1
fi
