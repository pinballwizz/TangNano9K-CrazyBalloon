copy /b cl01.bin + cl02.bin + cl03.bin + cl04.bin + cl05.bin + cl06.bin crballoon_cpu.bin
make_vhdl_prom crballoon_cpu.bin crballoon_cpu.vhd

make_vhdl_prom cl07.bin gfx_1.vhd
make_vhdl_prom cl08.bin gfx_2.vhd

pause