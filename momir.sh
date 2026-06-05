#!/bin/bash
curl https://api.scryfall.com/cards/random?q=t%3Acreature+mv%3D$1 > card.json
ruby main.rb > /dev/usb/lp0
