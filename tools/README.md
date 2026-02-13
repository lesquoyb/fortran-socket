# Tools

This folder contains scripts and templates used to generate platform-specific socket constant definitions for the Fortran binding.

Because socket option values (e.g. `SOL_SOCKET`, `SO_REUSEADDR`, error codes) differ between Windows, Linux, and macOS, they cannot be hardcoded portably. The generator solves this by compiling a small C program that prints the actual values from the system headers, then inserting them into a Fortran module template.

## Files

| File | Description |
|---|---|
| `constant_generator.py` | Main script — orchestrates the entire generation process |
| `constant.template.c` | C source template with a placeholder line for each constant |
| `constants.template.f90` | Fortran module template with platform-conditional sections |
| `constants.txt` | List of C constant names to extract (one per line, `#` for comments) |

## How it works

1. **Read constants** — The script reads `constants.txt` and collects every uncommented constant name.
2. **Generate C source** — For each constant, it expands `constant.template.c` with `#ifdef` guards and `fprintf` calls, producing a platform-specific C file (e.g. `constant_generator_windows.c`).
3. **Compile and run** — The generated C file is compiled with GCC and executed. The resulting binary writes a temporary Fortran file (`tmp_constants.<platform>.f90`) containing `integer(c_int), parameter` declarations with the resolved values.
4. **Assemble Fortran module** — The script inserts the generated declarations into the appropriate platform section of `constants.template.f90` and writes the result to `generated_constants.f90`.
5. **Cleanup** — Temporary files (C source, binary, temp Fortran) are deleted.

## Usage

### Prerequisites

- **Python 3**
- **GCC** — used to compile the generated C code and resolve the constant values from system headers

### Running the generator

```bash
cd tools
python constant_generator.py
```

The script auto-detects the current platform (Windows, Linux, or macOS) and fills in the corresponding section of the output file. The result is written to `tools/generated_constants.f90`.

To build a complete `constants.f90` with values for all three platforms, run the script once on each platform and merge the results, or copy the generated section into `src/constants.f90` under the appropriate `#if` / `#elif` / `#else` block.

### Adding new constants

1. Add the constant name to `constants.txt` (one per line).
2. If the constant requires a header that is not already included in `constant.template.c`, add the `#include` directive there.
3. Re-run `constant_generator.py`.

Constants can be commented out in `constants.txt` by prefixing them with `#`. This is used for legacy or platform-specific constants that are not needed (e.g. IPX/SPX, Appletalk).

## Output

After running, the script produces `generated_constants.f90` in this directory. This file defines a `socket_lib_constants` module with platform-conditional blocks:

```fortran
module socket_lib_constants
    use iso_c_binding
    implicit none

#if IS_WINDOWS
    ! Windows constants filled in here
#elif defined(__linux__)
    ! Linux constants filled in here
#else
    ! macOS constants filled in here
#endif

end module socket_lib_constants
```

Copy the generated content into `src/constants.f90` or replace it entirely.