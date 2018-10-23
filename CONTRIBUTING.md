# CONTRIBUTING

## Fixing bugs

If you find a bug and it is not one of the [known issues](README.md#issues), create a feature branch off the master branch and give it a descriptive name. Make the fix in the feature branch. When finished, submit a pull request for your changes to be reviewed and merged into the master branch.

Note that if an answer from clc is off by a decimal or two, it may not be a bug. It is likely due to the binary floating-point number representation used to approximate real numbers. To check, evaluate the same expression using another calculator that does *not* support arbitrary precision, such as [concalc](http://extcalc-linux.sourceforge.net/concalcdescr.html). See if the answer is off too.

## Adding new features

Before adding a new operator or function or making substantial changes, please file an issue first so we can all agree on the proposed feature or changes.

Note that the inclination is to keep clc small by supporting only addition, subtraction, multiplication and division on decimal numerals. This is because [more advanced command-line calculators already exist](README.md).
