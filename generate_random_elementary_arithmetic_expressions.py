#!/usr/bin/env python3

"""
This Python script generates random elementary math expressions of various
lengths to test clc.

Type -h or --help to see program options.

Exit code:
0 = Expressions generated.
1 = Command line options displayed.
2 = Invalid program option specified.

Credits:
https://stackoverflow.com/questions/6881170/is-there-a-way-to-autogenerate-valid-arithmetic-expressions
"""

from __future__ import print_function

from enum import Enum
import getopt
import random
import re
import sys


class Operators(Enum):
    ADDITION = 1
    SUBTRACTION = 2
    ADDITION_SUBTRACTION = 3
    MULTIPLICATION = 4
    DIVISION = 5
    MULTIPLICATION_DIVISION = 6
    ADDITION_SUBTRACTION_MULTIPLICATION_DIVISION = 7


class OperandGenerator():
    def __init__(self, generator_list):
        super(OperandGenerator, self).__init__()
        self._generators_list = generator_list

    def randomly_generate(self):
        r = random.random()
        cumulative = 0.0
        for o in self._generators_list:
            cumulative += o['prob']
            if r <= cumulative:
                generator = o['generator']
                break
        return generator()

    @classmethod
    def get_integer_generator(cls, integer_len, operators):
        GenerateInteger().integer_len = integer_len
        if integer_len == 1 and (operators == Operators.MULTIPLICATION
            or operators == Operators.DIVISION
            or operators == Operators.MULTIPLICATION_DIVISION):
            GenerateInteger().avoid_many_zeroes = True
        return OperandGenerator([
            {'prob': 1.0, 'generator': GenerateInteger}
        ])

    @classmethod
    def get_float_generator(cls, float_len):
        GenerateFloat().float_len = float_len
        return OperandGenerator([
            {'prob': 1.0, 'generator': GenerateFloat}
        ])

    @classmethod
    def get_integer_and_float_generator(cls, operators, integer_len,
                                        float_len):
        GenerateInteger().integer_len = integer_len
        if integer_len == 1 and (operators == Operators.MULTIPLICATION
            or operators == Operators.DIVISION
            or operators == Operators.MULTIPLICATION_DIVISION):
            GenerateInteger().avoid_many_zeroes = True
        GenerateFloat().float_len = float_len
        return OperandGenerator([
            {'prob': 0.5, 'generator': GenerateInteger},
            {'prob': 0.5, 'generator': GenerateFloat}
        ])


