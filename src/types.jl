using PauliOperators
# using LinearAlgebra
# using Printf
# using Dictionaries
# using StaticArrays

# SparseDyadVectors{N,T} = Dict{Dyad{N}, Vector{T}} 
# function SparseDyadVectors(ds::DyadSum{N,T}) where {N,T}
#     sdv = Dictionary{Dyad{N}, Vector{T}}()
#     for (dyad,coeff) in ds
#         sdv[dyad] = [coeff] 
#     end
#     return sdv
# end

"""
    H::PauliSum{N}
    L::Vector{PauliSum{N}}
    γ::Vector{Float64}

This is general enough to realize infinitesmal evolution of any CPT map. 
`H`: generates unitary evolution 
`L`: Is a vector of Jump operators
`γ`: Is the vector of Jump operator coefficients (diagonal form assumed)
"""
struct Lindbladian{N}
    H::PauliSum{N}          
    L::Vector{PauliSum{N}}
    γ::Vector{Float64}
end

function Lindbladian(N)
    return Lindbladian{N}(PauliSum(N), Vector{PauliSum{N}}([]), Vector{Float64}([]))
end

function Lindbladian(H, L, γ)
    return Lindbladian{N}(H,L,γ)
end

function Base.rand(T::Type{Lindbladian{N}}; nH=2, nL=2) where N
    Λ = Lindbladian(N)
    for i in 1:nH
        opi = rand(ScaledPauli{N})
        opi = opi + opi'
        # Λ.H += opi
        sum!(Λ.H,opi)
    end
    for i in 1:nL
        opi = rand(ScaledPauli{N})
        for j in 1:nL
            opi += rand(ScaledPauli{N})
        end
        push!(Λ.L,opi)
        push!(Λ.γ,rand())
    end
    return Λ
end

function Base.string(Λ::Lindbladian{N}) where N
    out = "H:\n"
    for (p,c) in Λ.H.ops
        out *= @sprintf(" %12.8f + %12.8fi %s\n", real(c), imag(c), p)
    end
    out *= "\n"
    out *= "L:\n"
    for i in 1:length(Λ.L)
        out *= @sprintf("%4i : γ = %12.8f + %12.8fi\n", i, real(Λ.γ[i]), imag(Λ.γ[i]))
        for (p,c) in Λ.L[i].ops
            out *= @sprintf("   %12.8f + %12.8fi %s\n", real(c), imag(c), p)
        end
        # out *= string(Λ.γ[i]) * " : " * string(Λ.L[i]) * "\n"
    end
    return out 
end

Base.display(Λ::Lindbladian) = println(string(Λ))