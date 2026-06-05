#!/bin/bash

while read -r line; do
    ./card.sh "$line"
done < $1