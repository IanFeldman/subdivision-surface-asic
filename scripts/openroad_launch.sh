printf "\
read_db `find runs/recent/final/odb/*`
read_lib  $PDKPATH/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__ss_100C_1v60.lib
read_sdc  `find runs/recent/final/sdc/*`
gui::show \n"