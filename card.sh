#!/bin/bash
name=$(echo $1 | sed "s/ /+/g")

curl https://api.scryfall.com/cards/named?fuzzy=$name > card.json
ruby main.rb > /dev/usb/lp0
