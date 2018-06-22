#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

static void get_next_char();
static long double start();
static long double get_number();
static long double get_term();
static long double get_factor();

static void report_invalid_expression_and_abort();
static void get_next_non_whitespace_char();
static void abort_if_not_end_of_expression();
static void init(char *expression);
static void skip_white_space();

char look; // lookahead character
char *_expression;

long double evaluate_expression(char *expression)
{
	init(expression);
	long double answer = start();
	abort_if_not_end_of_expression();
	return answer;
}

static void init(char *expression)
{
	_expression = expression;
	get_next_non_whitespace_char();
}

static long double start()
{
	long double acc = 0.0;

	if (look=='+' || look=='-')
		acc = 0.0;
	else
		acc = get_term();

	while (look=='+' || look=='-')
		switch (look) {
			case '+':
				get_next_non_whitespace_char();
				acc += get_term();
				break;
			case '-':
				get_next_non_whitespace_char();
				acc -= get_term();
				break;
		}

	return acc;
}

static long double get_term()
{
	long double acc = get_factor();
	while (look=='*' || look=='/') {
		switch (look) {
			case '*':
				get_next_non_whitespace_char();
				acc *= get_factor();
				break;
			case '/':
				get_next_non_whitespace_char();
				acc /= get_factor();
				break;
		}
	}

	return acc;
}

static long double get_factor()
{
	long double acc = 0.0;

	if (look == '(') {
		get_next_non_whitespace_char();
		acc = start();
		if (look != ')')
			report_invalid_expression_and_abort();
		get_next_non_whitespace_char();
	} else
		acc = get_number();

	return acc;
}

static long double get_number()
{
	long double acc = 0.0;
	int decimalPointCount = 0;
	long double negativePowerOfTen = 0.1;

	if (!isdigit(look) && (look != '.'))
		report_invalid_expression_and_abort();

	while (isdigit(look) || look=='.') {
		if (look == '.') {
			if (++decimalPointCount > 1)
				report_invalid_expression_and_abort();
		} else if (decimalPointCount == 1) {
			acc += (look - '0') * negativePowerOfTen;
			negativePowerOfTen /= 10.0;
		} else 
			acc = (acc * 10.0) + (look - '0');

		get_next_char();
	}

	skip_white_space();

	return acc;
}

static void get_next_non_whitespace_char()
{
	get_next_char();
	skip_white_space();
}

static void get_next_char()
{
	look = *_expression++;
}

static void skip_white_space()
{
	while (isspace(look))
		get_next_char();
}

static void abort_if_not_end_of_expression()
{
	if (look != '\0')
		report_invalid_expression_and_abort();
}

static void report_invalid_expression_and_abort()
{
	puts("clc: invalid elementary arithmetic expression\nTry 'clc --help' for more information.");
	exit(EXIT_FAILURE);
}
