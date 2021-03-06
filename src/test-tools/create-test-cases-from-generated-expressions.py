#!/usr/bin/env python3

"""
This Python script reads in a file containing elementary math expressions,
calculates the expected answers using another program named calc, and
generates a sh-compatible script function to call clc to test that clc
produces the correct answers.

Syntax: ./create-test-cases-from-generated-expressions.py \
        [-v, --verbose] expressions_filename

Dependencies:
calc - C-style arbitrary precision calculator (https://github.com/lcn2/calc);
    used to generate the expected answers. Version version 2.12.6.7 used.
"""

import re
import os
import subprocess
import sys


def main():
    expr_filename, verbose = get_expr_filename_from_command_line()
    expressions = read_in_all_expressions(expr_filename)

    output_filename = expr_filename + '.tests'
    tossed_out_count = generate_script_function(
        output_filename, expressions, verbose
    )

    total_expr_count = len(expressions)
    test_expr_count = total_expr_count - tossed_out_count
    print(test_expr_count, "test expressions",
            "+", tossed_out_count, "expressions commented out",
            "=", total_expr_count, "expressions total")


def get_expr_filename_from_command_line():
    expr_filename = None
    if len(sys.argv) == 2 or len(sys.argv) == 3:
        verbose = sys.argv[1] == '-v' or sys.argv[1] == '--verbose'
        if verbose:
            if len(sys.argv) == 3:
                expr_filename = sys.argv[2]
        else:
            expr_filename = sys.argv[1]

    if expr_filename == None:
        script_name = os.path.basename(__file__)
        print("Missing name of file containing elementary math expressions.")
        print("Syntax:", script_name, "[-v, --verbose] expressions_filename")
        sys.exit(1)

    return expr_filename, verbose


def read_in_all_expressions(expr_filename):
    with open(expr_filename, 'r') as expr_file:
        expressions = expr_file.read().splitlines()
    return expressions


def generate_script_function(output_filename, expressions, verbose):
    commented_out_expr_count = 0

    basename = os.path.splitext(os.path.basename(output_filename))[0]

    with open(output_filename, 'w') as script_file:
        function_name = generate_function_name(basename)
        script_file.write(function_name + "()\n")
        script_file.write("{\n")

        for idx, expr in enumerate(expressions):
            clc_answer, exit_code = evaluate_expression_using_clc(expr)
            full_answer_key, answer_key, approximated = \
                evaluate_expression_using_calc(expr, clc_answer)

            last_expression = idx+1 == len(expressions)

            if clc_answer == answer_key:
                if clc_answer == full_answer_key:
                    write_out_expr_test_case(
                        script_file, expr, answer_key, approximated,
                        exit_code, verbose
                    )
                else:
                    write_out_expr_test_case_rounded_key(
                        script_file, expr, full_answer_key, approximated,
                        answer_key, exit_code, verbose, not last_expression
                    )
            else:
                comment_out_expr_test_case(
                    script_file, expr, full_answer_key, approximated,
                    answer_key, clc_answer, exit_code, verbose,
                    not last_expression
                )
                commented_out_expr_count += 1

        script_file.write("}\n")

    return commented_out_expr_count


def generate_function_name(filename):
    function_name = "run_"

    regex_result = \
        re.search('^(a|s|m|d|as|md|asmd)-(i|f|if)99-expr$', filename)
    if regex_result == None:
        function_name += filename
        return function_name

    operators = regex_result.group(1)
    numbers = regex_result.group(2)

    if numbers == "i":
        function_name += "integer"
    elif numbers == "f":
        function_name += "decimal"
    elif numbers == "if":
        function_name += "integer_and_decimal"
    
    function_name += "_"

    if operators == "a":
        function_name += "addition"
    elif operators == "s":
        function_name += "subtraction"
    elif operators == "m":
        function_name += "multiplication"
    elif operators == "d":
        function_name += "division"
    elif operators == "as":
        function_name += "addition_and_subtraction"
    elif operators == "md":
        function_name += "multiplication_and_division"
    elif operators == "asmd":
        function_name += "addition_subtraction_multiplication_and_division"

    function_name += "_tests"

    return function_name


def evaluate_expression_using_clc(expr):
    script_path = os.path.dirname(os.path.realpath(__file__))
    clc_full_path = script_path + '/../clc'
    result = subprocess.run([clc_full_path, expr], stdout=subprocess.PIPE)
    answer = re.sub('\n$', '', result.stdout.decode('utf-8'))
    exit_code = result.returncode
    # is_float() handles +/-inf and +/-nan
    assert is_float(answer), \
        "Unexpected clc answer: %r. Expression: %r" % (answer, expr)
    assert exit_code == 0, \
        "Exit code is %r, not 0. Expression: %r" % (exit_code, expr)
    return answer, exit_code


def is_float(string):
    try:
        float(string)
    except ValueError:
        return False
    return True


def evaluate_expression_using_calc(expr, clc_answer):
    has_float = '.' in expr
    if 'e' in clc_answer:
        e_expr = 'printf("%e", ' + expr + ')'
        full_answer_key, approximated = get_answer_in_exponential_form(
            e_expr, has_float
        )
    else:
        full_answer_key, approximated = get_answer_in_real_form(
            expr, has_float
        )

    if full_answer_key == "Error 10001":
        full_answer_key += ": divide by zero"
        if clc_answer == 'inf' or clc_answer == '-inf' \
            or clc_answer == 'nan' or clc_answer == '-nan':
            answer_key = clc_answer
        else:
            answer_key = "divide0"
    elif full_answer_key == "Error 10002":
        full_answer_key += ": indeterminate (0/0)"
        if clc_answer == 'nan' or clc_answer == '-nan':
            answer_key = clc_answer
        else:
            answer_key = "indeter"
    else:
        if full_answer_key == clc_answer:
            answer_key = full_answer_key
        else:
            answer_key = get_answer_key_in_same_precision_as_clc_answer(
                expr, clc_answer
            )

    return full_answer_key, answer_key, approximated


