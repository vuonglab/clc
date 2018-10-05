#!/bin/sh

# This script calls the Python script create-test-cases-from-generated-expressions.py
# to create a shell script function from each expression file. The function
# invokes clc to test that it calculates the correct the answer for each
# expression.
#
# If a directory containing the expression files is not specified in $1,
# a default one is assigned:

_expression_dir=$1
[ "$_expression_dir" != "" ] || _expression_dir=~/downloads/test-cases

_script_dir="${0%/*}"

rm "$_expression_dir/summary" 2> /dev/null

echo -n "# " | tee -a "$_expression_dir/summary"
"$_script_dir/../clc" -p | tee -a "$_expression_dir/summary"

for f in "$_expression_dir"/*-expr; do
	echo -n "$(basename $f): " | tee -a "$_expression_dir/summary"
	"$_script_dir/create-test-cases-from-generated-expressions.py" "$f" | tee -a "$_expression_dir/summary"
done
