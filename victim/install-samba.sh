# installing packages
apt-get update
apt-get install curl make gcc -y --fix-missing

# downloading samba sources
cd /workdir
curl https://download.samba.org/pub/samba/stable/samba-3.4.5.tar.gz -o samba-3.4.5.tar.gz
tar -xvzf samba-3.4.5.tar.gz

# building from sources
cd ./samba-3.4.5/source3/
./configure --prefix=/samba
make
make install

# copy config
cd /workdir
cp smb.conf /samba/lib/smb.conf

# public share
mkdir /public
chown nobody:nogroup /public
chmod 777 /public

# private share
mkdir /private
echo "You f0und 7he s3cret!" > /private/secret.txt
chown root:root /private
chmod 777 /private
