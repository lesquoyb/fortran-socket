"""
Merge per-platform generated_constants.f90 files into a single constants.f90.

Usage:
    python merge_constants.py <windows_file> <linux_file> <macos_file> <output_file>

Each input file is a generated_constants.f90 produced by constant_generator.py
on the corresponding platform. This script extracts the constant declarations
from each platform's section and combines them into one file.
"""
import sys
import os

MARKERS = {
    'windows': '#if IS_WINDOWS',
    'linux':   '#elif defined(__linux__)',
    'macos':   '#else',
}

# End markers: the line that terminates a platform section
END_MARKERS = ['#elif', '#else', '#endif', 'end module']


def extract_constants(filepath, marker):
    """Extract constant declaration lines from the platform section of a generated file."""
    with open(filepath, 'r') as f:
        lines = f.readlines()

    in_section = False
    constants = []
    for line in lines:
        if marker in line:
            in_section = True
            continue
        if in_section:
            stripped = line.strip()
            # Stop at next preprocessor directive or end module
            if any(stripped.startswith(em) for em in END_MARKERS):
                break
            # Collect constant declarations (skip blank lines and comments)
            if stripped.startswith('integer('):
                constants.append(line)
    return constants


def main():
    if len(sys.argv) != 5:
        print(f"Usage: {sys.argv[0]} <windows_file> <linux_file> <macos_file> <output_file>")
        sys.exit(1)

    windows_file, linux_file, macos_file, output_file = sys.argv[1:5]

    # Read template
    current_dir = os.path.dirname(__file__)
    template_path = os.path.join(current_dir, 'constants.template.f90')
    with open(template_path, 'r') as f:
        template = f.readlines()

    # Extract constants for each platform
    platform_files = {
        'windows': windows_file,
        'linux':   linux_file,
        'macos':   macos_file,
    }

    platform_constants = {}
    for platform, filepath in platform_files.items():
        if os.path.exists(filepath):
            consts = extract_constants(filepath, MARKERS[platform])
            platform_constants[platform] = consts
            print(f"{platform}: extracted {len(consts)} constants from {filepath}")
        else:
            platform_constants[platform] = []
            print(f"{platform}: file {filepath} not found, skipping")

    # Build the output: insert constants after each platform marker + comment line
    output_lines = []
    for line in template:
        output_lines.append(line)
        for platform, marker in MARKERS.items():
            if marker in line:
                # The next line in the template is the comment - it will be added
                # naturally in the next iteration. We insert constants after it
                # by deferring. Instead, insert a placeholder we replace below.
                pass

    # Simpler approach: rebuild line by line, inserting after comment lines
    output_lines = []
    i = 0
    while i < len(template):
        output_lines.append(template[i])
        for platform, marker in MARKERS.items():
            if marker in template[i]:
                # Next line is the comment
                if i + 1 < len(template):
                    i += 1
                    output_lines.append(template[i])  # comment line
                # Insert constants
                consts = platform_constants.get(platform, [])
                if consts:
                    output_lines.append('\n')
                    output_lines.extend(consts)
                break
        i += 1

    with open(output_file, 'w') as f:
        f.writelines(output_lines)

    total = sum(len(c) for c in platform_constants.values())
    print(f"Wrote {output_file} with {total} total constants across all platforms.")


if __name__ == '__main__':
    main()
