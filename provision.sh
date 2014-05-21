#
# Make sure we are all up to date
#

sudo apt-get update
sudo apt-get upgrade -qy

#
# Install git
#

sudo apt-get install git -qy

#
# Copy git and ssh credentials from host
#

if [[ -f /vagrant/data/.gitconfig ]]; then
    echo "Found .gitconfig, copying to /home/vagrant"
    cp -rf /vagrant/data/.gitconfig /home/vagrant/
fi

if [[ -f /vagrant/data/.git-credentials ]]; then
    echo "Found .git-credentials, copying to /home/vagrant"
    cp -rf /vagrant/data/.git-credentials /home/vagrant/
fi

if [[ -d /vagrant/data/.git-credential-cache ]]; then
    echo "Found .git-credential-cache, copying to /home/vagrant"
    cp -rf /vagrant/data/.git-credential-cache /home/vagrant/
fi

if [[ -d /vagrant/data/.ssh ]]; then
    echo "Found .ssh, copying to /home/vagrant"
    cp -rf /vagrant/data/.ssh /home/vagrant/
fi

#
# Install docker
#

sudo groupadd docker
sudo gpasswd -a vagrant docker

[ -e /usr/lib/apt/methods/https ] || {
  apt-get install apt-transport-https -qy
}
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
sudo sh -c "echo deb https://get.docker.io/ubuntu docker main\
> /etc/apt/sources.list.d/docker.list"
sudo apt-get update
sudo apt-get install lxc-docker -qy

#
# Install node and nvm
#

git clone https://github.com/creationix/nvm.git ~/.nvm
source ~/.nvm/nvm.sh
nvm install 0.10
echo "source ~/.nvm/nvm.sh" >> ~/.bashrc
echo "nvm use 0.10" >> ~/.bashrc

#
# Install MongoDB
#

# Add 10gen official apt source to the sources list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list

# Install MongoDB
sudo apt-get update
sudo apt-get install -qy mongodb-org

# Create the MongoDB data directory
sudo mkdir -p /data/db
sudo chown mongodb:mongodb /data/db

#
# Install zmq 4 (needed for shiloh-node)
#
sudo dpkg -i /vagrant/zeromq4_20140428-1_amd64.deb
sudo dpkg -i /vagrant/zeromq4-dev_20140428-1_amd64.deb

#
# Misc niceties
#

echo "alias d='docker'" >> ~/.bashrc
rm -f ~/.bash_history
ln -s /fireeye/.bash_history ~/.bash_history

#
# Run local docker registry
# This took me FOREVER to get right.
#
sudo apt-get install -qy build-essential python-dev libevent-dev python-pip liblzma-dev
#sudo apt-get install -qy gunicorn
sudo chown vagrant:vagrant /opt
git clone https://github.com/dotcloud/docker-registry.git /opt/docker-registry
cd /opt/docker-registry
git fetch --tags
git checkout tags/0.6.9
sudo pip install .

cat << EOF > /opt/docker-registry/config/config.yml
dev:
    storage: local
    storage_path: /fireeye/vag-doc-reg
    loglevel: debug
    secret_key: DKIEK234KS923ASDFBB
EOF

sudo tee /etc/init/docker-registry.conf > /dev/null <<'EOF'
description "Docker Registry"
version "0.6.9"
author "Docker, Inc."

start on runlevel [2345]
stop on runlevel [016]

respawn
respawn limit 10 5

# set environment variables
env REGISTRY_HOME=/opt/docker-registry
env SETTINGS_FLAVOR=dev
env SECRET_KEY=LukUFVBHOI7myGN0mDCOO7

script
cd $REGISTRY_HOME
exec gunicorn -k gevent -b 0.0.0.0:5000 -w 2 docker_registry.wsgi:application
end script
EOF

# sudo echo "54.84.80.249 docker.map.mandiant.com" >> /etc/hosts
echo "54.84.80.249 docker.map.mandiant.com" | sudo tee -a /etc/hosts

# docker tag aa08a7bcb97d localhost:5000/boo:000
# docker push localhost:5000/boo:000

#############################################################################
### NOT TESTED!!!!!
#############################################################################

#
# Allows you to 'ssh' into a running docker container.
# https://jpetazzo.github.io/2014/03/23/lxc-attach-nsinit-nsenter-docker-0-9/
# docker inspect your container to get the pid then do
# nsenter --target $PID --mount --uts --ipc --net --pid
#

curl https://www.kernel.org/pub/linux/utils/util-linux/v2.24/util-linux-2.24.tar.gz | tar -zxf-
cd util-linux-2.24
./configure --without-ncurses
make nsenter
sudo mv nsenter /usr/local/bin
cd ..
rm -rf util-linux-2.24
