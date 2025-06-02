#!/usr/bin/env python

import sys

def f2q(n):
    return int(n * (1 << 16)).to_bytes(4, signed=True)

def convert(filename, outfile):
    verts = 0
    faces = 0
    vbytes = bytearray()
    fbytes = bytearray()

    with open(filename) as f:
        for line in f:
            if line[0] == "v":
                values = line.strip().split(" ")
                for coord in values[1:]:
                    vbytes.extend(f2q(float(coord)))
                verts += 1

            if line[0] == "f":
                values = line.strip().split(" ")
                for index in values[1:]:
                    fbytes.extend(int(index).to_bytes(4))
                faces += 1

    with open(outfile, "wb") as of:
        of.write(verts.to_bytes(4))
        of.write(vbytes)
        of.write(faces.to_bytes(4))
        of.write(fbytes)


if len(sys.argv) != 3:
    print("Usage: " + sys.argv[0] + " <obj file> <new bin file>")
    sys.exit()

convert(sys.argv[1], sys.argv[2])
