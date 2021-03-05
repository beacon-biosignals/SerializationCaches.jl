# SerializationCaches.jl

[![CI](https://github.com/beacon-biosignals/SerializationCaches.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/beacon-biosignals/SerializationCaches.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/beacon-biosignals/SerializationCaches.jl/branch/master/graph/badge.svg?token=Q8BQBGO9G5)](https://codecov.io/gh/beacon-biosignals/SerializationCaches.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://beacon-biosignals.github.io/SerializationCaches.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://beacon-biosignals.github.io/SerializationCaches.jl/dev)

A Julia package that implements a simple two-stage cache (the `SerializationCache`) that is useful for caching objects that take significantly longer to compute from scratch than to (de)serialize from disk. Recently fetched objects are cached within an in-memory data structure, while less recently fetched objects are (de)serialized to/from the filesystem via Julia's `Serialization` module.

See the package's documentation for more details.
