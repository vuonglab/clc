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
	_precision=$(./clc --precision)

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
	assert_is_equal 0 -7000000000000000000   -7000000000000000000
	assert_is_equal 0 -700000000000000000.0  -700000000000000000.
	assert_is_equal 0 -700000000000000000.0  -700000000000000000.0
	assert_is_equal 0 -700000000000000000.0 "-700000000000000000 + 0.0"

	assert_is_equal 0 -70000000000000000    "-70000000000000000 / 1"
	assert_is_equal 0 -7000000000000000.0   "-7000000000000000. / 1"
	assert_is_equal 0 -7000000000000000.0   "-7000000000000000 * 1.0"

	assert_is_equal 0 7000000000000000000   7000000000000000000
	assert_is_equal 0 700000000000000000.0  700000000000000000.
	assert_is_equal 0 700000000000000000.0  700000000000000000.0
	assert_is_equal 0 700000000000000000.0 "700000000000000000 - 0.0"

	assert_is_equal 0 70000000000000000    "70000000000000000 * 1"
	assert_is_equal 0 7000000000000000.0   "7000000000000000. * 1"
	assert_is_equal 0 7000000000000000.0   "7000000000000000 / 1.0"

	assert_is_equal 0 -3141592653589793238  "-3141592653589793238 + 0"
	assert_is_equal 0 -314159265358979323.8 "-314159265358979323 - 0.846"
	assert_is_equal 0 -314159265358979323.9 "-314159265358979323.85"

	assert_is_equal 0 3141592653589793238  "3141592653589793238 - 0"
	assert_is_equal 0 314159265358979323.8 "314159265358979323 + 0.846"
	assert_is_equal 0 314159265358979323.9 "314159265358979323.85"

	assert_is_equal 0 -31415926535897932  "-31415926535897932 * 1"
	assert_is_equal 0 -3141592653589793.0 "-3141592653589793 / 1.0"
	assert_is_equal 0 -3141592653589793.9 "-3141592653589793.85 * 1"

	assert_is_equal 0 31415926535897932  "31415926535897932 / 1"
	assert_is_equal 0 3141592653589793.4 "3141592653589793.432 * 1"
	assert_is_equal 0 3141592653589793.3 "3141592653589793.255 / 1"

	assert_is_equal 0 -20.0 -19.9999999999999999
	assert_is_equal 0 -12345678.0 -12345677.9999999912
	assert_is_equal 0 -987.0 "-986.999999999999934 - 0"
	assert_is_equal 0 -31415.0 -31414.9999999999994
	assert_is_equal 0 -3141492654.0 -3141492653.99999934
	assert_is_equal 0 -31414926535.9999999 -31414926535.9999999

	assert_is_equal 0 2.0 1.99999999999999999
	assert_is_equal 0 1234.0 1233.99999999999912
	assert_is_equal 0 987.0 986.999999999999934
	assert_is_equal 0 31415.0 31414.9999999999994
	assert_is_equal 0 3141492654.0 3141492653.99999934
	assert_is_equal 0 31414926535.9999999 31414926535.9999999

	assert_is_equal 0 -2000.0 "-1999.99999999999 x 1"
	assert_is_equal 0 123457.0 "123456.9999999912 / 1.0"
	assert_is_equal 0 -9866.0 "-9865.999999999934 * 1.0"
	assert_is_equal 0 31415.0 "31414.99999999994 / 1.0"
	assert_is_equal 0 -31414927.0 "-31414926.99999934 x 1.0"
	assert_is_equal 0 314926535.9999999 "314926535.9999999 / 1"

	assert_is_equal 0 7e+19 70000000000000000000
	assert_is_equal 0 7.0e+18 7000000000000000000.0
	assert_is_equal 0 7.0e+18 "7000000000000000000 + 0.0"

	assert_is_equal 0 1e+21 1000000000000000000000
	assert_is_equal 0 1.0e+21 1000000000000000000000.0
}

