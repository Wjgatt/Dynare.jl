@enum SymbolType Endogenous Exogenous ExogenousDeterministic Parameter DynareFunction

struct DynareSymbol
    longname::String
    texname::String
    type::SymbolType
    orderintype::Integer
end

SymbolTable = Dict{String, DynareSymbol}

for typ in instances(SymbolType)
    for f in fieldnames(DynareSymbol)
        s = Symbol("get_$(lowercase(string(typ)))_$(f)")
        @eval begin
            function $s(symboltable::SymbolTable)
                symbols = collect(values(symboltable))
                subset = filter(s -> s.type == $typ, symbols)
                sorted_index = sortperm(subset, by = v -> v.orderintype)
                names = [s.$f for s in subset[sorted_index]]
                return names
            end
        end
    end
end