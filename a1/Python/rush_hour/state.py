###############################################################################
#
# rush_hour/state.py
#
# Rush Hour puzzle solver
# (C) 2019 Norbert Zeh (nzeh@cs.dal.ca)
#
###############################################################################


"""This module provides the primitives for manipulating and querying the
current game state.

The game state is represented as a tuple of 4 64-bit words
(occupied, horiz, vert, ends).  Each bit corresponds to a cell of an 8x8 board
numbered in row-major order.  Referring to the ith bit of a bit vector vec as
vec[i], these four words have the following meaning:

- occupied[i] = 1 if cell i is occupied by a piece
- horiz[i] = 1    if cell i is occupied by a horizontal piece
- vert[i] = 1     if cell i is occupied by a vertical piece
- ends[i] = 1     if cell i is the rightmost or bottommost cell of a piece"""


from io import StringIO
from itertools import chain


def from_string_rep(string_rep):
    """Construct a state from its string representation.  The input is a
    36-character string listing the 6x6 cells of the board in row-major order.
    Empty cells are marked with "o".  Occupied cells are marked with letters
    representing pieces.  Cells occupied by the same piece carry the same
    letter."""
    grid = _grid_from_string_rep(string_rep)
    horiz, horiz_ends = _find_horiz_pieces(grid)
    vert, vert_ends = _find_vert_pieces(grid)
    occupied = vert | horiz
    ends = horiz_ends | vert_ends
    return (occupied, horiz, vert, ends)


def _grid_from_string_rep(string_rep):
    """Pad a 36-character string representation of a state into a 64-character
    representation that includes empty cells to represent the borders around
    the board."""
    grid = StringIO()
    print("oooooooo", file=grid, end="")
    for i in range(6):
        print("o{}o".format(string_rep[6*i:6*(i+1)]), file=grid, end="")
    print("oooooooo", file=grid, end="")
    return grid.getvalue()


def _find_vert_pieces(grid):
    """Find all vertical pieces on the board and return two words representing
    the cells occupied by these pieces and the cells that are the bottommost
    cells of these pieces."""
    transposed_grid = _transpose_grid(grid)
    transposed_bits, transposed_ends = \
        _find_horiz_pieces(transposed_grid)
    return _transpose_bits(transposed_bits), \
        _transpose_bits(transposed_ends)


def _find_horiz_pieces(grid):
    """Find all horizontal pieces on the board and return two words
    representing the cells occupied by these pieces and the cells that are the
    rightmost cells of these pieces."""
    bits = 0xff000000000000ff
    ends = 0
    for i in range(64):
        cellbit, cellend = _horiz_bits(grid, i)
        bits |= cellbit
        ends |= cellend
    return bits, ends


def _horiz_bits(grid, pos):
    """Return a pair of words representing position pos on the board.  The
    first word is 1 << pos if the position is occupied and 0 otherwise.  The
    second word is 1 << pos if the position is the rightmost position of a
    piece and 0 otherwise."""
    if grid[pos] == "o":
        return 0, 0
    if grid[pos] == grid[pos+1]:
        return 1 << pos, 0
    if grid[pos] == grid[pos-1]:
        return 1 << pos, 1 << pos
    else:
        return 0, 0


def _transpose_grid(grid):
    """Rearranges the character in a 64-character string represending an 8x8
    Rush Hour board so as to transpose the board."""
    transposed_grid = StringIO()
    for i in range(64):
        j = ((i & 7) << 3) | ((i & 56) >> 3)
        print(grid[j], file=transposed_grid, end="")
    return transposed_grid.getvalue()


def _transpose_bits(bits):
    """Rearranges the bits in a 64-bit bit string representing an 8x8 board so
    as to transpose the board."""
    # 2x2 transpose of individual bits
    trans = (bits ^ (bits << 7)) & 0x5500550055005500
    bits = bits ^ trans ^ (trans >> 7)
    # 2x2 transpose of 2x2 blocks
    trans = (bits ^ (bits << 14)) & 0x3333000033330000
    bits = bits ^ trans ^ (trans >> 14)
    # 2x2 transpose of 4x4 blocks
    trans = (bits ^ (bits << 28)) & 0x0f0f0f0f00000000
    bits = bits ^ trans ^ (trans >> 28)
    return bits


def pretty_print(state):
    """Produce a vector of 14 14-character strings that, if printed in
    consecutive rows display the Rush Hour board.  (The 14 rows and 14 columns
    result from using 2x2 characters for every board cell and one character for
    the border.  Since there are 6x6 cells on the board, this gives 14 rows and
    14 columns.)"""
    rows = [[_format_cell(state, row + col) for col in range(1, 7)]
            for row in range(8, 63, 8)]
    lines = ["████████████"] + \
            ["".join(chain.from_iterable(line))
             for line in chain.from_iterable((zip(*row) for row in rows))] + \
            ["████████████"]
    left_wall = "██████████████"
    right_wall = "█████  ███████"
    return ["".join(line) for line in zip(left_wall, lines, right_wall)]


