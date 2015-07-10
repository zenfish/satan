SHELL	= /bin/sh
BIN	= ../../bin
OBJECTS	= yp-chk.o yp_clnt.o yp_xdr.o 
MAKES	= yp.h yp_clnt.c yp_svc.c yp_xdr.c
PROG	= $(BIN)/yp-chk
CFLAGS	= -O -I. $(XFLAGS)
XFLAGS	= -DAUTH_GID_T=int
RPCGEN	= rpcgen
#LIBS	= -lsocket -lnsl

$(PROG):$(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $(OBJECTS) $(LIBS)

yp.h yp_clnt.c yp_xdr.c: yp.x
	$(RPCGEN) $? 2>/dev/null

clean:
	rm -f $(PROG) *.o core $(MAKES)

yp-chk.o: yp.h
