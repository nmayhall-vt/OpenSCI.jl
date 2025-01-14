using PauliOperators
using OpenSCI

function selected_ci(L::Lindbladian{N}, v::SparseDyadVectors{N,T}; 
    ϵsearch=1e-1, ϵdiscard=1e-4, max_iter_outer=4) where {N,T}

    dim, R = size(v)

    Pv= deepcopy(v)
    
    for n_iter in 1:max_iter_outer
        @printf("\n")
        @printf(" ####################################")
        @printf(" SCI Iteration: %4i\n", n_iter)
        
        σ = multiply(L, Pv, ϵ=ϵsearch)
        

        for (d,c) in σ
            if maximum(abs2.(c)) > ϵdiscard
                # sum!(PLP, d, c)
                sum!(Pv, d, zeros(T, R))
            else
                # sum!(QLP, d, c)
            end
        end

        display(size(Pv))

        Lmat = build_subspace_L(L, Pv)

        F = eigen(Lmat)

        @printf("\n Eigenvalues of Lmat:\n")
        for i in 1:length(F.values)
            @printf(" %4i % 12.8f % 12.8fi\n", i, real(F.values[i]), imag(F.values[i]))
        end

        fill!(Pv, F.vectors[:,end-R+1:end])
    end

end


function multiply(L::Lindbladian{N}, ρ::SparseDyadVectors{N,T}; ϵ=1e-16) where {N,T}
    σ = SparseDyadVectors{N,T}()

    # Unitary part
    for (rdyad, rcoeffs) in ρ

        σi = -1im * (L.H * rdyad - rdyad * L.H)
        
        for i in 1:length(L.γ)
            Li = L.L[i]
            LL = Li' * Li
           
            σi +=  L.γ[i] * (Li * rdyad * Li')
            σi -= 0.5*L.γ[i]*(LL*rdyad + rdyad*LL)
        end
        
        for (ldyad,lcoeff) in σi 
            sum!(σ, ldyad, lcoeff .* rcoeffs )
        end
    end
    return σ 
end

function Base.:*(L::Lindbladian{N}, ρ::SparseDyadVectors{N,T}) where {N,T}
    return multiply(L,ρ)
end

function build_subspace_L(L::Lindbladian{N}, v::SparseDyadVectors{N,T}) where {N,T}
   
    indices = Dict{Dyad{N}, Int}()
    idx = 1
    for (d,c) in v
        indices[d] = idx
        idx += 1
    end

    dim = length(v)
    
    Lmat = zeros(T, dim, dim)

    vi = 0
    # Unitary part
    for rdyad in keys(v)
        vi = indices[rdyad] 

        for (pauli, coeff) in L.H.ops
            
            ldyad = coeff * pauli * rdyad
            if haskey(v, ldyad.dyad) 
                Lmat[indices[ldyad.dyad], vi] += -1im * ldyad.coeff
            end
            
            ldyad = coeff * rdyad * pauli
            if haskey(v, ldyad.dyad) 
                Lmat[indices[ldyad.dyad], vi] += 1im * ldyad.coeff
            end
        end

        
        for i in 1:length(L.γ)
            γ = L.γ[i]
            for (pj, cj) in L.L[i].ops
                for (pk, ck) in L.L[i].ops
                    Pj = pj * cj
                    Pk = pk * ck

                    ldyad = γ * (Pj * rdyad * Pk')
                    if haskey(v, ldyad.dyad) 
                        Lmat[indices[ldyad.dyad], vi] += ldyad.coeff
                    end
                    
                    ldyad = γ * (rdyad * Pj' * Pk)
                    if haskey(v, ldyad.dyad) 
                        Lmat[indices[ldyad.dyad], vi] -= .5 * ldyad.coeff
                    end
                    
                    ldyad = γ * (Pj' * Pk * rdyad)
                    if haskey(v, ldyad.dyad) 
                        Lmat[indices[ldyad.dyad], vi] -= .5 * ldyad.coeff
                    end
                end
            end
        end
    end
    return Lmat 
end


function Base.fill!(sdv::SparseDyadVectors{N,T}, m::Matrix{T}) where {N,T}
    size(sdv) == size(m) || throw(DimensionMismatch)

    ridx = 0
    for (d,coeffs) in sdv
        ridx += 1
        sdv[d] .= m[ridx,:]
    end
    return sdv
end