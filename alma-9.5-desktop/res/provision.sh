cat > ~/provision.sh <<EOF
hostname
id -a

rm -f /etc/yum.repos.d/*
mkdir -p /mnt/cdrom

cat > /etc/yum.repos.d/cdrom.repo <<EOFF
[baseos]
name=CDROM - BaseOS
baseurl=file:///mnt/cdrom/BaseOS/
enabled=1
gpgcheck=0

[appstream]
name=CDROM - AppStream
baseurl=file:///mnt/cdrom/AppStream/
enabled=1
gpgcheck=0
EOFF

sudo systemctl set-default graphical.target

dnf remove -y \
baobab \
cheese \
eog \
evince \
gedit \
gnome-calculator \
gnome-characters \
gnome-disk-utility \
gnome-logs \
gnome-screenshot \
gnome-software \
gnome-tour \
totem \
yelp

cat > /etc/packer.build <<EOFF
version   = ${PACKER_BUILD_VERSION}
timestamp = $(date)
EOFF

cat /etc/packer.build

EOF

echo 'abcd1234' | sudo -S bash ~/provision.sh
rm -f ~/provision.sh
