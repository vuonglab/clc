#!/bin/bash

function assert_is_equal()
{
	local __expected_exit_code=$1
	local __answer_key=$2
	shift 2
	local __expression=$*

	local __answer

	# http://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
	if [ "$#" -eq 0 ]; then
		__answer=$(./whatis)
	elif [[ "$__expression" == *" * "* ]]; then
		__answer=$(./whatis "$__expression")
	else
		__answer=$(./whatis $__expression)
	fi
	local __exit_code=$?
	
	if [ "$__answer" != "$__answer_key" ]; then
		echo "ASSERT FAILED. EXPRESSION: $__expression ANSWER: $__answer KEY: $__answer_key"
		num_assert_failed=$[num_assert_failed+1]
	elif [ "$__exit_code" -ne "$__expected_exit_code" ]; then
		echo "ASSERT FAILED. EXPRESSION: $__expression EXIT CODE: $__exit_code EXPECTED: $__expected_exit_code"
		num_assert_failed=$[num_assert_failed+1]
	fi

	num_assert_total=$[num_assert_total+1]
}

function run_no_expression_test_cases()
{
	local __missing_expression="whatis: missing elementary arithmetic expression"$'\n'"Try 'whatis --help' for more information."

	assert_is_equal 1 "$__missing_expression"
	assert_is_equal 1 "$__missing_expression" ""
	assert_is_equal 1 "$__missing_expression" " "
	assert_is_equal 1 "$__missing_expression" "  "

	assert_is_equal 1 "$invalid_expression" \"\"
	assert_is_equal 1 "$invalid_expression" \" \"
	assert_is_equal 1 "$invalid_expression" \"  \"
}

function run_help_test_cases()
{
	local __usage="Usage: whatis expression"$'\n'"Command-line elementary arithmetic calculator."$'\n\n'"Exxpression can contain +, -, *, x, /, (), and []."$'\n\n'"Examples:"$'\n'"  whatis [[6+2]x5-10]/3          Answer: 10"$'\n'"  whatis 52.1834*(5100+18)/85015 Answer: 3.1415"

	assert_is_equal 1 "$__usage" "--help"
	assert_is_equal 1 "$__usage" "--help ignored"

	assert_is_equal 1 "$invalid_expression" "--Help"
	assert_is_equal 1 "$invalid_expression" "--HELP"

	assert_is_equal 1 "$invalid_expression" \" --help\"
	assert_is_equal 1 "$invalid_expression" \"--help \"
	assert_is_equal 1 "$invalid_expression" \" --help \"
	assert_is_equal 1 "$invalid_expression" \"--help ignored\"
	assert_is_equal 1 "$invalid_expression" "1+1 --help"
}

function run_expression_buffer_test_cases()
{
	local __buffer_too_small="Expression buffer too small."

	assert_is_equal 0 1482716035            "123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+1234567"
	assert_is_equal 1 "$__buffer_too_small" "123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+12345678"

	assert_is_equal 0 1481481595            "123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123 + 4"
	assert_is_equal 0 1481481595            "123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123 +  4"

	assert_is_equal 1 "$__buffer_too_small" "123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123 + 04"
	assert_is_equal 1 "$__buffer_too_small" "123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+1+ 2 + 3"
	assert_is_equal 1 "$__buffer_too_small" "123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+1+ 2 + 3 +"

	assert_is_equal 1 "$invalid_expression" "123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+1 + 2 +"
}

