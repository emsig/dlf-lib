using DataStructures
import JSON

# Create package directories
mkpath("julia/LibDLF/src")
mkpath("julia/LibDLF/test")

# Copy library to Julia package
cp(abspath("../lib"),abspath("julia/LibDLF/src/lib"),force=true)

# Copy README and LICENSE
cp("../README.md", "julia/README.md",force=true)
cp("../LICENSE", "julia/LICENSE",force=true)

# Create Project.toml
iop = open(abspath("julia/LibDLF/Project.toml"), "w")
println(iop,"name = \"LibDLF\"")
println(iop,"uuid = \"f0c3f387-4ff6-435f-9d63-77e28b8d1347\"")
println(iop,"authors = [\"The emsig community <info@emsig.xyz> \"]")
println(iop,"version = \"0.0.0\"") #kwk debug: how to get version in github build?
println(iop,"\n[deps]")
println(iop,"DelimitedFiles = \"8bb1440f-4735-579b-a4ab-409b98df4dab\"")
println(iop,"Memoization = \"6fafb56a-5788-4b4e-91ca-c0cea6611c73\"")
println(iop,"\n[extras]")
println(iop,"Test = \"8dfed614-e22c-5e08-85e1-65c5234f0b40\"")
println(iop,"\n[targets]")
println(iop,"test = [\"Test\"]")
close(iop)

# Read in .json file listing all filters
filters = JSON.parsefile(abspath("julia/LibDLF/src/lib/filters.json"),
                         dicttype=DataStructures.OrderedDict)

# Create Julia module
iol = open(abspath("julia/LibDLF/src/LibDLF.jl"), "w")

# Module name
println(iol,"module LibDLF\n")

# Create LibDLF.jl files
for type in filters.keys

    stype = titlecase(type)

    # Include sub module file in parent
    println(iol, "include(\"$stype.jl\")")

    # Create sub module file for filter type
    iot = open(abspath("julia/LibDLF/src/$stype.jl"), "w")

    println(iot, "module $stype\n")

    # Add used modules
    println(iot, "using DelimitedFiles")
    println(iot, "using Memoization")

    # Add library path variable:
    println(iot, "\nlibpath = @__DIR__")

    # Add filter functions:
    for filt in filters[type]

        # Get and write header as docstring:
        iof = open(abspath("julia/LibDLF/src/" * filt["file"]), "r")

        # Title
        println(iot, "\n\"\"\"")

        sname = filt["name"]
        println(iot, "\t $sname()\n")

        println(iot, readline(iof)[2:end])

        # Get vals and preformat if sin & cos
        vals = replace(filt["values"], "," => ", ")
        # println(typeof(vals))
        if type == "fourier"
            vals = replace(vals, "cos" => "fcos")
            vals = replace(vals, "sin" => "fsin")
        end

        # Rest of header
        for line in eachline(iof)

            # Do not copy the title-underline; just newline
            if contains(line, "========")
                println(iot, "")

            # Empty lines: only remove comment
            elseif line == "#\n"
                println(iot, "")

            # The license is the last thing of the header
            elseif contains(line, "This file is part of libdlf")

                # Add returned vals
                println(iot, "# Returns\n")
                println(iot, "base, $vals :: Array{Float64,1}")
                println(iot, "Filter base and its values.\n")

                # Example
                println(iot, "# Example\n")
                println(iot, "```julia")
                println(iot, "base, $vals = LibDLF.$stype.$sname()")
                println(iot, "```")

                # Finish header
                println(iot, "\n\"\"\"")

                # Stop header loop
                break

            # Print entire line
            else
                println(iot, line[2:end])

            end

        end

        # Print function contents
        println(iot, "@memoize function $sname()")

        sfile  =  filt["file"]
        println(iot,"\tsfile = joinpath(libpath,\"$sfile\")")
        println(iot, "\tdat = readdlm(sfile,comments=true)")
        println(iot, "\tbase, $vals = eachcol(dat)")
        println(iot, "end")

        # Close file
        close(iof)

    end

    # Close filter type sub module:
    println(iot, "\nend")
    close(iot)
end

# Close LibDLF module:
println(iol,"\nend")
close(iol)

# Create testing routine
ior = open(abspath("julia/LibDLF/test/runtests.jl"), "w")
println(ior,"using LibDLF")
println(ior,"using Test\n")
println(ior,"# insert code for @testset blocks and @test unit tests ")
close(ior)
