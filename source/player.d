import types;
import text;
import position;
import movegen;
import eval;
import std.format;
import std.random;
import std.stdio;
import std.datetime.stopwatch;
import std.algorithm.searching;
import std.algorithm.mutation;
import std.algorithm.comparison;


    // move_t ponder(const position& p) {
    //     boost::timer t;

    //     std::vector<std::tuple<move_t, int>> moves;

    //     //m = search(p, 5, m);
    //     move_t m = 0;
    //     for (int depth = 1; t.elapsed() < 1.0; depth++) {
    //         int score = search(p, depth, m, m);
    //         moves.push_back(std::make_tuple(m, score));
    //     }
    //     for (int i = moves.size() - 1; i >= 0; i--) {
    //         if ((p.side_to_move == side::BLACK) ? std::get<1>(moves[i]) > -15000 : std::get<1>(moves[i]) < 15000) {
    //             return std::get<0>(moves[i]);
    //         }
    //     }
    //     return std::get<0>(moves[0]);
    // }


private StopWatch SW;
immutable SECOND = 15;

int ponder(const ref Position p, out move_t result)
{
    move_t m = 0;
    // int score = 0;
    // search(p, 5, m, m, score);

    SW = StopWatch(AutoStart.yes);
    for (int depth = 1; SW.peek().total!"seconds" < SECOND; depth++) {
        search(p, depth, m, m, score);
    }
    result = m;
    return score;
}


private int search(Position p, int depth, move_t prev, ref move_t out_move, ref int out_score)
{
    if (SW.peek().total!"seconds" >= SECOND) {
        return 0;
    }

    move_t[593] moves;
    int length = p.legalMoves(moves);
    if (length == 0) {
        return 0;
    }
    moves[0..length].randomShuffle();
    if (prev != 0) {
        swap(moves[0], moves[0..length].find(prev)[0]);
    }

    int a = int.min;
    int b = int.max;
    stderr.write(format("%d: ", depth));
    if (p.sideToMove == Side.BLACK) {
        // maxノード
        for (int i = 0; i < length; i++) {
            int score = alphabeta(p.doMove(moves[i]), depth - 1, a, b);
            if (score > a && SW.peek().total!"seconds" < SECOND) {
                a = score;
                out_move = moves[i];
                out_score = score;
                stderr.write(format("%s(%d) ", moves[i].toString(p), score));
            }
        }
    } else {
        // minノード
        for (int i = 0; i < length; i++) {
            int score = alphabeta(p.doMove(moves[i]), depth - 1, a, b);
            if (score < b && SW.peek().total!"seconds" < SECOND) {
                b = score;
                out_move = moves[i];
                out_score = score;
                stderr.write(format("%s(%d) ", moves[i].toString(p), score));
            }
        }
    }
    stderr.write("\n");
    return (p.sideToMove == Side.BLACK) ? a : b;
}

/**
 * alphabeta
 * @param p
 * @param depth
 * @param a 探索済みminノードの最大値
 * @param b 探索済みmaxノードの最小値
 */
private int alphabeta(Position p, int depth, int a, int b)
{
    if (SW.peek().total!"seconds" >= SECOND) {
        return 0;
    }

    if (depth <= 0) {
        return quies(p, 4, a, b);
        //return p.staticValue();
    }

    move_t[593] moves;
    int length = p.legalMoves(moves);
    if (length == 0) {
        return p.staticValue();
    }

    if (p.sideToMove == Side.BLACK) {
        // maxノード
        for (int i = 0; i < length; i++) {
            a = max(a, alphabeta(p.doMove(moves[i]), depth - 1, a, b));
            if (a >= b) {
                return b; // bカット
            }
        }
        return a;
    } else {
        // minノード
        for (int i = 0; i < length; i++) {
            b = min(b, alphabeta(p.doMove(moves[i]), depth - 1, a, b));
            if (a >= b) {
                return a; // aカット
            }
        }
        return b;
    }
}

private int quies(Position p, int depth, int a, int b)
{
    int standpat = p.staticValue();
    if (depth == 0) {
        return standpat;
    }
    move_t[128] moves;

    if (p.sideToMove == Side.BLACK) {
        if (b <= standpat) {
            return b;
        }
        if (a < standpat) {
            a = standpat;
        }
        int length = p.capturelMoves(moves);
        for (int i = 0; i < length; i++) {
            int value = quies(p.doMove(moves[i]), depth - 1, a, b);
            if (b <= value) {
                return b;
            }
            if (a < value) {
                a = value;
            }
        }
        return a;
    } else {
        if (a >= standpat) {
            return a;
        }
        if (b > standpat) {
            b = standpat;
        }
        int length = capturelMoves(p, moves);
        for (int i = 0; i < length; i++) {
            int value = quies(p.doMove(moves[i]), depth - 1, a, b);
            if (a >= value) {
                return a;
            }
            if (b > value) {
                b = value;
            }
        }
        return b;
    }
}
