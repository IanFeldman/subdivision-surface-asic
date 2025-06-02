SIM-RTL-128:
	iverilog -o ram128-rtl.vvp -s DFFRAM128x32_tb -DFUNCTIONAL -DUNIT_DELAY=#1 DFFRAM128x32_tb.v ../../hdl/rtl/DFFRAM128x32.v ../../hdl/rtl/DFFRAM.v sky130_fd_sc_hd.v primitives.v
	./ram128-rtl.vvp

SIM-GL-128:
	iverilog -o ram128-gl.vvp -s DFFRAM128x32_tb -DFUNCTIONAL -DUSE_POWER_PINS -DUNIT_DELAY=#1  ../../hdl/gl/DFFRAM128x32.v sky130_fd_sc_hd.v  primitives.v DFFRAM128x32_tb.v
	./ram128-gl.vvp

SIM-RTL-256:
	iverilog -o ram256-rtl.vvp -DFUNCTIONAL -DUNIT_DELAY=#1 DFFRAM256x32_tb.v ../../hdl/rtl/DFFRAM256x32.v ../../hdl/rtl/DFFRAM.v sky130_fd_sc_hd.v primitives.v
	./ram256-rtl.vvp

SIM-GL-256:
	iverilog -o ram256-gl.vvp -s DFFRAM256x32_tb -DFUNCTIONAL -DUSE_POWER_PINS -DUNIT_DELAY=#1  ../../hdl/gl/DFFRAM256x32.v sky130_fd_sc_hd.v  primitives.v DFFRAM256x32_tb.v
	./ram256-gl.vvp

SIM-RTL-512:
	iverilog -o ram512-rtl.vvp -DFUNCTIONAL -DUNIT_DELAY=#1 DFFRAM512x32_tb.v ../../hdl/rtl/DFFRAM512x32.v ../../hdl/rtl/DFFRAM.v sky130_fd_sc_hd.v primitives.v
	./ram512-rtl.vvp

SIM-GL-512:
	iverilog -o ram512-gl.vvp -s DFFRAM512x32_tb -DFUNCTIONAL -DUSE_POWER_PINS -DUNIT_DELAY=#1  ../../hdl/gl/DFFRAM512x32.v sky130_fd_sc_hd.v  primitives.v DFFRAM512x32_tb.v
	./ram512-gl.vvp