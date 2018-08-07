#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "evaluation_result.h"

extern evaluation_result evaluate_expression(char *expression);

static void abort_if_no_expression_on_command_line(int argc);
static void show_usage_if_requested_and_exit(int argc, char **argv);
static void show_floating_point_type_if_requested_and_exit(int argc, char **argv);
static char* get_floating_point_type();
static void reconstruct_command_ine_to_get_expression(char* expression, char **argv, int expression_buf_size);
static void replace_brackets_and_x_in_expression_with_parentheses_and_asterisk(char *expression);
static void replace_char(char *str, char orig, char new);
static void pretty_print_answer(evaluation_result result);
static int get_number_of_significant_digits_in_answer(evaluation_result result);
static void snprintf_with_exit(char* buffer, int buf_size, char *fmt, int precision, long double answer);
static int get_mantissa(char *buffer);
static trailing_nines_result get_number_of_trailing_decimal_nines_and_non_nine(char *answer);
static trailing_zeros_result get_number_of_trailing_zeros_followed_by_a_nonzero(char *answer);
static void remove_trailing_zeros_in_decimal_fraction(char* buffer);

int main(int argc, char **argv)
{
	const int expression_buf_size = 511+1;
	char expression[expression_buf_size];

	abort_if_no_expression_on_command_line(argc);
	show_usage_if_requested_and_exit(argc, argv);
	show_floating_point_type_if_requested_and_exit(argc, argv);
	reconstruct_command_ine_to_get_expression(expression, argv, expression_buf_size);
	replace_brackets_and_x_in_expression_with_parentheses_and_asterisk(expression);

	evaluation_result result = evaluate_expression(expression);
	
	pretty_print_answer(result);

	exit(EXIT_SUCCESS);
}

static void abort_if_no_expression_on_command_line(int argc)
{
	if (argc > 1)
		return;

	puts("clc: missing elementary arithmetic expression\nTry 'clc --help' for more information.");
	exit(EXIT_FAILURE);
}

static void show_usage_if_requested_and_exit(int argc, char **argv)
{
	if (argv[1] == NULL || strcmp(argv[1], "--help") != 0)
		return;

	puts("Usage: clc expression");
	puts("Command-line elementary arithmetic calculator.");
	puts("");
	puts("Expression can contain +, -, *, x, /, (), and [].");
	puts("");
	puts("Examples:");
	puts("  clc [[6+2]x5-10]/3          Answer: 10");
	puts("  clc 52.1834*(5100+18)/85015 Answer: 3.1415");

	exit(EXIT_SUCCESS);
}

static void show_floating_point_type_if_requested_and_exit(int argc, char **argv)
{
	if (argv[1] == NULL || strcmp(argv[1], "--fp-type") != 0)
		return;

	char* fp_type = get_floating_point_type();
	puts(fp_type);

	exit(EXIT_SUCCESS);
}

static char* get_floating_point_type()
{
	if (sizeof(long double) > sizeof(double))
		return "long double";
	else if (sizeof(long double) == sizeof(double))
		return "double";
	else if (sizeof(long double) == sizeof(float))
		return "float";

	return "unknown";
}

static void reconstruct_command_ine_to_get_expression(char *expression, char **argv, int expression_buf_size)
{
	if (expression_buf_size <= 0) {
		puts("Invalid expression buffer size.");
		exit(EXIT_FAILURE);
	}

	expression[0] = '\0';
	int expr_buf_size_remaining = expression_buf_size-1;

	for (argv++; *argv != NULL; argv++) {
		strncat(expression, *argv, expr_buf_size_remaining);
		expr_buf_size_remaining -= strlen(*argv);

		if (*(argv+1) == NULL)
			break;

		strncat(expression, " ", expr_buf_size_remaining);
		expr_buf_size_remaining--;

		if (expr_buf_size_remaining < 0)
			break;
	}

	if (expr_buf_size_remaining < 0) {
		puts("Expression buffer too small.");
		exit(EXIT_FAILURE);
	}
}

static void replace_brackets_and_x_in_expression_with_parentheses_and_asterisk(char *expression)
{
	replace_char(expression, '[', '(');
	replace_char(expression, ']', ')');
	replace_char(expression, 'x', '*');
	replace_char(expression, 'X', '*');
}

static void replace_char(char *str, char orig, char new)
{
	char *match = str;
	while ((match = strchr(match, orig)) != NULL)
		*match++ = new;
}

