#!/usr/bin/env python

import sys

def q2f(n):
    return float(int.from_bytes(n, signed=True)) / (1 << 16)

def convert(filename, outfile):
    with open(filename, "rb") as f:
        with open(outfile, "w") as of:
            verts = int.from_bytes(f.read(4))
            for _ in range(verts):
                of.write("v")
                for _ in range(3):
                    of.write(" " + str(q2f(f.read(4))))
                of.write("\n")

            faces = int.from_bytes(f.read(4))
            for _ in range(faces):
                of.write("f")
                for _ in range(3):
                    of.write(" " + str(int.from_bytes(f.read(4))))
                of.write("\n")


if len(sys.argv) != 3:
    print("Usage: " + sys.argv[0] + " <bin file> <new obj file>")
    sys.exit()

convert(sys.argv[1], sys.argv[2])
