local QBCore = exports['qb-core']:GetCoreObject()
local resourceName = GetCurrentResourceName()

-- Initialize Database
CreateThread(function()
    local success = MySQL.rawExecute.await([[
        CREATE TABLE IF NOT EXISTS `landons_credit_scores` (
            `citizenid` varchar(50) NOT NULL,
            `score` int(11) NOT NULL DEFAULT 650,
            `liquidity_points` int(11) NOT NULL DEFAULT 0,
            `loan_points` int(11) NOT NULL DEFAULT 0,
            `payment_history_points` int(11) NOT NULL DEFAULT 150,
            `utilization_points` int(11) NOT NULL DEFAULT 0,
            `age_points` int(11) NOT NULL DEFAULT 0,
            `account_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    if success then
        print("[Landon's Loans] Database tables initialized successfully")
    else
        print("[Landon's Loans] Failed to initialize database tables")
    end
end)

-- Utility Functions
local function SendNotification(source, message, type)
    if Config.Notifications.type == 'qb' then
        TriggerClientEvent('QBCore:Notify', source, message, type, Config.Notifications.duration)
    elseif Config.Notifications.type == 'okok' then
        TriggerClientEvent('okokNotify:Alert', source, "Landon's Loans", message, Config.Notifications.duration, type)
    else
        -- Custom notification system
        TriggerClientEvent('landonsloans:notify', source, message, type)
    end
end

local function GetPlayerFromCitizenId(citizenid)
    local players = QBCore.Functions.GetPlayers()
    for i = 1, #players do
        local player = QBCore.Functions.GetPlayer(players[i])
        if player and player.PlayerData.citizenid == citizenid then
            return player
        end
    end
    return nil
end

local function LogTransaction(type, amount, description, citizenid, officerCitizenid, loanId)
    MySQL.insert('INSERT INTO landons_company_logs (type, amount, description, citizenid, officer_citizenid, loan_id) VALUES (?, ?, ?, ?, ?, ?)', {
        type, amount, description, citizenid, officerCitizenid, loanId
    })
end

local function UpdateCompanyBalance(amount)
    MySQL.update('UPDATE landons_company_account SET total_balance = total_balance + ?, last_updated = NOW()', {amount})
end

-- Events
RegisterNetEvent('landonsloans:server:checkCreditScore', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then 
        print("[Landon's Loans] ERROR: Player not found for credit check")
        return 
    end
    
    local citizenid = Player.PlayerData.citizenid
    print("[Landon's Loans] Checking credit score for citizen: " .. citizenid)
    
    -- Initialize credit score if it doesn't exist
    local result = MySQL.single.await('SELECT score FROM landons_credit_scores WHERE citizenid = ?', {citizenid})
    local creditScore = 650 -- Default score
    
    if result then
        creditScore = result.score
        print("[Landon's Loans] Found existing credit score: " .. creditScore)
    else
        -- Create new credit score record
        MySQL.insert.await('INSERT INTO landons_credit_scores (citizenid, score, payment_history_points) VALUES (?, ?, ?)', {
            citizenid, 650, 150
        })
        print("[Landon's Loans] Created new credit score record with default score: 650")
    end
    
    TriggerClientEvent('landonsloans:client:showCreditScore', src, creditScore)
    print("[Landon's Loans] Sent credit score to client: " .. creditScore)
end)

RegisterNetEvent('landonsloans:server:getActiveLoans', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local activeLoans = MySQL.query.await('SELECT * FROM landons_loans WHERE citizenid = ? AND status = "active" ORDER BY created_at DESC', {citizenid}) or {}
    
    TriggerClientEvent('landonsloans:client:showActiveLoans', src, activeLoans)
end)

RegisterNetEvent('landonsloans:server:getActiveLoansForPayment', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local activeLoans = MySQL.query.await('SELECT * FROM landons_loans WHERE citizenid = ? AND status = "active" ORDER BY created_at DESC', {citizenid}) or {}
    
    TriggerClientEvent('landonsloans:client:showPaymentUI', src, activeLoans)
end)

RegisterNetEvent('landonsloans:server:getEarlyPayoffQuote', function(loanId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Simplified early payoff - just return current balance for now
    local loan = MySQL.single.await('SELECT * FROM landons_loans WHERE loan_id = ? AND citizenid = ?', {loanId, Player.PlayerData.citizenid})
    local result = {
        success = loan ~= nil,
        payoffAmount = loan and loan.balance or 0,
        originalBalance = loan and loan.balance or 0,
        discount = 0
    }
    
    TriggerClientEvent('landonsloans:client:showEarlyPayoffQuote', src, result)
end)

RegisterNetEvent('landonsloans:server:processEarlyPayoff', function(loanId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    SendNotification(src, 'Early payoff feature coming soon!', 'info')
end)

RegisterNetEvent('landonsloans:server:staffLookupPlayer', function(citizenid)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player is staff
    local playerJob = Player.PlayerData.job.name
    local isStaff = false
    for _, job in pairs(Config.StaffJobs) do
        if playerJob == job then
            isStaff = true
            break
        end
    end
    
    if not isStaff then
        SendNotification(src, 'You are not authorized to lookup players.', 'error')
        return
    end
    
    -- Get player info
    local result = MySQL.single.await('SELECT score FROM landons_credit_scores WHERE citizenid = ?', {citizenid})
    local creditScore = result and result.score or 650
    local activeLoans = MySQL.query.await('SELECT * FROM landons_loans WHERE citizenid = ? AND status = "active"', {citizenid}) or {}
    local playerName = "Unknown"
    
    -- Try to get player name
    local targetPlayer = GetPlayerFromCitizenId(citizenid)
    if targetPlayer then
        playerName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
    else
        local result = MySQL.single.await('SELECT charinfo FROM players WHERE citizenid = ?', {citizenid})
        if result then
            local charinfo = json.decode(result.charinfo)
            playerName = charinfo.firstname .. ' ' .. charinfo.lastname
        end
    end
    
    local playerData = {
        citizenid = citizenid,
        name = playerName,
        creditScore = creditScore,
        activeLoans = #activeLoans
    }
    
    TriggerClientEvent('landonsloans:client:showPlayerLookupResult', src, playerData)
end)

RegisterNetEvent('landonsloans:server:getCompanyStats', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player is authorized for company stats
    local playerJob = Player.PlayerData.job.name
    local isAuthorized = false
    for _, job in pairs(Config.StaffJobs) do
        if playerJob == job then
            isAuthorized = true
            break
        end
    end
    
    if not isAuthorized then
        SendNotification(src, 'You are not authorized to view company stats.', 'error')
        return
    end
    
    -- Get company statistics
    local companyData = MySQL.single.await('SELECT * FROM landons_company_account ORDER BY id DESC LIMIT 1')
    local totalActiveLoans = MySQL.scalar.await('SELECT COUNT(*) FROM landons_loans WHERE status = "active"') or 0
    local totalPaidLoans = MySQL.scalar.await('SELECT COUNT(*) FROM landons_loans WHERE status = "paid"') or 0
    local totalDefaultedLoans = MySQL.scalar.await('SELECT COUNT(*) FROM landons_loans WHERE status = "defaulted"') or 0
    local totalOutstanding = MySQL.scalar.await('SELECT SUM(balance) FROM landons_loans WHERE status = "active"') or 0
    
    local stats = {
        companyBalance = companyData and companyData.total_balance or 0,
        totalLoansIssued = companyData and companyData.total_loans_issued or 0,
        totalDefaults = companyData and companyData.total_defaults or 0,
        activeLoans = totalActiveLoans,
        paidLoans = totalPaidLoans,
        defaultedLoans = totalDefaultedLoans,
        outstandingAmount = totalOutstanding
    }
    
    TriggerClientEvent('landonsloans:client:updateCompanyStats', src, stats)
end)

RegisterNetEvent('landonsloans:server:getLoanData', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then 
        print("[Landon's Loans] ERROR: Player not found for loan data")
        return 
    end
    
    local citizenid = Player.PlayerData.citizenid
    print("[Landon's Loans] Getting loan data for citizen: " .. citizenid)
    
    -- Get or create credit score
    local result = MySQL.single.await('SELECT score FROM landons_credit_scores WHERE citizenid = ?', {citizenid})
    local creditScore = 650
    
    if result then
        creditScore = result.score
    else
        -- Create new credit score record
        MySQL.insert.await('INSERT INTO landons_credit_scores (citizenid, score, payment_history_points) VALUES (?, ?, ?)', {
            citizenid, 650, 150
        })
    end
    
    -- Get active loans
    local activeLoans = MySQL.query.await('SELECT * FROM landons_loans WHERE citizenid = ? AND status = "active"', {citizenid}) or {}
    
    -- Check if can get loan (simplified check)
    local canGetLoan = {success = true, reason = ""}
    if creditScore < 600 then
        canGetLoan = {success = false, reason = "Credit score too low (minimum 600)"}
    elseif #activeLoans >= 1 then
        canGetLoan = {success = false, reason = "You already have the maximum number of automated loans"}
    end
    
    local bankBalance = Player.PlayerData.money.bank or 0
    
    -- Calculate max loan amount based on credit score
    local maxLoanAmount = 10000 -- Default max
    if creditScore >= 750 then
        maxLoanAmount = 10000
    elseif creditScore >= 700 then
        maxLoanAmount = 8000
    elseif creditScore >= 650 then
        maxLoanAmount = 6000
    elseif creditScore >= 600 then
        maxLoanAmount = 4000
    else
        maxLoanAmount = 1000
    end
    
    -- Calculate interest rate
    local interestRate = 25 -- Default high rate
    if creditScore >= 750 then
        interestRate = 5
    elseif creditScore >= 700 then
        interestRate = 8
    elseif creditScore >= 650 then
        interestRate = 12
    elseif creditScore >= 600 then
        interestRate = 18
    elseif creditScore >= 550 then
        interestRate = 25
    end
    
    local loanData = {
        creditScore = creditScore,
        activeLoans = activeLoans,
        canGetLoan = canGetLoan,
        bankBalance = bankBalance,
        maxLoanAmount = maxLoanAmount,
        interestRate = interestRate
    }
    
    print("[Landon's Loans] Sending loan data - Credit: " .. creditScore .. ", Max Amount: " .. maxLoanAmount .. ", Rate: " .. interestRate .. "%")
    TriggerClientEvent('landonsloans:client:receiveLoanData', src, loanData)
end)

RegisterNetEvent('landonsloans:server:applyForLoan', function(amount, term)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then 
        print("[Landon's Loans] ERROR: Player not found for loan application")
        return 
    end
    
    local citizenid = Player.PlayerData.citizenid
    print("[Landon's Loans] Processing loan application - Citizen: " .. citizenid .. ", Amount: $" .. tostring(amount) .. ", Term: " .. tostring(term) .. " days")
    
    -- Basic validation for now
    if amount < 1000 or amount > 10000 then
        SendNotification(src, 'Loan amount must be between $1,000 and $10,000', 'error')
        return
    end
    
    if term < 7 or term > 14 then
        SendNotification(src, 'Loan term must be between 7 and 14 days', 'error')
        return
    end
    
    -- Simple loan creation for now
    local interestRate = 15 -- Default rate
    local totalAmount = amount + (amount * (interestRate / 100))
    local dailyPayment = math.ceil(totalAmount / term)
    local nextPaymentDue = os.date('%Y-%m-%d %H:%M:%S', os.time() + 86400)
    
    local loanId = MySQL.insert.await('INSERT INTO landons_loans (citizenid, amount, original_amount, interest_rate, balance, daily_payment, term_days, days_remaining, loan_type, next_payment_due) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        citizenid, amount, amount, interestRate, totalAmount, dailyPayment, term, term, 'automated', nextPaymentDue
    })
    
    local result = {success = loanId ~= nil, loanId = loanId}
    
    if result.success then
        -- Add money to player's bank account
        Player.Functions.AddMoney('bank', amount, 'Loan from Landon\'s Loans')
        
        SendNotification(src, 'Loan approved! $' .. amount .. ' has been deposited to your account.', 'success')
        LogTransaction('loan_issued', amount, 'Automated loan issued', citizenid, nil, result.loanId)
        UpdateCompanyBalance(-amount)
        
        -- Close the UI after successful loan
        TriggerClientEvent('landonsloans:client:closeUI', src)
        print("[Landon's Loans] Loan approved and UI closed for citizen: " .. citizenid)
    else
        SendNotification(src, result.reason or 'Loan application failed', 'error')
        print("[Landon's Loans] Loan denied for citizen: " .. citizenid .. " - Reason: " .. (result.reason or 'Unknown'))
    end
end)

RegisterNetEvent('landonsloans:server:makePayment', function(loanId, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Check if player has enough money
    if Player.PlayerData.money.bank < amount then
        SendNotification(src, 'Insufficient funds in your bank account.', 'error')
        return
    end
    
    -- Simple payment processing
    local loan = MySQL.single.await('SELECT * FROM landons_loans WHERE loan_id = ? AND citizenid = ?', {loanId, citizenid})
    
    if not loan then
        SendNotification(src, 'Loan not found.', 'error')
        return
    end
    
    if loan.status ~= 'active' then
        SendNotification(src, 'This loan is not active.', 'error')
        return
    end
    
    if amount > loan.balance then
        amount = loan.balance
    end
    
    -- Remove money from player
    Player.Functions.RemoveMoney('bank', amount, 'Loan payment to Landon\'s Loans')
    
    -- Update loan balance
    local newBalance = loan.balance - amount
    if newBalance <= 0 then
        MySQL.update('UPDATE landons_loans SET balance = 0, status = "paid", updated_at = NOW() WHERE loan_id = ?', {loanId})
        SendNotification(src, 'Congratulations! Your loan has been fully paid off.', 'success')
    else
        MySQL.update('UPDATE landons_loans SET balance = ?, updated_at = NOW() WHERE loan_id = ?', {newBalance, loanId})
    end
    
    -- Record payment
    MySQL.insert('INSERT INTO landons_payments (loan_id, citizenid, amount, payment_type, status) VALUES (?, ?, ?, ?, ?)', {
        loanId, citizenid, amount, 'manual', 'completed'
    })
    
    SendNotification(src, 'Payment of $' .. amount .. ' processed successfully.', 'success')
    LogTransaction('payment_received', amount, 'Manual payment received', citizenid, nil, loanId)
    UpdateCompanyBalance(amount)
end)

-- Staff Events
RegisterNetEvent('landonsloans:server:staffApplyLoan', function(targetCitizenid, amount, term, interestRate)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player is staff
    local playerJob = Player.PlayerData.job.name
    local isStaff = false
    for _, job in pairs(Config.StaffJobs) do
        if playerJob == job then
            isStaff = true
            break
        end
    end
    
    if not isStaff then
        SendNotification(src, 'You are not authorized to issue loans.', 'error')
        return
    end
    
    local officerCitizenid = Player.PlayerData.citizenid
    local officerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    
    -- Simple staff loan creation
    local totalAmount = amount + (amount * (interestRate / 100))
    local dailyPayment = math.ceil(totalAmount / term)
    local nextPaymentDue = os.date('%Y-%m-%d %H:%M:%S', os.time() + 86400)
    
    local loanId = MySQL.insert.await('INSERT INTO landons_loans (citizenid, amount, original_amount, interest_rate, balance, daily_payment, term_days, days_remaining, loan_type, officer_citizenid, officer_name, next_payment_due) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        targetCitizenid, amount, amount, interestRate, totalAmount, dailyPayment, term, term, 'player', officerCitizenid, officerName, nextPaymentDue
    })
    
    local result = {success = loanId ~= nil, loanId = loanId}
    
    if result.success then
        -- Add money to target player if online
        local targetPlayer = GetPlayerFromCitizenId(targetCitizenid)
        if targetPlayer then
            targetPlayer.Functions.AddMoney('bank', amount, 'Loan from Landon\'s Loans')
            SendNotification(targetPlayer.PlayerData.source, 'You have received a loan of $' .. amount .. ' from Landon\'s Loans.', 'success')
        else
            -- Add to offline player's bank account
            MySQL.update('UPDATE players SET money = JSON_SET(money, "$.bank", JSON_EXTRACT(money, "$.bank") + ?) WHERE citizenid = ?', {
                amount, targetCitizenid
            })
        end
        
        SendNotification(src, 'Loan of $' .. amount .. ' approved for citizen ID: ' .. targetCitizenid, 'success')
        LogTransaction('loan_issued', amount, 'Staff loan issued by ' .. officerName, targetCitizenid, officerCitizenid, result.loanId)
        UpdateCompanyBalance(-amount)
        
        -- Calculate commission for officer
        local commission = math.floor(amount * Config.Commission.loanOfficer)
        Player.Functions.AddMoney('bank', commission, 'Loan officer commission')
        SendNotification(src, 'You earned $' .. commission .. ' in commission.', 'success')
    else
        SendNotification(src, result.reason, 'error')
    end
end)

-- Commands
QBCore.Commands.Add('creditcheck', 'Check someone\'s credit score (Staff Only)', {{name = 'citizenid', help = 'Citizen ID'}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player is staff
    local playerJob = Player.PlayerData.job.name
    local isStaff = false
    for _, job in pairs(Config.StaffJobs) do
        if playerJob == job then
            isStaff = true
            break
        end
    end
    
    if not isStaff then
        SendNotification(src, 'You are not authorized to check credit scores.', 'error')
        return
    end
    
    local citizenid = args[1]
    local creditData = MySQL.single.await('SELECT * FROM landons_credit_scores WHERE citizenid = ?', {citizenid})
    
    if creditData then
        TriggerClientEvent('landonsloans:client:showStaffCreditData', src, creditData)
    else
        SendNotification(src, 'No credit data found for this citizen ID.', 'error')
    end
end)

QBCore.Commands.Add('loanstatus', 'Check loan status for a player (Staff Only)', {{name = 'citizenid', help = 'Citizen ID'}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player is staff
    local playerJob = Player.PlayerData.job.name
    local isStaff = false
    for _, job in pairs(Config.StaffJobs) do
        if playerJob == job then
            isStaff = true
            break
        end
    end
    
    if not isStaff then
        SendNotification(src, 'You are not authorized to check loan status.', 'error')
        return
    end
    
    local citizenid = args[1]
    local loans = MySQL.query.await('SELECT * FROM landons_loans WHERE citizenid = ? AND status = "active" ORDER BY created_at DESC', {citizenid}) or {}
    
    TriggerClientEvent('landonsloans:client:showStaffLoanData', src, loans, citizenid)
end)

-- Test command to debug credit score
QBCore.Commands.Add('testcredit', 'Test credit score system', {}, false, function(source, args)
    local src = source
    print("[Landon's Loans] Test command executed by player: " .. src)
    TriggerClientEvent('landonsloans:client:showCreditScore', src, 650)
end)

-- Export functions for other resources
exports('GetCreditScore', function(citizenid)
    local result = MySQL.single.await('SELECT score FROM landons_credit_scores WHERE citizenid = ?', {citizenid})
    return result and result.score or 650
end)

exports('GetActiveLoans', function(citizenid)
    return MySQL.query.await('SELECT * FROM landons_loans WHERE citizenid = ? AND status = "active"', {citizenid}) or {}
end)

exports('ApplyForLoan', function(citizenid, loanType, amount, term, officer)
    -- For now, return a simple error - this would need full implementation
    return {success = false, reason = "Use server events instead of exports"}
end)

-- Start automated payment system
CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        
        local currentTime = os.date('%H')
        if tonumber(currentTime) == Config.Payments.autoDeductionHour then
            TriggerEvent('landonsloans:server:processAutomaticPayments')
        end
        
        -- Check for defaults every hour
        if tonumber(currentTime) % 1 == 0 then
            TriggerEvent('landonsloans:server:checkForDefaults')
        end
    end
end)

print("[Landon's Loans] Main server module loaded successfully")
