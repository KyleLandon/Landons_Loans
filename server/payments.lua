local QBCore = exports['qb-core']:GetCoreObject()

-- Payment Processing Functions

-- Make a payment on a loan
local function MakePayment(loanId, amount, citizenid, paymentType)
    local loan = exports['landons-loans']:GetLoan(loanId)
    
    if not loan then
        return {success = false, reason = 'Loan not found.'}
    end
    
    if loan.citizenid ~= citizenid then
        return {success = false, reason = 'This loan does not belong to you.'}
    end
    
    if loan.status ~= 'active' then
        return {success = false, reason = 'This loan is not active.'}
    end
    
    if amount <= 0 then
        return {success = false, reason = 'Payment amount must be greater than 0.'}
    end
    
    if amount > loan.balance then
        amount = loan.balance -- Adjust to remaining balance
    end
    
    -- Calculate new balance
    local newBalance = loan.balance - amount
    local loanPaidOff = newBalance <= 0
    
    -- Update loan balance
    if loanPaidOff then
        MySQL.update('UPDATE landons_loans SET balance = 0, status = "paid", updated_at = NOW() WHERE loan_id = ?', {loanId})
    else
        -- Update next payment due date if this is a regular payment
        local nextPaymentDue = loan.next_payment_due
        if paymentType == 'automatic' or amount >= loan.daily_payment then
            nextPaymentDue = os.date('%Y-%m-%d %H:%M:%S', os.time() + 86400) -- Next day
        end
        
        MySQL.update('UPDATE landons_loans SET balance = ?, next_payment_due = ?, days_remaining = GREATEST(days_remaining - 1, 0), updated_at = NOW() WHERE loan_id = ?', {
            newBalance, nextPaymentDue, loanId
        })
    end
    
    -- Record payment
    MySQL.insert('INSERT INTO landons_payments (loan_id, citizenid, amount, payment_type, status) VALUES (?, ?, ?, ?, ?)', {
        loanId, citizenid, amount, paymentType, 'completed'
    })
    
    -- Reset missed payments counter if payment is made
    if amount >= loan.daily_payment then
        MySQL.update('UPDATE landons_loans SET missed_payments = 0 WHERE loan_id = ?', {loanId})
    end
    
    return {success = true, newBalance = newBalance, loanPaidOff = loanPaidOff}
end

-- Process automatic payments for all active loans
local function ProcessAutomaticPayments()
    local overdueLoans = MySQL.query.await('SELECT * FROM landons_loans WHERE status = "active" AND next_payment_due <= NOW()')
    
    if not overdueLoans then return end
    
    for i = 1, #overdueLoans do
        local loan = overdueLoans[i]
        local citizenid = loan.citizenid
        local paymentAmount = loan.daily_payment
        
        -- Get player (online or offline)
        local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
        local bankBalance = 0
        
        if Player then
            bankBalance = Player.PlayerData.money.bank
        else
            -- Get balance from database for offline player
            local result = MySQL.single.await('SELECT money FROM players WHERE citizenid = ?', {citizenid})
            if result then
                local moneyData = json.decode(result.money)
                bankBalance = moneyData.bank or 0
            end
        end
        
        if bankBalance >= paymentAmount then
            -- Process automatic payment
            if Player then
                Player.Functions.RemoveMoney('bank', paymentAmount, 'Automatic loan payment to Landon\'s Loans')
            else
                -- Update offline player's money
                MySQL.update('UPDATE players SET money = JSON_SET(money, "$.bank", JSON_EXTRACT(money, "$.bank") - ?) WHERE citizenid = ?', {
                    paymentAmount, citizenid
                })
            end
            
            -- Record payment
            local result = MakePayment(loan.loan_id, paymentAmount, citizenid, 'automatic')
            
            if result.success then
                -- Notify player if online
                if Player then
                    TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 
                        'Automatic payment of $' .. paymentAmount .. ' processed for your loan.', 'success', 5000)
                    
                    if result.loanPaidOff then
                        TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 
                            'Congratulations! Your loan has been fully paid off.', 'success', 8000)
                    end
                end
                
                -- Log transaction
                MySQL.insert('INSERT INTO landons_company_logs (type, amount, description, citizenid, loan_id) VALUES (?, ?, ?, ?, ?)', {
                    'payment_received', paymentAmount, 'Automatic payment processed', citizenid, loan.loan_id
                })
                
                -- Update company balance
                MySQL.update('UPDATE landons_company_account SET total_balance = total_balance + ?', {paymentAmount})
            end
        else
            -- Insufficient funds - mark as missed payment
            ProcessMissedPayment(loan.loan_id)
            
            -- Notify player if online
            if Player then
                TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 
                    'Insufficient funds for loan payment of $' .. paymentAmount .. '. Payment marked as missed.', 'error', 8000)
            end
        end
    end
    
    print("[Landon's Loans] Processed automatic payments for " .. #overdueLoans .. " loans")
end

-- Process missed payment
local function ProcessMissedPayment(loanId)
    local loan = exports['landons-loans']:GetLoan(loanId)
    if not loan then return end
    
    local missedPayments = loan.missed_payments + 1
    local lateFee = math.floor(loan.daily_payment * (Config.Payments.latePaymentFeePercent / 100))
    local newBalance = loan.balance + lateFee
    
    -- Update loan with missed payment and late fee
    MySQL.update('UPDATE landons_loans SET missed_payments = ?, balance = balance + ?, late_fees = late_fees + ?, next_payment_due = DATE_ADD(next_payment_due, INTERVAL 1 DAY) WHERE loan_id = ?', {
        missedPayments, lateFee, lateFee, loanId
    })
    
    -- Apply credit score penalty
    exports['landons-loans']:AdjustCreditScore(loan.citizenid, Config.Penalties.missedPayment.creditScoreReduction, 'Missed loan payment')
    
    -- Check if loan should be defaulted
    if missedPayments >= Config.Payments.defaultAfterMissed then
        ProcessLoanDefault(loanId)
    end
    
    -- Log missed payment
    MySQL.insert('INSERT INTO landons_company_logs (type, amount, description, citizenid, loan_id) VALUES (?, ?, ?, ?, ?)', {
        'missed_payment', lateFee, 'Missed payment - late fee applied', loan.citizenid, loanId
    })
end

-- Process loan default
local function ProcessLoanDefault(loanId)
    local loan = exports['landons-loans']:GetLoan(loanId)
    if not loan then return end
    
    -- Update loan status to defaulted
    exports['landons-loans']:UpdateLoanStatus(loanId, 'defaulted')
    
    -- Apply severe credit score penalty
    exports['landons-loans']:AdjustCreditScore(loan.citizenid, Config.Penalties.default.creditScoreReduction, 'Loan default')
    
    -- Notify player if online
    local Player = QBCore.Functions.GetPlayerByCitizenId(loan.citizenid)
    if Player then
        TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, 
            'Your loan has been marked as defaulted. This will severely impact your credit score.', 'error', 10000)
    end
    
    -- Log default
    MySQL.insert('INSERT INTO landons_company_logs (type, amount, description, citizenid, loan_id) VALUES (?, ?, ?, ?, ?)', {
        'default', loan.balance, 'Loan defaulted after missed payments', loan.citizenid, loanId
    })
    
    print("[Landon's Loans] Loan " .. loanId .. " has been defaulted for citizen " .. loan.citizenid)