class OperatorGenerator():
    def __init__(self, operators_dict, num_of_spaces_around_operator):
        super(OperatorGenerator, self).__init__()
        self._operators_dict = operators_dict
        self._number_of_spaces_around_operator = num_of_spaces_around_operator

    def randomly_pick(self):
        r = random.random()
        cumulative = 0.0
        for k, v in self._operators_dict.items():
            cumulative += v['prob']
            if r <= cumulative:
                operator = k
                break
        assert operator is not None

        if self._number_of_spaces_around_operator is not  None:
            spaces = " " * self._number_of_spaces_around_operator
        else:
            spaces_dict = {'': 0.499, ' ': 0.499, '  ': 0.0018, '   ': 0.0002}
            r = random.random()
            cumulative = 0.0
            for spaces_key, prob in spaces_dict.items():
                cumulative += prob
                if r <= cumulative:
                    spaces = spaces_key
                    break
            assert spaces is not  None

        return {
            'symbol': k,
            'prec': v['prec'],
            'display': spaces + k + spaces
        }

    @classmethod
    def get(cls, operators, num_of_spaces_around_operator):
        switcher = {
            Operators.ADDITION: {
                'x': {'prec': 20, 'prob': 0},
                '*': {'prec': 20, 'prob': 0},
                '/': {'prec': 20, 'prob': 0},
                '+': {'prec': 30, 'prob': 1},
                '-': {'prec': 30, 'prob': 0}
            },
            Operators.SUBTRACTION: {
                'x': {'prec': 20, 'prob': 0},
                '*': {'prec': 20, 'prob': 0},
                '/': {'prec': 20, 'prob': 0},
                '+': {'prec': 30, 'prob': 0},
                '-': {'prec': 30, 'prob': 1}
            },
            Operators.ADDITION_SUBTRACTION: {
                'x': {'prec': 20, 'prob': 0},
                '*': {'prec': 20, 'prob': 0},
                '/': {'prec': 20, 'prob': 0},
                '+': {'prec': 30, 'prob': 0.5},
                '-': {'prec': 30, 'prob': 0.5}
            },
            Operators.MULTIPLICATION: {
                'x': {'prec': 20, 'prob': 0.5},
                '*': {'prec': 20, 'prob': 0.5},
                '/': {'prec': 20, 'prob': 0},
                '+': {'prec': 30, 'prob': 0},
                '-': {'prec': 30, 'prob': 0}
            },
            Operators.DIVISION: {
                'x': {'prec': 20, 'prob': 0},
                '*': {'prec': 20, 'prob': 0},
                '/': {'prec': 20, 'prob': 1},
                '+': {'prec': 30, 'prob': 0},
                '-': {'prec': 30, 'prob': 0}
            },
            Operators.MULTIPLICATION_DIVISION: {
                'x': {'prec': 20, 'prob': 0.25},
                '*': {'prec': 20, 'prob': 0.25},
                '/': {'prec': 20, 'prob': 0.5},
                '+': {'prec': 30, 'prob': 0},
                '-': {'prec': 30, 'prob': 0}
            },
            Operators.ADDITION_SUBTRACTION_MULTIPLICATION_DIVISION: {
                'x': {'prec': 20, 'prob': 0.125},
                '*': {'prec': 20, 'prob': 0.125},
                '/': {'prec': 20, 'prob': 0.25},
                '+': {'prec': 30, 'prob': 0.25},
                '-': {'prec': 30, 'prob': 0.25}
            }
        }
        operators_dict = switcher.get(operators, {})
        assert any(operators_dict.values())
        return OperatorGenerator(
            operators_dict, num_of_spaces_around_operator
        )


class MathExpression(object):
    max_levels = 12

    def __init__(self):
        super(MathExpression, self).__init__()

    def precedence(self):
        return -1

    @classmethod
    def create_random(cls, level, sub_expressions,
                      operand_generator, operator_generator):
        if level == 0:
            is_op = True
        elif level == cls.max_levels:
            is_op = False
        else:
            is_op = random.random() <= 1.0 - pow(level/cls.max_levels, 2.0)

        if is_op:
            bin_expr = BinaryExpression.create_random(level, sub_expressions,
                                                      operand_generator,
                                                      operator_generator)
            sub_expressions.append(bin_expr)
            return bin_expr
        else:
            operand = operand_generator.randomly_generate()
            sub_expressions.append(operand)
            return operand


class GenerateInteger():
    _avoid_many_zeroes = False

    # if None, integer length is randomly chosen from _integer_len_range
    _integer_len = None
    # 1 to 20 digits, max integer length 12345678901234567890
    _integer_len_range = range(1, 19 + 1)
    _random_integer_len_distribution = [
        0.0500, 0.3270, 0.3260, 0.2310, 0.0410, 0.0110, 0.0062, 0.0012, 0.0011, 0.0010,
        0.0009, 0.0008, 0.0007, 0.0006, 0.0005, 0.0004, 0.0003, 0.0002, 0.0001
    ]
    assert len(_integer_len_range) == len(_random_integer_len_distribution)
    assert sum(_random_integer_len_distribution) == 1.0

    @property
    def avoid_many_zeroes(self):
        return type(self)._avoid_many_zeroes

    @avoid_many_zeroes.setter
    def avoid_many_zeroes(self, val):
        type(self)._avoid_many_zeroes = val

    @property
    def integer_len(self):
        return type(self)._integer_len

    @integer_len.setter
    def integer_len(self, val):
        if val == 99:
            val = None
        if val is not None:
            assert val in self._integer_len_range
        type(self)._integer_len = val

    @property
    def integer_len_range(self):
        return type(self)._integer_len_range

    def _randomly_choose_integer_len(self):
        random_integer_len = None

        r = random.random()
        cumulative = 0.0
        for i in range(len(self._random_integer_len_distribution)):
            cumulative += self._random_integer_len_distribution[i]
            if r <= cumulative:
                random_integer_len = i + 1
                break
        assert random_integer_len is not None
        return random_integer_len

    def __init__(self):
        super(GenerateInteger, self).__init__()

        sign = -1 if random.random() <= 0.5 else 1

        if self._integer_len is None:
            integer_len = self._randomly_choose_integer_len()
        else:
            integer_len = self._integer_len
        if integer_len == 1:
            integer_range = (0, 9)
        else:
            integer_range = (
                10 ** (integer_len - 1),
                10**integer_len - 1
            )
        while True:
            self.value = sign * random.randint(integer_range[0],
                                               integer_range[1])
            if (self._avoid_many_zeroes == False
                or self.value != 0 or random.random() <= 0.001):
                break

    def __str__(self):
        return self.value.__str__()

    def __len__(self):
        return len(self.__str__())

    def precedence(self):
        return 0


