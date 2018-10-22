#!/bin/sh

_precision=$(./clc -p)

if [ "$_precision" = "[ ] 13-15 digits  [X] 16-19 digits" ] ; then
	./tests-long-double.sh
elif [ "$_precision" = "[X] 13-15 digits  [ ] 16-19 digits" ] ; then
	./tests-double.sh
else
	false
fi
