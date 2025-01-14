using PauliOperators
using OpenSCI 
using LinearAlgebra
using Printf
using Plots 
using Dictionaries
using StaticArrays


function Base.:*(L::Linbladian{N}, v::DyadSum{N,T}) where {N,T}
    w = -1im * (L.H*v - v*L.H)
    
    for i in 1:length(L.L)
       w += L.γ[i] * (L.L[i] * (v * L.L[i]'))
       LL = L.L[i]' * L.L[i] 
       w -= L.γ[i]/2 * (v * LL + LL * v)
    end
    return w
end

function SparseDyadVectors(ds::DyadSum{N,T}, R=1) where {N,T}
    sdv = Dictionary{Dyad{N}, SizedVector{R,T}}()
    for (dyad,coeff) in ds
        sdv[dyad] = SizedVector{R}(zeros(T,R))
        sdv[dyad][1] = coeff
    end
    return sdv
end



function build_full_hamiltonian(ω,λ,g,N)
    "https://www.uni-ulm.de/fileadmin/website_uni_ulm/nawi.inst.260/%C3%9Cbungen/6Spin_Boson_Modell.pdf"
    Hs = PauliSum(1)
    Hb = PauliSum(N)
    bi = boson_binary_transformation(N)'

    Hs += ω/2 * Pauli(1,Z=[1]) 
    Hb = ω * bi' * bi 
    H = Hs ⊕ Hb

    σᶻ = PauliSum(Pauli("Z"))
    σ⁺ = .5*(Pauli("X") + 1im*Pauli("Y"))
    σ⁻ = σ⁺' 
    Hc = g * (σ⁺⊗bi + σ⁻⊗bi')
    Hc += λ * σᶻ ⊗ (bi'+bi)
    clip!(Hc)
    # println("Hc")
    # display(Hc)
    H += Hc 
    return H
end

# function linbladian_matvec(H, L, γ, ρ)
    
#     length(L) == length(γ) || throw(DimensionMismatch)

#     dρ = -1im * (H*ρ - ρ*H)
    
#     for i in 1:length(L)
#        dρ += γ[i] * (L[i] * (ρ * L[i]'))
#        LL = L[i]' * L[i] 
#        dρ -= γ[i]/2 * (ρ * LL + LL * ρ)
#     end
#     return dρ
# end

function build_lindbladian_action(H, L, γ, vin::Dict{Dyad,Vector})
    #
    # L(ik,ρ) = sum_h c_h |i><k|P_h|j><l|
    # 
    length(L) == length(γ) || throw(DimensionMismatch)

    ρ = -1im * (H*ρ - ρ*H)
    
    for i in 1:length(L)
       dρ += γ[i] * (L[i] * (ρ * L[i]'))
       LL = L[i]' * L[i] 
       dρ -= γ[i]/2 * (ρ * LL + LL * ρ)
    end
    return dρ

    ndim = length(r)
    Lmat = zeros(ComplexF64, ndim, ndim)
    for (idr, dyad_r) in enumerate(keys(r))
        for (idl, dyad_l) in enumerate(keys(r))
            for (pauli, pcoeff) in H
                sigma_dyad = pauli*r[dr] # finish working this out!
                val = -1im
            end
        end
    end
end
    
function build_subspace_lindbladian(H, L, γ, ρ)

    #
    # sum_h c_h |i><k|P_h|j><l|
    # 

    r = SparseDyadVectors(ρ)
    ndim = length(r)
    Lmat = zeros(ComplexF64, ndim, ndim)
    for (idr, dyad_r) in enumerate(keys(r))
        for (idl, dyad_l) in enumerate(keys(r))
            for (pauli, pcoeff) in H
                sigma_dyad = pauli*r[dr] # finish working this out!
                val = -1im
            end
        end
    end
end
    
function run()
    ω0 = 1
    N = 4
    g = .1 # σ⁺b + σ⁻b'    
    λ = .1 # σᶻ(b + b')    

    ρ = Dyad(1,0,0)
    @printf(" Initial Density: %s\n", ρ)

    H = ω0*PauliSum(Pauli("X"))
    σ⁻ = .5*(Pauli("X") + -1im*Pauli("Y"))
    σᶻ = PauliSum(Pauli("Z"))
    γ = Vector{Float64}([])
    L = Vector{PauliSum{1}}([])
    
    push!(L, σ⁻)
    push!(L, σᶻ)
    push!(γ, .1)
    push!(γ, .1)
    Lind = Lindbladian(H,L,γ)
    # dρ = linbladian_matvec(H, L, γ, ρ)
    println()
    @printf(" ∂ₜρ %s\n", dρ)
    display(Matrix(ρ))
    sz_vals = []
    tr_vals = Vector{ComplexF64}([])

    stepsize = .001
    nsteps = 20000
    for i in 1:nsteps
        push!(sz_vals, tr(Matrix(ρ)*Matrix(Pauli("Z"))))
        push!(tr_vals, tr(Matrix(ρ*ρ)))
        ρ += stepsize * linbladian_matvec(H, L, γ, ρ)
    end
    display(Matrix(ρ))
    println(" tr(ρ): ", tr(Matrix(ρ)))
    plot(sz_vals)
    plot!(abs.(tr_vals))
    savefig("./plot.pdf")

    println()
    println(" Now obtain steady state via diagonalization.")
    

end

function run2()
    ω0 = 1
    N = 4
    g = .1 # σ⁺b + σ⁻b'    
    λ = .1 # σᶻ(b + b')    
    H = build_full_hamiltonian(ω0, λ, g, N)

    # println("H")
    # display(H)

    e,v = eigen(Matrix(H))
    nstates = min(length(e),5)
    println(" Eigenvalues")
    for i in 1:nstates
        @printf(" %3i %12.8f + %12.8fi\n",i,real(e[i]), imag(e[i]))
    end

    for i in 1:nstates
        println("\n State ", i)
        v0 = v[:,i]
        v0 = reshape(v0,(2,2^N))
        ρ = v0*v0'
        Z = Matrix(Pauli("Z"))
        println(" ρ:")
        ρ = round.(real(ρ),digits=3)
        
        display(round.(real(ρ),digits=3))

        sz = tr(ρ*Z)
        @printf(" tr(Sz,ρ) = %12.8f %12.8fi\n", real(sz), imag(sz))
    end
end
run()