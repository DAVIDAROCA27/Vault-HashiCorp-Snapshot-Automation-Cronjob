This is a guide on how to create an script for automation snapshots in vault using a cronjob


Script

Please change the VAULT_ADDR variable with the name of the node. 


Once the Vault snapshot script is ready, you can automate its execution using a cronjob.

The best method is to run the cronjob on all nodes of the cluster, each pointing to its own IP address. Only the leader node will generate snapshots.

The script checks whether the node is a leader or a standby node.

If it is a standby node, it will skip the snapshot execution.

If it is the leader node, it will execute the complete snapshot process.

Step 1: Place the Script
Make sure the script is in an accessible and executable location:



/opt/vault/scripts/vault-backup.sh
chmod +x /opt/vault/scripts/vault-backup.sh
Step 2: Edit the Crontab
Edit the crontab for the user that will execute the backups (e.g., root or a dedicated Vault user):



crontab -e
Step 3: Add the Cronjob
To run the script every hour, add:



#This will  run the script every 4  hours ideal to configure in production nodes.
0 */4 * * * /opt/vault/scripts/vault-backup.sh >> /var/log/vault-backup.log 2>&1
#This will run the script every 8 hours ideal to non production nodes.
0 */8 * * * /opt/vault/scripts/vault-backup.sh >> /var/log/vault-backup.log 2>&1
Step 4:Create files

Also please create the file for the logs of the crontab



touch /var/log/vault-backup.log
sudo chown youruser:yourgroup /var/log/vault-backup.log
sudo chmod 640 /var/log/vault-backup.log
IMPORTANT:If any of this steps fail please check all file owners and permision check that the user that is running the cronjob can read the files,You can check the log file to get exact errors.



/var/log/vault-backup.log

Explanation:


0 * * * * → runs at minute 0 of every hour

/opt/vault/scripts/vault-backup.sh → path to your backup script

>> /var/log/vault-backup.log 2>&1 → redirects both stdout and stderr to a log file

Considerations:

Verify that the backup directory is writable by the cron user.

Monitor /var/log/vault-backup.log for successful execution or errors.

Usually inspect the snapshots to see that all the data is OK.
