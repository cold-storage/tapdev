#!/usr/bin/env bash

mkdir -p data

if [[ -n "$HOME" ]]; then

    cp -rf $HOME/.gitconfig data/.gitconfig

    while true; do
        read -p "Do you want to copy your .ssh folder to your new VM for github authentication (y/n)? " yn
        case $yn in
            [Yy]* ) cp -rf $HOME/.ssh data/; rm data/.ssh/authorized_keys; break;;
            [Nn]* ) break;;
            * ) echo "Please enter y or n.";;
        esac
    done

    cp -rf $HOME/.git-credentials data/
    cp -rf $HOME/.git-credential-cache data/

    echo "Complete. You can now run vagrant up."
else
    echo "Something went wrong."
fi
