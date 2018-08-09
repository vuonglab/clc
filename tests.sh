#!/bin/sh

# Making scripts sh-compatible (portable):
# https://unix.stackexchange.com/questions/145522/what-does-it-mean-to-be-sh-compatible
# https://stackoverflow.com/questions/5725296/difference-between-sh-and-bash
# https://mywiki.wooledge.org/Bashism

assert_is_equal()
{
	local _expected_exit_code=$1
	local _answer_key="$2"
	shift 2
	local _expression="$*"

	local _answer

	if [ "$#" -eq 0 ]; then
		_answer=$(./clc)
	else
		case "$_expression" in
			*" * "*) _answer=$(./clc "$_expression") ;;
			*) _answer=$(./clc $_expression) ;;
		esac
	fi
	local _exit_code=$?
	
	# Special handling for nan and -nan.
	# On Linux, 0/0 gives -nan. On macOS and
	# FreeBSD, it's nan.
	[ "$_answer_key" = "-nan" ] && _answer_key="nan"
	[ "$_answer" = "-nan" ] && _answer="nan"

	if [ "$_answer" != "$_answer_key" ]; then
		echo "ASSERT FAILED. EXPRESSION: $_expression ANSWER: $_answer KEY: $_answer_key"
		num_assert_failed=$((num_assert_failed+1))
	elif [ "$_exit_code" -ne "$_expected_exit_code" ]; then
		echo "ASSERT FAILED. EXPRESSION: $_expression EXIT CODE: $_exit_code EXPECTED: $_expected_exit_code"
		num_assert_failed=$((num_assert_failed+1))
	fi

	num_assert_total=$((num_assert_total+1))
}

run_no_expression_test_cases()
{
	local _missing_expression=
	_missing_expression=$(printf "clc: missing elementary arithmetic expression\nTry 'clc --help' for more information.")

	assert_is_equal 1 "$_missing_expression"
	assert_is_equal 1 "$_missing_expression" ""
	assert_is_equal 1 "$_missing_expression" " "
	assert_is_equal 1 "$_missing_expression" "  "

	assert_is_equal 1 "$invalid_expression" \"\"
	assert_is_equal 1 "$invalid_expression" \" \"
	assert_is_equal 1 "$invalid_expression" \"  \"
}

run_help_test_cases()
{
	local _usage=
	_usage=$(printf "Usage: clc expression\nCommand-line elementary arithmetic calculator.\n\nExpression can contain +, -, *, x, /, (), and [].\n\nExamples:\n  clc [[6+2]x5-10]/3          Answer: 10\n  clc 52.1834*(5100+18)/85015 Answer: 3.1415")

	assert_is_equal 0 "$_usage" "--help"
	assert_is_equal 0 "$_usage" "--help ignored"
	assert_is_equal 0 "$_usage" "--help --fp-type"
	assert_is_equal 0 "$_usage" "--help 1+1"

	assert_is_equal 1 "$invalid_expression" "-h"
	assert_is_equal 1 "$invalid_expression" "-h --fp-type"
	assert_is_equal 1 "$invalid_expression" "-H"
	assert_is_equal 1 "$invalid_expression" "-H --fp-type"

	assert_is_equal 1 "$invalid_expression" "help"
	assert_is_equal 1 "$invalid_expression" "-help"
	assert_is_equal 1 "$invalid_expression" "--Help"
	assert_is_equal 1 "$invalid_expression" "--HELP"
	assert_is_equal 1 "$invalid_expression" "---help"

	assert_is_equal 1 "$invalid_expression" \" --help\"
	assert_is_equal 1 "$invalid_expression" \"--help \"
	assert_is_equal 1 "$invalid_expression" \" --help \"
	assert_is_equal 1 "$invalid_expression" \"--help ignored\"
	assert_is_equal 1 "$invalid_expression" "1+1 --help"
}

run_floating_point_type_test_cases()
{
	local _floating_point_type
	_floating_point_type=$(./clc --fp-type)

	assert_is_equal 0 "$_floating_point_type" "--fp-type"
	assert_is_equal 0 "$_floating_point_type" "--fp-type ignored"
	assert_is_equal 0 "$_floating_point_type" "--fp-type --help"
	assert_is_equal 0 "$_floating_point_type" "--fp-type 1+1"

	assert_is_equal 1 "$invalid_expression" "-fp-type"
	assert_is_equal 1 "$invalid_expression" "-fp-type --help"

	assert_is_equal 1 "$invalid_expression" "fp-type"
	assert_is_equal 1 "$invalid_expression" "-fp-type"
	assert_is_equal 1 "$invalid_expression" "--fptype"
	assert_is_equal 1 "$invalid_expression" "--floating-point-type"
	assert_is_equal 1 "$invalid_expression" "--FP-TYPE"
	assert_is_equal 1 "$invalid_expression" "---fp-type"

	assert_is_equal 1 "$invalid_expression" \" --fp-type\"
	assert_is_equal 1 "$invalid_expression" \"--fp-type \"
	assert_is_equal 1 "$invalid_expression" \" --fp-type \"
	assert_is_equal 1 "$invalid_expression" \"--fp-type ignored\"
	assert_is_equal 1 "$invalid_expression" "1+1 --fp-type"
}