run_scientific_vs_decimal_test_cases()
{
	# decimal only if 0 <= mantissa <= 19-1 for addition/subtraction of integers
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
	assert_is_equal 0 100000000000000 100000000000000
	assert_is_equal 0 1000000000000000 1000000000000000
	assert_is_equal 0 10000000000000000 10000000000000000
	assert_is_equal 0 100000000000000000 100000000000000000
	assert_is_equal 0 1000000000000000000 1000000000000000000 # 19 digits
	assert_is_equal 0 -1000000000000000000 -1000000000000000000 # 19 digits
	assert_is_equal 0 1e+19 10000000000000000000
	assert_is_equal 0 -1e+19 -10000000000000000000
	assert_is_equal 0 1e+20 100000000000000000000
	assert_is_equal 0 -1e+20 -100000000000000000000
	assert_is_equal 0 1e+45 1000000000000000000000000000000000000000000000
	assert_is_equal 0 -1e+45 -1000000000000000000000000000000000000000000000

	# decimal only if -3 <= mantissa <= 18-1 for addition/subtraction of floats
	assert_is_equal 0 1.0e-21 0.000000000000000000001
	assert_is_equal 0 -1.0e-04 -0.0001
	assert_is_equal 0 1.0e-04 0.0001
	assert_is_equal 0 -0.001 -0.001
	assert_is_equal 0 0.001 0.001
	assert_is_equal 0 0.01 0.01
	assert_is_equal 0 0.1 0.1
	assert_is_equal 0 1.0 1.0
	assert_is_equal 0 -100000000000000000.0 -100000000000000000.0 # 18 digits in integer
	assert_is_equal 0 100000000000000000.0 100000000000000000.0 # 18 digits in integer
	assert_is_equal 0 -1.0e+18 -1000000000000000000.0 # 19 digits in integer
	assert_is_equal 0 1.0e+18 1000000000000000000.0 # 19 digits in integer
	assert_is_equal 0 1.0e+27 1000000000000000000000000000.0

	# decimal only if 0 <= mantissa <= 17-1 for multiplication/division of integers
	assert_is_equal 0 -1 "-1 * 1"
	assert_is_equal 0 1 "1 x 1"
	assert_is_equal 0 10 "10 / 1"
	assert_is_equal 0 -10000000000000000 "-10000000000000000 * 1" # 17 digits
	assert_is_equal 0 10000000000000000 "10000000000000000 x 1" # 17 digits
	assert_is_equal 0 -1e+17 "-100000000000000000 * 1" # 18 digits
	assert_is_equal 0 1e+17 "100000000000000000 / 1" # 18 digits
	assert_is_equal 0 1e+19 "10000000000000000000 x 1" # 19 digits
	assert_is_equal 0 1e+23 "100000000000000000000000 / 1"

	# decimal only if -3 <= mantissa <= 16-1 for multiplication/division of floats
	assert_is_equal 0 1.0e-18 "0.000000000000000001 x 1"
	assert_is_equal 0 -1.0e-04 "-0.0001 / 1"
	assert_is_equal 0 1.0e-04 "0.0001 * 1"
	assert_is_equal 0 -0.001 "-0.001 x 1"
	assert_is_equal 0 0.001 "0.001 / 1"
	assert_is_equal 0 0.01 "0.01 * 1"
	assert_is_equal 0 0.1 "0.1 x 1"
	assert_is_equal 0 1.0 "1.0 / 1"
	assert_is_equal 0 10.0 "10.0 * 1"
	assert_is_equal 0 -1000000000000000.0 "-1000000000000000.0 / 1" # 16 digits
	assert_is_equal 0 1000000000000000.0 "1000000000000000.0 x 1" # 16 digits
	assert_is_equal 0 -1.0e+16 "-10000000000000000.0 / 1" # 17 digits
	assert_is_equal 0 1.0e+16 "10000000000000000.0 x 1" # 17 digits
	assert_is_equal 0 1.0e+17 "100000000000000000.0 / 1" # 18 digits
	assert_is_equal 0 1.0e+21 "1000000000000000000000.0 * 1"
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

	assert_is_equal 0 -7 "-4 - 3"
	assert_is_equal 0 -30000 "-31415 + 1400 + 15"
	assert_is_equal 0 -3141592653 "-3141500000 - 92653"
	assert_is_equal 0 -3141592653589799323 "-3141592653589799323" # 19 digits
	assert_is_equal 0 -3.141592653589799324e+20 "-314159265358979932384"
	assert_is_equal 0 -3.141592653589799324e+21 "-3141592653589799323846"

	assert_is_equal 0 -1234567890123456789 "-1234567890123456789 + 0"
	assert_is_equal 0 -9876543210987654323 "-9876543210987654322 - 1"

	assert_is_equal 0 -9.876543210987654321e+19 "-98765432109876543210"
	assert_is_equal 0 -9.876543210987654321e+19 "-98765432109876543212"
#			  Answer: -9.876543210987654322e+19
#	assert_is_equal 0 -9.876543210987654321e+19 "-98765432109876543214"
	assert_is_equal 0 -9.876543210987654322e+19 "-98765432109876543215"
	assert_is_equal 0 -9.876543210987654322e+19 "-98765432109876543216"
	assert_is_equal 0 -9.876543210987654322e+19 "-98765432109876543219"
#			  Answer: -9.876543210987654323e+22
#	assert_is_equal 0 -9.876543210987654322e+22 "-98765432109876543219999"

	assert_is_equal 0 -1.234567890123456789e+19 "-12345678901234567890"
	assert_is_equal 0 -1.234567890123456789e+19 "-12345678901234567894"
	assert_is_equal 0 -1.23456789012345679e+19 "-12345678901234567895"
	assert_is_equal 0 -1.23456789012345679e+19 "-12345678901234567897"
	assert_is_equal 0 -1.23456789012345679e+19 "-12345678901234567899"
	assert_is_equal 0 -1.23456789012345679e+20 "-123456789012345678969"
	assert_is_equal 0 -1.23456789012345679e+22 "-12345678901234567899127"
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

	assert_is_equal 0 -12 "-4 * 3"
	assert_is_equal 0 -31415927 "-31415927 x 1"
	assert_is_equal 0 -31415926535898 "-31415926535898 x 1"
	assert_is_equal 0 -3141592653589799 "-3141592653589799 * 1"
	assert_is_equal 0 -3141592653589792 "-3141592653589792 x 1" # 16 digits
	assert_is_equal 0 -31415926535897923 "-31415926535897923 x 1" # 17 digits
	assert_is_equal 0 -3.1415926535897932e+17 "-314159265358979323 x 1" # 18 digits
	assert_is_equal 0 -3.1415926535897932e+18 "-3141592653589793238 x 1" # 19 digits
	assert_is_equal 0 -3.1415926535897932e+19 "-31415926535897932384 x 1" # 20 digits
	assert_is_equal 0 -3.1415926535897932e+20 "-314159265358979323846 x 1" # 21 digits

	assert_is_equal 0 -9.8765432109876543e+18 "-(9876543210987654322 - 1) * 1"
	assert_is_equal 0 -9.8765432109876543e+19 "1 x -98765432109876543419"
	assert_is_equal 0 -9.8765432109876544e+22 "1 * -98765432109876543519000"
	assert_is_equal 0 -9.8765432109876544e+25 "1 x -98765432109876543690000000"
	assert_is_equal 0 -9.8765432109876544e+30 "1 * -9876543210987654399999999999999"
}

