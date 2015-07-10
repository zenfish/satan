#ifdef __STDC__
#define ARGS(x) x
#else
#define ARGS(x) ()
#endif

/* mallocs.c */
extern char *mymalloc();
extern char *myrealloc();
extern char *dupstr();

/* find_addr.c */
extern struct in_addr find_addr();
extern int find_port();

/* error.c */
extern void remark ARGS((char *,...));
extern void error ARGS((char *,...));
extern void panic ARGS((char *,...));
extern char *progname;

/* print_data.c */
extern void print_data();

/* ring.c */
typedef struct RING {
    struct RING *succ;                 /* successor */
    struct RING *pred;                 /* predecessor */
} RING;
extern void ring_init ARGS((RING *));
extern void ring_prepend ARGS((RING *, RING *));
extern void ring_append ARGS((RING *, RING *));
extern void ring_detach ARGS((RING *));
#define ring_succ(c) ((c)->succ)
#define ring_pred(c) ((c)->pred)
