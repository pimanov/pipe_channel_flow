CC = mpif90
compile_flags = -Wall -Ofast
link_flags = -Wall

programs = pipe
subprograms = com fft8 lin pres prog3 prt rp rrt8 serv0 step bc_om add_nl visc
objects = $(addsuffix .o, $(subprograms))


all: $(addsuffix .out, $(programs))


%.out: %.o $(objects) 
	$(CC) $< $(objects) $(link_flags) -o $@


%.o: %.for
	$(CC) -c $< $(compile_flags) -o $@


clean: 
	rm -rf *.o *.out