static void pretty_print_answer(evaluation_result result)
{
	// https://www.tutorialspoint.com/cprogramming/c_data_types.htm
	// float: 6 decimal places; double: 15 decimal places; long double: 19 decimal places

	// warning: integer constant is so large that it is unsigned
	// -9522868949551080827L // len 19, without the negative sign - overflow
	// 10000000000000000000L // len 20 - overflow
	// 9999999999999999999L // len 19 - overflow

	// No warning about integer constant too large
	// 9000000000000000000L // no overflow

	long double answer = result.answer;

	int num_decimal_places_e_form = get_number_of_significant_digits_in_answer(result)-1;

	const int buf_size = 1536;
	char buffer[buf_size];
	snprintf_with_exit(buffer, buf_size, "%.*Le", num_decimal_places_e_form, answer);

	if ((strcmp(buffer, "inf") != 0 && strcmp(buffer, "-inf") != 0) &&
		(strcmp(buffer, "nan") != 0 && strcmp(buffer, "-nan") != 0)) {
		int mantissa = get_mantissa(buffer);
		if (-3 <= mantissa && mantissa <= num_decimal_places_e_form) {
			int num_decimal_places = num_decimal_places_e_form - mantissa;
			snprintf_with_exit(buffer, buf_size, "%.*Lf", num_decimal_places, answer);
			trailing_nines_result nines_result = get_number_of_trailing_decimal_nines_and_non_nine(buffer);
			int number_of_nines = nines_result.nine_count + nines_result.non_nine_count;
			// 3-10
			if (number_of_nines >= 8 || (nines_result.nine_count == 4 && num_decimal_places >= 15)) {
				// handle answers like -8.408039999999999 (should be -8.40804)
				snprintf_with_exit(buffer, buf_size, "%.*Lf", num_decimal_places-number_of_nines, answer);
			}
			trailing_zeros_result zeros_result = get_number_of_trailing_zeros_followed_by_a_nonzero(buffer);
			int number_of_zeros_and_nonzero = zeros_result.zero_count + zeros_result.non_zero_count;
			// 9-12
			if (number_of_zeros_and_nonzero >= 9 || (zeros_result.zero_count >= 4 && num_decimal_places >= 15)) {
				// handle answers like -0.9400000000000001 (should be -0.94)
				snprintf_with_exit(buffer, buf_size, "%.*Lf", num_decimal_places-number_of_zeros_and_nonzero, answer);
			}
		}
	}

	remove_trailing_zeros_in_decimal_fraction(buffer);
	if (strcmp(buffer, "-0") == 0)
		strcpy(buffer, "0");

	puts(buffer);
}

static int get_number_of_significant_digits_in_answer(evaluation_result result)
{
	// Number of digits is empirically determined from generating many
	// random expressions and comparing answers from this program
	// to calc (https://github.com/lcn2/calc), an arbitrary precision calculator.
	if (result.expression_contains_multiplication_or_division)
		return result.expression_contains_floats ? 16 : 17;
	else
		return result.expression_contains_floats ? 18 : 19;
}

static void snprintf_with_exit(char* buffer, int buf_size, char *fmt, int precision, long double answer)
{
	int n = snprintf(buffer, buf_size, fmt, precision, answer);
	if (n >= buf_size) {
		puts("Answer buffer too small.");
		exit(EXIT_FAILURE);
	}
	if (n < 0) {
		puts("Internal format error.");
		exit(EXIT_FAILURE);
	}
}

static int get_mantissa(char *buffer)
{
	char *e = strchr(buffer, 'e');
	if (e == NULL) {
		printf("Mantissa not found: %s\n", buffer);
		exit(EXIT_FAILURE);
	}
	long mantissa_l = strtol(e+1, NULL,  10);
	int mantissa = (int)mantissa_l;
	if (errno == ERANGE || mantissa != mantissa_l) {
		printf("Mantissa too big: %s\n", buffer);
		exit(EXIT_FAILURE);
	}
	return mantissa;
}

static trailing_nines_result get_number_of_trailing_decimal_nines_and_non_nine(char *answer)
{
	trailing_nines_result result = { .nine_count = 0, .non_nine_count = 0 };

	char *p = strchr(answer, '.');
	if (p == NULL)
		return result;

	p = answer + strlen(answer) - 1;

	int number_of_non_nines = 0, i;
	for (i = 0; i < 2; i++)
		if ('0' <= *p && *p <= '8') {
			++number_of_non_nines;
			--p;
		}

	int number_of_nines = 0;
	while (answer <= p && *p == '9') {
		++number_of_nines;
		--p;
	}

	if (number_of_nines == 0)
		number_of_non_nines = 0;
	
	result.nine_count = number_of_nines;
	result.non_nine_count = number_of_non_nines;

	return result;
}

static trailing_zeros_result get_number_of_trailing_zeros_followed_by_a_nonzero(char *answer)
{
	trailing_zeros_result result = { .zero_count = 0, .non_zero_count = 0 };

	char *p = strchr(answer, '.');
	if (p == NULL)
		return result;

	p = answer + strlen(answer) - 1;
	if (!('1' <= *p && *p <= '9'))
		return result;

    --p;
    int num_non_zero = 1;
    if ('1' <= *p && *p <= '9') {
        ++num_non_zero;
        --p;
    }

    int number_of_zeros = 0;
    while (*p == '0') {
        ++number_of_zeros;
        --p;
    }
        
    if (number_of_zeros == 0)
        num_non_zero = 0;
    
	result.zero_count = number_of_zeros;
	result.non_zero_count = num_non_zero;

    return result;
}

static void remove_trailing_zeros_in_decimal_fraction(char* buffer)
{
	char *p = strchr(buffer, '.');
	if (p == NULL)
		return;

	int len = strlen(p);

	char *e = strchr(buffer, 'e');
	if (e != NULL) {
		if (!(e > p))
			return;
		len = (e-p)/sizeof(char);
	}

	p += len;
	int i;
	for (i=0; i<len; i++, p--)
		if (*(p-1) != '0' && *(p-1) != '.')
			break;

	if (e == NULL)
		*p = '\0';
	else
		strcpy(p, e);
}
