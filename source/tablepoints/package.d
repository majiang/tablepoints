module tablepoints;

import std.random : randomShuffle;
import std.algorithm, std.range;

__gshared SimulationResult[string] results;

import tablepoints.api;
class SimulationImpl : Simulation
{
    import std.format : format;
    import std.random : uniform;
    import std.concurrency : spawn;
    string putSimulation(
            size_t fixed, size_t random, size_t ggp,
            double[] initialScore, size_t position,
            string rule)
    {
        immutable id = "%016x".format(uniform!ulong);
        spawn(  &simulateAndStore,
                id,
                fixed, random, ggp,
                initialScore.idup, position, rule);
        return id;
    }
    string putFlatSimulation(
            size_t fixed, size_t random, size_t ggp,
            size_t tables, size_t position,
            string rule)
    {
        return putSimulation(
                fixed, random, ggp,
                double(0).repeat(tables*4).array, position,
                rule);
    }
    SimulationResult getSimulationResult(string id)
    {
        if (auto p = id in results)
        {
            debug
            {
                import std.stdio;
                stderr.writefln("found");
            }
            return *p;
        }
        else debug
        {
            import std.stdio;
            stderr.writefln("not found");
        }
        return SimulationResult.init; // TODO: return 404
    }
}

unittest
{
    auto s = new SimulationImpl;
    s.putFlatSimulation(
            0, 8, 0,
            8, 1, "MCR");
    s.putFlatSimulation(
            0, 0, 8,
            8, 1, "MCR");
    import core.thread : Thread;
    import core.time : seconds;
    Thread.sleep(10.seconds);
}

void simulateAndStore(
        string id,
        size_t fixed, size_t random, size_t ggp,
        immutable(double)[] initialScore, size_t position,
        string rule)
{
    auto simulator = new Simulator(rule.tablePoint);
    simulator.initialScore = initialScore;
    simulator.positions = [position];
    auto condition = SimulationCondition(rule, initialScore.dup, fixed, random, ggp, position);
    enum trialPerExec = 10000;
    enum execs = 100;
    size_t[immutable(real[])] ret;
    results[id] = ret.asResult(condition);
    debug
    {
        import std.stdio : stderr;
        stderr.writefln("%s: %s", id, results[id]);
    }
    foreach (i; 0..execs)
    {
        results[id] = ret.updateAdd(simulator.simulate(fixed, random, ggp, trialPerExec)).asResult(condition);
        assert (results[id].result.map!(_=>_.count).sum == trialPerExec*(i+1));
        debug
        {
            import std.stdio : stderr;
            stderr.writefln("%dth batch of %s: %s", i, id, results[id]);
        }
    }
    results[id].finished = true;
}

V[K] updateAdd(K, V)(ref V[K] lhs, in V[K] rhs)
{
    foreach (kvp; rhs.byKeyValue)
    {
        if (kvp.key in lhs)
            lhs[kvp.key] += kvp.value;
        else
            lhs[kvp.key] = kvp.value;
    }
    return lhs;
}

SimulationResult asResult(K, V)(V[K] resultAA, SimulationCondition condition)
{
    auto result = resultAA.byPair.map!(_=> ResultElem(_.key[0], _.value)).array;
    return SimulationResult(result, condition);
}

class Simulator
{
    this (TablePoint tp)
    {
        this.tp = tp;
    }
    void tables(in size_t value) @property
    {
        _tables = value;
        _initialScore = new int[_tables*tp.tableSize];
        currentScore.length = _initialScore.length;
    }
    void initialScore(FR)(in FR values) @property
        if (isInputRange!FR && is (ElementType!FR : real))
    {
        import std.algorithm, std.array, std.conv, std.math;
        _initialScore = values.map!(_ => (_*tp.denominator+.5).floor.to!int).array;
        currentScore.length = values.length;
        _tables = values.length / tp.tableSize;
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
package:
    void initialScore(int[] values) @property
    {
        _initialScore = values.dup;
        currentScore.length = values.length;
        _tables = values.length / tp.tableSize;
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
        foreach (t; 0.._tables)
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
    size_t _tables;
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
    immutable size_t tableSize;
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

TablePoint tablePoint(string name)
{
    import std.uni : toUpper;
    if (name.toUpper.startsWith("MCR"))
        return new MCRTablePoint;
    if (name.toUpper.startsWith("RCR"))
        return new RCRTablePoint;
    return null;
}

unittest
{
    import std.stdio;
    assert ("MCR".tablePoint.displayPoints == [4, 2, 1, 0]);
    assert ("RCR".tablePoint.displayPoints == [3, 2, 1, 0]);
}