run_significant_digits_test_cases_float_addition_and_subtraction()
{
	# additions and subtractions of floats: 18 significant digits
	assert_is_equal 0 1.12345678901234567  1.12345678901234567
	assert_is_equal 0 12.1234567890123456  12.1234567890123456
	assert_is_equal 0 123.123456789012345  123.123456789012345
	assert_is_equal 0 1234.12345678901234  1234.12345678901234
	assert_is_equal 0 12345.1234567890123  12345.1234567890123
	assert_is_equal 0 123456.123456789012  123456.123456789012
	assert_is_equal 0 1234567.12345678901  1234567.12345678901
	assert_is_equal 0 12345678.123456789   12345678.1234567890
	assert_is_equal 0 123456789.123456789  123456789.123456789
	assert_is_equal 0 1234567890.12345678  1234567890.12345678
	assert_is_equal 0 12345678901.1234567  12345678901.1234567
	assert_is_equal 0 123456789012.123456  123456789012.123456
	assert_is_equal 0 1234567890123.12345  1234567890123.12345
	assert_is_equal 0 12345678901234.1234  12345678901234.1234
	assert_is_equal 0 123456789012345.123  123456789012345.123
	assert_is_equal 0 1234567890123456.12  1234567890123456.12
	assert_is_equal 0 12345678901234567.1  12345678901234567.1
	assert_is_equal 0 123456789012345671.0  123456789012345671.

	assert_is_equal 0 -1.12345678901234567 -1.12345678901234567
	assert_is_equal 0 -123456.123456789012 -123456.123456789012
	assert_is_equal 0 -123456789012.123456 -123456789012.123456
	assert_is_equal 0 -12345678901234567.1 -12345678901234567.1

	assert_is_equal 0 14.0 "7 + 7.0"
	assert_is_equal 0 31415928.0 "31415927.0 + 1"
	assert_is_equal 0 31415926535898.0 "31415926535898-1.0 + 1.0"
	assert_is_equal 0 3141592653589799.0 "3141592653589799.0 - 0"
	assert_is_equal 0 31415926535897932.0 "0.0 + 31415926535897932" # 17 digits
	assert_is_equal 0 314159265358979323.0 "314159265358979320 + 3.0" # 18 digits
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
	assert_is_equal 0 9.87654321098765465e+22 "10.0 + 98765432109876546519000"
	assert_is_equal 0 9.87654321098765487e+25 "98765432109876548690000000 - 10.00"
	assert_is_equal 0 9.876543210987655e+32 "987654321098765499999999999999900.0 + 64"

	assert_is_equal 0 -14.0 "-7 + -7.0"
	assert_is_equal 0 -31415928.0 "-31415927.0 - 1"
	assert_is_equal 0 -31415926535898.0 "-31415926535898-1.0 + 1.0"
	assert_is_equal 0 -3141592653589799.0 "-3141592653589799.0 - 0"
	assert_is_equal 0 -31415926535897932.0 "0.0 + -31415926535897932" # 17 digits
	assert_is_equal 0 -314159265358979323.0 "-314159265358979320 + -3.0" # 18 digits
	assert_is_equal 0 -3.14159265358979324e+18 "-2.0 + -3141592653589793240" # 19 digits
	assert_is_equal 0 -3.14159265358979324e+19 "-31415926535897932380 - 4.0" # 20 digits
	assert_is_equal 0 -3.14159265358979324e+20 "-314159265358979323800 + 54.0" # 21 digits
	assert_is_equal 0 -3.14159265358979324e+20 "-314159265358979323846 + 0.0"

	assert_is_equal 0 -3.14159265358979323e+19 "-31415926535897932349 + 0.0" # 20 digits
#			  Answer: -3.14159265358979323e+20
#	assert_is_equal 0 -3.14159265358979324e+20 "-314159265358979323500 + 0.0" # 21 digits
	assert_is_equal 0 -3.14159265358979947e+21 "-3141592653589799469009.0 - 999"
	assert_is_equal 0 -3.14159265358979947e+19 "-31415926535897994601.0 - 60"
	assert_is_equal 0 -3.14159265358979946e+22 "-31415926535897994640000.0 - 9999"

	assert_is_equal 0 -9.87654321098765442e+18 "-9876543210987654422.0 - 1 + 1"
	assert_is_equal 0 -9.87654321098765454e+19 "-1.0 + -98765432109876545419"
	assert_is_equal 0 -9.87654321098765465e+22 "-10.0 + -98765432109876546519000"
	assert_is_equal 0 -9.87654321098765487e+25 "-98765432109876548690000000 - -10.00"
	assert_is_equal 0 -9.876543210987655e+32 "-987654321098765499999999999999900.0 + -64"
}