class GenerateFloat():
    # if None, integer part length is randomly chosen
    # from _float_len_range
    _float_len = None

    _float_len_range = range(1, 19 + 1)
    _random_float_len_distribution = [
        0.1850, 0.1900, 0.2000, 0.2000, 0.2000, 0.0110, 0.0062, 0.0012, 0.0011, 0.0010,
        0.0009, 0.0008, 0.0007, 0.0006, 0.0005, 0.0004, 0.0003, 0.0002, 0.0001
    ]
    assert len(_float_len_range) == \
        len(_random_float_len_distribution)
    assert round(sum(_random_float_len_distribution), 15) == 1.0

    _num_decimals = 0

    @property
    def float_len(self):
        return type(self)._float_len

    @float_len.setter
    def float_len(self, val):
        if val == 99:
            val = None
        if val is not None:
            assert val in self._float_len_range
        type(self)._float_len = val

    @property
    def float_len_range(self):
        return type(self)._float_len_range

    def _randomly_pick_float_len(self):
        random_float_len = None
        r = random.random()
        cumulative = 0.0
        for i in range(len(self._random_float_len_distribution)):
            cumulative += self._random_float_len_distribution[i]
            if r <= cumulative:
                random_float_len = i + 1
                break
        assert random_float_len is not None
        return random_float_len

    def __init__(self):
        super(GenerateFloat, self).__init__()

        sign = -1 if random.random() <= 0.5 else 1

        if self._float_len is None:
            float_len = self._randomly_pick_float_len()
        else:
            float_len = self._float_len
        if float_len == 1:
            float_integer_part_range = (0, 9)
        else:
            float_integer_part_range = (
                10 ** (float_len - 1),
                10**float_len - 1
            )

        float_integer_part = random.randint(float_integer_part_range[0],
                                            float_integer_part_range[1])
        
        self._num_decimals = random.randint(1, float_len)

        self.value = sign * (
            float_integer_part / 10**self._num_decimals
        )

    def __str__(self):
        return '{:.{prec}f}'.format(self.value, prec=self._num_decimals)

    def __len__(self):
        return len(self.__str__())

    def precedence(self):
        return 0


class BinaryExpression():
    def __init__(self, operator, left_expression, right_expression):
        super(BinaryExpression, self).__init__()

        self.operator = operator
        self.left = left_expression
        self.right = right_expression

    @classmethod
    def create_random(cls, level, sub_expressions, operand_generator,
                      operator_generator):
        operator = operator_generator.randomly_pick()

        left = MathExpression.create_random(level + 1, sub_expressions,
                                            operand_generator,
                                            operator_generator)
        right = MathExpression.create_random(level + 1, sub_expressions,
                                            operand_generator,
                                            operator_generator)

        return BinaryExpression(operator, left, right)

    def precedence(self):
        return self.operator['prec']

    def __str__(self):
        left_str = self.left.__str__()
        right_str = self.right.__str__()
        op_str = self.operator['display']

        if self.left.precedence() > self.precedence():
            left_str = enclose_expression_in_brackets(left_str)
        if self.right.precedence() > self.precedence():
            right_str = enclose_expression_in_brackets(right_str)

        if (op_str == '+' or op_str == '-') and self.right.__str__()[0] == '-':
            right_str = enclose_expression_in_brackets(right_str)

        return left_str + op_str + right_str

    def __len__(self):
        return len(self.__str__())


