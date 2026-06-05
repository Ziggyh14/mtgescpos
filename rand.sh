#!/bin/bash
curl https://api.scryfall.com/cards/random  > card.json
ruby main.rb > /dev/usb/lp0
