"""Static configuration for pentool."""

from __future__ import annotations

from importlib import resources

DOCKER_RESOURCES_PACKAGE = "pentool.resources"
DOCKERFILE_NAME = "Dockerfile"


def dockerfile_content() -> str:
    resource = resources.files(DOCKER_RESOURCES_PACKAGE).joinpath(
        DOCKERFILE_NAME
    )
    return resource.read_text(encoding="utf-8")


def dockerignore_content() -> str:
    return "*\n!Dockerfile\n"


# List derived from nmap-services frequency table.
COMMON_TCP_PORTS: tuple[int, ...] = (
    80,
    443,
    22,
    21,
    25,
    53,
    110,
    995,
    143,
    993,
    587,
    3306,
    3389,
    5900,
    8080,
    8443,
    53,
    135,
    139,
    445,
    1433,
    1521,
    1723,
    2049,
    2375,
    27017,
    27018,
    27019,
    5432,
    6379,
    8000,
    8888,
    9090,
    9200,
    9300,
    27017,
    11211,
    5000,
    25,
    389,
    636,
    465,
    2000,
    5060,
    2222,
    9418,
    9419,
    10250,
    10255,
    10256,
    11210,
    15672,
    2379,
    2380,
    3000,
    4000,
    5001,
    5601,
    5901,
    5984,
    5985,
    5986,
    6443,
    7001,
    7002,
    7077,
    7199,
    8008,
    8010,
    8042,
    8081,
    8088,
    8090,
    8333,
    8444,
    8484,
    8500,
    8530,
    8531,
    8765,
    8834,
    8880,
    9000,
    9080,
    9443,
    9999,
    10000,
    11211,
    15672,
    27017,
    50070,
    50075,
    61616,
    61617,
    62078,
    64738,
    65535,
)