class Expression(object):
    def __init__(self):
        super(Expression, self).__init__()

    def precedence(self):
        return -1

    def _lengthen_expression(cls, expr, desired_expression_len,
                             operator_generator, sub_expressions):
        while (len(expr) < desired_expression_len):
            operator = operator_generator.randomly_pick()['display']
            expr += operator

            sub_expression_len_needed = desired_expression_len - len(expr)
            if sub_expression_len_needed < 0:
                sub_expression_len_needed = 0
            sub_expression = cls._find_best_expression_having_certain_len(
                sub_expressions, sub_expression_len_needed).__str__()

            if ((operator == '+' or operator == '-')
                and sub_expression[0] == '-'):
                sub_expression = enclose_expression_in_brackets(sub_expression)

            expr += sub_expression

        return expr

    def _shorten_expression(expr, desired_expression_len):
        number_chars_to_shorten = len(expr) - desired_expression_len

        num_parentheses_to_remove = number_chars_to_shorten // 3
        if num_parentheses_to_remove > 0:
            neg_number_in_brackets_regex = re.compile(r"[(\[]-(\d+)[)\]]")
            (expr, num_replacements_made) = neg_number_in_brackets_regex.subn(
                r"\1", expr, num_parentheses_to_remove)
            number_chars_to_shorten -= (num_replacements_made * 3)
        num_negations = number_chars_to_shorten
        if num_negations > 0:
            neg_number_no_brackets_regex = re.compile(r"(^|(?<=[x*/ ]))-(\d+)")
            (expr, num_replacements_made) = neg_number_no_brackets_regex.subn(
                r"\2", expr, num_negations)
            number_chars_to_shorten -= num_replacements_made

        return expr

    def _find_best_expression_having_certain_len(sub_expressions, desired_len):
        best_expression = None

        for expr in sub_expressions:
            if best_expression is None:
                best_expression = expr
                continue

            expr_len_diff = expr.__len__() - desired_len
            best_expression_len_diff = best_expression.__len__() - desired_len

            if abs(expr_len_diff) < abs(best_expression_len_diff):
                best_expression = expr

        return best_expression

    @classmethod
    def generate(cls, operand_generator, operator_generator,
                 desired_expression_len, max_attempts):
        assert desired_expression_len >= 1

        for attempt in range(max_attempts):
            sub_expressions = []
            MathExpression.create_random(0, sub_expressions, operand_generator,
                                         operator_generator)

            expr = cls._find_best_expression_having_certain_len(
                sub_expressions, desired_expression_len).__str__()

            if (len(expr) < desired_expression_len):
                expr = cls._lengthen_expression(cls, expr,
                                                desired_expression_len,
                                                operator_generator,
                                                sub_expressions)

            if (len(expr) > desired_expression_len):
                expr = cls._shorten_expression(expr.__str__(),
                                               desired_expression_len)

            if len(expr) == desired_expression_len:
                print(expr)
                break

        if len(expr) != desired_expression_len:
            eprint("Expected ", desired_expression_len, ", got ", len(expr),
                   sep="")


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def enclose_expression_in_brackets(expr):
    use_parenthesis = random.random() <= 0.5
    left_bracket = '(' if use_parenthesis else '['
    right_bracket = ')' if use_parenthesis else ']'
    return left_bracket + expr + right_bracket


