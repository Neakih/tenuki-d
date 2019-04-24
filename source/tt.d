module tt;

import std.stdio;
import core.atomic;
import types;
import text;
import core.atomic;

private immutable MASK = 0x7ffffff; // 1024 * 1024 * 16 - 1
__gshared private TTEntry[MASK + 1] TT;
shared long stat_nothing = 0;
shared long stat_misshit = 0;
shared long stat_hit = 0;
shared long stat_stored = 0;

struct TTEntry
{
    uint key32;
    ushort move16;
    ushort _;
}

Move probe(ulong key)
{
    for (int i = 0; i < 5; i++)
    {
        TTEntry e = TT[((key & MASK) + i * 2) % (MASK + 1)];
        if (e.key32 == 0)
        {
            atomicOp!"+="(stat_nothing, 1);
            return cast(Move)(0);
        }
        if (e.key32 == (key >> 32))
        {
            atomicOp!"+="(stat_hit, 1);
            return cast(Move)(e.move16);
        }
        //atomicOp!"+="(stat_misshit, 1);
        //return cast(Move)(0);
    }
    atomicOp!"+="(stat_misshit, 1);
    return cast(Move)(0);
}

void store(ulong key, Move m)
{
    for (int i = 0; i < 5; i++)
    {
        const long address = ((key & MASK) + i * 2) % (MASK + 1);
        if (TT[address].key32 == 0 || TT[address].key32 == (key >> 32))
        {
            TT[address] = TTEntry((key >> 32), m.i);
            atomicOp!"+="(stat_stored, 1);
            return;
        }
        //return;
    }
}

long hashfull()
{
    long cnt = 0;
    foreach (TTEntry e; TT)
    {
        cnt += e.move16 == 0 ? 0 : 1;
    }
    return cnt * 1000 / (MASK + 1);
    //return cnt;
}
