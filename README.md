[![CI](https://github.com/dhanak/InlineDispatch.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/dhanak/InlineDispatch.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/dhanak/InlineDispatch.jl/branch/master/graph/badge.svg?token=CQYSC7NLOT)](https://codecov.io/gh/dhanak/InlineDispatch.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

# InlineDispatch.jl

A simple module to perform dispatch on a value of an expression using the
`@dispatch` macro.

```julia
    @dispatch expr begin
        v::Type1 -> body1...
        v::Type2 -> body2...
    end
```

Perform a dispatch on the value of `expr`.

The dispatch uses the anonymous functions in the block as methods, and returns
the value of the appropriate body expression. The order of the functions doesn't
matter, the most specific match is chosen, as customary with Julian dispatch.

# Examples

```julia
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
ERROR: @dispatch: Unmatched type String!
```

It can be particularly useful in `try ... catch` blocks to handle various types
of errors.

```julia
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
