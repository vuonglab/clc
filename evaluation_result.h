#ifndef EVALUATION_RESULT_H_INCLUDED
#define EVALUATION_RESULT_H_INCLUDED

#include <stdbool.h>

typedef struct evaluation_result evaluation_result;
struct evaluation_result {
    long double answer;
    bool expression_contains_floats;
    bool expression_contains_multiplication_or_division;
};

typedef struct trailing_d_result trailing_d_result;
struct trailing_d_result {
	int d_count;
	int non_d_count;
};

#endif
