# Tools
This folder contains scripts used to generate parts of the Fortran binding source code, mainly the constant definitions for different platforms.
Important files are:
- `constant_generator.py`: A Python script that generates C code to extract socket-related constants from system headers. It then evaluates those constants with the gcc compiler and generates a Fortran module with the correct values for the target platform.
- `constant.template.c`: Is a template file used by the Python script to generate platform-specific C code.
- `constant.template.f90`: A Fortran module template that will be filled with the extracted constants.
- `constants.txt`: A list of socket-related constants to extract.

