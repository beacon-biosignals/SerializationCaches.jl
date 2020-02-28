# SerializationCaches.jl

A Julia package that implements a simple two-stage cache (the `SerializationCache`) that is useful for caching objects that take significantly longer to compute from scratch than to (de)serialize from disk. Recently fetched objects are cached within an in-memory data structure, while less recently fetched objects are (de)serialized to/from the filesystem via Julia's `Serialization` module.

See the package's documentation for more details.
