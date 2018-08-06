#ifndef EVALUATION_RESULT_H_INCLUDED
#define EVALUATION_RESULT_H_INCLUDED

#include <stdbool.h>

typedef struct evaluation_result evaluation_result;
struct evaluation_result {
    long double answer;
    bool expression_contains_floats;
    bool expression_contains_multiplication_or_division;
};

typedef struct trailing_nines_result trailing_nines_result;
struct trailing_nines_result {
	int nine_count;
	int non_nine_count;
};

typedef struct trailing_zeros_result trailing_zeros_result;
struct trailing_zeros_result {
	int zero_count;
	int non_zero_count;
};

#endif