def _format_cell(state, pos):
    if not is_occupied(state, pos):
        return ["  ", "  "]
    if is_horizontal(state, pos):
        if not is_horizontal(state, pos - 1) or is_end(state, pos - 1):
            left = "▗▝"
        else:
            left = "▄▀"
        if not is_horizontal(state, pos + 1) or is_end(state, pos):
            right = "▖▘"
        else:
            right = "▄▀"
        return ["".join(line) for line in zip(left, right)]
    if not is_vertical(state, pos - 8) or is_end(state, pos - 8):
        top = "▗▖"
    else:
        top = "▐▌"
    if not is_vertical(state, pos + 8) or is_end(state, pos):
        bottom = "▝▘"
    else:
        bottom = "▐▌"
    return [top, bottom]


def is_occupied(state, pos):
    """Check whether the posth cell is occupied."""
    return state[0] & (1 << pos)


def is_horizontal(state, pos):
    """Check whether the posth cell is occupied by a horizontal piece."""
    return state[1] & (1 << pos)


def is_vertical(state, pos):
    """Check whether the posth cell is occupied by a vertical piece."""
    return state[2] & (1 << pos)


def is_end(state, pos):
    """Check whether the posth cell is the rightmost or bottommost cell of a
    piece."""
    return state[3] & (1 << pos)


def is_solved(state):
    """Check whether the board is solved.  This is the case when the horizontal
    on the 3rd row is moved all the way to the right, that is cell 30 is
    occupied by a horizontal piece."""
    return is_horizontal(state, 30)


def make_move(pos, offset):
    """Construct a move object from a given position-offset pair"""
    return (pos << 8) | (offset + 4)


def vertical_move(state, pos, offset):
    """Move the vertical piece occupying position pos by offset positions.  A
    negative offset means move up.  A positive offset means move down.  The
    return value is the new state and a representation of the move as a 16-bit
    word.  If the move is invalid because it moves the piece off the board or
    across another piece, two None values are returned."""
    stop = state[0] & \
        (state[1] ^ 0xffffffffffffffff) & \
        (state[3] ^ 0xffffffffffffffff)
    return _move(state, pos, offset, stop, 8, 0x0101010101010101)


def horizontal_move(state, pos, offset):
    """Move the horizontal piece occupying position pos by offset positions.  A
    negative offset means move left.  A positive offset means move right.  The
    return value is the new state and a representation of the move as a 16-bit
    word.  If the move is invalid because it moves the piece off the board or
    across another piece, two None values are returned."""
    stop = state[0] & \
        (state[2] ^ 0xffffffffffffffff) & \
        (state[3] ^ 0xffffffffffffffff)
    return _move(state, pos, offset, stop, 1, 0xffffffffffffffff)


def _move(state, pos, offset, stop, skip, mask):
    """This is the worker that implements both horizontal and vertical
    moves."""

    # Construct the bit vector representing the positions occupied by the piece
    # to be moved
    piece = 1 << pos
    left = piece >> skip
    while stop & left:
        piece |= left
        left >>= skip

    # Construct the new piece resulting from the move and
    # - the leftmost and rightmost of piece and new_piece
    # - the end positions of the leftmost and rightmost pieces
    if offset < 0:
        new_piece = piece >> (-offset * skip)
        left, right = new_piece, piece
        left_pos, right_pos = pos + offset * skip, pos
    else:
        new_piece = piece << (offset * skip)
        left, right = piece, new_piece
        left_pos, right_pos = pos, pos + offset * skip

    # Abort if the new piece is out of bounds
    if left_pos < 9 + skip or right_pos > 54:
        return None

    # Construct the swath of cells over which the piece moves from its old to
    # its new position.
    left = left | (mask << left_pos)
    right = right | (mask >> (64 - right_pos - skip))
    swath = (left & right) ^ piece

    # Abort if any of them is occupied.
    if state[0] & swath:
        return None

    # Construct the change in occupied cells and the change in end cells
    # resulting from the move
    piece_delta = piece ^ new_piece
    end_delta = (1 << pos) | (1 << (pos + offset * skip))

    # Update occupied, horiz, and end if this was a horizontal move.
    # Otherwise, update, occupied, vert, and end.
    if skip == 1:
        return (
            state[0] ^ piece_delta,
            state[1] ^ piece_delta,
            state[2],
            state[3] ^ end_delta
        )
    return (
        state[0] ^ piece_delta,
        state[1],
        state[2] ^ piece_delta,
        state[3] ^ end_delta
    )


def apply_move(state, move):
    """Try to apply the given move to state.  Return the new state if this
    succeeds.  Otherwise, return None."""
    pos = move >> 8
    offset = (move & 0xff) - 4
    if not is_occupied(state, pos):
        return None
    if is_horizontal(state, pos):
        return horizontal_move(state, pos, offset)
    return vertical_move(state, pos, offset)
