#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern long double evaluate_expression(char *expression);

static void abort_if_no_expression_on_command_line(int argc);
static void show_usage_if_requested_and_exit(int argc, char **argv);
static void reconstruct_command_ine_to_get_expression(char* expression, char **argv, int expression_buf_size);
static void replace_brackets_and_x_in_expression_with_parentheses_and_asterisk(char *expression);
static void pretty_print_answer(long double answer);
static void replace_char(char *str, char orig, char new);
static void remove_trailing_zeros_in_decimal_fraction(char* buffer);

int main(int argc, char **argv)
{
	const int expression_buf_size = 511+1;
	char expression[expression_buf_size];

	abort_if_no_expression_on_command_line(argc);
	show_usage_if_requested_and_exit(argc, argv);
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

	puts("whatis: missing elementary arithmetic expression\nTry 'whatis --help' for more information.");
	exit(EXIT_FAILURE);
}

static void show_usage_if_requested_and_exit(int argc, char **argv)
{
	if (argv[1] == NULL || strcmp(argv[1], "--help") != 0)
		return;

	puts("Usage: whatis expression");
	puts("Command-line elementary arithmetic calculator.");
	puts("");
	puts("Exxpression can contain +, -, *, x, /, (), and [].");
	puts("");
	puts("Examples:");
	puts("  whatis [[6+2]x5-10]/3          Answer: 10");
	puts("  whatis 52.1834*(5100+18)/85015 Answer: 3.1415");

	exit(EXIT_FAILURE);
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

		if (expr_buf_size_remaining >= 1)
			strcat(expression, " ");
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

static void pretty_print_answer(long double answer)
{
	const int buf_size = 48;
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

	remove_trailing_zeros_in_decimal_fraction(buffer);

	puts(buffer);
}

static void replace_char(char *str, char orig, char new)
{
	char *match = str;
	while ((match = strchr(match, orig)) != NULL)
		*match++ = new;
}

static void remove_trailing_zeros_in_decimal_fraction(char* buffer)
{
	char *p = strchr(buffer, '.');
	if (p == NULL)
		return;

	int len = strlen(p);
	p += (len-1);
	for (int i=0; i<len; i++, p--) {
		if (*p != '0' && *p != '.')
			break;
		*p = '\0';
	}
}
