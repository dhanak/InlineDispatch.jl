"""
A simple module to perform dispatch on the value of an expression using the
`@dispatch` macro.
"""
module InlineDispatch

using Base: remove_linenums!

export @dispatch

"""
    @dispatch expr begin
        v::Type1 -> body1...
        v::Type2 -> body2...
    end

Perform a dispatch on the value of `expr`.

The dispatch uses the anonymous functions in the block as methods, and returns
the value of the appropriate body expression. The order of the functions doesn't
matter, the most specific match is chosen, as customary with Julian dispatch.

# Examples

```jldoctest
julia> @dispatch 42 begin
           i::Integer -> "int \$i"
           r::Real    -> "real \$r"
           ::Nothing  -> "nothing"
       end
"int 42"

julia> @dispatch π begin
           i::Integer -> "int \$i"
           r::Real    -> "real \$r"
           ::Nothing  -> "nothing"
       end
"real π"

julia> @dispatch "foo" begin
           i::Integer -> "int \$i"
           r::Real    -> "real \$r"
           ::Nothing  -> "nothing"
       end
ERROR: @dispatch: Unmatched type String! @ REPL[3]:1
```

It can be particularly useful in `try ... catch` blocks to handle various types
of errors.

```julia-repl
julia> try
           do_some_stuff()
       catch exn
           @dispatch exn begin
               e::AssertionError -> println(stderr, "AssertionError: ", e.msg)
               ::InexactError    -> println(stderr, "InexactError")
               _                 -> rethrow()
           end
       end
```
"""
macro dispatch(expr, body)
    @assert(body isa Expr && body.head == :block,
            "begin ... end block expected in second argument!")
    fn = gensym("dispatch#$expr")
    has_any = false
    methods::Vector{Union{Expr, LineNumberNode}} = map(body.args) do ex
        ex isa LineNumberNode && return ex
        @assert Meta.isexpr(ex, :->, 2) "Anonymous function expected!"
        (matcher, handler) = ex.args
        has_any |= matcher isa Symbol
        has_any |= Meta.isexpr(matcher, :(::)) && matcher.args[end] === :Any
        return Expr(:(=), Expr(:call, fn, matcher), handler)
    end
    loc = string(__source__.file, ':', __source__.line)
    unmatched = :(error("@dispatch: Unmatched type $(T)! @ ", $loc))
    fallback = Expr(:(=),
                    Expr(:where, Expr(:call, fn, Expr(:(::), :T)), :T),
                    Expr(:block, __source__, unmatched))
    return Expr(:let,
                has_any ? Expr(:(::), fn, :Function) : fallback,
                Expr(:block, methods..., Expr(:call, fn, expr))) |> esc
end

end # module InlineDispatch