run_expression_buffer_test_cases()
{
	local _buffer_size=511 # must be odd number
	local _buffer_too_small="Expression buffer too small."

	local _longest_expression=$(printf %$((_buffer_size-1))s1 | sed 's/  /1+/g')
	assert_is_equal 0 $(((_buffer_size+1)/2)) $_longest_expression
	assert_is_equal 1 "$_buffer_too_small" "X$_longest_expression"

	local _almost_max_buffer_size=$((_buffer_size-4))
	local _almost_longest_expression=$(printf %$((_almost_max_buffer_size-1))s1 | sed 's/  /1+/g')
	assert_is_equal 0 $(((_almost_max_buffer_size+1)/2+1)) "$_almost_longest_expression + 1"
	assert_is_equal 0 $(((_almost_max_buffer_size+1)/2+1)) "$_almost_longest_expression + 1  "
	assert_is_equal 0 $(((_almost_max_buffer_size+1)/2+1)) "$_almost_longest_expression +  1"

	assert_is_equal 1 "$_buffer_too_small" "$_almost_longest_expression + 1+"
	assert_is_equal 1 "$invalid_expression" "$_almost_longest_expression +1+"

	assert_is_equal 1 "$_buffer_too_small" "$_almost_longest_expression + 01"
	assert_is_equal 1 "$_buffer_too_small" "$_almost_longest_expression + 01 +"
}

run_read_expression_test_cases()
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

run_bad_expression_test_cases()
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

	assert_is_equal 1 "$invalid_expression" "101a"
	assert_is_equal 1 "$invalid_expression" "1 4"

	assert_is_equal 1 "$invalid_expression" "3..14"
	assert_is_equal 1 "$invalid_expression" "3.1.4"

	assert_is_equal 1 "$invalid_expression" "3,141"
	assert_is_equal 1 "$invalid_expression" "31,415"
	assert_is_equal 1 "$invalid_expression" "314,159"
	assert_is_equal 1 "$invalid_expression" "3,141,592"
	assert_is_equal 1 "$invalid_expression" "31,415,926"
	assert_is_equal 1 "$invalid_expression" "314,159,265"
	assert_is_equal 1 "$invalid_expression" "3,141,592,653"
}

run_brackets_test_cases()
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

	assert_is_equal 0 10 "(2)*(5)"
	assert_is_equal 0 10 "(2)*[5]"
	assert_is_equal 0 10 "[2]*(5)"
	assert_is_equal 0 10 "[2]*[5]"

	assert_is_equal 1 "$invalid_expression" "(2)(5)"
	assert_is_equal 1 "$invalid_expression" "[2][5]"
	assert_is_equal 1 "$invalid_expression" "2*[3+4"
	assert_is_equal 1 "$invalid_expression" "2*3+4]"
	assert_is_equal 1 "$invalid_expression" "[[10+2]/6"
	assert_is_equal 1 "$invalid_expression" "[10+2]/6]"
}

run_xX_test_cases()
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

run_significant_digits_test_cases_integer_addition_and_subtraction()
{
	# additions and subtractions of integers: 19 significant digits
	assert_is_equal 0 7 "4 + 3"
	assert_is_equal 0 31415 "30000 + 1400 + 15"
	assert_is_equal 0 3141592653 "3141500000 + 92653"
	assert_is_equal 0 3141592653589799323 "3141592653589799323" # 19 digits
	assert_is_equal 0 3.141592653589799324e+20 "314159265358979932384"
	assert_is_equal 0 3.141592653589799324e+21 "3141592653589799323846"

	assert_is_equal 0 1234567890123456789 "1234567890123456789 + 0"
	assert_is_equal 0 9876543210987654321 "9876543210987654322 - 1"

	assert_is_equal 0 9.876543210987654321e+19 "98765432109876543210"
	assert_is_equal 0 9.876543210987654321e+19 "98765432109876543212"
#			  Answer: 9.876543210987654322e+19
#	assert_is_equal 0 9.876543210987654321e+19 "98765432109876543214"
	assert_is_equal 0 9.876543210987654322e+19 "98765432109876543215"
	assert_is_equal 0 9.876543210987654322e+19 "98765432109876543216"
	assert_is_equal 0 9.876543210987654322e+19 "98765432109876543219"
#			  Answer: 9.876543210987654323e+22
#	assert_is_equal 0 9.876543210987654322e+22 "98765432109876543219999"

	assert_is_equal 0 1.234567890123456789e+19 "12345678901234567890"
	assert_is_equal 0 1.234567890123456789e+19 "12345678901234567894"
	assert_is_equal 0 1.23456789012345679e+19 "12345678901234567895"
	assert_is_equal 0 1.23456789012345679e+19 "12345678901234567897"
	assert_is_equal 0 1.23456789012345679e+19 "12345678901234567899"
	assert_is_equal 0 1.23456789012345679e+20 "123456789012345678969"
	assert_is_equal 0 1.23456789012345679e+22 "12345678901234567899127"
}

