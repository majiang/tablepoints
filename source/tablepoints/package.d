module tablepoints;

import std.random : randomShuffle;
import std.algorithm : sort;

class Simulator
{
    this (TablePoint tp)
    {
        this.tp = tp;
    }
    void initialScore(int[] values) @property
    {
        _initialScore = values.dup;
        _initialScore[] /= tp.denominator;
        currentScore.length = values.length;
        tables = values.length / tp.tableSize;
    }
    void positions(size_t[] values) @property
    {
        _positions = values.dup;
        sliced.length = values.length;
        denominated.length = values.length;
    }
    auto simulate(in size_t fixed, in size_t random, in size_t ggp, in size_t trial)
    {
        size_t[immutable(real[])] ret;
        foreach (i; 0..trial)
        {
            auto r = simulateOnce(fixed, random, ggp).idup;
            if (auto p = r in ret)
                *p += 1;
            else
                ret[r] = 1;
        }
        return ret;
    }
    auto simulateOnce(in size_t fixed, in size_t random, in size_t ggp)
    {
        currentScore[] = _initialScore[];
        simulateFixed(fixed);
        simulateRandom(random);
        simulateGGP(ggp);
        return denominate;
    }
private:
    real[] denominate()
    {
        denominated[] = slice[] * (real(1) / real(tp.denominator));
        return denominated;
    }
    void simulateFixed(in size_t n)
    {
        foreach (i; 0..n)
            simulateTables;
    }
    void simulateRandom(in size_t n)
    {
        foreach (i; 0..n)
        {
            currentScore.randomShuffle;
            simulateTables;
        }
    }
    void simulateGGP(in size_t n)
    {
        foreach (i; 0..n)
        {
            currentScore.sort;
            simulateTables;
        }
    }
    void simulateTables()
    {
        foreach (t; 0..tables)
            currentScore[t*tp.tableSize .. (t+1)*tp.tableSize][] += tp.random[];
    }
    int[] slice()
    {
        assert (sliced.length == _positions.length);
        currentScore.sort!((a, b) => a > b);
        foreach (i, p; _positions)
            sliced[i] = currentScore[p];
        return sliced;
    }
    size_t[] _positions;
    TablePoint tp;
    int[] _initialScore;
    int[] currentScore;
    int[] sliced;
    real[] denominated;
    size_t tables;
}
unittest
{
    auto s = new Simulator(new MCRTablePoint);
    s.initialScore = [
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0];
    s.positions = [3, 4];
    import std.stdio;
    "random 8 rounds:".writeln;
    foreach (i; 0..5)
        s.simulate(0, 8, 0, 10000).displayResult(9000, 100);
    "random 4 and ggp 4 rounds:".writeln;
    foreach (i; 0..5)
        s.simulate(0, 4, 4, 10000).displayResult(9000, 100);
    "ggp 8 rounds:".writeln;
    foreach (i; 0..5)
        s.simulate(0, 0, 8, 10000).displayResult(9000, 100);
}

void displayResult(
        size_t[immutable(real[])] result,
        in size_t summax,
        in size_t min)
{
    import std.array, std.stdio;
    size_t sum;
    foreach (kvp; result.byPair.array.sort!((a, b) => a.value > b.value))
    {
        if (kvp.value < min)
            break;
        "%d\t%s".writefln(kvp.value, kvp.key);
        sum += kvp.value;
        if (summax < sum)
            break;
    }
    writeln;
}

abstract class TablePoint
{
    immutable int denominator;
    immutable int tableSize;
    immutable int[] basePoints;
    this (in int denominator, in size_t tableSize, in int[] basePoints)
    {
        this.denominator = denominator;
        this.tableSize = tableSize;
        this.reused.length = tableSize;
        this.basePoints = basePoints.idup;
    }

    final real[] displayPoints()
    {
        return displayPoints(basePoints);
    }
    final real[] displayPoints(in int[] points)
    {
        import std.conv : to;
        auto ret = points.to!(real[]);
        ret[] /= denominator;
        return ret;
    }
    final int[] random(real tieProbability=0)
    {
        assert (tieProbability == 0, "not supported ties");
        reused[] = basePoints[];
        randomShuffle(reused);
        return reused;
    }
private:
    int[] reused;
}

class MCRTablePoint : TablePoint
{
    this ()
    {
        super (12, 4, [48, 24, 12, 0]);
    }
}
class RCRTablePoint : TablePoint
{
    this ()
    {
        super (2, 4, [6, 4, 2, 0]);
    }
}

unittest
{
    import std.stdio;
    assert ((new MCRTablePoint).displayPoints == [4, 2, 1, 0]);
    assert ((new RCRTablePoint).displayPoints == [3, 2, 1, 0]);
}