run_significant_digits_test_cases_float_multiplication_and_division()
{
	# multiplications and divisions of floats: 16 significant digits
	assert_is_equal 0 49.0 "7 * 7.0"
	assert_is_equal 0 31415927.0 "31415927 x 1.0"
	assert_is_equal 0 3141592653589.0 "3141592653589.0 x 1"
	assert_is_equal 0 31415926535897.0 "31415926535897 * 1.0" # 14 digits
	assert_is_equal 0 3.141592653589793 "3.141592653589793 * 1" # 16 digits
	assert_is_equal 0 3.141592653589793 "3.1415926535897932 * 1" # 17 digits

	assert_is_equal 0 3.141592653589793e+16 "31415926535897932 * 1.0" # 17 digits
	assert_is_equal 0 3.141592653589793e+18 "3141592653589793238 x 1.0"
	assert_is_equal 0 3.141592653589793e+20 "314159265358979323846 * 1.0"

	assert_is_equal 0 3141592653585799.0 "3141592653585799 / 1.0" # 16 digits
	assert_is_equal 0 3.141592653584599e+16 "31415926535845994*2.0 / 2.0" # 17 digits
	assert_is_equal 0 3.141592653584599e+17 "314159265358459947*2.0 / 2.0"
	assert_is_equal 0 3.14159265358048e+22 "31415926535804795323846 * 1.0"

	assert_is_equal 0 9.876543210987654e+18 "9876543210987654422 * 1.0" # 19 digits
	assert_is_equal 0 9.876543210987655e+20 "1 x 987654321098765453419.0"
	assert_is_equal 0 9.876543210987655e+27 "1.0 * 9876543210987654664543519000"

	assert_is_equal 0 49.0 "-7 * -7.0"
	assert_is_equal 0 -31415927.0 "-31415927 x 1.0"
	assert_is_equal 0 -3141592653589.0 "-3141592653589.0 x 1"
	assert_is_equal 0 -31415926535897.0 "-31415926535897 * 1.0" # 14 digits
	assert_is_equal 0 -3.141592653589793 "-3.141592653589793 * 1" # 16 digits
	assert_is_equal 0 -3.141592653589793 "-3.1415926535897932 * 1" # 17 digits

	assert_is_equal 0 -3.141592653589793e+16 "-31415926535897932 * 1.0" # 17 digits
	assert_is_equal 0 -3.141592653589793e+18 "-3141592653589793238 x 1.0"
	assert_is_equal 0 -3.141592653589793e+20 "-314159265358979323846 * 1.0"

	assert_is_equal 0 -3141592653585799.0 "-3141592653585799 / 1.0" # 16 digits
	assert_is_equal 0 -3.141592653584599e+16 "-31415926535845994*2.0 / 2.0" # 17 digits
	assert_is_equal 0 -3.141592653584599e+17 "-314159265358459947*2.0 / 2.0"
	assert_is_equal 0 -3.14159265358048e+22 "-31415926535804795323846 * 1.0"

	assert_is_equal 0 -9.876543210987654e+18 "-9876543210987654422 * 1.0" # 19 digits
	assert_is_equal 0 -9.876543210987655e+20 "1 x -987654321098765453419.0"
	assert_is_equal 0 -9.876543210987655e+27 "1.0 * -9876543210987654664543519000"
}

