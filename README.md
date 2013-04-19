# simbur

SIMple Back Up and Recovery

## Quick Installation
You need to have accounts with administrator privileges on both the client and the server (you must be able to sudo
on both the client and the server).

### Server
If you already have a server set up, you don't have to do this again.

If you don't have a server set up, you have to set one up. You need a Linux server
that has enough space to store all your backups. A good rule of thumb is that you need the total space of all the
machines you intend to back up, times three. You need administrator privileges on the server.

Log in to the backup server. If you haven't installed git and make, install them.
```
sudo apt-get install git make
git config --global user.name "FirstName LastName"
git config --global user.email e-mail-address
```
Get the simbur code:

    git clone git://github.com/lcreid/simbur.git

Install it:

    cd simbur/server
    sudo make install

set up the server configuration file the way you want it:

    sudo vi /etc/sbur/server.conf

### Client
Enroll the new client machine. Log in to the server.

    sudo /usr/local/lib/simbur/enroll-host client-machine-name

Follow the instructions to copy the private key to the client machine in /etc/simbur/hostname_dsa.

Log in to the client machine. If you haven't installed git and make, install them.
```
sudo apt-get install git make
git config --global user.name "FirstName LastName"
git config --global user.email e-mail-address
```
Get the simbur code:

    git clone git://github.com/lcreid/simbur.git

Install it:
```
cd simbur/client
sudo make install
```
Set up the client configuration file the way you need it. This step is obligatory. You need to configure the 
backup server at the very least:

    sudo vi /etc/simbur/client.conf

Other documentation is in the [simbur wiki](https://github.com/lcreid/simbur/wiki).
