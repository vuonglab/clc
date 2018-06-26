#!/bin/sh

# Syntax: ./create-test-cases.sh expressions_filename

# Reads in a file containing elementary math expressions,
# calculates the expected answers using another program,
# and generates a sh-compatible script function to call
# clc to ensure clc produces the correct answers.

# Requires:
# calc - C-style arbitrary precision calculator (https://github.com/lcn2/calc) - generates the expected answers
# tr - replaces 'x', '[', and ']' with '*', '(', ')' and deletes the tab from calc's output answer

generate_test_function()
{
	local _insert_newline_if_next_expression_has_right_answer=0

	local _wrong_answer_count=0
	local _expression_count=0

	local _function_name=$(basename $1)
	echo "run_${_function_name}()" >>"$1.tests"
	echo "{" >>"$1.tests"

	local _expression
	while IFS='' read -r _expression || test -n "$_expression"; do
		local _expression_for_calc=$(echo "$_expression" | tr 'x' '*' | tr '[' '(' | tr ']' ')')
		local _answer_key=`calc -- "round($_expression_for_calc, 6)" | tr -d '\011'`
		local _expected_clc_exit_code=0
		if [ "$_answer_key" = "Error 10001" ] || [ "$_answer_key" = "Error 10002" ]; then
			# Error 10001: divide by zero
			# Error 10002: indeterminate (0/0)
			case "$_expression" in
				*" * "*) _answer_key=$(./clc "$_expression") ;;
				*) _answer_key=$(./clc $_expression) ;;
			esac
			_expected_clc_exit_code=1
		fi

		local _clc_answer
		case "$_expression" in
			*" * "*) _clc_answer=$(./clc "$_expression") ;;
			*) _clc_answer=$(./clc $_expression) ;;
		esac

		local _clc_exit_code=$?

		if [ "$_clc_exit_code" -ne "$_expected_clc_exit_code" ]; then
			echo "Expected exit code $_expected_clc_exit_code, got $_clc_exit_code"
			echo "Expected $_answer_key, got $_clc_answer"
			echo "Expression: $_expression"
			rm "$1.tests"
			exit 2
		fi

		if [ "$_clc_answer" != "$_answer_key" ]; then
			local _diff=`calc -- "abs($_answer_key - $_clc_answer)" | tr -d '\011'`
			[ "$_expression_count" -ne 0 ] && echo >>"$1.tests"
			printf "\t# Expected $_answer_key, got $_clc_answer, diff $_diff\n" >>"$1.tests"
			printf "\t# assert_is_equal $_expected_clc_exit_code $_answer_key \"$_expression\"\n" >>"$1.tests"

			_insert_newline_if_next_expression_has_right_answer=1
			_wrong_answer_count=$((_wrong_answer_count+1))
		else
			if [ "$_insert_newline_if_next_expression_has_right_answer" -eq 1 ]; then
				echo >>"$1.tests"
				_insert_newline_if_next_expression_has_right_answer=0
			fi
			printf "\tassert_is_equal $_expected_clc_exit_code $_answer_key \"$_expression\"\n" >>"$1.tests"
		fi

		_expression_count=$((_expression_count+1))
	done < "$1"

	echo "}" >>"$1.tests"

	echo $_expression_count expressions, $((_expression_count-_wrong_answer_count)) valid, $_wrong_answer_count commented out.
}

main() {
	[ "$#" -ne 1 ] && { echo "Missing filename"; exit 1; }
	generate_test_function "$1"
}

main "$@" && exit 0
