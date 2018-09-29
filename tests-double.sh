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
	_usage=$(printf "Usage: clc expression\nCommand-line elementary arithmetic calculator, version 1.00\n\nExpression can contain +, -, *, x, /, (), and [].\n\nExamples:\n  clc (8 + 5) / [14 - 14 + 1]   Answer: 13\n  clc 1 + 14 / 4                Answer: 4.5\n  clc 16 / 8 - 21               Answer: -19\n  clc 3141592653/(10000*100000) Answer: 3.141592653")

	assert_is_equal 0 "$_usage" "-h"
	assert_is_equal 0 "$_usage" "-h ignored"
	assert_is_equal 0 "$_usage" "-h -p"
	assert_is_equal 0 "$_usage" "-h --precision"
	assert_is_equal 0 "$_usage" "-h 1+1"

	assert_is_equal 0 "$_usage" "--help"
	assert_is_equal 0 "$_usage" "--help ignored"
	assert_is_equal 0 "$_usage" "--help -p"
	assert_is_equal 0 "$_usage" "--help --precision"
	assert_is_equal 0 "$_usage" "--help 1+1"

	assert_is_equal 1 "$invalid_expression" "h"
	assert_is_equal 1 "$invalid_expression" "H"

	assert_is_equal 1 "$invalid_expression" "--h"
	assert_is_equal 1 "$invalid_expression" "---h"

	assert_is_equal 1 "$invalid_expression" "-H"
	assert_is_equal 1 "$invalid_expression" "-H -p"
	assert_is_equal 1 "$invalid_expression" "-H --precision"

	assert_is_equal 1 "$invalid_expression" "help"
	assert_is_equal 1 "$invalid_expression" "-help"
	assert_is_equal 1 "$invalid_expression" "--Help"
	assert_is_equal 1 "$invalid_expression" "--HELP"
	assert_is_equal 1 "$invalid_expression" "---help"

	assert_is_equal 1 "$invalid_expression" \" -h\"
	assert_is_equal 1 "$invalid_expression" \"-h \"
	assert_is_equal 1 "$invalid_expression" \" -h \"
	assert_is_equal 1 "$invalid_expression" \"-h ignored\"
	assert_is_equal 1 "$invalid_expression" "1+1 -h"

	assert_is_equal 1 "$invalid_expression" \" --help\"
	assert_is_equal 1 "$invalid_expression" \"--help \"
	assert_is_equal 1 "$invalid_expression" \" --help \"
	assert_is_equal 1 "$invalid_expression" \"--help ignored\"
	assert_is_equal 1 "$invalid_expression" "1+1 --help"
}

