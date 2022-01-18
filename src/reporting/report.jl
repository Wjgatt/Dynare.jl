import Base.print
using Dates
using Tokenize

struct Graph
    filename::String
end

Base.print(io::IO, s::Graph) = print(
    io,
    "\\begin{centering}\\includegraphics[scale=0.6]{$(s.filename)}\\vspace{30pt}\\end{centering}\n",
)

struct Paragraph
    text::String
end

Base.print(io::IO, s::Paragraph) = print("$(s.text)\n")

struct Table
    string::String
    function Table(data, title, column_header, row_header, note)
        data = vcat(hcat("", column_header), hcat(row_header, data))
        string =
            dynare_table(data, title, note, backend = :latex)
        new(string)
    end
end

Base.print(io::IO, s::Table) = print(io, "$(s.string)\n")


struct Page
    sections::Vector{Any}
end

Page() = Page(Vector{Any}(undef, 0))
Page(s::String) = Page([Paragraph(s)])
Page(t::Table) = Page([t])
Page(g::Graph) = Page([g])

function print(io::IO, p::Page)
    for s in p.sections
        @show s
        print(io, s)
    end
end

struct Report
    title::String
    subtitle::String
    pages::Vector{Page}
    function Report(title::String; subtitle::String = "")
        pages = Vector{Page}(undef, 0)
        new(title, subtitle, pages)
    end
end

function add_page!(report::Report, page::Page)
    push!(report.pages, page)
end

function add_graph!(page::Page, graph::Graph)
    push!(page.sections, graph)
end

function add_model!(page::Page, context)
    model = modelprintout(context.modfileinfo.modfilepath,
                          context.symboltable,
                          context.work.params)
    push!(page.section, model)
end
          
function add_paragraph!(page::Page, paragraph::String)
    push!(page.sections, paragraph)
end

function add_table!(page::Page, table::Table)
    push!(page.sections, table)
end

function print(report::Report; texfilename::String = "report.tex")
    open(texfilename, "w") do io
        print(io, "\\documentclass{report}\n")
        print(io, "\\usepackage{graphicx}\n")
        print(io, "\\usepackage{stackrel}")
        print(io, "\\usepackage{threeparttable}\n")
        print(io, "\\begin{document}\n")
        print(io, "\\vspace*{0.2\\textheight}\n")
        print(io, "\\begin{center}\n")
        print(io, "\\Large\\textbf{$(report.title)}\\\\\n")
        print(io, "\\medskip\n")
        if length(report.subtitle) > 0
            print(io, "\\large $(report.subtitle)\n")
            print(io, "\\medskip\n")
        end
        print(io, "\\end{center}\n")
        print(io, "$(Dates.now())\\\\\n")
        print(io, "\\clearpage\n")
        for (i, page) in enumerate(report.pages)
            print(io, page)
            if i < length(report.pages)
                print(io, "\\newpage\n")
            end
        end
        print(io, "\\end{document}")
    end

    latex = `pdflatex $texfilename`
    run(latex)
end

    function modelprintout(modname::String, symboltable::SymbolTable, parameters_value::Vector{Float64})
        
    elements = []
    linenumber = 1
    for token in tokenize(modname)
        stringtoken = Tokens.untokenize(token)
        if Tokens.kind(token) == Tokens.IDENTIFIER
            if stringtoken in keys(symboltable)
                if is_parameter(stringtoken, symboltable)
                    k = symboltable[stringtoken].orderintype
                    stringtoken = "|\$ \\stackrel[($(parameters_value[k]))]{}{\\hbox{$(stringtoken)}}\$\\verb|"
                end
            end
        end
        push!(elements, stringtoken)
        if startswith(stringtoken, "\n")
            printfmt(io, "\\verb|{:4d}: {:s}|\n\n", linenumber, join(elements[1:end-1]))
            if length(stringtoken) > 1
                elements = [stringtoken[2:end]]
            else
                elements = []
            end
            linenumber += 1
        end
    end
    return nothing
end
