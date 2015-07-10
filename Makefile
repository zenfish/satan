SHELL	= /bin/sh
MAKE	= make
RPCGEN	= rpcgen
#LIBS	= -lsocket -lnsl

what:
	@echo "Usage: make system-type. Known types are:"
	@echo "aix osf bsd bsdi dgux irix4 irix5 freebsd hpux9 linux sunos4 sunos5 sysv4"
	@exit 1;

aix osf bsd hpux9 sunos4:
	@$(MAKE) all LIBS= XFLAGS="-DAUTH_GID_T=int"

ultrix4:
	@$(MAKE) rpcgen all LIBS= XFLAGS="-DAUTH_GID_T=int" \
		RPCGEN="../../bin/rpcgen"

bsdi:
	@$(MAKE) all LIBS="-lrpc" XFLAGS="-DAUTH_GID_T=int"

freebsd:
	@$(MAKE) all LIBS= XFLAGS="-DAUTH_GID_T=int -DSYS_ERRLIST_DECLARED"

linux:
	@echo The LINUX rules are untested and may be wrong
	@set +e; test -f include/netinet/ip.h || {\
		echo Please copy the 44BSD /usr/include/netinet include files; \
		echo files to `pwd`/include/netinet and try again.;\
		exit 1; \
	}
	@$(MAKE) all LIBS= XFLAGS="-I`pwd`/include -DAUTH_GID_T=int"

irix4:
	@$(MAKE) all LIBS="-lXm_s -lXt_s -lX11_s -lPW -lc_s -lsun" \
		XFLAGS="-DAUTH_GID_T=int"

irix5:
	@$(MAKE) all LIBS= XFLAGS="-DAUTH_GID_T=gid_t"

dgux:
	@$(MAKE) all LIBS="-lnsl" XFLAGS="-DAUTH_GID_T=gid_t -DTIRPC"

sunos5:
	@$(MAKE) all LIBS="-lsocket -lnsl" XFLAGS="-DAUTH_GID_T=gid_t -DTIRPC"

sysv4:
	@$(MAKE) rpcgen all LIBS="-lsocket -lnsl" \
		XFLAGS="-DAUTH_GID_T=gid_t -DTIRPC" \
		RPCGEN="../../bin/rpcgen"

rpcgen:
	cd src/rpcgen; $(MAKE) "LIBS=$(LIBS)" "XFLAGS=$(XFLAGS)"

all:
	cd src/misc; $(MAKE) "LIBS=$(LIBS)" "XFLAGS=$(XFLAGS)" "RPCGEN=$(RPCGEN)"
	cd src/boot; $(MAKE) "LIBS=$(LIBS)" "XFLAGS=$(XFLAGS)" "RPCGEN=$(RPCGEN)"
	cd src/port_scan; $(MAKE) "LIBS=$(LIBS)" "XFLAGS=$(XFLAGS)"
	cd src/nfs-chk; $(MAKE) "LIBS=$(LIBS)" "XFLAGS=$(XFLAGS)" "RPCGEN=$(RPCGEN)"
	cd src/yp-chk; $(MAKE) "LIBS=$(LIBS)" "XFLAGS=$(XFLAGS)" "RPCGEN=$(RPCGEN)"
	cd src/fping; $(MAKE) "LIBS=$(LIBS)" "CFLAGS=$(XFLAGS)"

checksums:
	@find * -type f -print | sort | xargs md5

clean: 
	cd src/misc; $(MAKE) clean
	cd src/boot; $(MAKE) clean
	cd src/port_scan; $(MAKE) clean
	cd src/nfs-chk; $(MAKE) clean
	cd src/yp-chk; $(MAKE) clean
	cd src/fping; $(MAKE) clean
	cd src/rpcgen; $(MAKE) clean
	rm -f html/satan.html html/satan_documentation.html status_file \
	bit_bucket

tidy:	clean
	rm -f *.old *.bak *.orig */*.old */*.bak */*.orig tmp_file*
	rm -rf results
	chmod -x satan
