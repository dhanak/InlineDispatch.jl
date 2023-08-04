using Aqua
using InlineDispatch
using Test

@testset "Aqua            " begin
    Aqua.test_all(InlineDispatch)
end

@testset "@dispatch values" begin
    let err = VERSION < v"1.8" ? LoadError : "function expected"
        @test_throws err @eval @dispatch nothing begin :foo end
    end

    function dispatch_test(v)
        return @dispatch v begin
            ::Integer -> :integer
            f::Real   -> string(f)
            s::String -> Symbol(s)
            v         -> v
        end
    end

    @test dispatch_test(1)     === :integer
    @test dispatch_test(2.0)   === "2.0"
    @test dispatch_test("foo") === :foo
    @test dispatch_test('c')   === 'c'
end

@testset "@dispatch errors" begin
    function catch_test(f)
        try
            f()
        catch e
            @dispatch e begin
                e::AssertionError -> println(stderr, "AssertionError: ", e.msg)
                ::InexactError    -> println(stderr, "InexactError")
                ::Exception       -> rethrow()
            end
        end
    end

    @test_warn   "AssertionError: false" catch_test(() -> @assert false)
    @test_warn   "InexactError"          catch_test(() -> Int(12.5))
    @test_throws ErrorException("foo")   catch_test(() -> error("foo"))
    @test_throws(ErrorException("@dispatch: Unmatched type String!"),
                 catch_test(() -> throw("bar")))
end
