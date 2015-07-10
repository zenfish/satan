SHELL	= /bin/sh
BIN	= ../../bin
OBJECTS	= nfs-chk.o nfs_prot_clnt.o nfs_prot_xdr.o mount_clnt.o mount_xdr.o
MAKES	= nfs_prot.h nfs_prot_clnt.c nfs_prot_svc.c nfs_prot_xdr.c mount.h \
	mount_clnt.c mount_svc.c mount_xdr.c
PROG	= $(BIN)/nfs-chk
CFLAGS	= -O -I. $(XFLAGS)
XFLAGS	= -DAUTH_GID_T=int
RPCGEN	= rpcgen
#LIBS	= -lsocket -lnsl

$(PROG):$(OBJECTS)
	$(CC) $(CFLAGS) -o $@ $(OBJECTS) $(LIBS)

nfs_prot.h nfs_prot_clnt.c nfs_prot_xdr.c: nfs_prot.x
	$(RPCGEN) $? 2>/dev/null

nfs_prot.x:
	cp /usr/include/rpcsvc/nfs_prot.x .

mount.h mount_clnt.c mount_xdr.c: mount.x
	$(RPCGEN) $? 2>/dev/null

mount.x:
	cp /usr/include/rpcsvc/mount.x .

clean:
	rm -f $(PROG) *.o core $(MAKES)

nfs-chk.o: mount.h nfs_prot.h