function run_read_expression_test_cases()
{
	assert_is_equal 0 6 "2 * 3"

	assert_is_equal 0 1.32 "[(1+2)*3-0.2]/20x3"

	assert_is_equal 0 1.32 "[(1 +2)*3-0.2]/20x3"
	assert_is_equal 0 1.32 "[(1+   2)*3-0.2]/20x3"
	assert_is_equal 0 1.32 "[(1 + 2)*3-0.2]/20x3"

	assert_is_equal 0 1.32 "[(1+2)*3 -0.2]/20x3"
	assert_is_equal 0 1.32 "[(1+2)*3-  0.2]/20x3"
	assert_is_equal 0 1.32 "[(1+2)*3  - 0.2]/20x3"

	assert_is_equal 0 1.32 "[(1+2) *3-0.2]/20x3"
	assert_is_equal 0 1.32 "[(1+2)* 3-0.2]/20x3"
	assert_is_equal 0 1.32 "[(1+2) * 3-0.2]/20x3"

	assert_is_equal 0 1.32 "[(1+2)*3-0.2]/20 x3"
	assert_is_equal 0 1.32 "[(1+2)*3-0.2]/20x 3"
	assert_is_equal 0 1.32 "[(1+2)*3-0.2]/20 x  3"

	assert_is_equal 0 1.32 "[(1+2)*3-0.2]  /20x3"
	assert_is_equal 0 1.32 "[(1+2)*3-0.2]/ 20x3"
	assert_is_equal 0 1.32 "[(1+2)*3-0.2]  / 20x3"

	assert_is_equal 0 1.32 "[ (1+2)*3-0.2]/20x3"
	assert_is_equal 0 1.32 "[(1+2) *3-0.2]/20x3"
	assert_is_equal 0 1.32 "[ (1+2)  *3-0.2]/20x3"

	assert_is_equal 0 1.32 "[(  1+2)*3-0.2]/20x3"
	assert_is_equal 0 1.32 "[(1+2 )*3-0.2]/20x3"
	assert_is_equal 0 1.32 "[( 1+2  )*3-0.2]/20x3"

	assert_is_equal 0 1.32 "  [(1+2)*3-0.2]/20x3"
	assert_is_equal 0 1.32 "[(1+2)*3-0.2]  /20x3"
	assert_is_equal 0 1.32 " [(1+2)*3-0.2] /20x3"

	assert_is_equal 0 1.32 "[  (1+2)*3-0.2]/20x3"
	assert_is_equal 0 1.32 "[(1+2)*3-0.2 ]/20x3"
	assert_is_equal 0 1.32 "[ (1+2)*3-0.2  ]/20x3"

	assert_is_equal 0 1.32 " [ ( 1+2)*3-0.2]/20x3"
	assert_is_equal 0 1.32 "[(1+2 ) *3-0.2 ] /20x3"
	assert_is_equal 0 1.32 "   [   (  1+2   )  *3-0.2  ]   /20x3"
	assert_is_equal 0 1.32 "   [   (  1 + 2   )  *3-0.2  ]   /20x3"
	assert_is_equal 0 1.32 "   [   (  1  +  2   )  *3 -  0.2  ]   /20x3"
	assert_is_equal 0 1.32 "   [   (  1  +  2   )  * 3 -  0.2  ]   /20x3"
	assert_is_equal 0 1.32 "   [   (  1  +  2   )  *  3 -  0.2  ] / 20 x 3"
	assert_is_equal 0 1.32 "   [   (  1  +  2   )  *  3  -  0.2 ]  /   20  x  3 "

	assert_is_equal 1 "$invalid_expression" "[(1+2)*3-0.2]/2 0x3"
	assert_is_equal 1 "$invalid_expression" "[(1+2)*3-0 .2]/20x3"
	assert_is_equal 1 "$invalid_expression" "[(1+2)*3-0. 2]/20x3"
	assert_is_equal 1 "$invalid_expression" "[(1+2)*3-0 . 2]/20x3"
}

function run_brackets_test_cases()
{
	assert_is_equal 0 8 "2*[3+1]"
	assert_is_equal 0 8 "2*(3+1]"
	assert_is_equal 0 8 "2*[3+1)"

	assert_is_equal 0 1.25 "[3+2]/4"
	assert_is_equal 0 1.25 "(3+2]/4"
	assert_is_equal 0 0.5 "[5-3)/4"

	assert_is_equal 0 21 "38/[10-8]+2"
	assert_is_equal 0 21 "38/(10-8]+2"
	assert_is_equal 0 21 "38/[10-8)+2"

	assert_is_equal 0 5.5 "[15-4]/[2.5-0.5]"
	assert_is_equal 0 68 "[[4+6]*2-3]*4"
	assert_is_equal 0 68 "[(4+6)*2-3]*4"
	assert_is_equal 0 68 "([4+6]*2-3)*4"
	assert_is_equal 0 68 "[([4+6]*2-3)*4]"
	assert_is_equal 0 68 "[([4+6)*2-3]*4)"
	assert_is_equal 0 68 "([(4+6]*2-3)*4]"

	assert_is_equal 1 "$invalid_expression" "2*[3+4"
	assert_is_equal 1 "$invalid_expression" "2*3+4]"
	assert_is_equal 1 "$invalid_expression" "[[10+2]/6"
	assert_is_equal 1 "$invalid_expression" "[10+2]/6]"
}

function run_xX_test_cases()
{
	assert_is_equal 0 84 "7x3x4"
	assert_is_equal 0 84 "7X3X4"

	assert_is_equal 0 84 "7x3X4"
	assert_is_equal 0 84 "7X3x4"

	assert_is_equal 0 84 "7 x 3 x 4"
	assert_is_equal 0 84 "7 X 3 X 4"

	assert_is_equal 0 84 "7 x 3 X 4"
	assert_is_equal 0 84 "7 X 3 x 4"

	assert_is_equal 1 "$invalid_expression" "7 x x 4"
	assert_is_equal 1 "$invalid_expression" "7 x 3 4"
}