run_trim_trailing_nines_after_decimal_point_test_cases()
{
	# truncate if 8 <= n <= 18-21, where n = nine count + up to 2 non-nines
	# 18 (*/ float), 19 (*/ int), 20 (+- float), 19 (+- int)
	assert_is_equal 0 0.123456789019999999 "0.123456789019999999" # 11 + 7 9's
	assert_is_equal 0 -0.1234567891 "-0.123456789099999999" # 10 + 8 9's
	assert_is_equal 0 -0.1234567891 "-0.123456789099999994" # 10 + 7 9's + 1 non-9
	assert_is_equal 0 -0.1234567891 "-0.123456789099999973" # 10 + 6 9's + 2 non-9
	assert_is_equal 0 0.1234567891 "0.123456789099999999" # 10 + 8 9's
	assert_is_equal 0 0.1234567891 "0.123456789099999994" # 10 + 7 9's + 1 non-9
	assert_is_equal 0 0.1234567891 "0.123456789099999973" # 10 + 6 9's + 2 non-9
	assert_is_equal 0 0.123456789099999673 "0.123456789099999673" # 10 + 5 9's + 3 non-9
	assert_is_equal 0 0.123457 "0.123456999999999999" # 6 + 12 9's

	assert_is_equal 0 0.2 0.199999999999999999 # 1 + 17 9's
	assert_is_equal 0 1.0 0.999999999999999999 # 18 9's
	assert_is_equal 0 1.0 0.9999999999999999995 # 18 9's + 1 non-9
	assert_is_equal 0 7.9999999999999912 7.9999999999999912 # 14 9's + 2 non-9
	assert_is_equal 0 7.99999999999999123 7.99999999999999123 # 14 9's + 3 non-9
	assert_is_equal 0 -1.0 -0.999999999999999999 # 18 9's
	assert_is_equal 0 -1.0 -0.9999999999999999995 # 18 9's + 1 non-9
	assert_is_equal 0 -8.0 -7.99999999999999912 # 15 9's + 2 non-9
	assert_is_equal 0 -8.0 -7.999999999999999123 # 15 9's + 3 non-9
	assert_is_equal 0 8.0 7.99999999999999912 # 15 9's + 2 non-9
	assert_is_equal 0 8.0 7.999999999999999123 # 15 9's + 3 non-9

	assert_is_equal 0 12345678901.9999999 "12345678901.9999999" # 7 9's
	assert_is_equal 0 -1234567891.0 -1234567890.99999999 # 8 9's
	assert_is_equal 0 -1234567891.0 -1234567890.99999998 # 7 9's + 1 non-9
	assert_is_equal 0 -1234567891.0 -1234567890.99999932 # 6 9's + 2 non-9
	assert_is_equal 0 1234567891.0 1234567890.99999999 # 8 9's
	assert_is_equal 0 1234567891.0 1234567890.99999998 # 7 9's + 1 non-9
	assert_is_equal 0 1234567891.0 1234567890.99999932 # 6 9's + 2 non-9
	assert_is_equal 0 1234567890.99999323 1234567890.99999323 # 5 9's + 3 non-9
	assert_is_equal 0 123457.0 123456.999999999999 # 12 9's

	assert_is_equal 0 12345.6789019999999 12345.6789019999999 # 7 9's
	assert_is_equal 0 -12345.67891 -12345.6789099999999 # 8 9's
	assert_is_equal 0 -12345.67891 -12345.6789099999998 # 7 9's + 1 non-9
	assert_is_equal 0 -12345.67891 -12345.6789099999932 # 6 9's + 2 non-9
	assert_is_equal 0 12345.67891 12345.6789099999999 # 8 9's
	assert_is_equal 0 12345.67891 12345.6789099999998 # 7 9's + 1 non-9
	assert_is_equal 0 12345.67891 12345.6789099999932 # 6 9's + 2 non-9
	assert_is_equal 0 12345.6789099999323 12345.6789099999323 # 5 9's + 3 non-9

	assert_is_equal 0 123456789019999999.0 123456789019999999.0 # len=18, 7 9's before .
	assert_is_equal 0 123456789099999999.0 123456789099999999.0 # len=18, 8 9's before .
	assert_is_equal 0 12345678909.9999999 12345678909.9999999 # 7 9's after .
	assert_is_equal 0 -1234567891.0 -1234567890.99999999 # 8 9's after .
	assert_is_equal 0 1234567891.0 1234567890.99999999 # 8 9's after .

	assert_is_equal 0 0.0123456789019999999 0.0123456789019999999 # 7 9's
	assert_is_equal 0 -0.01234567891 -0.0123456789099999999 # 8 9's
	assert_is_equal 0 0.01234567891 0.0123456789099999999 # 8 9's

	assert_is_equal 0 0.00123456789019999999 0.00123456789019999999 # 7 9's
	assert_is_equal 0 -0.001234567891 -0.00123456789099999999 # 8 9's
	assert_is_equal 0 0.001234567891 0.00123456789099999999 # 8 9's

	assert_is_equal 0 0.12345679 "0.1234567899999999 * 1" # 8 + 8 9's
	assert_is_equal 0 0.12345679 "0.1234567899999994 / 1" # 8 + 7 9's + 1 non-9
	assert_is_equal 0 0.12345679 "0.1234567899999973 * 1" # 8 + 6 9's + 2 non-9

	assert_is_equal 0 1.23456789099999999e-04 0.000123456789099999999 # 8 9's

	# 8 9's -> 0.999999990000000000 -> 0.99999999
	assert_is_equal 0 0.99999999 "0.99999999"
}

