import os
import platform

# Determine the current platform
is_windows = os.name == 'nt'
is_linux = platform.system() == 'Linux'
name_platform = 'linux' if is_linux else 'windows' if is_windows else 'macos'

# First we create a clean output file based on constants.template.f90 if needed
current_dir = os.path.dirname(__file__)
output_file_path = os.path.join(current_dir, 'generated_constants.f90')
template_fortran = open(os.path.join(current_dir, 'constants.template.f90'), 'r').readlines()
if not os.path.exists(output_file_path):
    print("Creating initial constants.f90 from template...")
    open(output_file_path, 'w').writelines(template_fortran)
output_file_content = open(output_file_path,'r').readlines()

fconstants = open(os.path.join(current_dir, 'constants.txt'), 'r').readlines()
constants = [line.strip() for line in fconstants if not line.startswith('#') and line.strip() != '']
constants = list(dict.fromkeys(constants))  # Remove duplicates

c_template = open(os.path.join(current_dir, 'constant.template.c'), 'r').readlines()
template_line = [line for line in c_template if '[var_name]' in line][0]
output_lines = []

for const in constants:
    line = template_line
    line = line.replace('[var_name]', const)
    output_lines.append("#ifdef " + const + "\n")
    output_lines.append(line)
    output_lines.append("#endif\n")
insert_index = c_template.index(template_line)
output_generator = c_template[:insert_index] + output_lines + c_template[insert_index+1:]

output_gen_name = 'constant_generator_' + name_platform + '.c'
output_gen_file = os.path.join(current_dir, output_gen_name)
with open(output_gen_file, 'w') as f:
    f.writelines(output_generator)

print(f"Generated {output_gen_file} for {name_platform} with {len(constants)} constants.")
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