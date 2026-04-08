"""
test_macro_orthogonality.py
Run the informational-sufficiency (orthogonality) test on the 9 macro variables
only, excluding the consumption-inequality measure (C_SD).

Replicates the logic of check_orthogonality.m from DFT2026, but applied to a
9-variable VAR:  G, Ft(1,4), GDP, Surplus, BondYield, RER, CorpProfits,
                 FedFunds, ConsumerConfidence.
"""

import numpy as np
import pandas as pd
from scipy import linalg
from statsmodels.regression.linear_model import OLS
from statsmodels.tools import add_constant
from scipy.stats import f as f_dist

np.random.seed(12345)

# ── 0. Paths ────────────────────────────────────────────────────────────────
DATA_DIR = "Data"
TAB_DIR = "Tables"

# ── 1. Load main dataset ────────────────────────────────────────────────────
print("=== Loading data ===")
data = pd.read_excel(f"{DATA_DIR}/data.xlsx")

start_sample = pd.Timestamp("1981-12-01")
end_sample = pd.Timestamp("2019-12-01")
mask = (data["TIME"] >= start_sample) & (data["TIME"] <= end_sample)
d = data.loc[mask].reset_index(drop=True)

G     = d["FEDGOV"].values
F     = d["F"].values
Y     = d["GDP"].values
SUR   = d["SUR"].values
BONDY = d["x10YBOND"].values
RER   = d["RER"].values
CP    = d["CP_REAL"].values
FFR   = d["FED_FUNDS"].values
CCI   = d["CSCICP03USM665S"].values

# 9 macro variables only (no consumption-inequality measure)
vardata_macro = np.column_stack([G, F, Y, SUR, BONDY, RER, CP, FFR, CCI])
varnames_macro = [
    "Government Spending", "Ft(1,4)", "Real GDP", "Federal Surplus",
    "Bond Yield", "Real Exchange Rate", "Corporate Profits",
    "Fed Funds Rate", "Consumer Confidence",
]
n_var = vardata_macro.shape[1]  # 9
print(f"  Macro-only VAR: {n_var} variables, T={vardata_macro.shape[0]}")


# ── 2. Extract FRED-QD factors ──────────────────────────────────────────────
def prepare_missing(rawdata, tcode):
    """Apply transformation codes to each series (matching MATLAB prepare_missing)."""
    T, N = rawdata.shape
    yt = np.full_like(rawdata, np.nan)
    for i in range(N):
        x = rawdata[:, i].copy()
        tc = int(tcode[i])
        y = np.full(T, np.nan)
        if tc == 1:
            y = x.copy()
        elif tc == 2:
            y[1:] = x[1:] - x[:-1]
        elif tc == 3:
            y[2:] = x[2:] - 2 * x[1:-1] + x[:-2]
        elif tc == 4:
            if np.nanmin(x) > 1e-6:
                y = np.log(x)
            else:
                y[:] = np.nan
        elif tc == 5:
            if np.nanmin(x) > 1e-6:
                lx = np.log(x)
                y[1:] = lx[1:] - lx[:-1]
        elif tc == 6:
            if np.nanmin(x) > 1e-6:
                lx = np.log(x)
                y[2:] = lx[2:] - 2 * lx[1:-1] + lx[:-2]
        elif tc == 7:
            y1 = np.zeros(T)
            y1[1:] = (x[1:] - x[:-1]) / x[:-1]
            y[2:] = y1[2:] - y1[1:-1]
        yt[:, i] = y
    return yt


def remove_outliers(X):
    """Replace outliers (|x - median| > 10*IQR) with NaN."""
    Y = X.copy()
    med = np.nanmedian(X, axis=0)
    Q1 = np.nanpercentile(X, 25, axis=0)
    Q3 = np.nanpercentile(X, 75, axis=0)
    IQR = Q3 - Q1
    Z = np.abs(X - med[np.newaxis, :])
    outlier = Z > (10 * IQR[np.newaxis, :])
    Y[outlier] = np.nan
    return Y


def transform_data(x2, DEMEAN):
    """Demean/standardize (DEMEAN=2: demean and standardize)."""
    T, N = x2.shape
    if DEMEAN == 0:
        return x2.copy(), np.zeros_like(x2), np.ones_like(x2)
    elif DEMEAN == 1:
        mu = np.tile(np.mean(x2, axis=0), (T, 1))
        sd = np.ones_like(x2)
        return x2 - mu, mu, sd
    elif DEMEAN == 2:
        mu = np.tile(np.mean(x2, axis=0), (T, 1))
        sd = np.tile(np.std(x2, axis=0, ddof=1), (T, 1))
        return (x2 - mu) / sd, mu, sd
    elif DEMEAN == 3:
        mu = np.full_like(x2, np.nan)
        for t in range(T):
            mu[t, :] = np.mean(x2[: t + 1, :], axis=0)
        sd = np.tile(np.std(x2, axis=0, ddof=1), (T, 1))
        return (x2 - mu) / sd, mu, sd