end

-- Check for defaults (run periodically)
local function CheckForDefaults()
    local overdueLoansByDays = MySQL.query.await([[
        SELECT *, DATEDIFF(NOW(), next_payment_due) as days_overdue 
        FROM landons_loans 
        WHERE status = "active" AND missed_payments >= ? AND next_payment_due < DATE_SUB(NOW(), INTERVAL 1 DAY)
    ]], {Config.Payments.defaultAfterMissed})
    
    if not overdueLoansByDays then return end
    
    for i = 1, #overdueLoansByDays do
        local loan = overdueLoansByDays[i]
        ProcessLoanDefault(loan.loan_id)
    end
    
    if #overdueLoansByDays > 0 then
        print("[Landon's Loans] Processed " .. #overdueLoansByDays .. " loan defaults")
    end
end

-- Get payment history for a loan
local function GetPaymentHistory(loanId)
    return MySQL.query.await('SELECT * FROM landons_payments WHERE loan_id = ? ORDER BY date DESC', {loanId})
end

-- Get payment history for a player
local function GetPlayerPaymentHistory(citizenid, limit)
    limit = limit or 50
    return MySQL.query.await('SELECT p.*, l.loan_type FROM landons_payments p JOIN landons_loans l ON p.loan_id = l.loan_id WHERE p.citizenid = ? ORDER BY p.date DESC LIMIT ?', {citizenid, limit})
end

-- Calculate total payments made by a player
local function GetTotalPaymentsByPlayer(citizenid)
    local result = MySQL.single.await('SELECT SUM(amount) as total FROM landons_payments WHERE citizenid = ? AND status = "completed"', {citizenid})
    return result and result.total or 0
end

-- Process early loan payoff
local function ProcessEarlyPayoff(loanId, citizenid)
    local loan = exports['landons-loans']:GetLoan(loanId)
    
    if not loan then
        return {success = false, reason = 'Loan not found.'}
    end
    
    if loan.citizenid ~= citizenid then
        return {success = false, reason = 'This loan does not belong to you.'}
    end
    
    if loan.status ~= 'active' then
        return {success = false, reason = 'This loan is not active.'}
    end
    
    -- Calculate early payment discount
    local discount = exports['landons-loans']:CalculateEarlyPaymentDiscount(loanId)
    local payoffAmount = loan.balance - discount
    
    return {
        success = true,
        payoffAmount = payoffAmount,
        originalBalance = loan.balance,
        discount = discount
    }
end

-- Internal server events for automated systems
RegisterNetEvent('landonsloans:server:processAutomaticPayments', function()
    ProcessAutomaticPayments()
end)

RegisterNetEvent('landonsloans:server:checkForDefaults', function()
    CheckForDefaults()
end)

-- Export functions
exports('MakePayment', MakePayment)
exports('ProcessAutomaticPayments', ProcessAutomaticPayments)
exports('ProcessMissedPayment', ProcessMissedPayment)
exports('ProcessLoanDefault', ProcessLoanDefault)
exports('CheckForDefaults', CheckForDefaults)
exports('GetPaymentHistory', GetPaymentHistory)
exports('GetPlayerPaymentHistory', GetPlayerPaymentHistory)
exports('GetTotalPaymentsByPlayer', GetTotalPaymentsByPlayer)
exports('ProcessEarlyPayoff', ProcessEarlyPayoff)

print("[Landon's Loans] Payment processing system loaded successfully")
