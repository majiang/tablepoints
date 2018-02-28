import vibe.vibe;

import std.conv : to;

void main()
{
    import std.process : environment;

    auto settings = new HTTPServerSettings;
    settings.port = environment.get("PORT", "8080").to!ushort;
    settings.sessionStore = new MemorySessionStore;

    auto router = new URLRouter;
    router.registerWebInterface(new Simulation);

    listenHTTP(settings, router);

    runApplication();
}

class Simulation
{
    void index()
    {
        bool hasResult = _hasResult;
        string result = _result;
        render!("index.dt", hasResult, result);
    }
    void postQuery(
            size_t fixed, size_t random, size_t ggp,
            size_t tables, size_t position, size_t trial)
    {
        import std.range : repeat;
        import std.array : array;
        import tablepoints;
        auto simulator = new Simulator(new MCRTablePoint);
        simulator.positions = [position];
        simulator.initialScore = 0.repeat(tables * 4).array;
        scope (success)
            _hasResult = true;
        _result = simulator.simulate(
                fixed, random, ggp, trial)
                .to!string;
        "/".redirect;
    }
private:
    SessionVar!(bool, "hasResult") _hasResult;
    SessionVar!(string, "result")_result;
}