run_significant_digits_test_cases_integer_multiplication_and_division()
{
	# multiplications and divisions of integers: 17 significant digits
	assert_is_equal 0 12 "4 * 3"
	assert_is_equal 0 31415927 "31415927 x 1"
	assert_is_equal 0 31415926535898 "31415926535898 x 1"
	assert_is_equal 0 3141592653589799 "3141592653589799 * 1"
	assert_is_equal 0 3141592653589792 "3141592653589792 x 1" # 16 digits
	assert_is_equal 0 31415926535897923 "31415926535897923 x 1" # 17 digits
	assert_is_equal 0 3.1415926535897932e+17 "314159265358979323 x 1" # 18 digits
	assert_is_equal 0 3.1415926535897932e+18 "3141592653589793238 x 1" # 19 digits
	assert_is_equal 0 3.1415926535897932e+19 "31415926535897932384 x 1" # 20 digits
	assert_is_equal 0 3.1415926535897932e+20 "314159265358979323846 x 1" # 21 digits

	assert_is_equal 0 9.8765432109876543e+18 "(9876543210987654322 - 1) * 1"
	assert_is_equal 0 9.8765432109876543e+19 "1 x 98765432109876543419"
	assert_is_equal 0 9.8765432109876544e+22 "1 * 98765432109876543519000"
	assert_is_equal 0 9.8765432109876544e+25 "1 x 98765432109876543690000000"
	assert_is_equal 0 9.8765432109876544e+30 "1 * 9876543210987654399999999999999"
}

run_significant_digits_test_cases_float_addition_and_subtraction()
{
	# additions and subtractions of floats: 18 significant digits
	assert_is_equal 0 14 "7 + 7.0"
	assert_is_equal 0 31415928 "31415927.0 + 1"
	assert_is_equal 0 31415926535898 "31415926535898-1.0 + 1.0"
	assert_is_equal 0 3141592653589799 "3141592653589799.0 - 0"
	assert_is_equal 0 31415926535897932 "0.0 + 31415926535897932" # 17 digits
	assert_is_equal 0 314159265358979323 "314159265358979320 + 3.0" # 18 digits
	assert_is_equal 0 3.14159265358979324e+18 "-2.0 + 3141592653589793240" # 19 digits
	assert_is_equal 0 3.14159265358979324e+19 "31415926535897932380 + 4.0" # 20 digits
	assert_is_equal 0 3.14159265358979324e+20 "314159265358979323800 - 54.0" # 21 digits
	assert_is_equal 0 3.14159265358979324e+20 "314159265358979323846 + 0.0"

	assert_is_equal 0 3.14159265358979323e+19 "31415926535897932349 + 0.0" # 20 digits
#			  Answer: 3.14159265358979323e+20
#	assert_is_equal 0 3.14159265358979324e+20 "314159265358979323500 + 0.0" # 21 digits
	assert_is_equal 0 3.14159265358979947e+21 "3141592653589799469009.0 + 999"
	assert_is_equal 0 3.14159265358979947e+19 "31415926535897994601.0 + 60"
	assert_is_equal 0 3.14159265358979946e+22 "31415926535897994640000.0 + 9999"

	assert_is_equal 0 9.87654321098765442e+18 "9876543210987654422.0 - 1 + 1"
	assert_is_equal 0 9.87654321098765454e+19 "1.0 + 98765432109876545419"
	assert_is_equal 0 9.87654321098765465e+22 "10.0 +  98765432109876546519000"
	assert_is_equal 0 9.87654321098765487e+25 "98765432109876548690000000 - 10.00"
	assert_is_equal 0 9.876543210987655e+32 "987654321098765499999999999999900.0 + 64"
}

run_significant_digits_test_cases_float_multiplication_and_division()
{
	# multiplications and divisions of floats: 16 significant digits
	assert_is_equal 0 49 "7 * 7.0"
	assert_is_equal 0 31415927 "31415927 x 1.0"
	assert_is_equal 0 3141592653589 "3141592653589.0 x 1"
	assert_is_equal 0 31415926535897 "31415926535897 * 1.0" # 14 digits
	assert_is_equal 0 3.141592653589793 "3.141592653589793 * 1" # 16 digits
	assert_is_equal 0 3.141592653589793 "3.1415926535897932 * 1" # 17 digits

	assert_is_equal 0 3.141592653589793e+16 "31415926535897932 * 1.0" # 17 digits
	assert_is_equal 0 3.141592653589793e+18 "3141592653589793238 x 1.0"
	assert_is_equal 0 3.141592653589793e+20 "314159265358979323846 * 1.0"

	assert_is_equal 0 3141592653585799 "3141592653585799 / 1.0" # 16 digits
	assert_is_equal 0 3.141592653584599e+16 "31415926535845994*2.0 / 2.0" # 17 digits
	assert_is_equal 0 3.141592653584599e+17 "314159265358459947*2.0 / 2.0"
	assert_is_equal 0 3.14159265358048e+22 "31415926535804795323846 * 1.0"

	assert_is_equal 0 9.876543210987654e+18 "9876543210987654422 * 1.0" # 19 digits
	assert_is_equal 0 9.876543210987655e+20 "1 x 987654321098765453419.0"
	assert_is_equal 0 9.876543210987655e+27 "1.0 * 9876543210987654664543519000"
}