def get_answer_key_in_same_precision_as_clc_answer(expr, clc_answer):
    precision = get_precision_in_clc_answer(clc_answer)
    if clc_answer.find('e') == -1:
        return get_answer_key_in_real_form(expr, precision)
    else:
        return get_answer_key_in_exponential_form(expr, precision)


def get_precision_in_clc_answer(clc_answer):
    regex_precision_result = \
        re.search('\.(\d*)e', clc_answer) or re.search("\.(\d*)$", clc_answer)
    if regex_precision_result == None:
        num_decimal_places = 0
    else:
        num_decimal_places = len(regex_precision_result.group(1))
    return num_decimal_places


def get_answer_key_in_real_form(expr, num_decimal_places):
    num_decimals = str(num_decimal_places)
    printf_expr = 'printf("%.' + num_decimals + 'f", ' + expr + ')'
    answer_key, approximated = run_calc(printf_expr)
    return answer_key


def get_answer_key_in_exponential_form(expression, num_decimal_places):
    e_expr = 'printf("%.' + str(num_decimal_places) + 'e", ' + expression + ')'
    has_float = '.' in expression
    e_answer, approximated = get_answer_in_exponential_form(e_expr, has_float)
    return e_answer 


def get_answer_in_exponential_form(expression, always_include_decimal_point):
    e_answer, approximated = run_calc(expression)

    if e_answer == "0":
        e_answer = "0e+00"
    elif e_answer.find('e') == -1:
        e_answer += 'e+00'
    else:
        e_answer = re.sub('e-(\d)$', r'e-0\1', e_answer)
        e_answer = re.sub('e(\d)$', r'e+0\1', e_answer)
        e_answer = re.sub('e(\d\d+)$', r'e+\1', e_answer)

    if always_include_decimal_point and '.' not in e_answer:
        parsed_e_re_result = re.search('^(-?\d+)(e[+-]\d+)$', e_answer)
        e_answer = parsed_e_re_result.group(1) + ".0" \
            + parsed_e_re_result.group(2)

    return e_answer, approximated


def get_answer_in_real_form(expression, always_include_decimal_point):
    answer, approximated = run_calc(expression)
    if always_include_decimal_point and re.match('^-?\d+$', answer):
        answer += ".0"
    return answer, approximated


def run_calc(expression):
    expr = expression.replace('x', '*').replace('[', '(').replace(']', ')')
    result = subprocess.run(['calc', '-- '+expr], stdout=subprocess.PIPE)
    answer = re.sub('^\t|\n$', '', result.stdout.decode('utf-8'))

    approximated = (answer[0] == '~')
    if approximated:
        answer = answer[1:]

    return answer, approximated


def write_out_expr_test_case(file, expr, answer_key, approximated, exit_code,
                             verbose):
    if approximated:
        file.write('\n')
        file.write('#\t             Key: ' + answer_key + ' (approximated)')
        if verbose:
            num_digits = number_of_significant_digits(answer_key)
            file.write(' (' + str(num_digits) + ')')
        file.write('\n')

    file.write("\tassert_is_equal ")
    file.write(str(exit_code) + " ")
    file.write(answer_key + " ")
    file.write('"' + expr + '"\n')

    if approximated:
        file.write('\n')


def write_out_expr_test_case_rounded_key(file, expr, full_answer_key,
                                         approximated, answer_key, exit_code,
                                         verbose, write_second_blank_line):
    file.write('\n')
    file.write('#\t             Key: ' + full_answer_key)
    if approximated:
        file.write(' (approximated)')
    if verbose:
        num_digits = number_of_significant_digits(full_answer_key)
        file.write(' (' + str(num_digits) + ')')
    file.write('\n')

    file.write("\tassert_is_equal ")
    file.write(str(exit_code) + " ")
    file.write(answer_key + " ")
    file.write('"' + expr + '"\n')

    if write_second_blank_line:
        file.write('\n')


def comment_out_expr_test_case(file, expr, full_answer_key, approximated,
                               answer_key, answer, exit_code, verbose,
                               write_second_blank_line):
    file.write('\n')
    if full_answer_key != answer_key or approximated:
        file.write("#\t             Key: ")
        file.write(full_answer_key)
        if approximated:
            file.write(' (approximated)')
        if verbose:
            num_digits = number_of_significant_digits(full_answer_key)
            file.write(' (' + str(num_digits) + ')')
        file.write('\n')
    file.write("#\t          Answer: " + answer)
    if verbose:
        num_digits = number_of_significant_digits(answer)
        file.write(' (' + str(num_digits) + ')')
    file.write('\n')

    file.write("#\tassert_is_equal ")
    file.write(str(exit_code) + " ")
    file.write(answer_key + " ")
    file.write('"' + expr + '"\n')

    if write_second_blank_line:
        file.write('\n')


def number_of_significant_digits(answer):
    e_index = answer.find('e')
    if e_index != -1:
        answer = answer[:e_index]
    digits = re.sub('[^0-9]', '', answer)
    return len(digits)


if __name__ == "__main__":
    main()
    sys.exit(0)
