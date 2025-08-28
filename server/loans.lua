local QBCore = exports['qb-core']:GetCoreObject()

-- Loan Management Functions

-- Get interest rate based on credit score and loan type
local function GetInterestRate(creditScore, loanType)
    local rates = Config.InterestRates[loanType]
    
    if not rates then return 25 end -- Default high rate
    
    if loanType == 'automated' then
        if creditScore >= 750 then return rates[750]
        elseif creditScore >= 700 then return rates[700]
        elseif creditScore >= 650 then return rates[650]
        elseif creditScore >= 600 then return rates[600]
        elseif creditScore >= 550 then return rates[550]
        else return 25 -- Denied or very high rate
        end
    else -- player loans
        if creditScore >= 750 then return rates[750]
        elseif creditScore >= 700 then return rates[700]
        elseif creditScore >= 650 then return rates[650]
        elseif creditScore >= 600 then return rates[600]
        elseif creditScore >= 550 then return rates[550]
        else return {min = 25, max = 35} -- High risk rates
        end
    end
end

-- Get maximum loan amount based on credit score and loan type
local function GetMaxLoanAmount(citizenid, loanType)
    local creditScore = exports['landons-loans']:GetCreditScore(citizenid)
    local config = Config.LoanTypes[loanType]
    
    if creditScore < config.minCreditScore then
        return 0
    end
    
    -- Base max amount on credit score
    local maxAmount = config.maxAmount
    
    if loanType == 'automated' then
        if creditScore >= 750 then
            maxAmount = config.maxAmount
        elseif creditScore >= 700 then
            maxAmount = math.floor(config.maxAmount * 0.8)
        elseif creditScore >= 650 then
            maxAmount = math.floor(config.maxAmount * 0.6)
        elseif creditScore >= 600 then
            maxAmount = math.floor(config.maxAmount * 0.4)
        else
            maxAmount = config.minAmount
        end
    end
    
    return maxAmount
end

-- Check if player can get an automated loan
local function CanGetAutomatedLoan(citizenid)
    local creditScore = exports['landons-loans']:GetCreditScore(citizenid)
    local config = Config.LoanTypes.automated
    
    -- Check credit score requirement
    if creditScore < config.minCreditScore then
        return {success = false, reason = 'Credit score too low. Minimum required: ' .. config.minCreditScore}
    end
    
    -- Check active loan count
    local activeLoans = MySQL.scalar.await('SELECT COUNT(*) FROM landons_loans WHERE citizenid = ? AND status = "active" AND loan_type = "automated"', {citizenid}) or 0
    
    if activeLoans >= config.maxActiveLoans then
        return {success = false, reason = 'You already have the maximum number of automated loans.'}
    end
    
    -- Check for recent defaults
    local recentDefaults = MySQL.scalar.await('SELECT COUNT(*) FROM landons_loans WHERE citizenid = ? AND status = "defaulted" AND created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)', {citizenid}) or 0
    
    if recentDefaults > 0 then
        return {success = false, reason = 'You have recent defaults on your record.'}
    end
    
    return {success = true}
end

-- Get active loans for a player
local function GetActiveLoans(citizenid)
    local loans = MySQL.query.await('SELECT * FROM landons_loans WHERE citizenid = ? AND status = "active" ORDER BY created_at DESC', {citizenid})
    
    for i = 1, #loans do
        loans[i].next_payment_amount = loans[i].daily_payment
        loans[i].total_remaining = loans[i].balance
        loans[i].days_overdue = 0
        
        -- Calculate if payment is overdue
        local dueDate = loans[i].next_payment_due
        local currentTime = os.time()
        local dueDateObj = os.time({
            year = tonumber(string.sub(dueDate, 1, 4)),
            month = tonumber(string.sub(dueDate, 6, 7)),
            day = tonumber(string.sub(dueDate, 9, 10)),
            hour = tonumber(string.sub(dueDate, 12, 13)),
            min = tonumber(string.sub(dueDate, 15, 16)),
            sec = tonumber(string.sub(dueDate, 18, 19))
        })
        
        if currentTime > dueDateObj then
            loans[i].days_overdue = math.floor((currentTime - dueDateObj) / 86400)
        end
    end
    
    return loans
end

