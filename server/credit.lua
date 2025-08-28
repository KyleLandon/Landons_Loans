local QBCore = exports['qb-core']:GetCoreObject()

-- Credit Score Calculation Functions

-- Initialize credit score for new player
local function InitializeCreditScore(citizenid)
    local result = MySQL.single.await('SELECT citizenid FROM landons_credit_scores WHERE citizenid = ?', {citizenid})
    
    if not result then
        MySQL.insert('INSERT INTO landons_credit_scores (citizenid, score, payment_history_points) VALUES (?, ?, ?)', {
            citizenid, Config.DefaultCreditScore, 150
        })
        return Config.DefaultCreditScore
    end
    
    return result.score
end

-- Calculate liquidity points based on bank balance
local function CalculateLiquidityPoints(citizenid)
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    local balance = 0
    
    if Player then
        balance = Player.PlayerData.money.bank
    else
        -- Get balance from database for offline player
        local result = MySQL.single.await('SELECT money FROM players WHERE citizenid = ?', {citizenid})
        if result then
            local moneyData = json.decode(result.money)
            balance = moneyData.bank or 0
        end
    end
    
    -- Cap balance at 500k for calculation
    local cappedBalance = math.min(balance, Config.CreditPoints.liquidity.cap)
    local points = (cappedBalance / Config.CreditPoints.liquidity.cap) * Config.CreditPoints.liquidity.maxPoints
    
    return math.floor(points)
end

-- Calculate active loan points
local function CalculateActiveLoanPoints(citizenid)
    local loans = MySQL.query.await('SELECT COUNT(*) as count, SUM(balance) as total_balance FROM landons_loans WHERE citizenid = ? AND status = "active"', {citizenid})
    
    if not loans[1] then return 0 end
    
    local loanCount = loans[1].count or 0
    local totalBalance = loans[1].total_balance or 0
    
    local loanPenalty = loanCount * Config.CreditPoints.activeLoans.perLoan
    local balancePenalty = totalBalance * Config.CreditPoints.activeLoans.perDollar
    
    return math.floor(loanPenalty + balancePenalty)
end

-- Calculate payment history points
local function CalculatePaymentHistoryPoints(citizenid)
    -- Get payment history data
    local missedPayments = MySQL.scalar.await('SELECT SUM(missed_payments) FROM landons_loans WHERE citizenid = ?', {citizenid}) or 0
    local defaults = MySQL.scalar.await('SELECT COUNT(*) FROM landons_loans WHERE citizenid = ? AND status = "defaulted"', {citizenid}) or 0
    local completedLoans = MySQL.scalar.await('SELECT COUNT(*) FROM landons_loans WHERE citizenid = ? AND status = "paid"', {citizenid}) or 0
    
    local points = Config.CreditPoints.paymentHistory.perfect
    
    -- Deduct for missed payments and defaults
    points = points - (missedPayments * Config.CreditPoints.paymentHistory.latePayment)
    points = points - (defaults * Config.CreditPoints.paymentHistory.default)
    
    -- Bonus for completed loans (positive payment history)
    points = points + (completedLoans * 10)
    
    return math.floor(points)
end

-- Calculate utilization points (based on active loans vs max available credit)
local function CalculateUtilizationPoints(citizenid)
    local creditScore = MySQL.scalar.await('SELECT score FROM landons_credit_scores WHERE citizenid = ?', {citizenid}) or Config.DefaultCreditScore
    local activeLoanBalance = MySQL.scalar.await('SELECT SUM(balance) FROM landons_loans WHERE citizenid = ? AND status = "active"', {citizenid}) or 0
    
    -- Calculate max available credit based on credit score
    local maxCredit = 0
    if creditScore >= 750 then
        maxCredit = Config.LoanTypes.player.maxAmount
    elseif creditScore >= 700 then
        maxCredit = 250000
    elseif creditScore >= 650 then
        maxCredit = 100000
    elseif creditScore >= 600 then
        maxCredit = 50000
    else
        maxCredit = Config.LoanTypes.automated.maxAmount
    end
    
    if maxCredit == 0 then return 0 end
    
    local utilization = activeLoanBalance / maxCredit
    local penalty = utilization * Config.CreditPoints.utilization.maxPenalty
    
    return math.floor(-penalty)
end

