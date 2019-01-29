%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% rush_hour/state.pl
%
% Rush Hour puzzle solver
% (C) 2019 Norbert Zeh (nzeh@cs.dal.ca)
%
% Predicates to manipulate board states
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Translate a string description of the puzzle into a list of 4 64-bit integers
% encoding which grid cells are occupied, by horizontal pieces, by vertical
% pieces, and by the rightmost cell of a horizontal piece or the bottommost
% cell of a vertical piece.
puzzle_state(Puzzle, State) :-
  puzzle_grid(Puzzle, Grid),
  grid_state(Grid, State).


% Pad a 36-character description of a board into an 8x8 grid of characters that
% includes empty cells where the walls are.
puzzle_grid(Puzzle, Grid) :-
  string_chars(Puzzle, Chars),
  string_chars(oooooooo, EmptyRow),
  Rows = [_ ,_ ,_ ,_ ,_ ,_],
  chars_rows(Chars, Rows),
  append([[EmptyRow], Rows, [EmptyRow]], Grid).


% Unpack the rows of the a grid from the 36-character representation
chars_rows([], []).

chars_rows([A, B, C, D, E, F | Rest], [[o, A, B, C, D, E, F, o] | Rows]) :-
  chars_rows(Rest, Rows).


% Transpose a grid
grid_transposed([], [[], [], [], [], [], [], [], []]).

grid_transposed([Row|Rows], Transposed) :-
  grid_transposed(Rows, Cols),
  maplist(list_head_tail, Transposed, Row, Cols).


% True if the second and third arguments are the head and tail of the first
% argument.
list_head_tail([X|Xs], X, Xs).


% Translate an 8x8 grid into a state object
grid_state(Grid, [Occupied, Horiz, Vert, Ends]) :-
  grid_transposed(Grid, Transposed),
  grid_horiz_ends(Grid, Horiz, HorizEnds),
  grid_horiz_ends(Transposed, VertTransposed, VertEndsTransposed),
  bits_transposed(VertTransposed, Vert),
  bits_transposed(VertEndsTransposed, VertEnds),
  Occupied is Horiz \/ Vert,
  Ends is HorizEnds \/ VertEnds.


% Rearrange the bits in a 64-bit string to model transposition of an 8x8 bit
% matrix.
bits_transposed(Bits, Transposed) :-
  T0 is (Bits xor (Bits << 7)) /\ 0x5500550055005500,
  B1 is Bits xor T0 xor (T0 >> 7),
  T1 is (B1 xor (B1 << 14)) /\ 0x3333000033330000,
  B2 is B1 xor T1 xor (T1 >> 14),
  T2 is (B2 xor (B2 << 28)) /\ 0x0f0f0f0f00000000,
  Transposed is B2 xor T2 xor (T2 >> 28).


% Locate all horizontal pieces in a grid and construct two 64-bit numbers that
% represent the cells occupied by these pieces and their rightmost cells.
grid_horiz_ends(Grid, Horiz, Ends) :-
  append(Grid, Cells),
  accumulate_horiz_ends(o, Cells, 0xff000000000000ff, 0, 1, Horiz, Ends).


% Inspect the cells in a list one by one to construct the corresponding bit
% vectors.
accumulate_horiz_ends(_, [], Bits, Ends, _, Bits, Ends) :- !.

accumulate_horiz_ends(_, [o|Xs], BitsIn, EndsIn, PosIn, BitsOut, EndsOut) :-
  PosN is PosIn << 1, !,
  accumulate_horiz_ends(o, Xs, BitsIn, EndsIn, PosN, BitsOut, EndsOut).

accumulate_horiz_ends(_, [X,X|Xs], BitsIn, EndsIn, PosIn, BitsOut, EndsOut) :-
  PosN is PosIn << 1,
  BitsN is BitsIn \/ PosIn, !,
  accumulate_horiz_ends(X, [X|Xs], BitsN, EndsIn, PosN, BitsOut, EndsOut).

accumulate_horiz_ends(X, [X|Xs], BitsIn, EndsIn, PosIn, BitsOut, EndsOut) :-
  PosN is PosIn << 1,
  BitsN is BitsIn \/ PosIn,
  EndsN is EndsIn \/ PosIn, !,
  accumulate_horiz_ends(X, Xs, BitsN, EndsN, PosN, BitsOut, EndsOut).

accumulate_horiz_ends(_, [X|Xs], BitsIn, EndsIn, PosIn, BitsOut, EndsOut) :-
  PosN is PosIn << 1, !,
  accumulate_horiz_ends(X, Xs, BitsIn, EndsIn, PosN, BitsOut, EndsOut).


% Check whether the given state is solved
state_is_solved(State) :-
  state_is_horizontal(State, 30).


% Check whether the Posth grid cell is occupied
state_is_ocupied([Occupied, _, _, _], Pos) :-
  state_bit_is_set(Occupied, Pos).


% Check whether the Posth grid cell is occupied by a horizontal piece
state_is_horizontal([_, Horiz, _, _], Pos) :-
  state_bit_is_set(Horiz, Pos).


