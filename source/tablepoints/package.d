module tablepoints;

abstract class Simulator
{
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
        import std.random : randomShuffle;
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
