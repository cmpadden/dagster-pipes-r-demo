# Showcase `dagster-pipes` usage from R

This project demonstrates the usage of `dagster-pipes` from an R runtime environment. It supports handling of `context` `extracts`, as well as logging events back to Dagster. It showcases a simple pipeline that loads in NYC vehicle collision data and generates a plot of annual collision per borough.

## Demonstration

### Context Parameters

Extras can be specified as a parameter to the `pipes_subprocess_client` `run` method.

```python
    return pipes_subprocess_client.run(
        command=cmd,
        context=context,
        extras={
            "vehicle_collisions_url": "https://data.cityofnewyork.us/api/views/h9gi-nx95/rows.csv",
            "vehicle_collisions_cache_path": "data/nyc-collisions.csv",
            "plot_output_path": "nyc-vehicle-collisions-by-borough.png",
        },
    ).get_materialize_result()
```

They can then be accessed from the context in R like so:

```r
context <- load_context(params$context_params)
```

### Event Logging

A logger can be used to send events back to the Dagster instance.

```r
logger <- PipesLogger$new(params)

logger$open()

logger$info(sprintf("saving plot to: %s", plot_output_path))
```

<img width="1149" alt="image" src="https://github.com/cmpadden/dagster-pipes-r-demo/assets/5807118/52667fa0-2c02-4200-b422-8ff37b98f9d4">

## Usage

```bash
pip install -e ".[dev]"
```

Then, start the Dagster UI web server:

```bash
dagster dev
```

Open http://localhost:3000 with your browser to see the project.

## Extra

This is the resulting plot that is generated from the pipeline.

![image](https://github.com/cmpadden/dagster-pipes-r-demo/assets/5807118/7df6948a-d9ab-4cb2-804e-2448a3d05bb7)
