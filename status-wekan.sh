#!/bin/sh

echo -e "\nwekan node.js:"
ps aux | grep "node main.js" | grep -v grep
echo -e "\nwekan mongodb:"
ps aux | grep mongo | grep -v grep
echo -e "\nwekan logs are at $PWD/wekan.log\n"
