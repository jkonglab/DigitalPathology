
module ColorDecon
using Images

"""
    mu_nmf(Y::Matrix{Float64}, A::Matrix{Float64}, X::Matrix{Float64}; ω=1,
    αsA=0 , αsX=0, maxiter=1000, cost="euclidean", normalization="LInf",
    tol=1e-8, verbose=false)
Non-negative matrix factorization using multiplicative updates. Modified
from alforithm 3.D.3 in Cichocki, 2009
"""
function mu_nmf(Y::Matrix{Float64}, A::Matrix{Float64}, X::Matrix{Float64};
                ω=1, αsA=0 , αsX=0, maxiter=1000, cost="euclidean",
                normalization="LInf", tol=1e-8, verbose=false)
    I,T = size(Y)
    J = size(A,2)

    # cost function
    if cost == "kl"
        cost_fn = (Y,Y_hat) -> sum(Y.*log.(Y./Y_hat)-Y+Y_hat) #KL-divergence
    elseif cost == "euclidean"
        cost_fn = (Y,Y_hat) -> (vecnorm(Y-Y_hat,2)^2)/2 #Euclidean
    else
        error("cost function does not exist")
    end

    # normalize A
    if normalization == "L1"
        norm_fn = (A) -> A = A./sum(A,1) #L1-norm
    elseif normalization == "L2"
        norm_fn = (A) -> A./sqrt.(sum(A.^2,1)) #L2-norm
    elseif normalization == "LInf"
        norm_fn = (A) -> A = A./maximum(A,1) #LInf-norm
    else
        error("normalization function does not exist")
    end

    A_e = norm_fn(A)

    # initialize
    Yhwr = max.(eps(),Y)
    Yhwr_hat = zeros(I,T)
    err = [Inf]
    X_e = copy(X)
    sY = sum(Y,2)

    # start minimization
    for iter = 0:(maxiter-1)
        # new estimate
        Yhwr_hat .= max.(eps(),A_e*X_e)

        # updates
        if cost == "kl"
            X_e .= (X_e .* (A_e.'*(Yhwr./Yhwr_hat)).^ω).^(1+αsX)
            # A_e .= (A_e .* ((Yhwr./Yhwr_hat)*X_e.').^ω).^(1+αsA)
        elseif cost == "euclidean"
            X_e .= X_e .* (A_e.' * Yhwr) ./ (A_e.' * Yhwr_hat + αsX)
            # A_e .= A_e .* (Yhwr * X_e.') ./ (Yhwr_hat * X_e.' + αsA)
        end
        # A_e = norm_fn(A_e)

        # correct for negatives
        @. X_e = max(eps(),X_e)
        # @. A_e = max(eps(),A_e)

        # error
        if (mod(iter,20) == 0) || (iter == maxiter)
            append!(err, cost_fn(Yhwr,Yhwr_hat))
            Δ = abs(err[end] - err[end-1])
            verbose && println(err[end])

            if (err[end] < 1e-5) | (Δ < tol)
                break
            end
        end
    end

    return A_e, X_e, err[2:end]
end

function color_decon(A::Matrix{Float64},img::Array{Float64,3})
    I,ty,tx = size(img)
    T = ty*tx
    J = size(A,2)

    # prep inputs to NMF
    Y = reshape(img,I,T)
    X_estimate = max.(eps(),rand(J,T))

    # deconvolution
    A_estimate, X_estimate, err = mu_nmf(Y,A,X_estimate; ω=1.5, αsX=0.005)

    # return image converted from weights
    return Gray.(reshape(X_estimate.',(ty,tx,J)))

end
end