def show_help_and_exit(default_max_expression_len,
                       max_number_of_spaces_around_operator):
    print("Generates random elementary math expressions of various lengths.")
    print()
    print("Options:")
    print("-i, --integer nn")
    print("  Generates random integers of length nn.")
    print("  nn: {}-{}, 99=random length. Default: 99".format(
            min(GenerateInteger().integer_len_range),
            max(GenerateInteger().integer_len_range)
        )
    )
    print("-f, --float nn")
    print("  Generates random floats of length nn.")
    print("  nn: {}-{}, 99=random length. Default: 99".format(
            min(GenerateFloat().float_len_range),
            max(GenerateFloat().float_len_range)
        )
    )
    print("-o, --operators a|s|m|d|as|md|asmd")
    print("     a: addition")
    print("     s: subtraction")
    print("     m: multiplication")
    print("     d: division")
    print("    as: addition, subtraction")
    print("    md: multiplication, division")
    print("  asmd: addition, subtraction, multiplication, division (default)")
    print("-s, --space n")
    print("  Number of spaces around an operator. n: 0-{}. Default: 0-3 random."
          .format(max_number_of_spaces_around_operator))
    print("-l, --length nnn")
    print("  Generates expressions of length 1 to nnn. Default:",
          default_max_expression_len)
    print("-h, --help")
    print("  Displays this help screen.")
    sys.exit(1)


def show_invalid_syntax_and_exit():
    eprint('Invalid syntax. Enter -h for help.')
    sys.exit(2)


def parse_cmd_line_options(argv):
    integer_len = None
    float_len = None
    operators = Operators.ADDITION_SUBTRACTION_MULTIPLICATION_DIVISION
    number_of_spaces_around_operator = None
    max_expression_len = 511
    max_number_of_spaces_around_operator = 9

    try:
        opts, args = getopt.getopt(argv, "i:f:l:s:o:h", ["integer=", "float=",
                                                         "length=", "space=",
                                                         "operators=", "help"])
    except getopt.GetoptError:
        show_invalid_syntax_and_exit()
    for opt,arg in opts:
        if opt in ("-i", "--integer"):
            if arg is None or not arg.isdigit():
                show_invalid_syntax_and_exit()
            integer_len = int(arg)
        elif opt in ("-f", "--float"):
            if arg is None or not arg.isdigit():
                show_invalid_syntax_and_exit()
            float_len = int(arg)
        elif opt in ("-l", "--length"):
            if arg is None or not arg.isdigit():
                show_invalid_syntax_and_exit()
            max_expression_len = int(arg)
        elif opt in ("-s", "--space"):
            if arg is None or not arg.isdigit():
                show_invalid_syntax_and_exit()
            number_of_spaces_around_operator = int(arg)
            if (number_of_spaces_around_operator
                > max_number_of_spaces_around_operator):
                show_invalid_syntax_and_exit()
        elif opt in ("-o", "--operators"):
            if arg == 'a':
                operators = Operators.ADDITION
            elif arg == 's':
                operators = Operators.SUBTRACTION
            elif arg == 'm':
                operators = Operators.MULTIPLICATION
            elif arg == 'd':
                operators = Operators.DIVISION
            elif arg == 'as':
                operators = Operators.ADDITION_SUBTRACTION
            elif arg == 'md':
                operators = Operators.MULTIPLICATION_DIVISION
            elif arg == 'asmd':
                operators = Operators.ADDITION_SUBTRACTION_MULTIPLICATION_DIVISION
            else:
                show_invalid_syntax_and_exit()
        elif opt in ("-h", "--help"):
            show_help_and_exit(max_expression_len,
                               max_number_of_spaces_around_operator)

    return {
        'integer_len': integer_len,
        'float_len': float_len,
        'operators': operators,
        'number_of_spaces_around_operator': number_of_spaces_around_operator,
        'max_expression_len': max_expression_len
    }

def main():
    random.seed()

    params = parse_cmd_line_options(sys.argv[1:])

    operator_generator = OperatorGenerator.get(params['operators'],
         params['number_of_spaces_around_operator'])

    if (params['integer_len'] is not None and
            params['float_len'] is None):
        operand_generator = OperandGenerator.get_integer_generator(
            params['integer_len'], params['operators'])
    elif (params['integer_len'] is None
            and params['float_len'] is not None):
        operand_generator = OperandGenerator.get_float_generator(
            params['float_len']
        )
    else:
        operand_generator = OperandGenerator.get_integer_and_float_generator(
            params['operators'], params['integer_len'],
            params['float_len']
        )

    for expr_len in range(params['max_expression_len']):
        desired_expression_len = expr_len + 1
        max_attempts = 100
        Expression.generate(operand_generator, operator_generator,
                            desired_expression_len, max_attempts)

    sys.exit(0)

if __name__ == "__main__":
    main()
