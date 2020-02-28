using SerializationCaches
using Documenter

makedocs(modules=[SerializationCaches],
         sitename="SerializationCaches",
         authors="Beacon Biosignals and other contributors",
         pages=["API Documentation" => "index.md"])

# this is commented out until we figure out how to do this privately
# deploydocs(repo="github.com/beacon-biosignals/SerializationCaches.jl.git")
