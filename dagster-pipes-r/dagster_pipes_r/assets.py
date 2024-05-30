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
        command=cmd, context=context
    ).get_materialize_result()
