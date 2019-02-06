%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% rush_hour/solver.pl
%
% Rush Hour puzzle solver
% (C) 2019 Norbert Zeh (nzeh@cs.dal.ca)
%
% The solver logic
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Import the state predicates
:- [rush_hour/state].


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% IMPLEMENT THE FOLLOWING PREDICATE
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Solve the puzzle
%solve_puzzle(Puzzle, Moves).

solve_puzzle(Puzzle, Moves) :-
	puzzle_state(Puzzle,State),
	next_state([],[[State]],Moves).

next_state(_,N,M) :-
	solution(N,M).
next_state(N,M) :- 
	visited(V),
	write("Visited: "),write(V),nl,
	write("Neighbors: "),write(N),nl,
	newly_visited(N),
	new_neighbors(N,[],NewN),
	filter_neighbors(NewN,FN),
	next_state(FN,M).

solution([[S,M]|SMPS],R) :-
	state_is_solved(S), 
	write("Found Sol: "), write([S,M]),nl,
	R is M;
	solution(SMPS,R).

new_neighbors([],L,L). %end case, got Neighbors for All S, P, O.
new_neighbors([SMP|SMPS],L,R) :-
	moves(SMP,0,L,NL), % get states from this state
	new_neighbors(SMPS,NL,R). % recursive tail call.


moves(_,65,M,M). % base case, checked all O for all P for this S.
moves([S|SS],P,M,R) :-
	state_is_end(S,P),
	%write("Checking moves for [S,P]: "), write([S,P]),nl,
	offsets([S|SS],P,-4,M,NewM),% keep building list of moves
	NewP is P+1, 
	moves([S|SS],NewP,NewM,R); % recursive tail call
	NewP is P+1,
	moves([S|SS],NewP,M,R). % not a movable peice at pos, try next one.

offsets(_,_,5,M,M). %base case, checked all O for this S and P.
offsets(SMP,P,0,M,R) :- offsets(SMP,P,1,M,R). %skip 1
offsets([S|SS],P,O,M,R) :- % general case.
	horizontal_move(S,P,O,NS), % if its an horizontal end state movable by O.
	pos_offset_move(P,O,Move),
	%write("New Move: "),write([NS,Move]),nl,
	NewM = [[NS,Move|SS]|M], %Keep building list of moves.
	NewO is O+1,
	offsets([S|SS],P,NewO,NewM,R)%recursive tail call.
	; 
	vertical_move(S,P,O,NS),
	pos_offset_move(P,O,Move),
	%write("New Move: "),write([NS,Move]),nl,
	NewM = [[NS,Move|SS]|M], %Keep building list of moves.
	NewO is O+1,
	offsets([S|SS],P,NewO,NewM,R)%recursive tail call.
	;
	NewO is O+1,
	offsets([S|SS],P,NewO,M,R).%not a valid move, try next one.

newly_visited([[S|_]:SMPS]) :- % should try a more efficient data structure
	visited(S),
	newly_visited(SMPS).

filter_neighbors(N,R) :- 
	exclude(visited,N,R).


	