run_trim_trailing_zeros_and_nonzero_after_decimal_point_test_cases()
{
	# truncate if 5 <= n <= (18-21)-1, where n = zero count + up to 2 non-zeros
	# 18-1 (*/ float), 19-1 (*/ int), 20-1 (+- float), 21-1 (+- int)
	assert_is_equal 0 1234567890123.00001 1234567890123.00001
	assert_is_equal 0 1234567890123.00012 1234567890123.00012

	assert_is_equal 0 -123456789012.3 -123456789012.300001
	assert_is_equal 0 -123456789012.3 -123456789012.300012

	assert_is_equal 0 123456789012.3 123456789012.300001
	assert_is_equal 0 123456789012.3 123456789012.300012

	assert_is_equal 0 123.456789012340001 123.456789012340001
	assert_is_equal 0 123.456789012340012 123.456789012340012

	assert_is_equal 0 -123.4567890123 -123.456789012300001
	assert_is_equal 0 -123.4567890123 -123.456789012300012

	assert_is_equal 0 123.4567890123 123.456789012300001
	assert_is_equal 0 123.4567890123 123.456789012300012

	assert_is_equal 0 123.456789012  123.456789012000002
	assert_is_equal 0 123.456789012  123.456789012000023

	assert_is_equal 0 123.45678901   123.456789010000003
	assert_is_equal 0 123.45678901   123.456789010000034

	assert_is_equal 0 123.456789     123.456789000000004
	assert_is_equal 0 123.456789     123.456789000000045

	assert_is_equal 0 123.45678      123.456780000000005
	assert_is_equal 0 123.45678      123.456780000000056

	assert_is_equal 0 123.4567       123.456700000000006
	assert_is_equal 0 123.4567       123.456700000000067

	assert_is_equal 0 123.456        123.456000000000007
	assert_is_equal 0 123.456        123.456000000000078

	assert_is_equal 0 123.45         123.450000000000007
	assert_is_equal 0 123.45         123.450000000000078

	assert_is_equal 0 -123.4        -123.400000000000008
	assert_is_equal 0 -123.4        -123.400000000000089

	assert_is_equal 0 123.4          123.400000000000008
	assert_is_equal 0 123.4          123.400000000000089

	assert_is_equal 0 123.000000000000009 123.000000000000009
	assert_is_equal 0 123.000000000000091 123.000000000000091

	assert_is_equal 0 -0.123          -0.123000000000000009
	assert_is_equal 0 -0.123          -0.123000000000000091

	assert_is_equal 0 0.123            0.123000000000000009
	assert_is_equal 0 0.123            0.123000000000000091

	assert_is_equal 0 0.12             0.120000000000000008
	assert_is_equal 0 0.12             0.120000000000000098

	assert_is_equal 0 0.1              0.100000000000000007
	assert_is_equal 0 0.1              0.100000000000000087

	assert_is_equal 0 0.02             0.0200000000000000006
	assert_is_equal 0 0.02             0.0200000000000000076

	assert_is_equal 0 -0.003          -0.00300000000000000006
	assert_is_equal 0 -0.003          -0.00300000000000000076

	assert_is_equal 0 0.003            0.00300000000000000006
	assert_is_equal 0 0.003            0.00300000000000000076

	assert_is_equal 0 3.00000000000000006e-04 0.000300000000000000006
	assert_is_equal 0 3.00000000000000076e-04 0.000300000000000000076

	assert_is_equal 0 -123.4        "-123.4000000000008 / 1"
	assert_is_equal 0 -123.4        "-123.4000000000089 / 1"

	assert_is_equal 0 123.4          "123.4000000000008 / 1"
	assert_is_equal 0 123.4          "123.4000000000089 / 1"

	assert_is_equal 0 123.0000000000009 "123.0000000000009 / 1"
	assert_is_equal 0 123.0000000000091 "123.0000000000091 / 1"

	assert_is_equal 0 0.003            "0.003000000000000006 * 1.0"
	assert_is_equal 0 0.003            "0.003000000000000076 * 1.0"

	assert_is_equal 0 123.400000000000789 123.400000000000789
	assert_is_equal 0 123.40000000000009  123.400000000000090
	assert_is_equal 0 123.4000000000009   123.400000000000900

	assert_is_equal 0 1234567890123450001 1234567890123450001
	assert_is_equal 0 1234567890123450012 1234567890123450012
}

