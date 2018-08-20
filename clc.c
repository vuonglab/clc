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
static trailing_d_result get_number_of_trailing_d_followed_by_up_to_two_non_d(char *answer, char digit);
static void remove_trailing_zeros_in_decimal_fraction(char* buffer, int buf_size, bool keep_decimal_point);

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
			if (num_decimal_places == 0)
				num_decimal_places = (result.expression_contains_floats ? 1 : 0);
			snprintf_with_exit(buffer, buf_size, "%.*Lf", num_decimal_places, answer);
			trailing_d_result nines_result = get_number_of_trailing_d_followed_by_up_to_two_non_d(buffer, '9');
			int number_of_nines = nines_result.d_count + nines_result.non_d_count;
			if (8 <= number_of_nines && number_of_nines <= num_decimal_places) {
				int num_decimals = num_decimal_places - number_of_nines;
				if (num_decimals == 0)
					num_decimals = (result.expression_contains_floats ? 1 : 0);
				snprintf_with_exit(buffer, buf_size, "%.*Lf", num_decimals, answer);
			}

			trailing_d_result zeros_result = get_number_of_trailing_d_followed_by_up_to_two_non_d(buffer, '0');
			int number_of_zeros = zeros_result.d_count + zeros_result.non_d_count;
			// Don't truncate -9170.0000000000029 and -508.00000000000087. 
			if (zeros_result.non_d_count > 0 && 5 <= number_of_zeros && number_of_zeros <= num_decimal_places-1)
				snprintf_with_exit(buffer, buf_size, "%.*Lf", num_decimal_places-number_of_zeros, answer);
		}
	}

	remove_trailing_zeros_in_decimal_fraction(buffer, buf_size, result.expression_contains_floats);
	if (strcmp(buffer, "-0") == 0)
		strcpy(buffer, "0");
	if (strcmp(buffer, "-0.0") == 0)
		strcpy(buffer, "0.0");

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

static trailing_d_result get_number_of_trailing_d_followed_by_up_to_two_non_d(char *answer, char digit)
{
	trailing_d_result result = { .d_count = 0, .non_d_count = 0 };

	char *p = strchr(answer, '.');
	if (p == NULL)
		return result;

	p = answer + strlen(answer) - 1;

	int non_digit_count = 0, i;
	for (i = 0; i < 2; i++)
		if ('0' <= *p && *p <= '9' && *p != digit) {
			++non_digit_count;
			--p;
		}

	int digit_count = 0;
	while (answer <= p && *p == digit) {
		++digit_count;
		--p;
	}

	if (digit_count == 0)
		non_digit_count = 0;
	
	result.d_count = digit_count;
	result.non_d_count = non_digit_count;

	return result;
}

static void remove_trailing_zeros_in_decimal_fraction(char* buffer, int buf_size, bool keep_decimal_point)
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

	if (keep_decimal_point && *p == '.') {
		++p;
		if (*p == '0')
			++p;
	}

	if (e == NULL)
		*p = '\0';
	else
		strcpy(p, e);
}