run_significant_digits_test_cases()
{
	run_significant_digits_test_cases_integer_addition_and_subtraction
	run_significant_digits_test_cases_integer_multiplication_and_division
	run_significant_digits_test_cases_float_addition_and_subtraction
	run_significant_digits_test_cases_float_multiplication_and_division
}

run_trim_trailing_nines_after_decimal_point__test_cases()
{
	assert_is_equal 0 -0.88888888   "-0.88888888"
	assert_is_equal 0 -0.8888888888 "-0.8888888888"
	assert_is_equal 0 -0.888888888888 "-0.888888888888"
	assert_is_equal 0 -0.888888888888888 "-0.888888888888888"
	assert_is_equal 0 -0.8888888888888889 "-0.888888888888888888"

	assert_is_equal 0 -0.9 "-0.9"
	assert_is_equal 0 -0.99 "-0.99"
	assert_is_equal 0 -0.999 "-0.999"
	assert_is_equal 0 -0.9999 "-0.9999"

	assert_is_equal 0 -0.19999999 "-0.19999999"
	assert_is_equal 0 -0.29999999 "-0.29999999"
	assert_is_equal 0 -0.39999999 "-0.39999999"
	assert_is_equal 0 -0.49999999 "-0.49999999"
	assert_is_equal 0 -0.59999999 "-0.59999999"
	assert_is_equal 0 -0.69999999 "-0.69999999"
	assert_is_equal 0 -0.79999999 "-0.79999999"

	assert_is_equal 0 -0.81999999 "-0.81999999"
	assert_is_equal 0 -0.85999999 "-0.85999999"
	assert_is_equal 0 -0.86999999 "-0.86999999"
	assert_is_equal 0 -0.87999999 "-0.87999999"
	assert_is_equal 0 -0.88999999 "-0.88999999"
	assert_is_equal 0 -0.89999999 "-0.89999999"

	assert_is_equal 0 -0.90999995 "-0.90999995"
	assert_is_equal 0 -0.91999995 "-0.91999995"
	assert_is_equal 0 -0.92999995 "-0.92999995"
	assert_is_equal 0 -0.93999995 "-0.93999995"
	assert_is_equal 0 -0.94999995 "-0.94999995"
	assert_is_equal 0 -0.95999995 "-0.95999995"
	assert_is_equal 0 -0.96999995 "-0.96999995"
	assert_is_equal 0 -0.97999995 "-0.97999995"
	assert_is_equal 0 -0.98999995 "-0.98999995"
	assert_is_equal 0 -0.99999995 "-0.99999995"

	assert_is_equal 0 -0.089999999 "-0.089999999"

	assert_is_equal 0 -0.090999995 "-0.090999995"
	assert_is_equal 0 -0.091999995 "-0.091999995"
	assert_is_equal 0 -0.092999995 "-0.092999995"
	assert_is_equal 0 -0.093999995 "-0.093999995"
	assert_is_equal 0 -0.094999995 "-0.094999995"
	assert_is_equal 0 -0.095999995 "-0.095999995"
	assert_is_equal 0 -0.096999995 "-0.096999995"
	assert_is_equal 0 -0.097999995 "-0.097999995"
	assert_is_equal 0 -0.098999995 "-0.098999995"
	assert_is_equal 0 -0.099999995 "-0.099999995"

	assert_is_equal 0 -0.0089999999 "-0.0089999999"

	assert_is_equal 0 -0.0090999995 "-0.0090999995"
	assert_is_equal 0 -0.0091999995 "-0.0091999995"
	assert_is_equal 0 -0.0092999995 "-0.0092999995"
	assert_is_equal 0 -0.0093999995 "-0.0093999995"
	assert_is_equal 0 -0.0094999995 "-0.0094999995"
	assert_is_equal 0 -0.0095999995 "-0.0095999995"
	assert_is_equal 0 -0.0096999995 "-0.0096999995"
	assert_is_equal 0 -0.0097999995 "-0.0097999995"
	assert_is_equal 0 -0.0098999995 "-0.0098999995"
	assert_is_equal 0 -0.0099999995 "-0.0099999995"

	assert_is_equal 0 0.89999999 "0.89999999"
	assert_is_equal 0 0.089999999 "0.089999999"
	assert_is_equal 0 0.0089999999 "0.0089999999"

	assert_is_equal 0 0.90999995 "0.90999995"
	assert_is_equal 0 0.090999995 "0.090999995"
	assert_is_equal 0 0.0090999995 "0.0090999995"

	assert_is_equal 0 0.99999995 "0.99999995"
	assert_is_equal 0 0.099999995 "0.099999995"
	assert_is_equal 0 0.0099999995 "0.0099999995"

	assert_is_equal 0 -1.89999999 "-1.89999999"
	assert_is_equal 0 -2.89999999 "-2.89999999"
	assert_is_equal 0 -3.89999999 "-3.89999999"
	assert_is_equal 0 -4.89999999 "-4.89999999"
	assert_is_equal 0 -5.89999999 "-5.89999999"
	assert_is_equal 0 -6.89999999 "-6.89999999"
	assert_is_equal 0 -7.89999999 "-7.89999999"
	assert_is_equal 0 -8.89999999 "-8.89999999"
	assert_is_equal 0 -9.89999999 "-9.89999999"

	assert_is_equal 0  9.99999995 "9.99999995"
	assert_is_equal 0 -9.99999995 "-9.99999995"

	assert_is_equal 0 -0.99999 "-0.99999"
	assert_is_equal 0 -0.999999 "-0.999999"
	assert_is_equal 0 -0.9999999 "-0.9999999"
	assert_is_equal 0 -0.99999999 "-0.99999999"
	assert_is_equal 0 -0.999999999 "-0.999999999"
	assert_is_equal 0 -0.9999999999 "-0.9999999999"
	assert_is_equal 0 -0.99999999999 "-0.99999999999"
	assert_is_equal 0 -0.999999999999 "-0.999999999999"
	assert_is_equal 0 -0.9999999999999 "-0.9999999999999"
	assert_is_equal 0 -0.99999999999999 "-0.99999999999999"
	assert_is_equal 0 -1 "-0.999999999999999"

	assert_is_equal 0 -0.99999 "-0.9999900000000008"

	assert_is_equal 0 -0.99999 "-0.9999900000000001"
	assert_is_equal 0 -0.999999 "-0.9999990000000001"
	assert_is_equal 0 -0.9999999 "-0.9999999000000001"
	assert_is_equal 0 -0.99999999 "-0.9999999900000001"
	assert_is_equal 0 -0.999999999 "-0.9999999990000001"
	assert_is_equal 0 -0.9999999999 "-0.9999999999000001"
	assert_is_equal 0 -0.99999999999 "-0.9999999999900001"
	assert_is_equal 0 -0.999999999999 "-0.9999999999990001"
	assert_is_equal 0 -0.9999999999999 "-0.9999999999999001"
	assert_is_equal 0 -0.99999999999999 "-0.9999999999999901"

#                Key: -0.9999999999999991
	assert_is_equal 0 -0.999999999999999 "-0.9999999999999991"

	assert_is_equal 0 0.99999 "0.99999"
	assert_is_equal 0 1 "0.999999999999999"

	assert_is_equal 0 0.99999 "0.9999900000000001"

#                Key: 0.9999999999999991
	assert_is_equal 0 1 "0.9999999999999991"
	# fails
	assert_is_equal 0 1 "0.9999999999999998"

	assert_is_equal 0 0.099999 "0.099999"
	assert_is_equal 0 0.0999999999999999 "0.0999999999999999"

	assert_is_equal 0 0.099999 "0.09999900000000001"

#                Key: 0.09999999999999991
	assert_is_equal 0 0.0999999999999999 "0.09999999999999991"

	assert_is_equal 0 0.0099999 "0.0099999"

	assert_is_equal 0 0.00999999999999999 "0.00999999999999999"

	assert_is_equal 0 0.0099999 "0.009999900000000001"

#                Key: 0.009999999999999991
	assert_is_equal 0 0.00999999999999999 "0.009999999999999991"

	assert_is_equal 0 0.00099999 "0.00099999"
	assert_is_equal 0 0.000999999999999999 "0.000999999999999999"

	# fails
	assert_is_equal 0 9.9999e-04 "0.00099999"
	# fails
	assert_is_equal 0 9.99999999999999e-04 "0.0009999999999999991"

	assert_is_equal 0 -1 "-0.9999999999999999"
}

