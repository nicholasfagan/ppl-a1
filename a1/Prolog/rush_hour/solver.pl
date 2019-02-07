:- [rush_hour/state].

solve_puzzle(Puzzle, Moves) :-
	puzzle_state(Puzzle,State),
	search([State|[]],[],Moves).

search([S|M], _, R) :-
	state_is_solved(S),
	reverse(M,[],R).
search([S|M],V,R) :-
	next([S|M],V,[NS,NM|M]),
	search([NS,NM|M],[S|V], R).

next([S|M], V, [NS,NM|M]) :-
	valid_pos(S,0,Pos),
	valid_offset(-4,Offset),
	(horizontal_move(S,Pos,Offset,NS);
		vertical_move(S,Pos,Offset,NS)),
	\+ visited(NS, V),
	pos_offset_move(Pos,Offset,NM).

visited(S,[S|_]).
visited(S,[_|VS]) :-
	visited(S,VS).
visited(S,S).


valid_pos(S,P,R) :-
	state_is_end(S,P),
	R is P.
valid_pos(S,P,R) :-
	NP is P+1,
	NP < 64,
	valid_pos(S,NP,R).

valid_offset(O,R) :-
	O \= 0,
	O < 5,
	R is O.
valid_offset(O,R) :-
	NO is O+1,
	NO < 5,
	valid_offset(NO,R).


reverse([],R,R).
reverse([X|XS],L,R) :- reverse(XS,[X|L],R).
