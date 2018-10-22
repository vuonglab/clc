#!/bin/sh

cat decimal_addition.tests >all.tests
printf '\n' >>all.tests
cat integer_addition.tests >>all.tests
printf '\n' >>all.tests
cat integer_and_decimal_addition.tests >>all.tests
printf '\n' >>all.tests

cat decimal_subtraction.tests >>all.tests
printf '\n' >>all.tests
cat integer_subtraction.tests >>all.tests
printf '\n' >>all.tests
cat integer_and_decimal_subtraction.tests >>all.tests
printf '\n' >>all.tests

cat decimal_multiplication.tests >>all.tests
printf '\n' >>all.tests
cat integer_multiplication.tests >>all.tests
printf '\n' >>all.tests
cat integer_and_decimal_multiplication.tests >>all.tests
printf '\n' >>all.tests

cat decimal_division.tests >>all.tests
printf '\n' >>all.tests
cat integer_division.tests >>all.tests
printf '\n' >>all.tests
cat integer_and_decimal_division.tests >>all.tests
printf '\n' >>all.tests

cat decimal_addition_and_subtraction.tests >>all.tests
printf '\n' >>all.tests
cat integer_addition_and_subtraction.tests >>all.tests
printf '\n' >>all.tests
cat integer_and_decimal_addition_and_subtraction.tests >>all.tests
printf '\n' >>all.tests

cat decimal_multiplication_and_division.tests >>all.tests
printf '\n' >>all.tests
cat integer_multiplication_and_division.tests >>all.tests
printf '\n' >>all.tests
cat integer_and_decimal_multiplication_and_division.tests >>all.tests
printf '\n' >>all.tests

cat decimal_addition_subtraction_multiplication_and_division.tests >>all.tests
printf '\n' >>all.tests
cat integer_addition_subtraction_multiplication_and_division.tests >>all.tests
printf '\n' >>all.tests
cat integer_and_decimal_addition_subtraction_multiplication_and_division.tests >>all.tests