-- Calculate account age points
local function CalculateAccountAgePoints(citizenid)
    local result = MySQL.single.await('SELECT account_created FROM landons_credit_scores WHERE citizenid = ?', {citizenid})
    
    if not result then return 0 end
    
    local createdTime = result.account_created
    local currentTime = os.time()
    local accountCreated = os.time({
        year = tonumber(string.sub(createdTime, 1, 4)),
        month = tonumber(string.sub(createdTime, 6, 7)),
        day = tonumber(string.sub(createdTime, 9, 10)),
        hour = tonumber(string.sub(createdTime, 12, 13)),
        min = tonumber(string.sub(createdTime, 15, 16)),
        sec = tonumber(string.sub(createdTime, 18, 19))
    })
    
    local daysDiff = math.floor((currentTime - accountCreated) / 86400)
    local points = math.min(daysDiff * Config.CreditPoints.accountAge.perDay, Config.CreditPoints.accountAge.maxPoints)
    
    return points
end

-- Main credit score calculation function
local function CalculateCreditScore(citizenid)
    -- Initialize if new player
    InitializeCreditScore(citizenid)
    
    -- Calculate all point categories
    local liquidityPoints = CalculateLiquidityPoints(citizenid)
    local loanPoints = CalculateActiveLoanPoints(citizenid)
    local paymentHistoryPoints = CalculatePaymentHistoryPoints(citizenid)
    local utilizationPoints = CalculateUtilizationPoints(citizenid)
    local agePoints = CalculateAccountAgePoints(citizenid)
    
    -- Calculate final score
    local finalScore = Config.MinCreditScore + liquidityPoints + loanPoints + paymentHistoryPoints + utilizationPoints + agePoints
    
    -- Ensure score stays within bounds
    finalScore = math.max(Config.MinCreditScore, math.min(Config.MaxCreditScore, finalScore))
    
    -- Update database
    MySQL.update('UPDATE landons_credit_scores SET score = ?, liquidity_points = ?, loan_points = ?, payment_history_points = ?, utilization_points = ?, age_points = ?, last_updated = NOW() WHERE citizenid = ?', {
        finalScore, liquidityPoints, loanPoints, paymentHistoryPoints, utilizationPoints, agePoints, citizenid
    })
    
    return finalScore
end

-- Get credit score (with caching)
local function GetCreditScore(citizenid)
    local result = MySQL.single.await('SELECT score, last_updated FROM landons_credit_scores WHERE citizenid = ?', {citizenid})
    
    if not result then
        return CalculateCreditScore(citizenid)
    end
    
    -- Check if score needs updating (older than 1 hour)
    local lastUpdated = result.last_updated
    local currentTime = os.time()
    local updateTime = os.time({
        year = tonumber(string.sub(lastUpdated, 1, 4)),
        month = tonumber(string.sub(lastUpdated, 6, 7)),
        day = tonumber(string.sub(lastUpdated, 9, 10)),
        hour = tonumber(string.sub(lastUpdated, 12, 13)),
        min = tonumber(string.sub(lastUpdated, 15, 16)),
        sec = tonumber(string.sub(lastUpdated, 18, 19))
    })
    
    if (currentTime - updateTime) > 3600 then -- 1 hour
        return CalculateCreditScore(citizenid)
    end
    
    return result.score
end

-- Get detailed credit score breakdown
local function GetCreditScoreDetailed(citizenid)
    local result = MySQL.single.await('SELECT * FROM landons_credit_scores WHERE citizenid = ?', {citizenid})
    
    if not result then
        CalculateCreditScore(citizenid)
        result = MySQL.single.await('SELECT * FROM landons_credit_scores WHERE citizenid = ?', {citizenid})
    end
    
    return result
end

-- Update credit score (force recalculation)
local function UpdateCreditScore(citizenid)
    return CalculateCreditScore(citizenid)
end

-- Adjust credit score manually (for defaults, late payments, etc.)
local function AdjustCreditScore(citizenid, adjustment, reason)
    local currentScore = GetCreditScore(citizenid)
    local newScore = math.max(Config.MinCreditScore, math.min(Config.MaxCreditScore, currentScore + adjustment))
    
    MySQL.update('UPDATE landons_credit_scores SET score = ?, last_updated = NOW() WHERE citizenid = ?', {
        newScore, citizenid
    })
    
    -- Log the adjustment
    MySQL.insert('INSERT INTO landons_company_logs (type, amount, description, citizenid) VALUES (?, ?, ?, ?)', {
        'credit_adjustment', adjustment, reason, citizenid
    })
    
    return newScore
end

-- Export functions
exports('GetCreditScore', GetCreditScore)
exports('GetCreditScoreDetailed', GetCreditScoreDetailed)
exports('UpdateCreditScore', UpdateCreditScore)
exports('AdjustCreditScore', AdjustCreditScore)
exports('InitializeCreditScore', InitializeCreditScore)

print("[Landon's Loans] Credit scoring system loaded successfully")
