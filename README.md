# Subdivision Surface ASIC

Hardware implementation of the [loop subdivision surface algorithm](https://en.wikipedia.org/wiki/Loop_subdivision_surface). It operates on a closed, triangular input mesh and outputs a higher-polygon, smoothed, and modified resultant mesh.

## Features
- SPI input and output
- Modular RTL design
- DFFRAM macros and placement
- Low top-level pin count
- System-wide iverilog test bench

## I/O
The device takes one mesh at a time, performs the subdivion, then outputs the result before it's ready for the next mesh. Each input must be sent over SPI while the chip is not busy. The supported mesh format is a binary wavefront OBJ with only vertex and face data (8k max) as Q16.16.
<div align="center">
  <img width="512" alt="Binary OBJ format" src="https://github.com/user-attachments/assets/294c4dbf-7904-4260-a916-1699b793a884"/>
</div>

<br>
SPI transactions are in mode 3, with 32-bit data, and MSB first.

<div align="center">
  <img width="1024" alt="SPI send waveform" src="https://github.com/user-attachments/assets/b35e6144-ce1a-42a1-b65a-f877dcb207bc"/>
  <br>
  SPI send mesh procedure
</div>

<br>
<div align="center">
  <img width="1024" alt="SPI receive waveform" src="https://github.com/user-attachments/assets/aa54c984-a69b-4cad-b360-3540c6e3a0ed"/>
  <br>
  SPI receive mesh procedure
</div>

<br>
While the device is still busy, it will return 0xFFFFFFFF for every SPI transaction. Once it is complete, it will send the data size and output mesh data.

## Implementation
The algorithm is performed by three sequential modules: Subdiv, Neighbor, and Averager. They each access multiple RAM modules to store temporary data while processing.

<div align="center">
  <img width="768" alt="System architecture diagram" src="https://github.com/user-attachments/assets/bf8808bb-54e2-435e-bbc9-202705687c46"/>
</div>

### Subdiv
This module subdivides each triangle of the input mesh into 4 separate triangles. In order to pair triangles that share an edge, an edge to new vertex map is maintained in RAM 2.
```
# Define E as midpoint(AB)
#        F as midpoint(BC)
#        D as midpoint(CA)

Initialize map M = empty

For each face ABC in F:
    For edge e in {AB, BC, CA}:
        If e not in M:
            m = midpoint(e)
            M(e) = m
        Else:
            m = M(e)
        Write m to output mesh vertices
    Write AED, EBF, DFC, EDF to output mesh faces
```

### Neighbor
Neighbor creates an adjacency list of all of the mesh vertices and stores it in RAM. Averager requries this list in order to perform a weighted average of each vertex and its neighbors. The list is formatted as an array where each vertex is allotted 1 index for its neighbor count and 9 indices for its neighbors. The algorithm for assembling the list is as follows:
```
For each face F:
    Read Va, Vb, Vc
    For Va:
        Read neighbor count from neighbor list
        If Vb not in neighbor list:
            Write Vb to neighbor list
            Increment neighbor count
        If Vc not in neighbor list:
            Write Vc to neighbor list
            Increment neighbor count
    For Vb:
        Read neighbor count from neighbor list
        If Va not in neighbor list:
            Write Va to neighbor list
            Increment neighbor count
        If Vc not in neighbor list:
            Write Vc to neighbor list
            Increment neighbor count
    For Vc:
        Read neighbor count from neighbor list
        If Vb not in neighbor list:
            Write Vb to neighbor list
            Increment neighbor count
        If Vc not in neighbor list:
            Write Vc to neighbor list
            Increment neighbor count
```
This is implemented in a finite state machine in RTL.

### Averager
In this module, the final step of smoothing out all the vertices occurs. Using the adjacency matrix from Neighbor, Averager calculates a new set of X, Y, Z coordinates for each vertex and overwrites those values in RAM.
```
For each vert, V, in neighbor structure:
    Init sumX, sumY, sumZ to 0
    Read in neighbor count, C
    For each neighbor, N, in neighbors:
        sumX += NX / β
        sumY += NY / β
        sumZ += NZ / β
    sumX += VX(1 - Cβ) 
    sumY += VY(1 - Cβ) 
    sumZ += VZ(1 - Cβ) 
    Write sumX, sumY, sumZ to RAM
```
β can vary between implementations of the loop algorithm. It changes how much each vertex's position is influenced by its neighbors. Here, its value is 1/8.

## Testing
To run the test bench, first generate a valid OBJ hex file and place it in the testbench directory as `input.hex`. Object files cannot be too large; complexity of models should be similar to those seen in the Gallery below.

```
./tools/obj2hex.py tools/bird.obj tests/tb_top/input.hex
```
The above command refers to the `tb_top` test bench, which is an end-to-end testbench that uses an SPI master module to simulate sending/receiving the object data from the accerlator. The `tb_subsurf` testbench initializes memory modules with the object file and only tests the `subsurf` module without any I/O.

Run the testbench:
```sh
# Use Verilator
make tests
# Use Icarus Verilog
make itests

# View waveforms in gtkwave
gtkwave tests/tb_top/waveform.gtkw
gtkwave tests/tb_subsurf/waveform.gtkw
```

Then, convert `output.hex` into an OBJ file and import into something like Blender to see results!
```
./tools/hex2obj.py tests/tb_top/output.hex output.obj
```

## Running the Flow
To generate the GDSII, run:
```
make openlane
```

In its current state, the design is very large at 5000 by 6700 μm. This is due to the use of 12 `DFFRAM512x32` memory macros. Beware that the static timing analysis uses up to 50 GB of memory at a time. There are also persistent LVS errors, preventing full generation of the design.

## Gallery
<table>
  <tr>
    <td><img width="512" alt="Bird mesh input" src="https://github.com/user-attachments/assets/ea6552bf-ee37-4643-bfe0-06d1f7f0c1a0"/></td>
    <td><img width="512" alt="Bird mesh output" src="https://github.com/user-attachments/assets/fd23d7bb-3e67-4297-a016-6a9c8e6484b8"/></td>
  </tr>
  <tr>
    <td><img width="512" alt="Apple mesh input" src="https://github.com/user-attachments/assets/5408ea7a-cfbf-496f-8252-3047f0099aed"/></td>
    <td><img width="512" alt="Apple mesh output" src="https://github.com/user-attachments/assets/7354084f-9443-4b9b-9c38-5d95fc12ef09"/></td>
  </tr>
</table>
