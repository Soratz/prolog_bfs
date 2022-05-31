% Graph data is saved as Relation(Entity1, Relation, Entity2), there can be more than one relation between entities.
% Baslat reads the inputs from the user and tries to find paths between entities A, B, C.
% It find the shortest path by BFS algorithm and prints it.
start_app :-
    clean2, clean3,
    write('Inputs: '), nl,
    write('Entity 1: '), nl,
    read(Entity1), entity_check(Entity1),
    write('Entity 2: '), nl,
    read(Entity2), entity_check(Entity2),
    write('Entity 3: '), nl,
    read(Entity3), entity_check(Entity3),
    write('Enter relations you include: '), nl,
    write('Example input: [relation1, relation2].'), nl,
    write('Enter "all" to search with all relations'), nl,
    read(Relations), nl, relation_check(Relations),
    write('Finding the path...'),
    % There are 6 possible paths: (a,b,c), (a,c,b), (b,a,c), (b,c,a), (c,a,b), (c,b,a) 
    % We search for each possible path due to selecting an start point and end point
    % After finding 6 paths with using BFS, we choose the shortest.. .
    start(Entity1, Entity2, Entity3, Relations),
    start(Entity1, Entity3, Entity2, Relations),
    start(Entity2, Entity1, Entity3, Relations),
    start(Entity2, Entity3, Entity1, Relations),
    start(Entity3, Entity1, Entity2, Relations),
    start(Entity3, Entity2, Entity1, Relations), nl,
    getshortest,
    shorter(Length, Path, RelationList),
    % If it takes too long to find a path ten we cancel the operation.
    % The parameter might change for different datas.
    ((Length >= 12000) -> write('It took too long so application timed out.'), nl ;
    write('Shortest path that found: '), nl,
    write2(Path, RelationList), nl,
    write('Length: '), write(Length), nl).

% Checks if the given entity is available
entity_check(Entity) :-
    relation(Entity, _, _), !.

entity_check(_) :-
    write('There is no such entity for any relation.'), nl, fail.

% Checks if the given relation is available
relation_check(X) :- atom(X).
relation_check([]).
relation_check([Relation | RelationList]) :- relation_check2(Relation), relation_check(RelationList).

relation_check2(Relation) :-
    relation(_, Relation, _), !.

relation_check2(Relation) :-
    write('There is no such relation in the graph: '), write(Relation), nl, fail.


% Countlist, to find list length.
countlist([], 0).
countlist([H|T], N) :- countlist(T, N2), N is N2 + 1.

% Writelist, to print a list. Generally used for debug purposes.
writelist([]).
writelist([H|T]) :- write(H), write(' '), writelist(T).

% Declaring dynamic definitions of Facts to handle them during runtime.
:-dynamic target/1.
:-dynamic queue/3.
:-dynamic result/3.
:-dynamic shorter/3.
:-dynamic temp/1.

% Write2 and Write3, used to print the shortest path in a user-friendly manner.
write2([], []).
write2(_, []).
write2([P1, P2|PT], [I|IT]) :- write2([P2|PT], IT), write(P2), write(' - '), write(I), write(' - '), write(P1), nl.

write3([LastP|PT], [LastI|IT]) :- target(Target), write2([LastP|PT], IT), write(LastP), write(' - '), write(LastI), write(' - '), write(Target), nl.

% Member, checks if any given element is a member of the given list.
member(X, [X | []]).
member(X, [X | L]) :- !.
member(X, [Y | L]) :- member(X, L).

% Storelist, stores a list as definition by using dynamic Fact temp.
% This approach is used to perform stack operations in ProLog language.
storelist([]).
storelist([H | List]) :- asserta(temp(H)), storelist(List).

% Merges two lists.
mergelist(Templist, NewList) :- ((retract(temp(X))) -> mergelist([X|Templist], NewList) ; NewList = Templist).
mergelist(List1, List2, NewList) :- clean4, storelist(List2), storelist(List1), !, mergelist([], NewList).

% Rules that start with "clean" are used to clean previously defined dynamic Facts and relations.

clean4 :-
    retract(temp(_)), fail.

clean4. % this part is to return true as as result of the query.

clean3 :-
    retract(shorter(_, _, _)), fail.

clean3. 

clean2 :-
    retract(result(_, _, _)), fail.

clean2. 

clean :-
    retract(queue(_, _, _)), fail.

clean :-
    retract(target(_)), fail.

clean. 

% asserter, adds all to ather entities, that are connected to given entity, to a queue data. 
% Queue data structure is handled by dynamic Fact generating.
% By using this queue we perform BFS algorithm.
asserter(X, From, IList, GivenRelations) :-
    relation(X, Relation, Y),
    ((GivenRelations \= 'all') -> member(Relation, GivenRelations) ; true),
    (not(queue(Y, _, _)) -> assert(queue(Y, [X|From], [Relation|IList]))), fail.
    
asserter(_, _, _, _). % this part is to return true as as result of the query.

% Start, finds a path between X and Z which includes Y in somewhere between the path. 
% This is the start point of the BFS algorithm.
% There are 6 possible paths which includes XYZ: 
% (X, Y, Z), (X, Z, Y), (Z, Y, X), (Z, X, Y), (Y, X, Z), (Y, Z, X)
% By using start 6 times, we find 6 different paths.
% At the end of the program, the shortest path is returned.
start(X, Y, Z, GivenRelations) :-
    clean,
    assert(queue(X, [], [])),
    write('.'),
    search(Y, N1, GivenRelations, Path1, IList1, 0), % X'den Y'ye yol aranır.
    clean,
    assert(queue(Y, [], [])),
    write('.'),
    search(Z, N2, GivenRelations, Path2, IList2, N1), % Y'den Z'ye yol aranır.
    assert(target(Z)),
    mergelist(Path1, Path2, FinalPath), % En son yollar birleştirilip X -> Y -> Z yolu bulunur.
    mergelist(IList1, IList2, FinalIList),
    Length is N1 + N2, % yol uzunluğu
    assert(result(Length, [Z|FinalPath], FinalIList)), % Diğer sonuçlarla karşılaştırmak için sonuç kaydedilir.
    % write3(FinalPath, FinalIList),
    clean.

% When finding a path takes too much time. We should stop the search.
% This is useful when the graph is too big and not sparsed.
% The value 12000 should be increased to find paths that are longer.
search(_, Length, _, _, _, Counter) :- % yol bulamazsa diye
    Counter > 12000, write('..'), Length = 12000.

% Search, represents the BFS algorithm. Adds an entity to queue and if its target entity, it stops searching.
% Until finding the target, it removes an entity from the queue and add all of its neighbours to queue.
search(Target, Length, GivenRelations, Path, IList, Counter) :-
    retract(queue(X, From, RelationList)),
    ((X \= Target) -> asserter(X, From, RelationList, GivenRelations), Cnt2 is Counter + 1, search(Target, Length, GivenRelations, Path, IList, Cnt2) ; Path = From, IList = RelationList, countlist(From, Length)). 

% getshortest, find the shortest path between the six paths.
getshortest :-
    result(X, Path, IList), asserta(shorter(X, Path, IList)), !, getshortest2.

getshortest2 :-
    result(X, Path, IList), retract(shorter(Y, SP, SI)), ((X =< Y) -> asserta(shorter(X, Path, IList)) ; true, asserta(shorter(Y, SP, SI))), fail.

getshortest2.