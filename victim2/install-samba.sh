# installing packages
apt-get update
apt-get install curl make gcc -y --fix-missing

# downloading samba sources
cd /workdir
curl https://download.samba.org/pub/samba/stable/samba-4.5.2.tar.gz -o samba-4.5.2.tar.gz
tar -xvzf samba-4.5.2.tar.gz

# building from sources
cd ./samba-4.5.2
./configure --without-acl-support --without-ldap --without-ads --prefix=/samba
make
make install

# copy config
cd /workdir
cp smb.conf /samba/etc/smb.conf

# public share
mkdir /public
chown nobody:nogroup /public
chmod 777 /public

# the secret
echo "You f0und 7he s3cret!" > /secret
chown nobody:nogroup /secret
chmod 777 /secret
