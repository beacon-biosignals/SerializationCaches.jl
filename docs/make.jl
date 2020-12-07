using SerializationCaches
using Documenter

makedocs(modules=[SerializationCaches],
         sitename="SerializationCaches",
         authors="Beacon Biosignals and other contributors",
         pages=["API Documentation" => "index.md"])

deploydocs(repo="github.com/beacon-biosignals/SerializationCaches.jl.git")
