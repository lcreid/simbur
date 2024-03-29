# simbur

SIMple Back Up and Recovery

## Quick Installation
You need to have accounts with administrator privileges on both the client and the server (you must be able to sudo
on both the client and the server).

NOTE: This version is not suitable for use on a network where you can't trust everyone.

### Server
The server must be a Synology DSM 5.2 or similar device.

Log in to the server as root, can create a directory for the backup:

```
mkdir -p /volume1/NetBackup/backupdata/client-machine-name
```

Where `client-machine-name` is the name of the host that you want to back up.

### Client
Download the client installer from:
https://github.com/lcreid/simbur/releases/download/v2.2.2/simbur-client.deb

Install the client:

```
sudo dpkg -i simbur-client.deb
```

Set up the client configuration file the way you need it. This step is obligatory.
You need to configure the
backup server at the very least:

```
sudo vi /etc/simbur/simbur-client.conf
```

Change `fs-1` on the line that starts `BACKUP_HOST=` to the name of the Synology device, e.g.:

```
BACKUP_HOST=my-syno-box
```

Make a password file, and put the admin password for your Synology box in it:

```
sudo touch /etc/simbur/password
sudo chmod 600 /etc/simbur/password
sudo vi /etc/simbur/password
```

At this point, you may want to read more detailed information about [configuration](https://github.com/lcreid/simbur/wiki/Additional-Configuration#excludes), but it's not absolutely necessary.

Finally, start the daemon. On systems with `upstart`, do:

```
sudo start simburd
```

On systems with `systemd`, do:
```
sudo systemctl start simburd
```

Other documentation is in the [simbur wiki](https://github.com/lcreid/simbur/wiki).
