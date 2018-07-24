#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern long double evaluate_expression(char *expression);

static void abort_if_no_expression_on_command_line(int argc);
static void show_usage_if_requested_and_exit(int argc, char **argv);
static void show_floating_point_type_if_requested_and_exit(int argc, char **argv);
static char* get_floating_point_type();
static void reconstruct_command_ine_to_get_expression(char* expression, char **argv, int expression_buf_size);
static void replace_brackets_and_x_in_expression_with_parentheses_and_asterisk(char *expression);
static void replace_char(char *str, char orig, char new);
static void pretty_print_answer(long double answer);
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

	long double answer = evaluate_expression(expression);

	pretty_print_answer(answer);

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

static void pretty_print_answer(long double answer)
{
	const int buf_size = 1536;
	char buffer[buf_size];
	int n = snprintf(buffer, buf_size, "%Lf", answer);
	if (n >= buf_size) {
		puts("Answer buffer too small.");
		exit(EXIT_FAILURE);
	}
	if (n < 0) {
		puts("Internal format error.");
		exit(EXIT_FAILURE);
	}
	if ((strcmp(buffer, "inf")==0 || strcmp(buffer, "-inf")==0) ||
		(strcmp(buffer, "nan")==0 || strcmp(buffer, "-nan")==0)) {
		puts(buffer);
		exit(EXIT_FAILURE);
	}

	remove_trailing_zeros_in_decimal_fraction(buffer);

	// A: 5*0*9x6x3*2*8x3*5*5*1*2*7*2x6x6xmk3x4*9*-7x-3x-3*-7*7*-4*8*-9*-1*-7x6*-5*-4*-2x5*-7x5x-5*3*-4x-1*-8x4x-3*-3*-6x-5x0*2x1x-1x-7*-5 = -0
	// B: -98/18/-78/93/-70/46 = -0.000000
	if (strcmp(buffer, "-0") == 0) {
		puts("0");
		return;
	}

	puts(buffer);
}

static void remove_trailing_zeros_in_decimal_fraction(char* buffer)
{
	char *p = strchr(buffer, '.');
	if (p == NULL)
		return;

	int len = strlen(p);
	p += (len-1);
	int i;
	for (i=0; i<len; i++, p--) {
		if (*p != '0' && *p != '.')
			break;
		*p = '\0';
	}
}
