// client JS code comes here.
function refresh(simulationID, campusID)
{
    Simulation.getSimulationResult(simulationID, function(result){
        document.getElementById(campusID).innerHTML = JSON.stringify(result);
    }, function(){alert("getSimulationResult error!");});
}

function startPolling(id)
{
    var intervalID = setInterval(refresh, 1000, id, "show_result");
    setTimeout(clearInterval, 180000, intervalID);
}

function putFlatSimulation()
{
    var form = document.forms.condition;
    console.log(form.rule.value);
    console.log(form.fixed.value);
    console.log(form.random.value);
    console.log(form.ggp.value);
    console.log(form.fixed.value);
    console.log(form.position.value);
    console.log(form.tables.value);
    Simulation.putFlatSimulation(
            parseInt(form.fixed.value, 10), parseInt(form.random.value, 10), parseInt(form.ggp.value, 10),
            parseInt(form.tables.value, 10), parseInt(form.position.value, 10), form.rule.value,
            startPolling, onError);
}

function putSimulation()
{
    var form = document.forms.condition;
    console.log(form.rule.value);
    console.log(form.fixed.value);
    console.log(form.random.value);
    console.log(form.ggp.value);
    console.log(form.position.value);
    console.log(form.initial.value);
    Simulation.putSimulation(
            parseInt(form.fixed.value, 10), parseInt(form.random.value, 10), parseInt(form.ggp.value, 10),
            JSON.parse(form.initial.value), parseInt(form.position.value, 10), form.rule.value,
            startPolling, onError);
}

function onError()
{
    aleart("error!");
}