function run_pretty_print_test_cases()
{
	assert_is_equal 0 3 "3"
	assert_is_equal 0 3 "3."
	assert_is_equal 0 3 "3.0"
	assert_is_equal 0 3 "3.00"
	assert_is_equal 0 3 "3.000"
	assert_is_equal 0 3 "3.0000"
	assert_is_equal 0 3 "3.00000"
	assert_is_equal 0 3 "3.000000"

	assert_is_equal 0 3.1 "3.100000"
	assert_is_equal 0 3.01 "3.010000"
	assert_is_equal 0 3.001 "3.001000"
	assert_is_equal 0 3.0001 "3.000100"
	assert_is_equal 0 3.00001 "3.000010"
	assert_is_equal 0 3.000001 "3.000001"

	assert_is_equal 0 3.14 "3.140000"
	assert_is_equal 0 3.141 "3.141000"
	assert_is_equal 0 3.1415 "3.141500"
	assert_is_equal 0 3.14159 "3.141590"
	assert_is_equal 0 3.141592 "3.141592"
	assert_is_equal 0 3.141593 "3.1415926"
	assert_is_equal 0 3.141593 "3.14159265"
	assert_is_equal 0 3.141593 "3.141592653"

	assert_is_equal 0 314 "314"
	assert_is_equal 0 314 "314."
	assert_is_equal 0 314.15 "314.15"
	assert_is_equal 0 314.15 "314.150"
	assert_is_equal 0 314.15 "314.1500"
	assert_is_equal 0 314.15 "0314.15"
	assert_is_equal 0 314.15 "00314.15"
	assert_is_equal 0 314.15 "00314.150"
	assert_is_equal 0 314.15 "00314.1500"

	assert_is_equal 0 0.1415 ".1415"
	assert_is_equal 0 0.1415 "0.1415"
	assert_is_equal 0 0.1415 "00.1415"
	assert_is_equal 0 0.1415 "000.1415"
	assert_is_equal 0 0.1415 "000.14150"
	assert_is_equal 0 0.1415 "000.141500"
}

function run_bad_expression_test_cases()
{
	assert_is_equal 1 "$invalid_expression" "+"
	assert_is_equal 1 "$invalid_expression" \"  +\"
	assert_is_equal 1 "$invalid_expression" \"+   \"
	assert_is_equal 1 "$invalid_expression" \"   + \"

	assert_is_equal 1 "$invalid_expression" "-"
	assert_is_equal 1 "$invalid_expression" \"   -\"
	assert_is_equal 1 "$invalid_expression" \"- \"
	assert_is_equal 1 "$invalid_expression" \"     -    \"

	assert_is_equal 1 "$invalid_expression" "*"
	assert_is_equal 1 "$invalid_expression" \"  *\"
	assert_is_equal 1 "$invalid_expression" \"* \"
	assert_is_equal 1 "$invalid_expression" \"  *   \"

	assert_is_equal 1 "$invalid_expression" "x"
	assert_is_equal 1 "$invalid_expression" \"  x\"
	assert_is_equal 1 "$invalid_expression" \"x    \"
	assert_is_equal 1 "$invalid_expression" \" x \"

	assert_is_equal 1 "$invalid_expression" "X"
	assert_is_equal 1 "$invalid_expression" \"  X\"
	assert_is_equal 1 "$invalid_expression" \"X    \"
	assert_is_equal 1 "$invalid_expression" \" X \"

	assert_is_equal 1 "$invalid_expression" "/"
	assert_is_equal 1 "$invalid_expression" \" /\"
	assert_is_equal 1 "$invalid_expression" \"/ \"
	assert_is_equal 1 "$invalid_expression" \" / \"

	assert_is_equal 1 "$invalid_expression" "("
	assert_is_equal 1 "$invalid_expression" ")"
	assert_is_equal 1 "$invalid_expression" "()"
	assert_is_equal 1 "$invalid_expression" ")("

	assert_is_equal 1 "$invalid_expression" "["
	assert_is_equal 1 "$invalid_expression" "]"
	assert_is_equal 1 "$invalid_expression" "[]"
	assert_is_equal 1 "$invalid_expression" "]["

	assert_is_equal 1 "$invalid_expression" "(3"
	assert_is_equal 1 "$invalid_expression" "4)"
	assert_is_equal 1 "$invalid_expression" "((1)/6"
	assert_is_equal 1 "$invalid_expression" "(1)/(6"
	assert_is_equal 1 "$invalid_expression" "(2)/6)"

	assert_is_equal 1 "$invalid_expression" "++1"
	assert_is_equal 1 "$invalid_expression" "3++14"
	assert_is_equal 1 "$invalid_expression" "101a"
	assert_is_equal 1 "$invalid_expression" "1 4"

	assert_is_equal 1 "$invalid_expression" "3..14"
	assert_is_equal 1 "$invalid_expression" "3.1.4"
}

