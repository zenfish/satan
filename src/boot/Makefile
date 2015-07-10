SHELL	= /bin/sh
BIN	= ../../bin
OBJECTS	= boot.o bootparam_prot_xdr.o
CFLAGS	= -I. -O $(XFLAGS)
XFLAGS	= -DAUTH_GID_T=int
RPCGEN	= rpcgen
#LIBS	= -lsocket -lnsl

$(BIN)/boot: $(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $(OBJECTS) $(LIBS)

bootparam_prot.h bootparam_prot_xdr.c: bootparam_prot.x
	$(RPCGEN) bootparam_prot.x 2>/dev/null

$(OBJECTS): bootparam_prot.h

clean:
	rm -f *.o $(BIN)/boot bootparam_prot*.[hc]
