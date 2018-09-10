#!/bin/sh

# This script calls the Python script generate-random-elementary-arithmetic-expressions.py
# to generate various files containing expressions involving different operations and
# integers and/or decimals.
#
# If no output directory is specified in $1, a default one is assigned:

_output_dir=$1
[ "$_output_dir" != "" ] || _output_dir=~/downloads/test-cases

# https://unix.stackexchange.com/questions/253524/dirname-and-basename-vs-parameter-expansion
_script_dir="${0%/*}"

generate_expressions()
{
	local _operation=$1
	local _number_type=$2

	local _operation_option="--operators $1"

	local _number_option="--integer 99 --float 99"
	[ "$_number_type" = "i" ] && _number_option="--integer 99"
	[ "$_number_type" = "f" ] && _number_option="--float 99"

	echo "Generating expressions in the background for $_operation_option $_number_option"
	"$_script_dir/generate-random-elementary-arithmetic-expressions.py" $_operation_option $_number_option >${_output_dir}/${_operation}-${_number_type}99-expr  2>${_output_dir}/${_operation}-${_number_type}99.err &
}

generate_expression_files()
{
	generate_expressions a i
	generate_expressions a f
	generate_expressions a if

	generate_expressions s i
	generate_expressions s f
	generate_expressions s if

	generate_expressions m i
	generate_expressions m f
	generate_expressions m if

	generate_expressions d i
	generate_expressions d f
	generate_expressions d if

	generate_expressions as i
	generate_expressions as f
	generate_expressions as if

	generate_expressions md i
	generate_expressions md f
	generate_expressions md if

	generate_expressions asmd i
	generate_expressions asmd f
	generate_expressions asmd if
}

generate_expression_files
