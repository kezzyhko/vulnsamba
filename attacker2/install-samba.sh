# installing packages
apt-get update
apt-get install curl make gcc patch -y --fix-missing

# downloading samba sources
cd /workdir
curl https://download.samba.org/pub/samba/stable/samba-4.5.2.tar.gz -o samba-4.5.2.tar.gz
tar -xvzf samba-4.5.2.tar.gz

# patch for exploit
patch ./samba-4.5.2/source3/client/client.c attack_commands.patch

# building from sources
cd ./samba-4.5.2/
./configure --without-acl-support --without-ldap --without-ads --prefix=/samba
make
make install