run_display_precision_test_cases()
{
	local _precision
	_precision='[X] 13-15 digits  [ ] 16-19 digits'

	assert_is_equal 0 "$_precision" "-p"
	assert_is_equal 0 "$_precision" "-p --precision"
	assert_is_equal 0 "$_precision" "-p ignored"
	assert_is_equal 0 "$_precision" "-p --help"
	assert_is_equal 0 "$_precision" "-p 1+1"

	assert_is_equal 0 "$_precision" "--precision"
	assert_is_equal 0 "$_precision" "--precision -p"
	assert_is_equal 0 "$_precision" "--precision ignored"
	assert_is_equal 0 "$_precision" "--precision --help"
	assert_is_equal 0 "$_precision" "--precision 1+1"

	assert_is_equal 1 "$invalid_expression" "p"
	assert_is_equal 1 "$invalid_expression" "P"
	assert_is_equal 1 "$invalid_expression" "-P"
	assert_is_equal 1 "$invalid_expression" "--PRECISION"
	assert_is_equal 1 "$invalid_expression" "--Precision"

	assert_is_equal 1 "$invalid_expression" "--p"
	assert_is_equal 1 "$invalid_expression" "--p --help"

	assert_is_equal 1 "$invalid_expression" "-precision"
	assert_is_equal 1 "$invalid_expression" "-precision --help"

	assert_is_equal 1 "$invalid_expression" "precision"
	assert_is_equal 1 "$invalid_expression" "-precision"
	assert_is_equal 1 "$invalid_expression" "--fp-type"
	assert_is_equal 1 "$invalid_expression" "---p"
	assert_is_equal 1 "$invalid_expression" "---precision"

	assert_is_equal 1 "$invalid_expression" \" -p\"
	assert_is_equal 1 "$invalid_expression" \"-p \"
	assert_is_equal 1 "$invalid_expression" \" -p \"
	assert_is_equal 1 "$invalid_expression" \"-p ignored\"
	assert_is_equal 1 "$invalid_expression" "1+1 -p"

	assert_is_equal 1 "$invalid_expression" \" --precision\"
	assert_is_equal 1 "$invalid_expression" \"--precision \"
	assert_is_equal 1 "$invalid_expression" \" --precision \"
	assert_is_equal 1 "$invalid_expression" \"--precision ignored\"
	assert_is_equal 1 "$invalid_expression" "1+1 --precision"
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

	assert_is_equal 1 "$invalid_expression" "..1"
	assert_is_equal 1 "$invalid_expression" ".1."
	assert_is_equal 1 "$invalid_expression" ".1415."
	assert_is_equal 1 "$invalid_expression" ".14.15"
	assert_is_equal 1 "$invalid_expression" ".14.1.5."

	assert_is_equal 1 "$invalid_expression" ".."
	assert_is_equal 1 "$invalid_expression" "..."
	assert_is_equal 1 "$invalid_expression" ". ."
	assert_is_equal 1 "$invalid_expression" ". .."
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

run_add_decimal_point_test_cases()
{
	assert_is_equal 0 -700000000000000  -700000000000000
	assert_is_equal 0 -7000000000000.0  -7000000000000.
	assert_is_equal 0 -7000000000000.0  -7000000000000.0
	assert_is_equal 0 -7000000000000.0 "-7000000000000 + 0.0"

	assert_is_equal 0 -7000000000000   "-7000000000000 / 1"
	assert_is_equal 0 -7000000000000.0 "-7000000000000. / 1"
	assert_is_equal 0 -7000000000000.0 "-7000000000000 * 1.0"

	assert_is_equal 0 700000000000000  700000000000000
	assert_is_equal 0 7000000000000.0  7000000000000.
	assert_is_equal 0 7000000000000.0  7000000000000.0
	assert_is_equal 0 7000000000000.0 "7000000000000 - 0.0"

	assert_is_equal 0 7000000000000   "7000000000000 * 1"
	assert_is_equal 0 7000000000000.0 "7000000000000. * 1"
	assert_is_equal 0 7000000000000.0 "7000000000000 / 1.0"

	assert_is_equal 0 -314159265358979 "-314159265358979 + 0"
	assert_is_equal 0 -3141592653589.8 "-3141592653589 - 0.846"
	assert_is_equal 0 -3141592653589.9 "-3141592653589.86"

	assert_is_equal 0 314159265358979 "314159265358979 - 0"
	assert_is_equal 0 3141592653589.8 "3141592653589 + 0.846"
	assert_is_equal 0 3141592653589.9 "3141592653589.86"

	assert_is_equal 0 -3141592653589   "-3141592653589 * 1"
	assert_is_equal 0 -3141592653589.0 "-3141592653589 / 1.0"
	assert_is_equal 0 -3141592653589.9 "-3141592653589.86 * 1"

	assert_is_equal 0 3141592653589   "3141592653589 / 1"
	assert_is_equal 0 3141592653589.4 "3141592653589.432 * 1"
	assert_is_equal 0 3141592653589.3 "3141592653589.255 / 1"

	assert_is_equal 0 -20.0 -19.99999999999
	assert_is_equal 0 -124.0 -123.9999999912
	assert_is_equal 0 -987.0 "-986.9999999934 - 0"
	assert_is_equal 0 -32.0 -31.99999999934
	assert_is_equal 0 -31415.0 -31414.99999994
	assert_is_equal 0 -31415.0 -31414.99999999
	assert_is_equal 0 -314149.9999934 -314149.9999934
	assert_is_equal 0 -314149.9999999 -314149.9999999

	assert_is_equal 0 2.0 1.999999999999
	assert_is_equal 0 1234.0 1233.999999912
	assert_is_equal 0 987.0 986.9999999934
	assert_is_equal 0 31415.0 31414.99999994
	assert_is_equal 0 314149.9999934 314149.9999934
	assert_is_equal 0 31414926535.99 31414926535.99

	assert_is_equal 0 -2000.0 "-1999.999999999 x 1"
	assert_is_equal 0 123456.9999912 "123456.9999912 / 1.0"
	assert_is_equal 0 -9866.0 "-9865.999999934 * 1.0"
	assert_is_equal 0 31415.0 "31414.99999994 / 1.0"
	assert_is_equal 0 -31414927.0 "-31414926.99999934 x 1.0"
	assert_is_equal 0 314926535.9999 "314926535.9999 / 1"

	assert_is_equal 0 7e+15 7000000000000000
	assert_is_equal 0 7.0e+13 70000000000000.0
	assert_is_equal 0 7.0e+13 "70000000000000 + 0.0"

	assert_is_equal 0 1e+17 100000000000000000
	assert_is_equal 0 1.0e+17 100000000000000000.0
}

run_scientific_vs_decimal_test_cases()
{
	# decimal only if 0 <= mantissa <= 15-1 for addition/subtraction of integers
	assert_is_equal 0 -1 -1
	assert_is_equal 0 1 1
	assert_is_equal 0 10 10
	assert_is_equal 0 100 100
	assert_is_equal 0 1000 1000
	assert_is_equal 0 10000 10000
	assert_is_equal 0 100000 100000
	assert_is_equal 0 1000000 1000000
	assert_is_equal 0 10000000 10000000
	assert_is_equal 0 100000000 100000000
	assert_is_equal 0 1000000000 1000000000
	assert_is_equal 0 10000000000 10000000000
	assert_is_equal 0 100000000000 100000000000
	assert_is_equal 0 1000000000000 1000000000000
	assert_is_equal 0 10000000000000 10000000000000
	assert_is_equal 0 100000000000000 100000000000000 # 15 digits
	assert_is_equal 0 -100000000000000 -100000000000000 # 15 digits
	assert_is_equal 0 1e+15 1000000000000000 # 16 digits
	assert_is_equal 0 -1e+15 -1000000000000000 # 16 digits
	assert_is_equal 0 1e+16 10000000000000000
	assert_is_equal 0 -1e+16 -10000000000000000
	assert_is_equal 0 1e+18 1000000000000000000 # 19 digits
	assert_is_equal 0 -1e+18 -1000000000000000000 # 19 digits
	assert_is_equal 0 1e+19 10000000000000000000 # 20 digits
	assert_is_equal 0 -1e+19 -10000000000000000000
	assert_is_equal 0 1e+20 100000000000000000000
	assert_is_equal 0 -1e+20 -100000000000000000000
	assert_is_equal 0 1e+45 1000000000000000000000000000000000000000000000
	assert_is_equal 0 -1e+45 -1000000000000000000000000000000000000000000000

	# decimal only if -3 <= mantissa <= 13-1 for addition/subtraction of floats
	assert_is_equal 0 1.0e-21 0.000000000000000000001
	assert_is_equal 0 -1.0e-04 -0.0001
	assert_is_equal 0 1.0e-04 0.0001
	assert_is_equal 0 -0.001 -0.001
	assert_is_equal 0 0.001 0.001
	assert_is_equal 0 0.01 0.01
	assert_is_equal 0 0.1 0.1
	assert_is_equal 0 1.0 1.0
	assert_is_equal 0 -1000000000000.0 -1000000000000.0 # 13 digits in integer
	assert_is_equal 0  1000000000000.0  1000000000000.0 # 13 digits in integer
	assert_is_equal 0 -1.0e+13 -10000000000000.0 # 14 digits in integer
	assert_is_equal 0  1.0e+13  10000000000000.0 # 14 digits in integer
	assert_is_equal 0 -1.0e+17 -100000000000000000.0 # 18 digits in integer
	assert_is_equal 0  1.0e+17  100000000000000000.0 # 18 digits in integer
	assert_is_equal 0 -1.0e+18 -1000000000000000000.0 # 19 digits in integer
	assert_is_equal 0  1.0e+18  1000000000000000000.0 # 19 digits in integer
	assert_is_equal 0  1.0e+27  1000000000000000000000000000.0

	# decimal only if 0 <= mantissa <= 13-1 for multiplication/division of integers
	assert_is_equal 0 -1 "-1 * 1"
	assert_is_equal 0 1 "1 x 1"
	assert_is_equal 0 10 "10 / 1"
	assert_is_equal 0 -1000000000000 "-1000000000000 * 1" # 13 digits
	assert_is_equal 0 1000000000000 "1000000000000 x 1" # 13 digits
	assert_is_equal 0 -1e+13 "-10000000000000 * 1" # 14 digits
	assert_is_equal 0 1e+13 "10000000000000 x 1" # 14 digits
	assert_is_equal 0 -1e+16 "-10000000000000000 * 1" # 17 digits
	assert_is_equal 0 1e+16 "10000000000000000 x 1" # 17 digits
	assert_is_equal 0 -1e+17 "-100000000000000000 * 1" # 18 digits
	assert_is_equal 0 1e+17 "100000000000000000 / 1" # 18 digits
	assert_is_equal 0 1e+19 "10000000000000000000 x 1" # 19 digits
	assert_is_equal 0 1e+23 "100000000000000000000000 / 1"

	# decimal only if -3 <= mantissa <= 13-1 for multiplication/division of floats
	assert_is_equal 0 1.0e-18 "0.000000000000000001 x 1"
	assert_is_equal 0 -1.0e-04 "-0.0001 / 1"
	assert_is_equal 0 1.0e-04 "0.0001 * 1"
	assert_is_equal 0 -0.001 "-0.001 x 1"
	assert_is_equal 0 0.001 "0.001 / 1"
	assert_is_equal 0 0.01 "0.01 * 1"
	assert_is_equal 0 0.1 "0.1 x 1"
	assert_is_equal 0 1.0 "1.0 / 1"
	assert_is_equal 0 10.0 "10.0 * 1"
	assert_is_equal 0 -1000000000000.0 "-1000000000000.0 / 1" # 13 digits
	assert_is_equal 0  1000000000000.0  "1000000000000.0 x 1" # 13 digits
	assert_is_equal 0 -1.0e+13 "-10000000000000.0 / 1" # 14 digits
	assert_is_equal 0  1.0e+13  "10000000000000.0 x 1" # 14 digits
	assert_is_equal 0 -1.0e+15 "-1000000000000000.0 / 1" # 16 digits
	assert_is_equal 0  1.0e+15  "1000000000000000.0 x 1" # 16 digits
	assert_is_equal 0 -1.0e+16 "-10000000000000000.0 / 1" # 17 digits
	assert_is_equal 0  1.0e+16  "10000000000000000.0 x 1" # 17 digits
	assert_is_equal 0  1.0e+17  "100000000000000000.0 / 1" # 18 digits
	assert_is_equal 0  1.0e+21  "1000000000000000000000.0 * 1"
}

run_significant_digits_test_cases_integer_addition_and_subtraction()
{
	# additions and subtractions of integers: 15 significant digits
	assert_is_equal 0 7 "4 + 3"
	assert_is_equal 0 31415 "30000 + 1400 + 15"
	assert_is_equal 0 3141592653 "3141500000 + 92653"
	assert_is_equal 0 314159265358979 "314159265358979" # 15 digits
	assert_is_equal 0 3.14159265358979e+15 "3141592653589793" # 16 digits
	assert_is_equal 0 3.14159265358979e+18 "3141592653589794323" # 19 digits
	assert_is_equal 0 3.14159265358979e+20 "314159265358979232384"
	assert_is_equal 0 3.14159265358979e+21 "3141592653589791323846"

	assert_is_equal 0 123456789012345 "123456789012345 + 0"
	assert_is_equal 0 987654321098764 "987654321098765 - 1"

	assert_is_equal 0 9.87654321098765e+15 "9876543210987650"
	assert_is_equal 0 9.87654321098765e+15 "9876543210987652"
	assert_is_equal 0 9.87654321098765e+15 "9876543210987654"
	assert_is_equal 0 9.87654321098766e+15 "9876543210987655"
	assert_is_equal 0 9.87654321098766e+15 "9876543210987656"
	assert_is_equal 0 9.87654321098766e+15 "9876543210987659"
	assert_is_equal 0 9.87654321098766e+18 "9876543210987659999"

	assert_is_equal 0 1.23456789012345e+15 "1234567890123450"
	assert_is_equal 0 1.23456789012345e+15 "1234567890123454"
	assert_is_equal 0 1.23456789012346e+15 "1234567890123455"
	assert_is_equal 0 1.23456789012346e+15 "1234567890123457"
	assert_is_equal 0 1.23456789012346e+15 "1234567890123459"
	assert_is_equal 0 1.23456789012346e+16 "12345678901234569"
	assert_is_equal 0 1.23456789012345e+22 "12345678901234537899127"

	assert_is_equal 0 -7 "-4 - 3"
	assert_is_equal 0 -30000 "-31415 + 1400 + 15"
	assert_is_equal 0 -3141592653 "-3141500000 - 92653"
	assert_is_equal 0 -314159265358979 "-314159265358979" # 15 digits
	assert_is_equal 0 -3.1415926535898e+16 "-31415926535897993" # 17 digits
	assert_is_equal 0 -3.1415926535898e+21 "-3141592653589799323846"

	assert_is_equal 0 -123456789012345 "-123456789012345 + 0"
	assert_is_equal 0 -987654321098766 "-987654321098765 - 1"

	assert_is_equal 0 -9.87654321098765e+15 "-9876543210987650"
	assert_is_equal 0 -9.87654321098765e+15 "-9876543210987652"
	assert_is_equal 0 -9.87654321098765e+15 "-9876543210987654"
	assert_is_equal 0 -9.87654321098766e+15 "-9876543210987655"
	assert_is_equal 0 -9.87654321098766e+15 "-9876543210987656"
	assert_is_equal 0 -9.87654321098766e+15 "-9876543210987659"
	assert_is_equal 0 -9.87654321098765e+22 "-98765432109876543219999"

	assert_is_equal 0 -1.23456789012345e+15 "-1234567890123450"
	assert_is_equal 0 -1.23456789012345e+15 "-1234567890123454"
	assert_is_equal 0 -1.23456789012346e+15 "-1234567890123455"
	assert_is_equal 0 -1.23456789012346e+15 "-1234567890123457"
	assert_is_equal 0 -1.23456789012346e+15 "-1234567890123459"
	assert_is_equal 0 -1.23456789012346e+20 "-123456789012345678969"
	assert_is_equal 0 -1.23456789012346e+22 "-12345678901234567899127"
}

run_significant_digits_test_cases_integer_multiplication_and_division()
{
	# multiplications and divisions of integers: 13 significant digits
	assert_is_equal 0 12 "4 * 3"
	assert_is_equal 0 31415927 "31415927 x 1"
	assert_is_equal 0 314159265358 "314159265358 x 1" # 12 digits
	assert_is_equal 0 3141592653589 "3141592653589 x 1" # 13 digits
	assert_is_equal 0 3.14159265359e+13 "31415926535898 x 1" # 14 digits

	assert_is_equal 0 3.141592653589e+14 "314159265358923 * 1" # 15 digits
	assert_is_equal 0 3.141592653589e+15 "3141592653589479 x 1" # 16 digits
	assert_is_equal 0 3.141592653589e+16 "31415926535890792 x 1" # 17 digits
	assert_is_equal 0 3.141592653589e+17 "314159265358917932 x 1" # 18 digits
	assert_is_equal 0 3.141592653589e+18 "3141592653589379323 x 1" # 19 digits
	assert_is_equal 0 3.141592653589e+19 "31415926535892793238 x 1" # 20 digits
	assert_is_equal 0 3.141592653589e+20 "314159265358947932384 x 1" # 21 digits

	assert_is_equal 0 9.876543210988e+18 "(9876543210987654322 - 1) * 1"
	assert_is_equal 0 9.876543210988e+19 "1 x 98765432109876543419"
	assert_is_equal 0 9.876543210988e+22 "1 * 98765432109876543519000"
	assert_is_equal 0 9.876543210988e+25 "1 x 98765432109876543690000000"
	assert_is_equal 0 9.876543210988e+30 "1 * 9876543210987654399999999999999"

	assert_is_equal 0 -12 "-4 * 3"
	assert_is_equal 0 -31415927 "-31415927 x 1"
	assert_is_equal 0 -314159265358 "-314159265358 x 1" # 13 digits
	assert_is_equal 0 -3141592653589 "-3141592653589 x 1" # 13 digits
	assert_is_equal 0 -3.14159265359e+13 "-31415926535898 x 1" # 14 digits
	assert_is_equal 0 -3.14159265359e+15 "-3141592653589799 * 1"
	assert_is_equal 0 -3.14159265359e+15 "-3141592653589792 x 1" # 16 digits
	assert_is_equal 0 -3.14159265359e+16 "-31415926535897923 x 1" # 17 digits
	assert_is_equal 0 -3.14159265359e+17 "-314159265358979323 x 1" # 18 digits
	assert_is_equal 0 -3.14159265359e+18 "-3141592653589793238 x 1" # 19 digits
	assert_is_equal 0 -3.14159265359e+19 "-31415926535897932384 x 1" # 20 digits
	assert_is_equal 0 -3.14159265359e+20 "-314159265358979323846 x 1" # 21 digits

	assert_is_equal 0 -9.876543210988e+18 "-(9876543210987654322 - 1) * 1"
	assert_is_equal 0 -9.876543210988e+19 "1 x -98765432109876543419"
	assert_is_equal 0 -9.876543210988e+22 "1 * -98765432109876543519000"
	assert_is_equal 0 -9.876543210988e+25 "1 x -98765432109876543690000000"
	assert_is_equal 0 -9.876543210988e+30 "1 * -9876543210987654399999999999999"
}

run_significant_digits_test_cases_float_addition_and_subtraction()
{
	# additions and subtractions of floats: 13 significant digits
	assert_is_equal 0 1.123456789012 1.123456789012
	assert_is_equal 0 12.12345678901 12.12345678901
	assert_is_equal 0 123.123456789  123.1234567890
	assert_is_equal 0 1234.123456789 1234.123456789
	assert_is_equal 0 12345.12345678 12345.12345678
	assert_is_equal 0 123456.1234567 123456.1234567
	assert_is_equal 0 1234567.123456 1234567.123456
	assert_is_equal 0 12345678.12345 12345678.12345
	assert_is_equal 0 123456789.1234 123456789.1234
	assert_is_equal 0 1234567890.123 1234567890.123
	assert_is_equal 0 12345678901.12 12345678901.12
	assert_is_equal 0 123456789012.1 123456789012.1
	assert_is_equal 0 1234567890123.0 1234567890123.

	assert_is_equal 0 -1.123456789012 -1.123456789012
	assert_is_equal 0 -1239.012345671 -1239.012345671
	assert_is_equal 0 -123456.1234567 -123456.1234567
	assert_is_equal 0 -123456789012.1 -123456789012.1

	assert_is_equal 0 14.0 "7 + 7.0"
	assert_is_equal 0 31415928.0 "31415927.0 + 1"
	assert_is_equal 0 314159265358.0 "314159265358-1.0 + 1.0" # 12 digits
	assert_is_equal 0 3141592653589.0 "3141592653589-1.0 + 1.0" # 13 digits
	assert_is_equal 0 3.141592653589e+13 "31415926535892-1.0 + 1.0" # 14 digits
	assert_is_equal 0 3.141592653589e+15 "3141592653589199.0 - 0"
	assert_is_equal 0 3.141592653589e+16 "0.0 + 31415926535892932" # 17 digits
	assert_is_equal 0 3.141592653589e+17 "314159265358939320 + 3.0" # 18 digits
	assert_is_equal 0 3.141592653589e+18 "-2.0 + 3141592653589493240" # 19 digits
	assert_is_equal 0 3.141592653589e+19 "31415926535893932380 + 4.0" # 20 digits
	assert_is_equal 0 3.141592653589e+20 "314159265358929323800 - 54.0" # 21 digits
	assert_is_equal 0 3.141592653589e+20 "314159265358919323846 + 0.0"

	assert_is_equal 0 3.141592653583e+14 "314159265358349 + 0.0" # 15 digits
	assert_is_equal 0 3.141592653584e+15 "3141592653583500 + 0.0" # 16 digits
	assert_is_equal 0 3.141592653587e+16 "31415926535869009.0 + 999"
	assert_is_equal 0 3.141592653587e+14 "314159265358601.0 + 60"
	assert_is_equal 0 3.141592653586e+17 "314159265358640000.0 + 9999"

	assert_is_equal 0 9.876543210942e+13 "98765432109422.0 - 1 + 1" # 14+1 digits
	assert_is_equal 0 9.876543210984e+14 "1.0 + 987654321098419" # 15 digits
	assert_is_equal 0 9.876543210985e+17 "10.0 + 987654321098519000" # 18 digits
	assert_is_equal 0 9.876543210987e+20 "987654321098690000000 - 10.00" # 21 digits
	assert_is_equal 0 9.876543211e+27    "9876543210999999999999999900.0 + 64" # 28 digits

	assert_is_equal 0 -14.0 "-7 + -7.0"
	assert_is_equal 0 -31415928.0 "-31415927.0 - 1"
	assert_is_equal 0 -314159265358.0 "-314159265358-1.0 + 1.0" # 12 digits
	assert_is_equal 0 -3141592653589.0 "-3141592653589-1.0 + 1.0" # 13 digits
	assert_is_equal 0 -3.14159265359e+13  "-31415926535898-1.0 + 1.0" # 14 digits

	assert_is_equal 0 -31415926535.0 "-31415926535.0 - 0"
	assert_is_equal 0 -314159265358.0 "0.0 + -314159265358" # 12 digits
	assert_is_equal 0 -3141592653583.0 "-3141592653580 + -3.0" # 13 digits
	assert_is_equal 0 -3.141592653584e+13 "-2.0 + -31415926535840" # 14 digits
	assert_is_equal 0 -3.141592653584e+14 "-314159265358380 - 4.0" # 15 digits
	assert_is_equal 0 -3.141592653584e+15 "-3141592653583800 + 54.0" # 16 digits
	assert_is_equal 0 -3.141592653584e+15 "-3141592653583846 + 0.0"

	assert_is_equal 0 -3.141592653583e+14 "-314159265358349 + 0.0" # 15 digits
	assert_is_equal 0 -3.141592653584e+15 "-3141592653583500 + 0.0" # 16 digits
	assert_is_equal 0 -3.141592653587e+16 "-31415926535869009.0 - 999"
	assert_is_equal 0 -3.141592653587e+14 "-314159265358601.0 - 60"
	assert_is_equal 0 -3.141592653586e+17 "-314159265358640000.0 - 9999"

	assert_is_equal 0 -9.876543210982e+13 "-98765432109822.0 - 1 + 1"
	assert_is_equal 0 -9.876543210984e+14 "-1.0 + -987654321098419"
	assert_is_equal 0 -9.876543210985e+17 "-10.0 + -987654321098519000"
	assert_is_equal 0 -9.876543210987e+20 "-987654321098690000000 - -10.00"
	assert_is_equal 0 -9.87654321099e+27  "-9876543210989999999999999900.0 + -64"
}

run_significant_digits_test_cases_float_multiplication_and_division()
{
	# multiplications and divisions of floats: 13 significant digits
	assert_is_equal 0 49.0 "7 * 7.0"
	assert_is_equal 0 31415927.0 "31415927 x 1.0"
	assert_is_equal 0 3141592653589.0 "3141592653589.0 x 1" # 13 digits
	assert_is_equal 0 3.14159265359e+13 "31415926535897 * 1.0" # 14 digits
	assert_is_equal 0 3.14159265359 "3.141592653589793 * 1" # 16 digits
	assert_is_equal 0 3.14159265359 "3.1415926535897932 * 1" # 17 digits

	assert_is_equal 0 3.141592653583e+13 "31415926535832 * 1.0" # 14 digits
	assert_is_equal 0 3.141592653583e+15 "3141592653583238 x 1.0"
	assert_is_equal 0 3.141592653583e+17 "314159265358323846 * 1.0"

	assert_is_equal 0 3141592653799.0    "3141592653799 / 1.0" # 13 digits
	assert_is_equal 0 3.141592653599e+13 "31415926535994*2.0 / 2.0" # 14 digits
	assert_is_equal 0 3.141592653599e+14 "314159265359947*2.0 / 2.0" # 15 digits
	assert_is_equal 0 3.14159265358e+19  "31415926535795323846 * 1.0" # 20 digits

	assert_is_equal 0 9.876543210984e+15 "9876543210984422 * 1.0" # 16 digits
	assert_is_equal 0 9.876543210985e+17 "1 x 987654321098453419.0" # 18 digits
	assert_is_equal 0 9.876543210985e+24 "1.0 * 9876543210984664543519000" # 25 digits

	assert_is_equal 0 49.0 "-7 * -7.0"
	assert_is_equal 0 -31415927.0 "-31415927 x 1.0"
	assert_is_equal 0 -3141592653589.0 "-3141592653589.0 x 1" # 13 digits

	assert_is_equal 0 -3141592653589.0   "-3141592653589.0 x 1" # 13 digits
	assert_is_equal 0 -3.14159265359e+13 "-31415926535897 * 1.0" # 14 digits
	assert_is_equal 0 -3.14159265359 "-3.141592653589793 * 1" # 16 digits
	assert_is_equal 0 -3.14159265359 "-3.1415926535897932 * 1" # 17 digits

	assert_is_equal 0 -3.141592653583e+13 "-31415926535832 * 1.0" # 14 digits
	assert_is_equal 0 -3.141592653583e+15 "-3141592653583238 x 1.0"
	assert_is_equal 0 -3.141592653583e+17 "-314159265358323846 * 1.0"

	assert_is_equal 0 -3141592653799.0    "-3141592653799 / 1.0" # 13 digits
	assert_is_equal 0 -3.141592653584e+13 "-31415926535844*2.0 / 2.0" # 14 digits
	assert_is_equal 0 -3.141592653584e+14 "-314159265358447*2.0 / 2.0"
	assert_is_equal 0 -3.141592653585e+17 "-314159265358479530 * 1.0"

	assert_is_equal 0 -9.876543210984e+15 "-9876543210984422 * 1.0" # 16 digits
	assert_is_equal 0 -9.876543210985e+17 "1 x -987654321098453419.0"
	assert_is_equal 0 -9.876543210985e+24 "1.0 * -9876543210984664543519000"
}

run_trim_trailing_nines_after_decimal_point_test_cases()
{
	# truncate if 8 <= n <= 15-17, where n = nine count + up to 2 non-nines
	# 15 (*/ float), 15 (*/ int), 15 (+- float), 17 (+- int)
	assert_is_equal 0 0.1234569999999 "0.1234569999999" # 6 + 7 9's
	assert_is_equal 0 0.1234599999673 "0.1234599999673" # 5 + 5 9's + 3 non-9

	assert_is_equal 0 -0.12346 "-0.1234599999999" # 5 + 8 9's
	assert_is_equal 0 -0.12346 "-0.1234599999994" # 5 + 7 9's + 1 non-9
	assert_is_equal 0 -0.12346 "-0.1234599999973" # 5 + 6 9's + 2 non-9
	assert_is_equal 0  0.12346  "0.1234599999999" # 5 + 8 9's
	assert_is_equal 0  0.12347  "0.1234699999994" # 5 + 7 9's + 1 non-9
	assert_is_equal 0  0.12346  "0.1234599999973" # 5 + 6 9's + 2 non-9
	assert_is_equal 0  0.124    "0.1239999999999" # 3 + 10 9's

	assert_is_equal 0 0.2 0.1999999999999 # 1 + 12 9's
	assert_is_equal 0 1.0 0.9999999999999 # 13 9's
	assert_is_equal 0 1.0 0.9999999999995 # 12 9's + 1 non-9

	assert_is_equal 0 7.9999912 7.9999912 # 5 9's + 2 non-9
	assert_is_equal 0 7.999999999123 7.999999999123 # 9 9's + 3 non-9

	assert_is_equal 0 -1.0 -0.9999999999999 # 13 9's
	assert_is_equal 0 -1.0 -0.9999999999995 # 12 9's + 1 non-9
	assert_is_equal 0 -8.0 -7.999999999912 # 10 9's + 2 non-9
	assert_is_equal 0 -7.999999999123 -7.999999999123 # 9 9's + 3 non-9
	assert_is_equal 0 8.0 7.999999999912 # 10 9's + 2 non-9
	assert_is_equal 0 7.999999999123 7.999999999123 # 9 9's + 3 non-9

	assert_is_equal 0 123456.9999999 "123456.9999999" # 7 9's
	assert_is_equal 0 -12346.0 -12345.99999999 # 8 9's
	assert_is_equal 0 -12346.0 -12345.99999998 # 7 9's + 1 non-9
	assert_is_equal 0 -12346.0 -12345.99999932 # 6 9's + 2 non-9
	assert_is_equal 0  12346.0 12345.99999999 # 8 9's
	assert_is_equal 0  12346.0 12345.99999998 # 7 9's + 1 non-9
	assert_is_equal 0  12346.0 12345.99999932 # 6 9's + 2 non-9
	assert_is_equal 0 12345.99999323 12345.99999323 # 5 9's + 3 non-9
	assert_is_equal 0 124.0 123.9999999999 # 10 9's

	assert_is_equal 0 123.9019999999 123.9019999999 # 7 9's
	assert_is_equal 0 -123.91 -123.9099999999 # 8 9's
	assert_is_equal 0 -123.91 -123.9099999998 # 7 9's + 1 non-9
	assert_is_equal 0 -123.91 -123.9099999932 # 6 9's + 2 non-9
	assert_is_equal 0  123.91  123.9099999999 # 8 9's
	assert_is_equal 0  123.91  123.9099999998 # 7 9's + 1 non-9
	assert_is_equal 0  123.91  123.9099999932 # 6 9's + 2 non-9
	assert_is_equal 0  123.9099999323 123.9099999323 # 5 9's + 3 non-9

	assert_is_equal 0 1234519999999.0 1234519999999.0 # len=13, 7 9's before .
	assert_is_equal 0 1234099999999.0 1234099999999.0 # len=15, 8 9's before .
	assert_is_equal 0 123459.9999999 123459.9999999 # 7 9's after .
	assert_is_equal 0 -12341.0 -12340.99999999 # 8 9's after .
	assert_is_equal 0  12341.0  12340.99999999 # 8 9's after .

	assert_is_equal 0 0.01234519999999 0.01234519999999 # 7 9's
	assert_is_equal 0 -0.012341 -0.01234099999999 # 8 9's
	assert_is_equal 0  0.012341  0.01234099999999 # 8 9's

	assert_is_equal 0 0.001234019999999 0.001234019999999 # 7 9's
	assert_is_equal 0 -0.0012341 -0.001234099999999 # 8 9's
	assert_is_equal 0  0.0012341  0.001234099999999 # 8 9's

	assert_is_equal 0 0.129 "0.12899999999 * 1" # 3 + 8 9's
	assert_is_equal 0 0.12349 "0.1234899999994 / 1" # 3 + 7 9's + 1 non-9
	assert_is_equal 0 0.12349 "0.1234899999973 * 1" # 3 + 6 9's + 2 non-9

	assert_is_equal 0 1.234099999999e-04 0.0001234099999999 # 8 9's

	# 8 9's -> 0.999999990000000000 -> 0.99999999
	assert_is_equal 0 0.99999999 "0.99999999"
}

run_trim_trailing_zeros_and_nonzero_after_decimal_point_test_cases()
{
	# truncate if 5 <= n <= (15-17)-1, where n = zero count + up to 2 non-zeros
	# 15-1 (*/ float), 15-1 (*/ int), 15-1 (+- float), 17-1 (+- int)
	assert_is_equal 0 12345673.00001 12345673.00001
	assert_is_equal 0 12345673.00012 12345673.00012

	assert_is_equal 0 -1234567.3 -1234567.300001
	assert_is_equal 0 -1234567.3 -1234567.300012

	assert_is_equal 0 1234567.3 1234567.300001
	assert_is_equal 0 1234567.3 1234567.300012

	assert_is_equal 0 123.4567890001 123.4567890001
	assert_is_equal 0 123.4567890012 123.4567890012

	assert_is_equal 0 -123.45673 -123.4567300001
	assert_is_equal 0 -123.45673 -123.4567300012

	assert_is_equal 0 123.45673 123.4567300001
	assert_is_equal 0 123.45673 123.4567300012

	assert_is_equal 0 123.4562  123.4562000002
	assert_is_equal 0 123.4562  123.4562000023

	assert_is_equal 0 123.451   123.4510000003
	assert_is_equal 0 123.451   123.4510000034

	assert_is_equal 0 123.9     123.9000000004
	assert_is_equal 0 123.9     123.9000000045

	assert_is_equal 0 1.45678      1.456780000005
	assert_is_equal 0 1.45678      1.456780000056

	assert_is_equal 0 1.4567       1.456700000006
	assert_is_equal 0 1.4567       1.456700000067

	assert_is_equal 0 1.456        1.456000000007
	assert_is_equal 0 1.456        1.456000000078

	assert_is_equal 0 1.45         1.450000000007
	assert_is_equal 0 1.45         1.450000000078

	assert_is_equal 0 -1.4        -1.400000000008
	assert_is_equal 0 -1.4        -1.400000000089

	assert_is_equal 0 1.4          1.400000000008
	assert_is_equal 0 1.4          1.400000000089

	assert_is_equal 0 1.000000000009 1.000000000009
	assert_is_equal 0 1.000000000091 1.000000000091

	assert_is_equal 0 -0.123          -0.1230000000009
	assert_is_equal 0 -0.123          -0.1230000000091

	assert_is_equal 0 0.123            0.1230000000009
	assert_is_equal 0 0.123            0.1230000000091

	assert_is_equal 0 0.12             0.1200000000008
	assert_is_equal 0 0.12             0.1200000000098

	assert_is_equal 0 0.1              0.1000000000007
	assert_is_equal 0 0.1              0.1000000000087

	assert_is_equal 0 0.02             0.02000000000006
	assert_is_equal 0 0.02             0.02000000000076

	assert_is_equal 0 -0.003          -0.003000000000006
	assert_is_equal 0 -0.003          -0.003000000000076

	assert_is_equal 0 0.003            0.003000000000006
	assert_is_equal 0 0.003            0.003000000000076

	assert_is_equal 0 3.000000000006e-04 0.0003000000000006
	assert_is_equal 0 3.000000000076e-04 0.0003000000000076

	assert_is_equal 0 -123.4      "-123.4000000008 / 1"
	assert_is_equal 0 -123.4      "-123.4000000089 / 1"

	assert_is_equal 0 123.4        "123.4000000008 / 1"
	assert_is_equal 0 123.4        "123.4000000089 / 1"

	assert_is_equal 0 123.00000009 "123.00000009 / 1"
	assert_is_equal 0 123.00000091 "123.00000091 / 1"

	assert_is_equal 0 0.003 "0.003000000000006 * 1.0"
	assert_is_equal 0 0.003 "0.003000000000076 * 1.0"

	assert_is_equal 0 123.4000000789 123.4000000789
	assert_is_equal 0 123.400000009  123.4000000090
	assert_is_equal 0 123.40000009   123.4000000900

	assert_is_equal 0 123456789050001 123456789050001
	assert_is_equal 0 123456789050012 123456789050012
}

run_trim_trailing_zeros_after_decimal_point_decimals_test_cases()
{
	assert_is_equal 0 0.0                  0.000000000000
	assert_is_equal 0 9.0                  9.000000000000
	assert_is_equal 0 98.0                 98.00000000000
	assert_is_equal 0 987.0                987.0000000000
	assert_is_equal 0 9876.0               9876.000000000
	assert_is_equal 0 98765.0              98765.00000000
	assert_is_equal 0 987654.0             987654.0000000
	assert_is_equal 0 9876543.0            9876543.000000
	assert_is_equal 0 98765432.0           98765432.00000
	assert_is_equal 0 987654321.0          987654321.0000
	assert_is_equal 0 9876543210.0         9876543210.000
	assert_is_equal 0 98765432109.0        98765432109.00
	assert_is_equal 0 987654321098.0       987654321098.0
	assert_is_equal 0 9876543210987.0      9876543210987.

	assert_is_equal 0 987654321.0987 987654321.0987
	assert_is_equal 0 987654321.5    987654321.5000
	assert_is_equal 0 9876543210.9   9876543210.900
	assert_is_equal 0 98765432109.8  98765432109.80
	assert_is_equal 0 987654321098.7 987654321098.7

	assert_is_equal 0 0.98765432109    0.9876543210900
	assert_is_equal 0 0.987654         0.9876540000000
	assert_is_equal 0 0.98             0.9800000000000

	assert_is_equal 0 0.09876543210987 0.09876543210987
	assert_is_equal 0 0.09876          0.09876000000000
	assert_is_equal 0 0.09             0.09000000000000

	assert_is_equal 0 0.00987654321098 0.009876543210980
	assert_is_equal 0 0.0098765432     0.009876543200000
	assert_is_equal 0 0.0098765        0.009876500000000

	assert_is_equal 0 0.0              -0.000000000000
	assert_is_equal 0 -9.0             -9.000000000000
	assert_is_equal 0 -98765.0         -98765.00000000
	assert_is_equal 0 -987654.0        -987654.0000000
	assert_is_equal 0 -9876543210987.0 -9876543210987.
	assert_is_equal 0 -987654321.5     -987654321.5000
	assert_is_equal 0 -98765432109.3   -98765432109.30

	assert_is_equal 0 -0.98765432109   -0.9876543210900
	assert_is_equal 0 -0.98765432      -0.9876543200000
	assert_is_equal 0 -0.9876543       -0.9876543000000

	assert_is_equal 0 -0.09876543210987 -0.09876543210987
	assert_is_equal 0 -0.09876          -0.09876000000000
	assert_is_equal 0 -0.09             -0.09000000000000

	assert_is_equal 0 -0.00987654321098 -0.009876543210980
	assert_is_equal 0 -0.0098765432     -0.009876543200000
	assert_is_equal 0 -0.0098765        -0.009876500000000

	assert_is_equal 0 98765432100000 98765432100000
}

run_trim_trailing_zeros_after_decimal_point_scientific_notation_test_cases()
{
	assert_is_equal 0 6.0221409e+18 6022140900000000000
	assert_is_equal 0 602214096022140      602214096022140
	assert_is_equal 0 6.0221409602214e+15  6022140960221400
	assert_is_equal 0 6.02214096022149e+18 6022140960221490000
	assert_is_equal 0 6.02214096022149e+29 602214096022149000000000000000

	assert_is_equal 0 -6.0221409e+23        -602214090000000000000000
	assert_is_equal 0 -602214096022149      -602214096022149
	assert_is_equal 0 -6.02214096022149e+15 -6022140960221490
	assert_is_equal 0 -6.02214096022149e+19 -60221409602214900000
	assert_is_equal 0 -6.02214096022149e+29 -602214096022149000000000000000

	assert_is_equal 0 2.718281828459 2.7182818284585
	assert_is_equal 0 0.002718281828459 0.002718281828459

	assert_is_equal 0 2.0e-26            0.0000000000000000000000000200000000000000000
	assert_is_equal 0 2.71e-19           0.000000000000000000271000000000000000
	assert_is_equal 0 2.718281e-15       0.00000000000000271828100000000000
	assert_is_equal 0 2.718281828459e-09 0.00000000271828182845900000

	assert_is_equal 0 -0.002718281828459 -0.002718281828459

	assert_is_equal 0 -2.0e-26                 -0.0000000000000000000000000200000000000000000
	assert_is_equal 0 -2.71e-19                -0.000000000000000000271000000000000000
	assert_is_equal 0 -2.718281e-15            -0.00000000000000271828100000000000
	assert_is_equal 0 -2.718281828459e-09      -0.00000000271828182845900000

	assert_is_equal 0 2.718281828459e-04 0.0002718281828459
	assert_is_equal 0 2.71828182845e-04  0.0002718281828450
	assert_is_equal 0 2.7182818284e-04   0.0002718281828400
	assert_is_equal 0 2.718281828e-04    0.0002718281828000
	assert_is_equal 0 2.7182818e-04      0.0002718281800000
	assert_is_equal 0 2.718281e-04       0.0002718281000000
	assert_is_equal 0 2.71828e-04        0.0002718280000000
	assert_is_equal 0 2.7182e-04         0.0002718200000000
	assert_is_equal 0 2.718e-04          0.0002718000000000
	assert_is_equal 0 2.71e-04           0.0002710000000000
	assert_is_equal 0 2.7e-04            0.0002700000000000
	assert_is_equal 0 2.0e-04            0.0002000000000000
	assert_is_equal 0 2.0e-05            0.000020000000000000000
	assert_is_equal 0 2.0e-06            0.000002000000000000000
	assert_is_equal 0 2.0e-07            0.000000200000000000000
	assert_is_equal 0 2.0e-08            0.000000020000000000000
	assert_is_equal 0 2.0e-09            0.000000002000000000000
	assert_is_equal 0 2.0e-10            0.000000000200000000000
	assert_is_equal 0 2.0e-11            0.000000000020000000000
	assert_is_equal 0 2.0e-12            0.000000000002000000000
	assert_is_equal 0 2.0e-13            0.000000000000200000000
	assert_is_equal 0 2.0e-14            0.000000000000020000000
	assert_is_equal 0 2.0e-15            0.000000000000002000000
	assert_is_equal 0 2.0e-16            0.000000000000000200000
	assert_is_equal 0 2.0e-17            0.000000000000000020000
	assert_is_equal 0 2.0e-18            0.000000000000000002000
	assert_is_equal 0 2.0e-19            0.000000000000000000200
	assert_is_equal 0 2.0e-20            0.000000000000000000020
	assert_is_equal 0 2.0e-21            0.000000000000000000002
	assert_is_equal 0 0.0                0.000000000000000000000

	assert_is_equal 0 -2.718281828459e-04 -0.0002718281828459
	assert_is_equal 0 -2.7182818284e-04   -0.0002718281828400
	assert_is_equal 0 -2.71e-04           -0.0002710000000000
	assert_is_equal 0 -2.0e-04            -0.0002000000000000
	assert_is_equal 0 -2.0e-11            -0.0000000000200000
	assert_is_equal 0 -2.0e-21            -0.000000000000000000002
	assert_is_equal 0 0.0                 -0.000000000000000000000
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

run_unusual_decimal_test_cases()
{
	assert_is_equal 0 314.0 314.

	assert_is_equal 0 314.15 "0314.15"
	assert_is_equal 0 314.15 "000314.15"
	assert_is_equal 0 314.15 "00000314.15"
	assert_is_equal 0 314.15 "0000000314.15"
	assert_is_equal 0 314.15 "000000000000000000314.15"

	assert_is_equal 0 0.1415 ".1415"
	assert_is_equal 0 0.1415 "0.1415"
	assert_is_equal 0 0.1415 "00.1415"
	assert_is_equal 0 0.1415 "000.1415"
	assert_is_equal 0 0.1415 "0000000.1415"
	assert_is_equal 0 0.1415 "00000000000000000000.1415"

	assert_is_equal 0 0.0 -0.0
	assert_is_equal 0 0 -0
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

run_significant_digits_test_cases()
{
	run_significant_digits_test_cases_integer_addition_and_subtraction
	run_significant_digits_test_cases_integer_multiplication_and_division
	run_significant_digits_test_cases_float_addition_and_subtraction
	run_significant_digits_test_cases_float_multiplication_and_division
}

run_pretty_print_test_cases()
{
	run_add_decimal_point_test_cases
	run_scientific_vs_decimal_test_cases

	run_significant_digits_test_cases

	run_trim_trailing_nines_after_decimal_point_test_cases
	run_trim_trailing_zeros_and_nonzero_after_decimal_point_test_cases

	run_trim_trailing_zeros_after_decimal_point_decimals_test_cases
	run_trim_trailing_zeros_after_decimal_point_scientific_notation_test_cases
}

run_input_output_test_cases()
{
	run_no_expression_test_cases
	run_help_test_cases
	run_display_precision_test_cases

	run_expression_buffer_test_cases

	run_read_expression_test_cases
	run_bad_expression_test_cases

	run_brackets_test_cases
	run_xX_test_cases

	run_pretty_print_test_cases
}

run_expression_test_cases()
{
	run_unary_operator_test_cases
	run_multiple_unary_operators_at_beginning_of_expression_test_cases

	run_unusual_decimal_test_cases

	run_division_by_zero_test_cases
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
