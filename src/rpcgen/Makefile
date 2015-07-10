#
# @(#)Makefile	2.1 88/08/01 4.0 RPCSRC
#
# Makefile for rpc protocol compiler
# Copyright (C) 1987, Sun Microsystems, Inc.
#
SRCS= rpc_main.c rpc_hout.c rpc_cout.c rpc_parse.c rpc_scan.c rpc_util.c \
	rpc_svcout.c rpc_clntout.c
HDRS= rpc_util.h rpc_parse.h rpc_scan.h
OBJS= rpc_main.o rpc_hout.o rpc_cout.o rpc_parse.o rpc_scan.o rpc_util.o \
	rpc_svcout.o rpc_clntout.o

GOAL=../../bin/rpcgen
CFLAGS = -O $(XFLAGS)

$(GOAL): $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o $@

lint: $(SRCS) $(HDRS)
	lint $(SRCS)

clean:
	rm -f $(GOAL) $(OBJS)

rpc_clntout.o: rpc_clntout.c
rpc_clntout.o: rpc_parse.h
rpc_clntout.o: rpc_util.h
rpc_cout.o: rpc_cout.c
rpc_cout.o: rpc_parse.h
rpc_cout.o: rpc_util.h
rpc_hout.o: rpc_hout.c
rpc_hout.o: rpc_parse.h
rpc_hout.o: rpc_util.h
rpc_main.o: rpc_main.c
rpc_main.o: rpc_parse.h
rpc_main.o: rpc_scan.h
rpc_main.o: rpc_util.h
rpc_parse.o: rpc_parse.c
rpc_parse.o: rpc_parse.h
rpc_parse.o: rpc_scan.h
rpc_parse.o: rpc_util.h
rpc_scan.o: rpc_scan.c
rpc_scan.o: rpc_scan.h
rpc_scan.o: rpc_util.h
rpc_svcout.o: rpc_parse.h
rpc_svcout.o: rpc_svcout.c
rpc_svcout.o: rpc_util.h
rpc_util.o: rpc_parse.h
rpc_util.o: rpc_scan.h
rpc_util.o: rpc_util.c
rpc_util.o: rpc_util.h
