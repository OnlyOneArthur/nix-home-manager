#!/bin/bash

cd ~/nix-home-manager/ || exit

git add .

read -r -p "Enter commit message: " msg

git commit -m "$msg"

git push -u origin master

home-manager switch --flake .#arthur
