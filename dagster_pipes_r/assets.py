from dagster import (
    AssetExecutionContext,
    MaterializeResult,
    PipesSubprocessClient,
    asset,
    file_relative_path,
)


@asset
def nyc_vehicle_collision_report(
    context: AssetExecutionContext, pipes_subprocess_client: PipesSubprocessClient
) -> MaterializeResult:
    """Generates a visualization of NYC vehicle collisions by borough via R."""
    cmd = [
        "r",
        "-f",
        file_relative_path(__file__, "../analyses/nyc-vehicle-collisions.R"),
    ]
    return pipes_subprocess_client.run(
        command=cmd,
        context=context,
        extras={
            "vehicle_collisions_url": "https://data.cityofnewyork.us/api/views/h9gi-nx95/rows.csv",
            "vehicle_collisions_cache_path": "data/nyc-collisions.csv",
            "plot_output_path": "nyc-vehicle-collisions-by-borough.png",
        },
    ).get_materialize_result()
