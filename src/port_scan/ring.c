 /*
  * ring_init(), ring_append(), ring_prepend(), ring_detach(), ring_succ(),
  * ring_pred() - circular list management utilities.
  * 
  * Author: Wietse Venema.
  */

#include "lib.h"

/* ring_init - initialize ring head */

void    ring_init(ring)
RING   *ring;
{
    ring->pred = ring->succ = ring;
}

/* ring_append - insert entry after ring head */

void    ring_append(ring, entry)
RING   *ring;
RING   *entry;
{
    entry->succ = ring->succ;
    entry->pred = ring;
    ring->succ->pred = entry;
    ring->succ = entry;
}

/* ring_prepend - insert new entry before ring head */

void    ring_prepend(ring, entry)
RING   *ring;
RING   *entry;
{
    entry->pred = ring->pred;
    entry->succ = ring;
    ring->pred->succ = entry;
    ring->pred = entry;
}

/* ring_detach - remove entry from ring */

void    ring_detach(entry)
RING   *entry;
{
    register RING *succ = entry->succ;
    register RING *pred = entry->pred;

    pred->succ = succ;
    succ->pred = pred;
}
