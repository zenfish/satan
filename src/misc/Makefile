SHELL	= /bin/sh
BIN	= ../../bin
PROGS	= $(BIN)/md5 $(BIN)/sys_socket $(BIN)/timeout $(BIN)/rcmd \
	$(BIN)/safe_finger $(BIN)/rex 
CFLAGS	= -O -I. $(XFLAGS)
XFLAGS	= -DAUTH_GID_T=int
RPCGEN	= rpcgen
#LIBS	= -lsocket -lnsl

all:	$(PROGS)

$(BIN)/timeout: timeout.c
	$(CC) $(CFLAGS) -o $@ $?

$(BIN)/rex: rex.o rex_xdr.o
	$(CC) $(CFLAGS) -o $@ rex.o rex_xdr.o $(LIBS)

$(BIN)/md5: md5.o md5c.o
	$(CC) $(CFLAGS) -o $@ md5.o md5c.o

$(BIN)/rcmd: rcmd.c
	$(CC) $(CFLAGS) -o $@ $? $(LIBS)

$(BIN)/sys_socket: sys_socket.c
	$(CC) $(CFLAGS) -o $@ $?

$(BIN)/safe_finger: safe_finger.c
	$(CC) $(CFLAGS) -o $@ $?

rex.h rex_xdr.c: rex.x
	$(RPCGEN) rex.x 2>/dev/null

rex.o rex_xdr.o: rex.h

clean:
	rm -f $(PROGS) *.o core rex_svc.c rex_clnt.c rex.h rex_xdr.c
