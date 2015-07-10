SHELL	= /bin/sh
BIN	= ../../bin
TCP_SRC	= tcp_scan.c find_addr.c mallocs.c non_blocking.c \
		print_data.c open_limit.c error.c strerror.c
TCP_OBJ	= tcp_scan.o find_addr.o mallocs.o non_blocking.o \
		print_data.o open_limit.o error.o strerror.o
UDP_SRC	= udp_scan.c find_addr.c mallocs.c open_limit.c error.c ring.c \
		strerror.c
UDP_OBJ	= udp_scan.o find_addr.o mallocs.o open_limit.o error.o ring.o \
		strerror.o
CFLAGS	= -O $(XFLAGS)
FILES	= README tcp_scan.1 error.c find_addr.c lib.h makefile mallocs.c \
	non_blocking.c open_limit.c print_data.c tcp_scan.c udp_scan.c ring.c \
	strerror.o
PROGS	= $(BIN)/tcp_scan $(BIN)/udp_scan
#LIBS	= -lsocket -lnsl

all: $(PROGS)

$(BIN)/tcp_scan: $(TCP_OBJ)
	$(CC) $(CFLAGS) -o $@ $(TCP_OBJ) $(LIBS)

$(BIN)/udp_scan: $(UDP_OBJ)
	$(CC) $(CFLAGS) -o $@ $(UDP_OBJ) $(LIBS)

shar:
	@shar $(FILES)

lint:
	lint $(TCP_SRC)
	lint $(UDP_SRC)

clean:
	rm -f *.o $(PROGS) core
