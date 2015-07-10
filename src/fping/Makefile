
PROG= ../../bin/fping
OBJS= fping.o
SRC= fping.c
BIN= /usr/local/bin
MAN= /usr/man/manl
MANSRC= fping.man
MANDST= fping.l

#
# Interval is the minimum amount of time between sending a ping packet to 
# any host.
#
# Timeout  is the minimum amount of time between sending a ping packet to
# a particular host.
#
# Retry is the number of ping packets to send to a host before giving up.
#

DEFAULTS= -DDEFAULT_INTERVAL=25  \
          -DDEFAULT_TIMEOUT=2500  \
          -DDEFAULT_RETRY=3
#
# some systems need the following:
#
#LIBS= -lsocket

LIBS=

all: $(PROG)

$(PROG) : $(OBJS)
	$(CC) $(OBJS) -o $(PROG) $(LIBS)

$(OBJS) : $(SRC)
	$(CC) $(CFLAGS) -c $(DEFAULTS) $(SRC)

# if you don't have install type:
# cp $(PROG) /usr/local/bin
# chown root /usr/local/bin/$(PROG)
# chmod 4555 /usr/local/bin/$(PROG)
# strip      /usr/local/bin/$(PROG)
#

install:
	install -c -m 4555 -o root -s $(PROG) $(BIN)/$(PROG)
	install -c -m 0444 -o root $(MANSRC) $(MAN)/$(MANDST)

clean:
	rm -f a.out core *~  *.o $(PROG)

shar:
	shar README CHANGES fping.c fping.man Makefile README.VMS > fping.shar