def pc2(X, nfac):
    """PCA via SVD (matches MATLAB pc2)."""
    N = X.shape[1]
    U, S, Vt = np.linalg.svd(X.T @ X, full_matrices=False)
    lam = U[:, :nfac] * np.sqrt(N)
    fhat = X @ lam / N
    return fhat, lam, S


def baing(X, r, jj):
    """Select number of factors via information criterion (matches MATLAB baing).

    Returns ic1 (selected number of factors) and Fhat (T x r factor matrix).
    """
    T, N = X.shape
    NT = N * T
    NT1 = N + T
    GCT = min(N, T)

    # Penalty term for each possible number of factors (1..r)
    ii = np.arange(1, r + 1, dtype=float)
    if jj == 1:
        CT = np.log(NT / NT1) * ii * NT1 / NT
    elif jj == 2:
        CT = (NT1 / NT) * np.log(GCT) * ii
    elif jj == 3:
        CT = ii * np.log(GCT) / GCT

    # SVD
    if T < N:
        ev_mat, eigval_mat, _ = np.linalg.svd(X @ X.T, full_matrices=False)
        Fhat0 = np.sqrt(T) * ev_mat
        Lambda0 = X.T @ Fhat0 / T
    else:
        ev_mat, eigval_mat, _ = np.linalg.svd(X.T @ X, full_matrices=False)
        Lambda0 = np.sqrt(N) * ev_mat
        Fhat0 = X @ Lambda0 / N

    # Evaluate IC for each number of factors
    Sigma = np.zeros(r + 1)
    IC1 = np.zeros(r + 1)
    for i in range(r, 0, -1):
        Fhat_i = Fhat0[:, :i]
        lam_i = Lambda0[:, :i]
        chat_i = Fhat_i @ lam_i.T
        ehat_i = X - chat_i
        Sigma[i - 1] = np.mean(np.sum(ehat_i * ehat_i / T, axis=0))
        IC1[i - 1] = np.log(Sigma[i - 1]) + CT[i - 1]

    # No-factor case
    Sigma[r] = np.mean(np.sum(X * X / T, axis=0))
    IC1[r] = np.log(Sigma[r])

    # Select number that minimizes IC
    ic1 = np.argmin(IC1) + 1  # 1-indexed count
    if ic1 > r:
        ic1 = 0

    return ic1


def factors_em(x, kmax, jj=2, DEMEAN=2, maxit=50):
    """EM algorithm for factor extraction (matches MATLAB factors_em)."""
    T, N = x.shape
    x1 = np.isnan(x)

    # Initialize: fill missing with column mean
    col_mean = np.nanmean(x, axis=0)
    x2 = x.copy()
    for j in range(N):
        x2[np.isnan(x2[:, j]), j] = col_mean[j]

    x3, mut, sdt = transform_data(x2, DEMEAN)

    # Initial IC selection
    icstar = kmax

    fhat, lam, _ = pc2(x3, icstar)
    chat0 = fhat @ lam.T
    err = 999.0
    it = 0

    while err > 1e-6 and it < maxit:
        it += 1
        # Update missing values
        chat_unscaled = chat0 * sdt + mut
        for t in range(T):
            for j in range(N):
                if x1[t, j]:
                    x2[t, j] = chat_unscaled[t, j]
                else:
                    x2[t, j] = x[t, j]

        x3, mut, sdt = transform_data(x2, DEMEAN)

        # IC-based factor selection (matches MATLAB baing call)
        icstar = baing(x3, kmax, jj)
        if icstar == 0:
            icstar = kmax  # fallback

        fhat, lam, _ = pc2(x3, icstar)
        chat = fhat @ lam.T
        diff = chat - chat0
        err = np.sum(diff ** 2) / np.sum(chat0 ** 2)
        chat0 = chat
        print(f"  EM iteration {it}: err={err:.8f}, nfac={icstar}")

    return fhat


print("\n=== Estimating factors from FRED-QD ===")
fred = pd.read_csv(f"{DATA_DIR}/FRED-QD.csv")
tcode = fred.iloc[1, 1:].values.astype(float)  # row index 1 = "transform"
rawdata_all = fred.iloc[2:, 1:].values.astype(float)  # from row 2 onwards = actual data

