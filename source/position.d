import types;
import text;
import hash_seed;
import movegen;
import std.string;
import std.stdio;
import std.format;
import std.conv;
import std.array;
import std.container;
import std.conv;
import std.regex;

/**
 * do_move
 */
Position doMove(Position p, Move m)
{
    if (m != Move.NULL_MOVE && m != Move.TORYO) {
        if (m.isDrop) {
            type_t t = m.from;
            p.squares[m.to] = Square((p.sideToMove == Color.BLACK ? 0 : 0b10000) | t);
            p.hash ^= HASH_SEED_BOARD[p.squares[m.to].i][m.to];
            p.hash ^= HASH_SEED_HAND[p.sideToMove][t][ p.piecesInHand[p.sideToMove][t] ];
            p.piecesInHand[p.sideToMove][t]--;
            p.hash ^= HASH_SEED_HAND[p.sideToMove][t][ p.piecesInHand[p.sideToMove][t] ];
        } else {
            // capture
            if (p.squares[m.to] != Square.EMPTY) {
                type_t t = p.squares[m.to].unpromote.type;
                p.hash ^= HASH_SEED_BOARD[p.squares[m.to].i][m.to];
                p.hash ^= HASH_SEED_HAND[p.sideToMove][t][ p.piecesInHand[p.sideToMove][t] ];
                p.piecesInHand[p.sideToMove][t]++;
                p.hash ^= HASH_SEED_HAND[p.sideToMove][t][ p.piecesInHand[p.sideToMove][t] ];
            }
            p.squares[m.to] = m.isPromote ? p.squares[m.from].promote : p.squares[m.from];
            p.hash ^= HASH_SEED_BOARD[p.squares[m.to].i][m.to];
            p.hash ^= HASH_SEED_BOARD[p.squares[m.from].i][m.from];
            p.squares[m.from] = Square.EMPTY;
        }
    }
    p.sideToMove ^= 1;
    p.hash ^= HASH_SEED_SIDE;
    p.moveCount++;
    p.previousMove = m;
    return p;
}
