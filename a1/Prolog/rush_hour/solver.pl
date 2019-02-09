:- [rush_hour/state].

solve_puzzle(Puzzle, Moves) :-
	puzzle_state(Puzzle,State),
	search([[State|[]]],[],Moves).



search([],_,[]) :-
	write("No solution found."),nl.
search(Prev,V,R) :-
	is_sol(Prev,R)
	;
	next(Prev,V,Next, NextV),
	search(Next,NextV,R).
is_sol([[S|M]|SMPS],R) :-
	state_is_solved(S),
	reverse(M,[],R);
	is_sol(SMPS,R).

next(PrevS,V,NextS,NextV) :-
	findall([S|M],moves(PrevS,S,M,V), NextS),
	visit(NextS,V,NextV).

moves(States,NewS,[NewMove|M],V) :-
	in(States, [S|M]),
	valid_pos(Pos),
	valid_offset(Offset),
	(	state_is_horizontal(S,Pos),
		horizontal_move(S,Pos,Offset,NewS);
		vertical_move(S,Pos,Offset,NewS)
	),
  \+ visited(NewS,V),
	%	length(V,L),
	%	write("Lengh of visited: "),write(L),nl,
	%write("Found New State: "),write(NewS),nl,nl,	
	
	pos_offset_move(Pos,Offset,NewMove).

valid_pos(P) :-
	valid_pos(0,P).
valid_pos(P,R) :-
	P < 64,
	(R is P;
	NP is P+1,
	valid_pos(NP,R)).

valid_offset(O) :-
	valid_offset(-4,O).
valid_offset(0,R) :- valid_offset(1,R).
valid_offset(O,R) :-
	O < 5,
	(R is O;
	NO is O+1,
	valid_offset(NO,R)).

%visited(S,[S|_]).
%visited(S,[_|VS]) :-
%	visited(S,VS).
%visited(S,S).
visited(S,L) :- member(S,L).

reverse([],R,R).
reverse([X|XS],L,R) :- reverse(XS,[X|L],R).

visit(SMPS,OldV,NextV) :- 
	strip_moves(SMPS,States),
	append(States,OldV,NextV).

strip_moves([],[]).
strip_moves([[S|_]|SMPS],[S|R]) :- strip_moves(SMPS,R).

in([[S|M]|_], [S|M]).
in([_|SMPS], S) :- in(SMPS,S).

