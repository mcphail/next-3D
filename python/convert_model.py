#!/usr/bin/python3

# Title:		Create C model data from an OBJ file exported from Blender
# Author:		Dean Belfield
# Created:		03/09/2025
# Last Updated:	03/09/2025
#
# Modinfo:

import sys
import os

# Open the file for reading
#
# name = sys.argv[1]							# Get the filename
# full_path = os.path.expanduser(name)			# Expand the full path to the file and

full_path = "/Users/admin/Documents/Dev/Git/next-3D/models/cobra_mk3.obj"
file = open(full_path, "r")						# Open it up as a text file

file_stdout = sys.stdout						# Store the current stdout file handle
# sys.stdout = open(full_path + ".h", "w")		# Redirect stdout for the detokenised file output

scale = 95										# Percentage scale
line = ""										# Storage for line
modelName = ""									# The model name
vertices = []									# List of vertices
faces = []										# List of faces

# Iterate through the file
# Use print to output to file
#
while True:
	line = file.readline()						# Read 1 byte into the buffer data
	if len(line) == 0:
		break
	
	code = line[:line.find(" ")]				# Find the code
	data = line[line.find(" ")+1:].rstrip('\n').split(" ")

	if code == "o":
		modelName = data[0]
	elif code == "v":							# Vertex data	
		if len(data) != 3:
			sys.exit("Invalid vertex count")
		output = []
		for item in data:
			value = round(float(item)*scale/100)
			if value < -128 or value > 127:
				sys.exit("Coordinate data out of range")
			output.append(str(value))
		vertices.append(f"\t{{ {', '.join(output)} }},")
	elif code == "vn:":							# Normal data
		pass
	elif code == "f":							# Face data
		if len(data) != 3:
			sys.exit("Invalid face count")
		output = []
		for item in data:
			value = item.split("//")
			output.append(str(int(value[0])-1))	# Blender indexes vertices from 1, not 0
		output.append("0xFF")					# Colour of face, stubbed
		faces.append(f"\t{{ {', '.join(output)} }},")
		pass
	elif code == "l":							# Line data
		pass
	else:
		pass

print(f"Point8_3D {modelName}_p[] = {{")
print("\n".join(vertices))
print("};")
print(f"Vertice_3D {modelName}_v[] = {{")
print("\n".join(faces))
print("};")

file.close()									# We've done so close the files

sys.stdout.close()								# Close and restore stdout
sys.stdout = file_stdout