run_pretty_print_decimal_test_cases()
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
	assert_is_equal 0 3.1415926 "3.1415926"
	assert_is_equal 0 3.14159265 "3.14159265"
	assert_is_equal 0 3.141592653 "3.141592653"
	assert_is_equal 0 3.14159265358979 "3.14159265358979"
	assert_is_equal 0 3.141592653589793 "3.141592653589793"
	assert_is_equal 0 3.141592653589793 "3.141592653589793238"
	assert_is_equal 0 3.141592653589793 "3.1415926535897932384"

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

run_pretty_print_scientific_test_cases()
{
	assert_is_equal 0 3.141592653589793 "3.141592653589793238"
}

run_pretty_print_test_cases()
{
	run_significant_digits_test_cases
	run_trim_trailing_nines_after_decimal_point__test_cases

	run_pretty_print_decimal_test_cases
	run_pretty_print_scientific_test_cases

	assert_is_equal 0 0 "-0"
}

run_multiple_unary_operators_at_beginning_of_expression_test_cases()
{
	assert_is_equal 1 "$invalid_expression" "++1"
	assert_is_equal 1 "$invalid_expression" " ++1"
	assert_is_equal 1 "$invalid_expression" "  ++1"
	assert_is_equal 1 "$invalid_expression" "+ +1"
	assert_is_equal 1 "$invalid_expression" "+ + 1"
	assert_is_equal 1 "$invalid_expression" "++73"
	assert_is_equal 1 "$invalid_expression" "+++1973"

	assert_is_equal 1 "$invalid_expression" "--1"
	assert_is_equal 1 "$invalid_expression" " --1"
	assert_is_equal 1 "$invalid_expression" "  --1"
	assert_is_equal 1 "$invalid_expression" " -  -1"
	assert_is_equal 1 "$invalid_expression" "  -   -  1"
	assert_is_equal 1 "$invalid_expression" "--73"
	assert_is_equal 1 "$invalid_expression" "----73"

	assert_is_equal 1 "$invalid_expression" "+-83"
	assert_is_equal 1 "$invalid_expression" "+ - 83"

	assert_is_equal 1 "$invalid_expression" "-+83"
	assert_is_equal 1 "$invalid_expression" " -  +  83"

	assert_is_equal 1 "$invalid_expression" "+*1"
	assert_is_equal 1 "$invalid_expression" "+/2"
	assert_is_equal 1 "$invalid_expression" "-*3"
	assert_is_equal 1 "$invalid_expression" "-/4"
	assert_is_equal 1 "$invalid_expression" "*+5"
	assert_is_equal 1 "$invalid_expression" "/+6"
	assert_is_equal 1 "$invalid_expression" "*-7"
	assert_is_equal 1 "$invalid_expression" "/-8"
}

