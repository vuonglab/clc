#!/usr/bin/env python3

"""
This Python script reads in a shell script containing the generated expressions
(and other test cases). It then writes the generated expression test cases to a
separate file ending in .tests and the expressions themselves to another file.
The files will be created in the same directory as the shell script.

The generated expression test cases are expected to be inside the function
run_generated_expression_test_cases.

Syntax: ./recreate-expressions-and-test-cases.py shell_script
        shell_script is either tests-long-double.sh or tests-double.sh
"""

import re
import os
import sys


def main():
    test_script_filename = get_test_script_filename_from_command_line()
    test_script_path = os.path.dirname(test_script_filename)

    lines = read_in_all_lines(test_script_filename)

    functions_dict = find_all_functions(lines)
    gen_expr_functions = get_gen_expr_functions(functions_dict, lines)

    create_test_files(gen_expr_functions, test_script_path, lines)
    create_expression_files(gen_expr_functions, test_script_path, lines)


def get_test_script_filename_from_command_line():
    if len(sys.argv) != 2:
        script_name = os.path.basename(__file__)
        print("Missing shell script file containing test cases.")
        print("Syntax:", script_name, "test_script_filename")
        sys.exit(1)
    test_script_filename = sys.argv[1]
    return test_script_filename


def read_in_all_lines(test_script_filename):
    with open(test_script_filename, 'r') as expr_file:
        expressions = expr_file.read().splitlines()
    return expressions


def find_all_functions(lines):
    functions_dict = {}

    func_name_line_no = -1
    open_brace_line_no = -1

    for line_no, line in enumerate(lines):
        if line_is_function(line):
            assert func_name_line_no < 0, \
                "%s not processed." % (lines[func_name_line_no])
            assert open_brace_line_no < 0, \
                "%s not processed." % (lines[func_name_line_no])
            func_name_line_no = line_no

        if line_is_open_function_brace(line):
            assert line_no == func_name_line_no+1, \
                "%s not immediately followed by {" % (lines[func_name_line_no])
            open_brace_line_no = line_no

        if line_is_closing_function_brace(line):
            assert func_name_line_no >= 0, \
                "} without function."
            assert open_brace_line_no >= 0, \
                "%s has no {" % (lines[func_name_line_no])
            function_name = lines[func_name_line_no][:-2]
            # print(function_name)
            functions_dict[function_name] = {
                "start_line_no": open_brace_line_no,
                "end_line_no": line_no
            }
            func_name_line_no = -1
            open_brace_line_no = -1

    return functions_dict


def line_is_function(line):
    return re.compile("^[a-zA-z_][a-zA-Z_0-9]*\(\)$").match(line)


def line_is_open_function_brace(line):
    return line == "{"


def line_is_closing_function_brace(line):
    return line == "}"


def get_gen_expr_functions(functions_dict, lines):
    gen_expr_functions_dict = {}

    run_func = functions_dict['run_generated_expression_test_cases']
    assert run_func != None, \
        "run_generated_expression_test_cases not found."
    
    for line_no in range(run_func["start_line_no"]+1, run_func["end_line_no"]):
        line = lines[line_no].strip()
        if line == "": continue
        generated_expression_func = functions_dict[line]
        assert generated_expression_func != None, \
            "%s not found." % (line)
        gen_expr_functions_dict[line] = generated_expression_func

    return gen_expr_functions_dict


def create_test_files(gen_expr_functions, test_script_path, lines):
    for func_name in gen_expr_functions:
        test_full_filename = os.path.join(test_script_path,
            extract_filename_from_func_name(func_name) + '.tests')

        func = gen_expr_functions[func_name]
        with open(test_full_filename, 'w') as tests_file:
            tests_file.write("%s()\n" % func_name)
            for line_no in range(func["start_line_no"], func["end_line_no"]+1):
                tests_file.write("%s\n" % lines[line_no])


def create_expression_files(gen_expr_functions, test_script_path, lines):
    for func_name in gen_expr_functions:
        test_full_filename = os.path.join(test_script_path,
            extract_filename_from_func_name(func_name))

        func = gen_expr_functions[func_name]
        with open(test_full_filename, 'w') as tests_file:
            for line_no in range(func["start_line_no"]+1, func["end_line_no"]):
                line = lines[line_no]
                if "assert_is_equal" not in line:
                    continue
                regex_result = re.search('"(.*)"', line)
                assert regex_result != None, \
                    "No expression: %s" % line
                expression = regex_result.group(1)
                assert expression != None, \
                    "No expression: %s" % line
                tests_file.write("%s\n" % expression)


def extract_filename_from_func_name(func_name):
    return func_name[4:-6]


if __name__ == "__main__":
    main()
    sys.exit(0)
