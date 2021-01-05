using Dynare_preprocessor_jll

function dynare_preprocess(modfilename, args)
    dynare_args = [basename(modfilename), "language=julia", "output=third", "json=compute"]
    offset = 0
    for a in args
        astring = string(a)
        if (!occursin(r"^output=", astring)
            && !occursin(r"^json=", astring))
            push!(dynare_args, astring)
        end
    end
    println(dynare_args)
    run_dynare(modfilename, dynare_args)
end

function run_dynare(modfilename, dynare_args)
    directory = dirname(modfilename)
    if length(directory) > 0
        current_directory = pwd()
        cd(directory)
    end
    dynare_m() do dynare_m_path
        run(`$dynare_m_path $dynare_args`)
    end
    if length(directory) > 0
        cd(current_directory)
    end
end    