run_unary_operator_test_cases()
{
	assert_is_equal 0 7 "+7"
	assert_is_equal 0 1983 "+1983"
	assert_is_equal 0 50 "+50"
	assert_is_equal 0 50 "(+50)"
	assert_is_equal 0 -1 "-1"
	assert_is_equal 0 -318 "-318"
	assert_is_equal 0 -25 "-25"
	assert_is_equal 0 -25 "(-25)"
	assert_is_equal 0 7 "+ 7"
	assert_is_equal 0 -1 "- 1"
	assert_is_equal 0 -10 "-   10"

	assert_is_equal 0 10 "3 + (+7)"
	assert_is_equal 0 10 "3 + +7"
	assert_is_equal 0 5 "50 + (-45)"
	assert_is_equal 0 5 "50 + -45"

	assert_is_equal 0 38 "+38"
	assert_is_equal 0 38 "+(+38)"
	assert_is_equal 0 38 "+(+(+38))"

	assert_is_equal 0 -34 "-34"
	assert_is_equal 0 34 "-(-34)"
	assert_is_equal 0 -34 "-(-(-34))"

	assert_is_equal 0 14 "17 + -(1+2)"
	assert_is_equal 0 20 "17 - -(1+2)"
	assert_is_equal 0 -51 "17 * -(1+2)"

	assert_is_equal 0 83 "83"
	assert_is_equal 0 83 "+83"
	assert_is_equal 0 83 "(+83)"
	assert_is_equal 0 -83 "-(+83)"

	assert_is_equal 0 17 "3++14"
	assert_is_equal 0 -11 "3+-14"
	assert_is_equal 0 -11 "3-+14"
	assert_is_equal 0 17 "3--14"

	assert_is_equal 0 10 "3  +  +  7"
	assert_is_equal 0 -4 "3  +  -  7"
	assert_is_equal 0 5 "50 + - 45"
	assert_is_equal 0 95 "50 + + 45"

	assert_is_equal 0 -4 "3  -  + 7"
	assert_is_equal 0 10 "3  -   -  7"
	assert_is_equal 0 95 "50 -  - 45"
	assert_is_equal 0 5 "50 -+ 45"

	assert_is_equal 0 -1 "1 * -1"
	assert_is_equal 0 -0.5 "1 / -2"
	assert_is_equal 0 3 "1 * +3"
	assert_is_equal 0 -0.2 "1 / -5"

	assert_is_equal 1 "$invalid_expression" "+"
	assert_is_equal 1 "$invalid_expression" \" +\"
	assert_is_equal 1 "$invalid_expression" \"+ \"
	assert_is_equal 1 "$invalid_expression" \" + \"

	assert_is_equal 1 "$invalid_expression" "-"
	assert_is_equal 1 "$invalid_expression" \" -\"
	assert_is_equal 1 "$invalid_expression" \"-  \"
	assert_is_equal 1 "$invalid_expression" \"  -  \"

	assert_is_equal 1 "$invalid_expression" "-  1 00"
}

