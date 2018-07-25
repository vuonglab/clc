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
	assert_is_equal 0 3.141592653589793238 "3.141592653589793238"
	assert_is_equal 0 3.1415926535897932384 "3.141592653589793238e+00"

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
	assert_is_equal 0 3.1415926535897932384 "3.141592653589793238e+00"
	assert_is_equal 0 3.14159265358979323846 "3.141592653589793238e+00"
}

run_pretty_print_test_cases()
{
	run_pretty_print_decimal_test_cases
	run_pretty_print_scientific_test_cases
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
	assert_is_equal 0 12345678901234567890 "12345678901234567890"

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
	assert_is_equal 0 -12345678901234567890 "-12345678901234567890"

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
	assert_is_equal 0 12345678901.123457 "12345678901.123457"
	assert_is_equal 0 123456789012.123457 "123456789012.123457"
	assert_is_equal 0 1234567890123.123457 "1234567890123.123457"
	assert_is_equal 0 12345678901234.123457 "12345678901234.123457"
	# assert_is_equal 0 99999999999999.123456 "99999999999999.123456" # answer: 99999999999999.123451
	# assert_is_equal 0 99999999999999.987654 "99999999999999.987654" # answer: 99999999999999.987671
	# assert_is_equal 0 123456789012345.123457 "123456789012345.1234567" # answer: 123456789012345.123451
	# assert_is_equal 0 1234567890123456.123457 "1234567890123456.1234567" # answer: 1234567890123456.123413
	# assert_is_equal 0 12345678901234567.123457 "12345678901234567.1234567" # answer: 12345678901234567.12207

	assert_is_equal 0 -123456789012.123457 "-123456789012.123457"
	assert_is_equal 0 -1234567890123.123457 "-1234567890123.123457"
	assert_is_equal 0 -12345678901234.123457 "-12345678901234.123457"
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
