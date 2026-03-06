import os
import platform

# Determine the current platform
is_windows = os.name == 'nt'
is_linux = platform.system() == 'Linux'
name_platform = 'linux' if is_linux else 'windows' if is_windows else 'macos'

# Mapping from Fortran iso_c_binding types to C printf format and cast
TYPE_INFO = {
    'c_int':    ('%d',  '(int)'),
    'c_long':   ('%ld', '(long)'),
    'c_short':  ('%hd', '(short)'),
}

# First we create a clean output file based on constants.template.f90 if needed
current_dir = os.path.dirname(__file__)
output_file_path = os.path.join(current_dir, 'generated_constants.f90')
template_fortran = open(os.path.join(current_dir, 'constants.template.f90'), 'r').readlines()
if not os.path.exists(output_file_path):
    print("Creating initial constants.f90 from template...")
    open(output_file_path, 'w').writelines(template_fortran)
output_file_content = open(output_file_path,'r').readlines()

# Parse constants.txt: each line is "CONST_NAME [type]"
# If type is omitted, defaults to c_int
fconstants = open(os.path.join(current_dir, 'constants.txt'), 'r').readlines()
constants_with_types = []
seen = set()
for line in fconstants:
    line = line.strip()
    if line.startswith('#') or line == '':
        continue
    parts = line.split()
    name = parts[0]
    ftype = parts[1] if len(parts) > 1 else 'c_int'
    if name not in seen:
        constants_with_types.append((name, ftype))
        seen.add(name)

c_template = open(os.path.join(current_dir, 'constant.template.c'), 'r').readlines()
template_line = [line for line in c_template if '[var_name]' in line][0]
output_lines = []

for name, ftype in constants_with_types:
    fmt, cast = TYPE_INFO.get(ftype, ('%d', '(int)'))
    line = f'    fprintf(fptr, "    integer({ftype}), parameter :: {name} = {fmt}\\n", {cast}{name});\n'
    output_lines.append("#ifdef " + name + "\n")
    output_lines.append(line)
    output_lines.append("#endif\n")
insert_index = c_template.index(template_line)
output_generator = c_template[:insert_index] + output_lines + c_template[insert_index+1:]

output_gen_name = 'constant_generator_' + name_platform + '.c'
output_gen_file = os.path.join(current_dir, output_gen_name)
with open(output_gen_file, 'w') as f:
    f.writelines(output_generator)

print(f"Generated {output_gen_file} for {name_platform} with {len(constants_with_types)} constants.")
print("Now compiling the generated file...")
binary_path = os.path.join(current_dir, 'constant_generator_' + name_platform + ('.exe' if is_windows else ''))
if os.system(f"gcc -o {binary_path} {output_gen_file}") != 0:
    raise RuntimeError("Compilation failed.")

print("Now running the compiled generator...")
tmp_file = f"tmp_constants.{name_platform}.f90"
if os.system(f"{binary_path} {tmp_file}") != 0:
    raise RuntimeError("Running the constant generator failed.")

const_code = open(tmp_file, 'r').readlines()
print("Inserting generated constants into generated_constants.f90...")

# Find the insertion point just after the platform-specific section
insert_index = output_file_content.index([line for line in output_file_content \
                                       if '#if IS_WINDOWS' in line and is_windows \
                                            or '__linux__' in line and is_linux \
                                            or '#else' in line and not (is_windows or is_linux)][0]) + 2

final_fortran = output_file_content[:insert_index] + const_code + output_file_content[insert_index:]

# Finally we write the final Fortran file
with open(output_file_path, 'w') as f:
    f.writelines(final_fortran)


print("Deleting temporary files...")
os.remove(binary_path)
os.remove(output_gen_file)
os.remove(tmp_file)
print("Done.")