run_trim_trailing_zeros_after_decimal_point_decimals_test_cases()
{
	assert_is_equal 0 0.0                  0.00000000000000000
	assert_is_equal 0 9.0                  9.00000000000000000
	assert_is_equal 0 98.0                 98.0000000000000000
	assert_is_equal 0 987.0                987.000000000000000
	assert_is_equal 0 9876.0               9876.00000000000000
	assert_is_equal 0 98765.0              98765.0000000000000
	assert_is_equal 0 987654.0             987654.000000000000
	assert_is_equal 0 9876543.0            9876543.00000000000
	assert_is_equal 0 98765432.0           98765432.0000000000
	assert_is_equal 0 987654321.0          987654321.000000000
	assert_is_equal 0 9876543210.0         9876543210.00000000
	assert_is_equal 0 98765432109.0        98765432109.0000000
	assert_is_equal 0 987654321098.0       987654321098.000000
	assert_is_equal 0 9876543210987.0      9876543210987.00000
	assert_is_equal 0 98765432109876.0     98765432109876.0000
	assert_is_equal 0 987654321098765.0    987654321098765.000
	assert_is_equal 0 9876543210987654.0   9876543210987654.00
	assert_is_equal 0 98765432109876543.0  98765432109876543.0
	assert_is_equal 0 987654321098765432.0 987654321098765432.

	assert_is_equal 0 98765432109876.5432 98765432109876.5432
	assert_is_equal 0 98765432109876.5    98765432109876.5000
	assert_is_equal 0 987654321098765.4   987654321098765.400
	assert_is_equal 0 9876543210987654.3  9876543210987654.30
	assert_is_equal 0 98765432109876543.2 98765432109876543.2

	assert_is_equal 0 0.9876543210987654    0.987654321098765400
	assert_is_equal 0 0.98765432109         0.987654321090000000
	assert_is_equal 0 0.9876543             0.987654300000000000

	assert_is_equal 0 0.0987654321098765432 0.0987654321098765432
	assert_is_equal 0 0.0987654321          0.0987654321000000000
	assert_is_equal 0 0.09                  0.0900000000000000000

	assert_is_equal 0 0.0098765432109876543 0.00987654321098765430
	assert_is_equal 0 0.009876543210987     0.00987654321098700000
	assert_is_equal 0 0.0098765             0.00987650000000000000

	assert_is_equal 0 0.0                   -0.00000000000000000
	assert_is_equal 0 -9.0                  -9.00000000000000000
	assert_is_equal 0 -98765.0              -98765.0000000000000
	assert_is_equal 0 -98765432109.0        -98765432109.0000000
	assert_is_equal 0 -987654321098765432.0 -987654321098765432.
	assert_is_equal 0 -98765432109876.5     -98765432109876.5000
	assert_is_equal 0 -9876543210987654.3   -9876543210987654.30

	assert_is_equal 0 -0.9876543210987654    -0.987654321098765400
	assert_is_equal 0 -0.98765432109         -0.987654321090000000
	assert_is_equal 0 -0.9876543             -0.987654300000000000

	assert_is_equal 0 -0.0987654321098765432 -0.0987654321098765432
	assert_is_equal 0 -0.0987654321          -0.0987654321000000000
	assert_is_equal 0 -0.09                  -0.0900000000000000000

	assert_is_equal 0 -0.0098765432109876543 -0.00987654321098765430
	assert_is_equal 0 -0.009876543210987     -0.00987654321098700000
	assert_is_equal 0 -0.0098765             -0.00987650000000000000

	assert_is_equal 0 9876543210987600000 9876543210987600000
}

