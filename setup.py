from setuptools import find_packages, setup

setup(
    name="dagster_pipes_r",
    packages=find_packages(exclude=["dagster_pipes_r_tests"]),
    install_requires=[
        "dagster",
        "dagster-cloud"
    ],
    extras_require={"dev": ["dagster-webserver", "pytest"]},
)