# Determine sample range in quarters
# FRED-QD starts 1981Q2 (row index 2 = "06/01/1981" which is 1981-Q2)
# We need 1981Q4 to 2019Q4
# 1981Q2 = row 0 of rawdata_all
# 1981Q4 = row 2 of rawdata_all (Q2->Q3->Q4)
# ... but the MATLAB code uses dates to slice. Let's match it:
# initial_quarter = 4 (Dec), initial_year = 1981
# final_quarter = 4 (Dec), final_year = 2019
# dates = (1981 + (4-2)/4 : 1/4 : 2019 + 4/4)' = (1981.5 : 0.25 : 2020.0)
# T = number of elements in dates

initial_year, initial_quarter = 1981, 4
final_year, final_quarter = 2019, 4
dates = np.arange(
    initial_year + (initial_quarter - 2) / 4,
    final_year + final_quarter / 4 + 0.001,
    0.25,
)
T_fred = len(dates)
rawdata = rawdata_all[:T_fred, :]

# Apply transformations
yt = prepare_missing(rawdata, tcode)
yt = yt[2:, :]  # remove first 2 rows (lost to differencing), matches MATLAB yt=yt(3:T,:)
yt = remove_outliers(yt)

# Extract up to 9 factors
kmax = 9
factor = factors_em(yt, kmax, jj=2, DEMEAN=2)

print(f"  Factors shape: {factor.shape}")


# ── 3. VAR estimation and Cholesky shock extraction ─────────────────────────
def lagmatrix(x, lags):
    """Create lagged matrix (matching MATLAB lagmatrix)."""
    if x.ndim == 1:
        x = x.reshape(-1, 1)
    T, k = x.shape
    n_lags = len(lags)
    xlag = np.zeros((T, k * n_lags))
    for c, lag in enumerate(lags):
        cols = slice(k * c, k * (c + 1))
        if lag > 0:
            xlag[lag:, cols] = x[:-lag, :]
            xlag[:lag, cols] = 0.0  # pad with 0 (matching MATLAB missingValue=0)
        elif lag < 0:
            alag = abs(lag)
            xlag[:-alag, cols] = x[alag:, :]
            xlag[-alag:, cols] = 0.0
        else:
            xlag[:, cols] = x
    return xlag


def var_ols(data, p, c, t):
    """OLS VAR estimation (matches MATLAB VAR.m)."""
    T_full = data.shape[0]
    Y = data[p:, :]
    lag_mat = lagmatrix(data, list(range(1, p + 1)))
    X = lag_mat[p:, :]  # remove first p rows

    if c == 1 and t == 0:
        X = np.column_stack([np.ones(X.shape[0]), X])
    elif c == 0 and t == 1:
        dt = np.arange(1, X.shape[0] + 1, dtype=float).reshape(-1, 1)
        X = np.column_stack([dt, X])
    elif c == 1 and t == 1:
        dt = np.arange(1, X.shape[0] + 1, dtype=float).reshape(-1, 1)
        X = np.column_stack([np.ones(X.shape[0]), dt, X])

    pi_hat = np.linalg.lstsq(X, Y, rcond=None)[0]
    Yfit = X @ pi_hat
    err = Y - Yfit
    return pi_hat, Y, X, err


def chol_irf(data, n, p, c, t, hor):
    """Cholesky IRF and structural shock extraction (matches MATLAB chol_irf.m)."""
    pi_hat, Y, X, err = var_ols(data, p, c, t)

    # Companion matrix
    coef = pi_hat[c + t :, :]  # remove intercept/trend rows
    BigA = np.zeros((n * p, n * p))
    BigA[:n, :] = coef.T
    if n * p > n:
        BigA[n:, : n * (p - 1)] = np.eye(n * p - n)

    # Wold IRFs
    C = np.zeros((n, n, hor))
    BigC = np.eye(n * p)
    for j in range(hor):
        C[:, :, j] = BigC[:n, :n]
        BigC = BigC @ BigA

    # Cholesky decomposition
    omega = np.cov(err, rowvar=False, bias=False)
    # Match MATLAB's cov() which uses N-1 normalization: np default with bias=False
    S = linalg.cholesky(omega, lower=True)

    # Structural shocks
    eta = (np.linalg.solve(S, err.T)).T  # (T-p) x n

    return eta


