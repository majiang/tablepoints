module tablepoints.api;

struct SimulationResult
{
    ResultElem[] result;
    SimulationCondition condition;
    bool finished;
}
struct SimulationCondition
{
    string rule;
    double[] initialScore;
    size_t fixed, random, ggp, position;
}
struct ResultElem
{
    double point;
    size_t count;
}

interface Simulation
{
    string putSimulation(
            size_t fixed, size_t random, size_t ggp,
            double[] initialScore, size_t position,
            string rule);
    string putFlatSimulation(
            size_t fixed, size_t random, size_t ggp,
            size_t tables, size_t position,
            string rule);
    SimulationResult getSimulationResult(string id);
}
