%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% rush_hour_solve.pl
%
% Rush Hour puzzle solver
% (C) 2019 Norbert Zeh (nzeh@cs.dal.ca)
%
% Main program
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Import the solver code and the database of puzzles
:- [rush_hour/solver].
:- [rush_no_walls].


% Main predicate
main :-
  get_args(PuzzleNumber),
  load_puzzle(PuzzleNumber, Puzzle), !,
  solve_puzzle(Puzzle, Moves),
  format("~s~n", [Puzzle]),
  print_moves(Moves),
  halt.


% Get the puzzle number from the command line
get_args(PuzzleNumber) :-
  current_prolog_flag(argv, [PuzzleNumberStr]),
  string_int(PuzzleNumberStr, PuzzleNumber), !.

get_args(_) :-
  format("USAGE: rush_hour_solve.pl <puzzle number>~n"), !, fail.


% Convert a string into an integer
string_int(String, Int) :-
  atom_codes(String, Codes),
  phrase(int(Int), Codes).


% Deterministic clause grammar for an integer literal
int(X) -->
  digit(D),
  digits(Ds),
  { number_codes(X, [D|Ds]) }.

digits([D|Ds]) -->
  digit(D), !, digits(Ds).

digits([]) --> [].

digit(D) -->
  [D],
  { code_type(D, digit) }.


% Load the given puzzle from the database
load_puzzle(Number, Puzzle) :-
  puzzle(Number, _, Puzzle, _), !.

load_puzzle(_, []) :-
  num_puzzles(Total),
  format("ERROR: There are only ~d puzzles~n", [Total]),
  !, fail.


% Print the list of moves
print_moves([]).
print_moves([Move|Moves]) :-
  move_string(Move, String),
  format(String),
  print_moves(Moves).