# ── 4. Orthogonality (informational sufficiency) test ───────────────────────
def check_orthogonality(macro_data, factor, p=4, c=1, t=0, hor=17):
    """
    Test informational sufficiency (Forni & Gambetti 2014).

    Regresses Cholesky surprise (shock 1) and news (shock 2) on lags 1, 1:2,
    1:3, 1:4 of each principal component. Reports F-test p-values.
    """
    n = macro_data.shape[1]
    n_pc = factor.shape[1]
    T_f = factor.shape[0]

    # Extract OLS Cholesky shocks
    eta = chol_irf(macro_data, n, p, c, t, hor)

    # Build lagged factor matrices for each PC
    # factor_lags[:, lag, pc]
    factor_lags = np.zeros((T_f, p, n_pc))
    for i in range(n_pc):
        fl = lagmatrix(factor[:, i], list(range(1, p + 1)))
        factor_lags[:, :, i] = fl

    # Trim to match eta length: after removing p initial obs
    factor_trimmed = factor_lags[p:, :, :]

    pval_surp = np.full((n_pc, 4), np.nan)
    pval_news = np.full((n_pc, 4), np.nan)

    for i in range(n_pc):
        X_all = factor_trimmed[:, :, i]  # (T-p) x p
        for j in range(4):  # lag groups: 1, 1:2, 1:3, 1:4
            X = add_constant(X_all[:, : j + 1])

            # Surprise shock (col 0)
            mdl_s = OLS(eta[:, 0], X).fit()
            pval_surp[i, j] = mdl_s.f_pvalue

            # News shock (col 1)
            mdl_n = OLS(eta[:, 1], X).fit()
            pval_news[i, j] = mdl_n.f_pvalue

    return pval_surp, pval_news


# ── 5. Run the test ─────────────────────────────────────────────────────────
print("\n=== Orthogonality test: MACRO VARIABLES ONLY (9 vars, no C_SD) ===")
pval_surp, pval_news = check_orthogonality(vardata_macro, factor, p=4, c=1, t=0, hor=17)

n_pc_show = min(7, factor.shape[1])


def get_stars(p):
    if p < 0.01:
        return "***"
    elif p < 0.05:
        return "**"
    elif p < 0.10:
        return "*"
    return ""


# ── 6. Display results ──────────────────────────────────────────────────────
print()
print("Orthogonality test: Macro variables only (9-variable VAR)")
print("Variables: G, Ft(1,4), GDP, Surplus, BondYield, RER, CorpProfits, FFR, ConsConf")
print("* p < 0.10, ** p < 0.05, *** p < 0.01\n")
print("       Surprise shock                    |       News shock")
print("  PC  Lag1    Lag1:2  Lag1:3  Lag1:4  |  PC  Lag1    Lag1:2  Lag1:3  Lag1:4")
print("-" * 80)

for i in range(n_pc_show):
    row_s = ""
    for j in range(4):
        p = pval_surp[i, j]
        stars = get_stars(p)
        row_s += f"{p:.2f}{stars}".ljust(8)
    row_n = ""
    for j in range(4):
        p = pval_news[i, j]
        stars = get_stars(p)
        row_n += f"{p:.2f}{stars}".ljust(8)
    print(f"  {i+1}   {row_s}| {i+1}   {row_n}")

print()

# ── 7. Save to file ─────────────────────────────────────────────────────────
import os
os.makedirs(TAB_DIR, exist_ok=True)
outpath = os.path.join(TAB_DIR, "Table_MacroOnly_Orthogonality.txt")
with open(outpath, "w") as fid:
    fid.write("Orthogonality test: Macro variables only (9-variable VAR)\n")
    fid.write("Variables: G, Ft(1,4), GDP, Surplus, BondYield, RER, CorpProfits, FFR, ConsConf\n")
    fid.write("* p < 0.10, ** p < 0.05, *** p < 0.01\n\n")
    fid.write("       Surprise shock                    |       News shock\n")
    fid.write("  PC  Lag1    Lag1:2  Lag1:3  Lag1:4  |  PC  Lag1    Lag1:2  Lag1:3  Lag1:4\n")
    fid.write("-" * 80 + "\n")
    for i in range(n_pc_show):
        row_s = ""
        for j in range(4):
            p = pval_surp[i, j]
            stars = get_stars(p)
            row_s += f"{p:.2f}{stars}".ljust(8)
        row_n = ""
        for j in range(4):
            p = pval_news[i, j]
            stars = get_stars(p)
            row_n += f"{p:.2f}{stars}".ljust(8)
        fid.write(f"  {i+1}   {row_s}| {i+1}   {row_n}\n")

print(f"Table saved to: {outpath}")