run_trim_trailing_zeros_after_decimal_point_scientific_notation_test_cases()
{
	assert_is_equal 0 6.0221409e+23 602214090000000000000000
	assert_is_equal 0 6022140960221409602 6022140960221409602
	assert_is_equal 0 6.022140960221409602e+19 60221409602214096020
	assert_is_equal 0 6.022140960221409602e+23 602214096022140960200000
	assert_is_equal 0 6.022140960221409602e+33 6022140960221409602000000000000000

	assert_is_equal 0 -6.0221409e+23 -602214090000000000000000
	assert_is_equal 0 -6022140960221409602 -6022140960221409602
	assert_is_equal 0 -6.022140960221409602e+19 -60221409602214096020
	assert_is_equal 0 -6.022140960221409602e+23 -602214096022140960200000
	assert_is_equal 0 -6.022140960221409602e+33 -6022140960221409602000000000000000

#			  Answer: 2.71828182845904523
#	assert_is_equal 0 2.71828182845904524 2.7182818284590452353

	assert_is_equal 0 0.00271828182845904523 0.00271828182845904523

	assert_is_equal 0 2.0e-26                 0.0000000000000000000000000200000000000000000
	assert_is_equal 0 2.71e-19                0.000000000000000000271000000000000000
	assert_is_equal 0 2.718281e-15            0.00000000000000271828100000000000
	assert_is_equal 0 2.718281828459e-09      0.00000000271828182845900000

	assert_is_equal 0 -0.00271828182845904523 -0.00271828182845904523

	assert_is_equal 0 -2.0e-26                 -0.0000000000000000000000000200000000000000000
	assert_is_equal 0 -2.71e-19                -0.000000000000000000271000000000000000
	assert_is_equal 0 -2.718281e-15            -0.00000000000000271828100000000000
	assert_is_equal 0 -2.718281828459e-09      -0.00000000271828182845900000

	assert_is_equal 0 2.71828182845904523e-04 0.000271828182845904523
	assert_is_equal 0 2.7182818284590452e-04  0.000271828182845904520
	assert_is_equal 0 2.718281828459045e-04   0.000271828182845904500
	assert_is_equal 0 2.71828182845904e-04    0.000271828182845904000
	assert_is_equal 0 2.718281828459e-04      0.000271828182845900000
	assert_is_equal 0 2.71828182845e-04       0.000271828182845000000
	assert_is_equal 0 2.7182818284e-04        0.000271828182840000000
	assert_is_equal 0 2.718281828e-04         0.000271828182800000000
	assert_is_equal 0 2.71828182e-04          0.000271828182000000000
	assert_is_equal 0 2.7182818e-04           0.000271828180000000000
	assert_is_equal 0 2.718281e-04            0.000271828100000000000
	assert_is_equal 0 2.71828e-04             0.000271828000000000000
	assert_is_equal 0 2.7182e-04              0.000271820000000000000
	assert_is_equal 0 2.718e-04               0.000271800000000000000
	assert_is_equal 0 2.71e-04                0.000271000000000000000
	assert_is_equal 0 2.7e-04                 0.000270000000000000000
	assert_is_equal 0 2.0e-04                 0.000200000000000000000
	assert_is_equal 0 2.0e-05                 0.000020000000000000000
	assert_is_equal 0 2.0e-06                 0.000002000000000000000
	assert_is_equal 0 2.0e-07                 0.000000200000000000000
	assert_is_equal 0 2.0e-08                 0.000000020000000000000
	assert_is_equal 0 2.0e-09                 0.000000002000000000000
	assert_is_equal 0 2.0e-10                 0.000000000200000000000
	assert_is_equal 0 2.0e-11                 0.000000000020000000000
	assert_is_equal 0 2.0e-12                 0.000000000002000000000
	assert_is_equal 0 2.0e-13                 0.000000000000200000000
	assert_is_equal 0 2.0e-14                 0.000000000000020000000
	assert_is_equal 0 2.0e-15                 0.000000000000002000000
	assert_is_equal 0 2.0e-16                 0.000000000000000200000
	assert_is_equal 0 2.0e-17                 0.000000000000000020000
	assert_is_equal 0 2.0e-18                 0.000000000000000002000
	assert_is_equal 0 2.0e-19                 0.000000000000000000200
	assert_is_equal 0 2.0e-20                 0.000000000000000000020
	assert_is_equal 0 2.0e-21                 0.000000000000000000002
	assert_is_equal 0 0.0                     0.000000000000000000000

	assert_is_equal 0 -2.71828182845904523e-04 -0.000271828182845904523
	assert_is_equal 0 -2.7182818284e-04        -0.000271828182840000000
	assert_is_equal 0 -2.71e-04                -0.000271000000000000000
	assert_is_equal 0 -2.0e-04                 -0.000200000000000000000
	assert_is_equal 0 -2.0e-11                 -0.000000000020000000000
	assert_is_equal 0 -2.0e-21                 -0.000000000000000000002
	assert_is_equal 0 0.0                      -0.000000000000000000000
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
