using Test, SerializationCaches, OrderedCollections, Serialization

@testset "`SerializationCache`" begin
    mktempdir() do tmp
        in_memory_limit = 5
        file_limit, file_gc_ratio = 10, 0.1
        total_limit = in_memory_limit + file_limit
        offset = 3
        cache = SerializationCache(tmp; in_memory_limit=in_memory_limit,
                                   file_limit=file_limit,
                                   file_gc_ratio=file_gc_ratio)
        range = 1:(total_limit + offset)
        for i in range
            @test i == fetch!(() -> i, cache, string(i))
        end
        file_keys = string.((offset + 1):(offset + file_limit))
        @test cache.file_keys == OrderedSet(file_keys)
        in_memory_keys = string.((offset + file_limit + 1):(offset + file_limit + in_memory_limit))
        @test all(keys(cache.in_memory) .== in_memory_keys)
        let hits = 0
            for r in (range, reverse(range))
                hits += length(r)
                for i in r
                    @test i == fetch!(cache, string(i)) do
                        hits -= 1
                        return i
                    end
                end
            end
            @test hits == 10
            @test cache.file_keys == OrderedSet(["15", "14", "13", "12", "11", "10", "9", "8", "7", "6"])
            @test all(keys(cache.in_memory) .== ["5", "4", "3", "2", "1"])
        end
        put_range = (total_limit + offset):(total_limit + offset + total_limit)
        for i in put_range
            put!(cache, string(i), ()-> i)
        end
        @test all(keys(cache.in_memory) .== ["29", "30", "31", "32", "33"])
        @test cache.file_keys == OrderedSet(["19", "20", "21", "22", "23", "24", "25", "26", "27", "28"])

        @test isdir(set_up_cache_path(joinpath(tmp, "big/made/up/path")))
    end
end

struct NoFile
    i::Int
end

# Test that when `in_memory_limit` is 0, deserializing an existing file does not
# (redundantly) call `put`
function Base.put!(cache::SerializationCache, key::AbstractString, item::NoFile;
                   directly_to_file::Bool=false)
   throw(error("Should not hit this!"))
end

@testset "No in_memory_limit" begin
    mktempdir() do tmp
        in_memory_limit = 0
        file_limit, file_gc_ratio = 10, 0.1

        # Set up existing cache
        range = 1:file_limit
        for i in range
            serialize(joinpath(tmp, "$i.jls"), NoFile(i))
        end

        # Set up cache
        cache = SerializationCache(tmp; in_memory_limit=0,
                                   file_limit=file_limit, file_gc_ratio=file_gc_ratio)

        # Now test that `fetch!()` never calls `put`, since it should be able to
        # grab all files
        for i in range
            @test NoFile(i) == fetch!(() -> (error("shouldn't need to call this...")), cache, string(i))
        end
    end
end
