module SerializationCaches

using Serialization
using OrderedCollections

export SerializationCache, fetch!, put!, set_up_cache_path

"""
    SerializationCache{T}(path; in_memory_limit, file_limit, file_gc_ratio)

Return a `SerializationCache` instance that holds elements of type `T`.

A `SerializationCache` (along with [`fetch!`](@ref) and [`put!`](@ref))
implements a simple two-stage cache that is useful for caching objects that take
significantly longer to compute from scratch than to (de)serialize from disk.

Recently fetched objects are cached within an in-memory data structure, while
less recently fetched objects are (de)serialized to/from the filesystem via
Julia's `Serialization` module. Specifically, if adding an object to the
in-memory cache would cause the in-memory cache to grow beyond `in_memory_limit`
elements, the least recently fetched object in the cache is serialized to a
`.jls` file in `path`. Once the number of `.jls` files in `path` exceeds
`file_limit`, less recently deserialized files are deleted to clear space;
the actual ratio of files that are deleted during this "garbage collection"
process is determined by `file_gc_ratio`.

Note that all `.jls` files in `path` at the time of `SerializationCache`
construction are considered to be part of constructed cache.

A valid method for function [`set_up_cache_path(path)`](@ref) must exist for the
given `path`; only `set_up_cache_path(::AbstractString)` currently exists.

See also: [`fetch!`](@ref), [`put!`](@ref), [`set_up_cache_path`](@ref)
"""
struct SerializationCache{T}
    path::Any
    file_keys::OrderedSet{String}
    file_gc_ratio::Float64
    file_limit::Int
    in_memory::OrderedDict{String,T}
    in_memory_limit::Int
    function SerializationCache{T}(path; in_memory_limit, file_limit,
                                   file_gc_ratio) where {T}
        path = set_up_cache_path(path)
        file_keys = OrderedSet{String}(first(splitext(name)) for name in readdir(path)
                                       if endswith(name, ".jls"))
        return new{T}(path, file_keys, file_gc_ratio, file_limit, OrderedDict{String,T}(),
                      in_memory_limit)
    end
end

SerializationCache(args...; kwargs...) = SerializationCache{Any}(args...; kwargs...)

"""
    set_up_cache_path(path::AbstractString)

Return the `SerializationCache`-ready `path`. For input type `AbstractString`,
creates `path` if it is not already a directory. Can be extended to support
other types of (e.g., AWSS3.jl's `S3Path`).
"""
function set_up_cache_path(path::AbstractString)
    path = rstrip(abspath(path), '/')
    isdir(path) || mkpath(path)
    return path
end

"""
    fetch!(f, cache::SerializationCache, key::AbstractString)

Return the object stored at `key` in `cache`. If `key` doesn't exist `cache`,
set `key` to `f()` and return the result.

Note that `key` must be a valid file name.

As part of fetching the requested result, this function performs several
bookkeeping operations to maintain `cache` within its configured limits; see
[`SerializationCache`](@ref) for details.
"""
function fetch!(f, cache::SerializationCache, key::AbstractString)
    if haskey(cache.in_memory, key)
        item = cache.in_memory[key]
        delete!(cache.in_memory, key) # re-prioritize `key`
        cache.in_memory[key] = item
        return item
    end
    if key in cache.file_keys
        item = deserialize(joinpath(cache.path, key * ".jls"))
        delete!(cache.file_keys, key) # re-prioritize `key`
        push!(cache.file_keys, key)
        cache.in_memory_limit == 0 && return item
    else
        item = f()
    end
    return put!(cache, key, item)
end

"""
    put!(cache::SerializationCache, key::AbstractString, item;
         directly_to_file::Bool=false)

Store `item` in `cache` at `key` and return `item`.

If `directly_to_file == true`, `item` is directly serialized to the `cache`'s
filesystem layer, skipping the `cache`'s in-memory layer.

Note that `key` must be a valid file name.
"""
function Base.put!(cache::SerializationCache, key::AbstractString, item;
                   directly_to_file::Bool=false)
    if directly_to_file || cache.in_memory_limit == 0
        _file_layer_put!(cache, key, item)
    else
        haskey(cache.in_memory, key) && delete!(cache.in_memory, key) # re-prioritize 'key'
        cache.in_memory[key] = item
        if length(cache.in_memory) > cache.in_memory_limit
            # too bad `popfirst!` isn't implemented on `OrderedDict`...
            oldest_key = first(keys(cache.in_memory))
            oldest_item = cache.in_memory[oldest_key]
            delete!(cache.in_memory, oldest_key)
            _file_layer_put!(cache, oldest_key, oldest_item)
        end
    end
    return item
end

function _popfirst!(ordered_set::OrderedSet)
    item = first(ordered_set)
    delete!(ordered_set, item)
    return item
end

function _file_layer_put!(cache::SerializationCache, key, item)
    serialize(joinpath(cache.path, key * ".jls"), item)
    if key in cache.file_keys # re-prioritize 'key'
        delete!(cache.file_keys, key)
    end
    push!(cache.file_keys, key)
    file_count = length(cache.file_keys)
    if file_count > cache.file_limit
        delete_count = cache.file_gc_ratio * file_count
        for _ in 1:clamp(floor(Int, delete_count), 1, file_count)
            rm(joinpath(cache.path, _popfirst!(cache.file_keys) * ".jls"))
        end
    end
end

end # module