function run_unary_operator_test_cases()
{
	assert_is_equal 0 7 "+7"
	assert_is_equal 0 1983 "+1983"
	assert_is_equal 0 50 "(+50)"
	assert_is_equal 0 -1 "-1"
	assert_is_equal 0 -318 "-318"
	assert_is_equal 0 -25 "(-25)"
	assert_is_equal 0 7 "+ 7"
	assert_is_equal 0 -1 "- 1"
	assert_is_equal 0 -10 "-   10"

	assert_is_equal 0 10 "3 + (+7)"
	assert_is_equal 0 5 "50 + (-45)"

	assert_is_equal 0 38 "+38"
	assert_is_equal 0 38 "+(+38)"
	assert_is_equal 0 38 "+(+(+38))"

	assert_is_equal 0 -34 "-34"
	assert_is_equal 0 34 "-(-34)"
	assert_is_equal 0 -34 "-(-(-34))"

	assert_is_equal 0 83 "83"
	assert_is_equal 0 83 "+83"
	assert_is_equal 0 83 "(+83)"
	assert_is_equal 0 -83 "-(+83)"

	assert_is_equal 1 "$invalid_expression" "+"
	assert_is_equal 1 "$invalid_expression" \" +\"
	assert_is_equal 1 "$invalid_expression" \"+ \"
	assert_is_equal 1 "$invalid_expression" \" + \"

	assert_is_equal 1 "$invalid_expression" "-"
	assert_is_equal 1 "$invalid_expression" \" -\"
	assert_is_equal 1 "$invalid_expression" \"-  \"
	assert_is_equal 1 "$invalid_expression" \"  -  \"

	assert_is_equal 1 "$invalid_expression" "++7"
	assert_is_equal 1 "$invalid_expression" "--1"
	assert_is_equal 1 "$invalid_expression" "-  1 00"
	# Some parsers, like those in Python and JavaScript, consider "3 + +7" and "50 + -45" to be legal expressions.
	assert_is_equal 1 "$invalid_expression" "3 + +7"
	assert_is_equal 1 "$invalid_expression" "50 + -45"
}

function run_one_number_test_cases()
{
	assert_is_equal 0 5 "5"
	assert_is_equal 0 226 "226"
	assert_is_equal 0 3982 "3982"
	assert_is_equal 0 226 "00226"
	assert_is_equal 0 3982 "03982"
	assert_is_equal 0 1234567890 "1234567890"
	assert_is_equal 0 123456789012345 "123456789012345"
	assert_is_equal 0 12345678901234567890 "12345678901234567890"
	# find max of long double
	# assert_is_equal 0 123456789012345678900 "123456789012345678900" # answer: 123456789012345678896

	assert_is_equal 0 0.1 ".1"
	assert_is_equal 0 0.1 "0.1"
	assert_is_equal 0 0.1 "00.1"
	assert_is_equal 0 0.1 "000.1"

	assert_is_equal 0 0.1234 ".1234"
	assert_is_equal 0 0.1234 "0.1234"
	assert_is_equal 0 0.1234 "00.1234"
	assert_is_equal 0 0.1234 "000.1234"
	assert_is_equal 0 0.12345 "0.12345"
	# 6 decimals is the precision of a long double
	assert_is_equal 0 0.123456 "0.123456"
	assert_is_equal 0 0.123457 "0.1234567"
	assert_is_equal 0 0.123457 "0.12345678"

	assert_is_equal 1 "$invalid_expression" ".."
	assert_is_equal 1 "$invalid_expression" "..."
	assert_is_equal 1 "$invalid_expression" ". ."
	assert_is_equal 1 "$invalid_expression" ". .."

	assert_is_equal 1 "$invalid_expression" "..1"
	assert_is_equal 1 "$invalid_expression" ".1."
	assert_is_equal 1 "$invalid_expression" ".1415."
	assert_is_equal 1 "$invalid_expression" ".14.15"
	assert_is_equal 1 "$invalid_expression" ".14.1.5."
}

function run_input_output_test_cases()
{
	run_no_expression_test_cases
	run_help_test_cases

	run_expression_buffer_test_cases

	run_read_expression_test_cases

	run_brackets_test_cases
	run_xX_test_cases

	run_pretty_print_test_cases
}

function run_expression_test_cases()
{
	# need to add more test cases
	run_bad_expression_test_cases

	run_unary_operator_test_cases

	run_one_number_test_cases
}

function run_all_test_cases()
{
	run_input_output_test_cases
	run_expression_test_cases
}

invalid_expression="whatis: invalid elementary arithmetic expression"$'\n'"Try 'whatis --help' for more information."

num_assert_total=0
num_assert_failed=0

run_all_test_cases

echo $num_assert_total tests, $[num_assert_total-num_assert_failed] passed, $num_assert_failed failed.
if [ "$num_assert_failed" -ge 1 ] ; then
	exit 1
fi
exit 0
