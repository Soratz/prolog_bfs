# prolog_bfs
Breadth-first search algorithm to search on a entity-relationship graph.

The graph data structure is implemented as knowledge base by using Prologs facts.
The BFS algorithm is developed and tested on SWI-Prolog.

An example of knowledge base facts:

```
relation('Human', 'drive', 'Car').
relation('Car', 'include', 'Door').
relation('Car', 'include', 'Seat').
relation('Human', 'eat', 'vegatable').
relation('Human', 'eat', 'fruit').
```

After loading the knowledge base and bfs_algorithm.pl, by querying "start_app" the program can be started.
