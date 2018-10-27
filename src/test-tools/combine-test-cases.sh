#!/bin/sh

combine_test_cases()
{
    local _short_filename=$1.tests
    local _long_filename=$2.tests

	local _filename=$_long_filename
	[ -e $_short_filename ] && _filename=$_short_filename

	cat $_filename >>combined.tests
	printf '\n' >>combined.tests
}

combine_test_cases a-f99-expr decimal_addition
combine_test_cases a-i99-expr integer_addition
combine_test_cases a-if99-expr integer_and_decimal_addition

combine_test_cases s-f99-expr decimal_subtraction
combine_test_cases s-i99-expr integer_subtraction
combine_test_cases s-if99-expr integer_and_decimal_subtraction

combine_test_cases m-f99-expr decimal_multiplication
combine_test_cases m-i99-expr integer_multiplication
combine_test_cases m-if99-expr integer_and_decimal_multiplication

combine_test_cases d-f99-expr decimal_division
combine_test_cases d-i99-expr integer_division
combine_test_cases d-if99-expr integer_and_decimal_division

combine_test_cases as-f99-expr decimal_addition_and_subtraction
combine_test_cases as-i99-expr integer_addition_and_subtraction
combine_test_cases as-if99-expr integer_and_decimal_addition_and_subtraction

combine_test_cases md-f99-expr decimal_multiplication_and_division
combine_test_cases md-i99-expr integer_multiplication_and_division
combine_test_cases md-if99-expr integer_and_decimal_multiplication_and_division

combine_test_cases asmd-f99-expr decimal_addition_subtraction_multiplication_and_division
combine_test_cases asmd-i99-expr integer_addition_subtraction_multiplication_and_division
combine_test_cases asmd-if99-expr integer_and_decimal_addition_subtraction_multiplication_and_division