% Check whether the Posth grid cell is occupied by a vertical piece
state_is_vertical([_, _, Vert, _], Pos) :-
  state_bit_is_set(Vert, Pos).


% Check whether the Posth grid cell is the rightmost cell of a horizontal piece
% or the bottommost cell of a vertical piece
state_is_end([_, _, _, Ends], Pos) :-
  state_bit_is_set(Ends, Pos).


% Check that the Posth bit in Bits is set
state_bit_is_set(Bits, Pos) :-
  Bit is Bits /\ (1 << Pos),
  Bit \= 0.


% Given a state, a position, and an offset, the predicate is true if and only
% if position Pos is the rightmost cell of a horizontal piece, this piece can
% be moved horizontally by Offset positions, and NewState is the resulting
% state.  Should be used as a function to compute NewState from State, Pos, and
% Offset by passing a variable for NewState.
horizontal_move(State, Pos, Offset, NewState) :-
  state_is_end(State, Pos), state_is_horizontal(State, Pos),
  State = [Occupied, _, Vert, Ends],
  Stop is Occupied
       /\ (Vert xor 0xffffffffffffffff)
       /\ (Ends xor 0xffffffffffffffff),
  move(State, Pos, Offset, Stop, 1, 0xffffffffffffffff, NewState).


% Given a state, a position, and an offset, the predicate is true if and only
% if position Pos is the bottommost cell of a vertical piece, this piece can be
% moved vertical by Offset positions, and NewState is the resulting state.
% Should be used as a function to compute NewState from State, Pos, and Offset
% by passing a variable for NewState.
vertical_move(State, Pos, Offset, NewState) :-
  state_is_end(State, Pos), state_is_vertical(State, Pos),
  State = [Occupied, Horiz, _, Ends],
  Stop is Occupied
       /\ (Horiz xor 0xffffffffffffffff)
       /\ (Ends xor 0xffffffffffffffff),
  move(State, Pos, Offset, Stop, 8, 0x0101010101010101, NewState).


% The actual worker predicate used to implement horizontal_move and
% vertical_move.
move([Occupied, Horiz, Vert, Ends],
     Pos, Offset, Stop, Skip, Mask,
     [NewOccupied, NewHoriz, NewVert, NewEnds]) :-

  % Locate the piece and calculate its new position
  find_piece(Stop, Pos, Skip, Piece),
  NewPiece is Piece << (Offset * Skip),
  NewPos is Pos + (Offset * Skip),

  % Any position outside the range 9-54 is outside the board and is not
  % permissible, so the predicate fails.
  NewPos >= 9, NewPos =< 54,

  % Figure out the swath of positions over which the piece moves from its old
  % to its new position
  Left is min(Piece, NewPiece),
  Right is max(Piece, NewPiece),
  LeftPos is min(Pos, NewPos),
  RightPos is max(Pos, NewPos),
  LeftMask is Left \/ (Mask << LeftPos),
  RightMask is Right \/ (Mask >> (64 - RightPos - Skip)),
  Swath is LeftMask /\ RightMask,

  % The swath of positions over which the piece moves should not be occupied by
  % any other piece
  Conflicts is Swath /\ (Occupied xor Piece),
  Conflicts = 0,

  % Now that we know the move is legal, construct the new state.
  PieceDelta is Piece xor NewPiece,
  EndsDelta is (1 << Pos) \/ (1 << (Pos + Offset * Skip)),
  NewOccupied is Occupied xor PieceDelta,
  NewEnds is Ends xor EndsDelta,
  (Skip == 1 -> (HorizDelta, VertDelta) = (PieceDelta, 0); (HorizDelta, VertDelta) = (0, PieceDelta)),
  NewHoriz is Horiz xor HorizDelta,
  NewVert is Vert xor VertDelta.


% Find the piece whose bottommost or rightmost position is Pos.
find_piece(Stop, Pos, Skip, Piece) :-
  Init is 1 << Pos,
  Next is Init >> Skip,
  find_piece0(Stop, Skip, Init, Next, Piece).


% Helper that implements the recursion of looking for the piece
find_piece0(Stop, Skip, Init, Next, Piece) :-
  More is Stop /\ Next,
  ( More = 0 -> Piece = Init;
    Init0 is Init \/ Next,
    Next0 is Next >> Skip,
    find_piece0(Stop, Skip, Init0, Next0, Piece)
  ).


% Construct a move object from a position and an offset
pos_offset_move(Pos, Offset, Move) :-
  Move is (Pos << 8) \/ (Offset + 4).


% Format the move into a string
move_string(Move, String) :-
  with_output_to(string(String), format_move(Move)).

format_move(Move) :-
  Pos is Move >> 8,
  Offset is (Move /\ 15) - 4,
  Row is Pos >> 3,
  Col is Pos /\ 7,
  Abs is abs(Offset),
  (Offset == Abs -> Sign = "+"; Sign = "-"),
  format("(~d,~d)~s~d~n", [Row, Col, Sign, Abs]).