run_one_number_precision_test_cases()
{
	assert_is_equal 0 5 "5"
	assert_is_equal 0 226 "226"
	assert_is_equal 0 3982 "3982"
	assert_is_equal 0 226 "00226"
	assert_is_equal 0 3982 "03982"
	assert_is_equal 0 1234567890 "1234567890"
	assert_is_equal 0 123456789012345 "123456789012345"

	# find max of long double
	# assert_is_equal 0 123456789012345678900 "123456789012345678900" # answer: 123456789012345678896
	# assert_is_equal 0 12345678901234567890.1 "12345678901234567890.1" # answer: 12345678901234567890
	# assert_is_equal 0 1234567890123456789.1 "1234567890123456789.1" # answer: 1234567890123456789.125
	# assert_is_equal 0 123456789012345678.125 "123456789012345678.125" # answer: 123456789012345678.132812

	assert_is_equal 0 -5 "-5"
	assert_is_equal 0 -226 "-226"
	assert_is_equal 0 -3982 "-3982"
	assert_is_equal 0 -226 "-00226"
	assert_is_equal 0 -3982 -"03982"
	assert_is_equal 0 -1234567890 "-1234567890"
	assert_is_equal 0 -123456789012345 "-123456789012345"
	assert_is_equal 0 -1.234567890123456789e+19 "-12345678901234567890"

	# find min of long double
	# assert_is_equal 0 -123456789012345678900 "-123456789012345678900" # answer: -123456789012345678896
	# assert_is_equal 0 -12345678901234567890.1 "-12345678901234567890.1" # answer: -12345678901234567890
	# assert_is_equal 0 -1234567890123456789.1 "-1234567890123456789.1" # answer: -1234567890123456789.125
	# assert_is_equal 0 -123456789012345678.125 "-123456789012345678.125" # answer: -123456789012345678.132812

	assert_is_equal 0 0.1 ".1"
	assert_is_equal 0 0.1 "0.1"
	assert_is_equal 0 0.1 "00.1"
	assert_is_equal 0 0.1 "000.1"

	assert_is_equal 0 0.1234 ".1234"
	assert_is_equal 0 0.1234 "0.1234"
	assert_is_equal 0 0.1234 "00.1234"
	assert_is_equal 0 0.1234 "000.1234"
	assert_is_equal 0 0.12345 "0.12345"
	assert_is_equal 0 0.123456 "0.123456"
	# 6 decimals is the precision of a long double
	# assert_is_equal 0 0.1234567 "0.1234567" # answer: 0.123457
	# assert_is_equal 0 0.12345678 "0.12345678" # answer: 0.123457

	assert_is_equal 0 -0.12345 "-0.12345"
	assert_is_equal 0 -0.123456 "-0.123456"
	# 6 decimals is the precision of a long double
	# assert_is_equal 0 -0.1234567 "-0.1234567" # answer: -0.123457
	# assert_is_equal 0 -0.12345678 "-0.12345678" # answer: -0.123457

	assert_is_equal 0 1.123457 "1.123457"
	assert_is_equal 0 12.123457 "12.123457"
	assert_is_equal 0 123.123457 "123.123457"
	assert_is_equal 0 1234.123457 "1234.123457"
	assert_is_equal 0 12345.123457 "12345.123457"
	assert_is_equal 0 123456.123457 "123456.123457"
	assert_is_equal 0 1234567.123457 "1234567.123457"
	assert_is_equal 0 12345678.123457 "12345678.123457"
	assert_is_equal 0 123456789.123457 "123456789.123457"
	assert_is_equal 0 1234567890.123457 "1234567890.123457"
	assert_is_equal 0 12345678901.12346 "12345678901.123457"
	assert_is_equal 0 123456789012.1235 "123456789012.123457"
	assert_is_equal 0 1234567890123.123 "1234567890123.123457"
	assert_is_equal 0 12345678901234.12 "12345678901234.123457"
	# assert_is_equal 0 99999999999999.123456 "99999999999999.123456" # answer: 99999999999999.123451
	# assert_is_equal 0 99999999999999.987654 "99999999999999.987654" # answer: 99999999999999.987671
	# assert_is_equal 0 123456789012345.123457 "123456789012345.1234567" # answer: 123456789012345.123451
	# assert_is_equal 0 1234567890123456.123457 "1234567890123456.1234567" # answer: 1234567890123456.123413
	# assert_is_equal 0 12345678901234567.123457 "12345678901234567.1234567" # answer: 12345678901234567.12207

	assert_is_equal 0 -123456789012.1235 "-123456789012.123457"
	assert_is_equal 0 -1234567890123.123 "-1234567890123.123457"
	assert_is_equal 0 -12345678901234.12 "-12345678901234.123457"
	# assert_is_equal 0 -99999999999999.123456 "-99999999999999.123456" # answer: -99999999999999.123451
	# assert_is_equal 0 -99999999999999.987654 "-99999999999999.987654" # answer: -99999999999999.987671
	# assert_is_equal 0 -123456789012345.123457 "-123456789012345.1234567" # answer: -123456789012345.123451
	# assert_is_equal 0 -1234567890123456.123457 "-1234567890123456.1234567" # answer: -1234567890123456.123413
	# assert_is_equal 0 -12345678901234567.123457 "-12345678901234567.1234567" # answer: -12345678901234567.12207

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

run_division_by_zero_test_cases()
{
	assert_is_equal 0 inf "1/0"
	assert_is_equal 0 inf "3.1415 / 0"

	assert_is_equal 0 -inf "-3310 / 552 / 0 x 79 * -489 x -265641"
	assert_is_equal 0 -inf "34*9/85/25/2917/200*78x6167*865x-810*7676/0"
	assert_is_equal 0 inf "28 / 64 / 51179 x 5549 / -702 / 67 * -28 / 0 / 37394771 / 60 * -93 / -118 / 75 / 7"
	assert_is_equal 0 inf "353*33x4148x-62/-2429414066042069329*7714/66/0x877x-6213*-7362/360*6570"

	# 0 / 0 is indeterminate
	assert_is_equal 0 nan "0 / 0"
	assert_is_equal 0 nan "78 x 179230 * -26 x 0 x -967 / 92 * -3 / -71473 x -1763945 / -9029 x -791 x -27 / -169 / 2 / -7 / -8807 * -2630 * 19 / -80 / -7309 / 0 / 9134 * 4 / 78 * 4876 x -3637"
	assert_is_equal 0 nan "4067/-637*-42*21*-51110/-99/15/-347/416/56x-5946/-10216/56/497x6126x51/0/-4/4597/-2962x9x7782/9583/-6519x-53/-111*-34x-71x-9563x13649233490/7x-8566x-397/-8141*0"

	assert_is_equal 0 -nan "0 / 0"
	assert_is_equal 0 -nan "78 x 179230 * -26 x 0 x -967 / 92 * -3 / -71473 x -1763945 / -9029 x -791 x -27 / -169 / 2 / -7 / -8807 * -2630 * 19 / -80 / -7309 / 0 / 9134 * 4 / 78 * 4876 x -3637"
	assert_is_equal 0 -nan "4067/-637*-42*21*-51110/-99/15/-347/416/56x-5946/-10216/56/497x6126x51/0/-4/4597/-2962x9x7782/9583/-6519x-53/-111*-34x-71x-9563x13649233490/7x-8566x-397/-8141*0"

	# calc and bc's answer is divide by zero
	# Chrome's answer is -0.5
	assert_is_equal 0 -0.5 "3.1*(-72.63/-0.28*1.3 - 0.1515*(9.6491/0.727/-99.321 + 1.790 + -45.5) - (-0.9+(-0.5))/(-8.1+91.5+(-28.860/-0.89))/-5279.7)/(-0.973 * -0.3+(-2.512 * -4.3/0.0 + 3273.2) / (-89.9+(-0.29 - -0.161+20.310)) * 3.6)/((0.6+(-70.365 / -0.0)) / 9.6009 + 0.74283 - -982.9)*(7907860.521452139*-0.93*775.4*-270.3 - -0.4 / 0.40114)/(1969.2+9800.7+(-0.6)) * (-0.19 - 0.4) * 21.7 / 0.3*72.5 * -9.48/-7367.6/-0.61855*7.1 / -0.9+(-0.5)"

	# calc returns 0, bc returns divide by zero
	assert_is_equal 0 -nan "([-9.3311 - 0.370 + -0.7-(-0.35)]/[-0.75+[-0.5410-1.260]] - -0.2) / (-3.7+0.7 * -0.458 + -0.31+0.8785)x-0.470x(377.24 / 20.2 / (-888.7 + -346.24)+0.15 + 0.0) x -5.20 x -6582.8/7.7714 / 89.98x-8958.59/-0.6 / [(-0.3-0.563)/0.3 / 0.0x(-0.3-450149.7/-30.50/-8549.9 - 0.7 + -586.8) / (-9.942 - 0.50 / -8.2809)x-24.4-[[-6.114 - 1.62 / 0.0/0.15] / -0.6 + 0.601 / -917.06x80.80 / -6.6198 + -1.5x9.870/2.7/-0.7]/[-0.28394/0.65493 + -0.13139-[-0.754] - (0.8 - -0.7) * -2.5]]*0.370"
}

run_addition_test_cases()
{
	shift 0
}

run_subtraction_test_cases()
{
	shift 0
}

run_addition_subtraction_test_cases()
{
	shift 0
}

run_multiplication_test_cases()
{
	shift 0
}

run_division_test_cases()
{
	shift 0
}

run_multiplication_division_test_cases()
{
	shift 0
}

run_addition_subtraction_multiplication_division_test_cases()
{
	shift 0
}

run_input_output_test_cases()
{
	run_no_expression_test_cases
	run_help_test_cases
	run_floating_point_type_test_cases

	run_expression_buffer_test_cases

	run_read_expression_test_cases
	run_bad_expression_test_cases

	run_brackets_test_cases
	run_xX_test_cases

	run_pretty_print_test_cases
}

run_expression_test_cases()
{
	run_multiple_unary_operators_at_beginning_of_expression_test_cases
	run_unary_operator_test_cases

	run_one_number_precision_test_cases

	run_division_by_zero_test_cases

	run_addition_test_cases
	run_subtraction_test_cases
	run_addition_subtraction_test_cases

	run_multiplication_test_cases
	run_division_test_cases
	run_multiplication_division_test_cases

	run_addition_subtraction_multiplication_division_test_cases
}

run_all_test_cases()
{
	run_input_output_test_cases
	run_expression_test_cases
}

invalid_expression=$(printf "clc: invalid elementary arithmetic expression\nTry 'clc --help' for more information.")

num_assert_total=0
num_assert_failed=0

run_all_test_cases

echo $num_assert_total tests, $((num_assert_total-num_assert_failed)) passed, $num_assert_failed failed.
[ "$num_assert_failed" -eq 0 ] && exit 0 || exit 1
