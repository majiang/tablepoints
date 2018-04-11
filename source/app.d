import std.conv : to;
import std.algorithm, std.array, std.range;

import vibe.vibe;

import tablepoints, tablepoints.api;

void main()
{
    import std.process : environment;

    auto settings = new HTTPServerSettings;
    settings.port = environment.get("PORT", "8080").to!ushort;

    auto router = new URLRouter;
    router.registerRestInterface(new SimulationImpl);
    router.get("/", staticTemplate!"index.dt");
    router.get("/js/api.js", serveRestJSClient!Simulation("http://localhost:8080"));
    router.get("*", serveStaticFiles("./public/"));

    listenHTTP(settings, router);

    runApplication();
}
