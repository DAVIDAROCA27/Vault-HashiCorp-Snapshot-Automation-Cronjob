# 1.2 Backup Automation using a Cronjob

Linux **Crontab** is a powerful utility used for task scheduling and automation in Unix-like operating systems.  
It allows users to run Linux commands or scripts at specified intervals.

It is ideal for recurring tasks such as:
- System maintenance  
- Backups  
- Updating  

Cron jobs automate repetitive tasks, ensuring they run at scheduled times without manual intervention.  
For example: backing up files, running system maintenance, or sending email reports.

To get this cronjob running, we need to obtain a **Vault token** and create a **policy** that grants the capability to create snapshots only on a specific path.

---

## Policy

```hcl
path "sys/storage/raft/snapshot" {
  capabilities = ["read","create"]
}
```

You can add this policy using the **CLI** or the **UI**, whichever you feel more comfortable with.

### CLI Method

```bash
# To create the policy file
cat > snapshots-policy.hcl <<EOF
path "sys/storage/raft/snapshot" {
  capabilities = ["read","create"]
}
EOF

# To write the policy into Vault
vault policy write snapshots-policy ./snapshots-policy.hcl
```

### UI Method
You can also create the policy through the Vault UI:  
`https://myvaultaddress:8200/ui/vault/policies/acl`

---

## Generate Token for Script Integration

Now that we have our policy created, we can generate a token to integrate with our running script:

```bash
vault write auth/approle/role/snapshots-role -secret-id-ttl=0 \
token_policies="snapshots-policy" -format=json
```

With this token, we can read the **role-id** and **secret-id**:

```bash
# Get the role-id
vault read auth/approle/role/snapshots-role/role-id

# Get the secret-id
vault write -f auth/approle/role/snapshots-role/secret-id
```

---

## Create Credential Files

We need to create files for the script to read, avoiding hardcoded secrets.

1. Create the `role_id` file and place it in:
   ```
   /opt/vault/auth/role_id
   ```

2. Create the `secret_id` file and place it in:
   ```
   /opt/vault/auth/secret_id
   ```

3. Change permissions so only the Vault service can read the data:
   ```bash
   sudo chown vault:vault /opt/vault/auth/*
   sudo chmod 600 /opt/vault/auth/*
   ```

---

# Vault Snapshot Automation Using Cronjob

This is a guide on how to create a script for automating Vault snapshots using a cronjob.

## Script

Please update the `VAULT_ADDR` variable with the name or IP of the node.

Once the Vault snapshot script is ready, you can automate its execution using a cronjob.

The best method is to run the cronjob on all nodes of the cluster, each pointing to its own IP address. Only the leader node will generate snapshots.  
The script checks whether the node is a leader or a standby node.  
- If it is a standby node, it will skip the snapshot execution.  
- If it is the leader node, it will execute the complete snapshot process.

---

## Step 1: Place the Script

Make sure the script is in an accessible and executable location:

```bash
/opt/vault/scripts/vault-backup.sh
chmod +x /opt/vault/scripts/vault-backup.sh
```

---

## Step 2: Edit the Crontab

Edit the crontab for the user that will execute the backups (for example, root or a dedicated Vault user):

```bash
crontab -e
```

---

## Step 3: Add the Cronjob

To run the script automatically, add one of the following entries:

```bash
# Run the script every 4 hours (recommended for production nodes)
0 */4 * * * /opt/vault/scripts/vault-backup.sh >> /var/log/vault-backup.log 2>&1

# Run the script every 8 hours (recommended for non-production nodes)
0 */8 * * * /opt/vault/scripts/vault-backup.sh >> /var/log/vault-backup.log 2>&1
```

---

## Step 4: Create Log Files

Please create the file for the cronjob logs:

```bash
touch /var/log/vault-backup.log
sudo chown youruser:yourgroup /var/log/vault-backup.log
sudo chmod 640 /var/log/vault-backup.log
```

---

## Important Notes

If any of these steps fail, check:
- File owners and permissions.
- That the user running the cronjob can read and execute all necessary files.
- The log file `/var/log/vault-backup.log` for detailed error messages.

---

## Explanation

| Cron Expression | Meaning |
|-----------------|----------|
| `0 * * * *` | Runs at minute 0 of every hour |
| `/opt/vault/scripts/vault-backup.sh` | Path to your backup script |
| `>> /var/log/vault-backup.log 2>&1` | Redirects both stdout and stderr to a log file |

---

## Considerations

- Verify that the backup directory is writable by the cron user.  
- Monitor `/var/log/vault-backup.log` for successful execution or errors.  
- Regularly inspect the snapshots to ensure all data is correctly backed up.
