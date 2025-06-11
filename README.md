# subdivision-surface-asic

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

### Neighbor

### Average

## Testing

## Gallery
