#!/bin/sh

# Syntax: run-multiple-calculators.sh expression
#
# This script takes an expression; replaces 'x', '[', and ']' with
# '*', '(', and ')'; and then calls various console calculators to
# evaluate the expression.

run_calculator()
{
	local _calc=$1
	local _expr=$2

	echo
	echo "*** $_calc ***"

	if command -v "$_calc" >/dev/null 2>&1 ; then
		"$_calc" "$_expr" | cut -d '=' -f 2 | awk '{$1=$1};1'
	else
		echo "not installed"
	fi
}

run_calculator_pipe()
{
	local _calc=$1
	local _expr=$2

	echo
	echo "*** $_calc ***"

	if command -v "$_calc" >/dev/null 2>&1 ; then
		(echo "$_expr" | "$_calc" | cut -d '=' -f 2 | awk '{$1=$1};1')
	else
		echo "not installed"
	fi
}

evaluate_using_programming_languages()
{
	local _std_expr=$@

	echo
	echo "*** bash arithmetic expansion ***"
	if [[ $_std_expr == *.* ]] ; then
		echo "Expression can't contain decimals."
	else
		echo "$(($_std_expr))"
	fi

	echo
	echo "*** Python 3 ***"
	if command -v python3 >/dev/null 2>&1 ; then
		python3 -c 'import sys; print(eval(" ".join(sys.argv[1:])))' "$_std_expr"
	else
		echo "not installed"
	fi

	echo
	echo "*** perl ***"
	if command -v perl >/dev/null 2>&1 ; then
		perl -le 'printf "%f\n", eval"@ARGV"' "$_std_expr"
	else
		echo "not installed"
	fi

	echo
	echo "*** awk ***"
	if command -v awk >/dev/null 2>&1 ; then
		awk "BEGIN{print $_std_expr; exit}"
	else
		echo "not installed"
	fi
}

_orig_expr="$@"
_std_expr=$(echo "$_orig_expr" | tr 'x' '*' | tr '[' '(' | tr ']' ')')

echo "*** Standard expression ***"
echo "$_std_expr"

_script_dir="${0%/*}"
run_calculator "$_script_dir/../clc" "$_orig_expr"

run_calculator calc "$_std_expr"
run_calculator concalc "$_std_expr"
run_calculator apcalc "$_std_expr"
run_calculator wcalc "$_std_expr"
run_calculator gcalccmd "$_std_expr"
run_calculator qalc "$_std_expr"

run_calculator_pipe bc "$_std_expr"
run_calculator_pipe genius "$_std_expr"
run_calculator_pipe octave "$_std_expr"

evaluate_using_programming_languages "$_std_expr"