-- Apply for a loan
local function ApplyForLoan(citizenid, loanType, amount, term, officer)
    local config = Config.LoanTypes[loanType]
    
    -- Validate amount
    if amount < config.minAmount or amount > config.maxAmount then
        return {success = false, reason = 'Loan amount must be between $' .. config.minAmount .. ' and $' .. config.maxAmount}
    end
    
    -- Validate term
    if term < config.minTerm or term > config.maxTerm then
        return {success = false, reason = 'Loan term must be between ' .. config.minTerm .. ' and ' .. config.maxTerm .. ' days'}
    end
    
    -- Check maximum loan amount for this player
    local maxAmount = GetMaxLoanAmount(citizenid, loanType)
    if amount > maxAmount then
        return {success = false, reason = 'Maximum loan amount for your credit score is $' .. maxAmount}
    end
    
    -- Check if automated loan is allowed
    if loanType == 'automated' then
        local canGet = CanGetAutomatedLoan(citizenid)
        if not canGet.success then
            return canGet
        end
    end
    
    -- Check active loan limits
    local activeLoans = MySQL.scalar.await('SELECT COUNT(*) FROM landons_loans WHERE citizenid = ? AND status = "active" AND loan_type = ?', {citizenid, loanType}) or 0
    
    if activeLoans >= config.maxActiveLoans then
        return {success = false, reason = 'You already have the maximum number of ' .. loanType .. ' loans.'}
    end
    
    -- Calculate loan details
    local creditScore = exports['landons-loans']:GetCreditScore(citizenid)
    local interestRate
    
    if loanType == 'automated' then
        interestRate = GetInterestRate(creditScore, loanType)
    else
        -- For player loans, use provided rate or calculate default
        if officer and officer.interestRate then
            interestRate = officer.interestRate
        else
            local rateRange = GetInterestRate(creditScore, loanType)
            interestRate = rateRange.min -- Use minimum rate as default
        end
    end
    
    -- Calculate total amount with interest and daily payment
    local totalAmount = amount + (amount * (interestRate / 100))
    local dailyPayment = math.ceil(totalAmount / term)
    local nextPaymentDue = os.date('%Y-%m-%d %H:%M:%S', os.time() + 86400) -- Tomorrow
    
    -- Insert loan into database
    local insertData = {
        citizenid = citizenid,
        amount = amount,
        original_amount = amount,
        interest_rate = interestRate,
        balance = totalAmount,
        daily_payment = dailyPayment,
        term_days = term,
        days_remaining = term,
        loan_type = loanType,
        next_payment_due = nextPaymentDue
    }
    
    if officer then
        insertData.officer_citizenid = officer.citizenid
        insertData.officer_name = officer.name
    end
    
    local loanId = MySQL.insert.await('INSERT INTO landons_loans (citizenid, amount, original_amount, interest_rate, balance, daily_payment, term_days, days_remaining, loan_type, officer_citizenid, officer_name, next_payment_due) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        insertData.citizenid,
        insertData.amount,
        insertData.original_amount,
        insertData.interest_rate,
        insertData.balance,
        insertData.daily_payment,
        insertData.term_days,
        insertData.days_remaining,
        insertData.loan_type,
        insertData.officer_citizenid,
        insertData.officer_name,
        insertData.next_payment_due
    })
    
    if loanId then
        -- Update company stats
        MySQL.update('UPDATE landons_company_account SET total_loans_issued = total_loans_issued + 1')
        
        return {success = true, loanId = loanId, totalAmount = totalAmount, dailyPayment = dailyPayment}
    else
        return {success = false, reason = 'Database error occurred while processing loan.'}
    end
end

-- Get loan by ID
local function GetLoan(loanId)
    return MySQL.single.await('SELECT * FROM landons_loans WHERE loan_id = ?', {loanId})
end

-- Calculate early payment discount
local function CalculateEarlyPaymentDiscount(loanId)
    local loan = GetLoan(loanId)
    if not loan then return 0 end
    
    local remainingDays = loan.days_remaining
    local totalDays = loan.term_days
    local paymentsMade = totalDays - remainingDays
    
    -- Calculate interest saved for early payment
    local dailyInterest = (loan.original_amount * (loan.interest_rate / 100)) / totalDays
    local interestSaved = dailyInterest * remainingDays * 0.5 -- 50% of remaining interest saved
    
    return math.floor(interestSaved)
end

-- Update loan status
local function UpdateLoanStatus(loanId, status)
    MySQL.update('UPDATE landons_loans SET status = ?, updated_at = NOW() WHERE loan_id = ?', {status, loanId})
    
    if status == 'defaulted' then
        MySQL.update('UPDATE landons_company_account SET total_defaults = total_defaults + 1')
    end
end

-- Export functions
exports('GetInterestRate', GetInterestRate)
exports('GetMaxLoanAmount', GetMaxLoanAmount)
exports('CanGetAutomatedLoan', CanGetAutomatedLoan)
exports('GetActiveLoans', GetActiveLoans)
exports('ApplyForLoan', ApplyForLoan)
exports('GetLoan', GetLoan)
exports('CalculateEarlyPaymentDiscount', CalculateEarlyPaymentDiscount)
exports('UpdateLoanStatus', UpdateLoanStatus)

print("[Landon's Loans] Loan management system loaded successfully")
