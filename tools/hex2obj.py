#!/usr/bin/env python

import sys

def q2f(n):
    value = int(n, 16) / (1 << 16)
    num_bits = 16 
    if value >= 2**(num_bits - 1):
        value -= 2**num_bits
    return value

# no comments (for icarus verilog dumps)
def readline_nc(file):
    while True:
        line = file.readline()
        if line[0:2] != "//":
            break
    return line

def convert(filename, outfile):
    with open(filename, "r") as f:
        with open(outfile, "w") as of:
            verts = int(readline_nc(f)[:-1], 16)
            for _ in range(verts):
                of.write("v")
                for _ in range(3):
                    of.write(" " + str(q2f(readline_nc(f)[:-1])))
                of.write("\n")

            faces = int(readline_nc(f)[:-1], 16)
            for _ in range(faces):
                of.write("f")
                for _ in range(3):
                    of.write(" " + str(int(readline_nc(f)[:-1], 16)))
                of.write("\n")

if len(sys.argv) != 3:
    print("Usage: " + sys.argv[0] + " <hex file> <new obj file>")
    sys.exit()

convert(sys.argv[1], sys.argv[2])

