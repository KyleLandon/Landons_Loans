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
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local creditScore = exports[resourceName]:GetCreditScore(citizenid)
    
    TriggerClientEvent('landonsloans:client:showCreditScore', src, creditScore)
end)

RegisterNetEvent('landonsloans:server:getActiveLoans', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local activeLoans = exports[resourceName]:GetActiveLoans(citizenid)
    
    TriggerClientEvent('landonsloans:client:showActiveLoans', src, activeLoans)
end)

RegisterNetEvent('landonsloans:server:getActiveLoansForPayment', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local activeLoans = exports[resourceName]:GetActiveLoans(citizenid)
    
    TriggerClientEvent('landonsloans:client:showPaymentUI', src, activeLoans)
end)

RegisterNetEvent('landonsloans:server:getEarlyPayoffQuote', function(loanId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local result = exports[resourceName]:ProcessEarlyPayoff(loanId, citizenid)
    
    TriggerClientEvent('landonsloans:client:showEarlyPayoffQuote', src, result)
end)

RegisterNetEvent('landonsloans:server:processEarlyPayoff', function(loanId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local result = exports[resourceName]:ProcessEarlyPayoff(loanId, citizenid)
    
    if result.success then
        -- Check if player has enough money
        if Player.PlayerData.money.bank < result.payoffAmount then
            SendNotification(src, 'Insufficient funds for early payoff.', 'error')
            return
        end
        
        -- Process the payoff
        Player.Functions.RemoveMoney('bank', result.payoffAmount, 'Early loan payoff to Landon\'s Loans')
        
        -- Update loan status
        exports[resourceName]:UpdateLoanStatus(loanId, 'paid')
        
        SendNotification(src, 'Loan paid off early! You saved $' .. result.discount .. ' in interest.', 'success')
        LogTransaction('payment_received', result.payoffAmount, 'Early payoff processed', citizenid, nil, loanId)
        UpdateCompanyBalance(result.payoffAmount)
        
        -- Update credit score
        exports[resourceName]:UpdateCreditScore(citizenid)
    else
        SendNotification(src, result.reason, 'error')
    end
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
    local creditScore = exports[resourceName]:GetCreditScore(citizenid)
    local activeLoans = exports[resourceName]:GetActiveLoans(citizenid)
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
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local creditScore = exports[resourceName]:GetCreditScore(citizenid)
    local activeLoans = exports[resourceName]:GetActiveLoans(citizenid)
    local canGetLoan = exports[resourceName]:CanGetAutomatedLoan(citizenid)
    
    local bankBalance = Player.PlayerData.money.bank
    local maxLoanAmount = exports[resourceName]:GetMaxLoanAmount(citizenid, 'automated')
    local interestRate = exports[resourceName]:GetInterestRate(creditScore, 'automated')
    
    local loanData = {
        creditScore = creditScore,
        activeLoans = activeLoans,
        canGetLoan = canGetLoan,
        bankBalance = bankBalance,
        maxLoanAmount = maxLoanAmount,
        interestRate = interestRate
    }
    
    TriggerClientEvent('landonsloans:client:receiveLoanData', src, loanData)
end)

RegisterNetEvent('landonsloans:server:applyForLoan', function(amount, term)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Validate loan application
    local canGetLoan = exports[resourceName]:CanGetAutomatedLoan(citizenid)
    if not canGetLoan.success then
        SendNotification(src, canGetLoan.reason, 'error')
        return
    end
    
    -- Apply for the loan
    local result = exports[resourceName]:ApplyForLoan(citizenid, 'automated', amount, term, nil)
    
    if result.success then
        -- Add money to player's bank account
        Player.Functions.AddMoney('bank', amount, 'Loan from Landon\'s Loans')
        
        SendNotification(src, 'Loan approved! $' .. amount .. ' has been deposited to your account.', 'success')
        LogTransaction('loan_issued', amount, 'Automated loan issued', citizenid, nil, result.loanId)
        UpdateCompanyBalance(-amount)
        
        -- Update credit score
        exports[resourceName]:UpdateCreditScore(citizenid)
    else
        SendNotification(src, result.reason, 'error')
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
    
    -- Process payment
    local result = exports[resourceName]:MakePayment(loanId, amount, citizenid, 'manual')
    
    if result.success then
        -- Remove money from player
        Player.Functions.RemoveMoney('bank', amount, 'Loan payment to Landon\'s Loans')
        
        SendNotification(src, 'Payment of $' .. amount .. ' processed successfully.', 'success')
        LogTransaction('payment_received', amount, 'Manual payment received', citizenid, nil, loanId)
        UpdateCompanyBalance(amount)
        
        -- Update credit score
        exports[resourceName]:UpdateCreditScore(citizenid)
        
        if result.loanPaidOff then
            SendNotification(src, 'Congratulations! Your loan has been fully paid off.', 'success')
        end
    else
        SendNotification(src, result.reason, 'error')
    end
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
    
    -- Apply for the loan
    local result = exports[resourceName]:ApplyForLoan(targetCitizenid, 'player', amount, term, {
        citizenid = officerCitizenid,
        name = officerName,
        interestRate = interestRate
    })
    
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
        
        -- Update credit score
        exports[resourceName]:UpdateCreditScore(targetCitizenid)
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
    local creditData = exports[resourceName]:GetCreditScoreDetailed(citizenid)
    
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
    local loans = exports[resourceName]:GetActiveLoans(citizenid)
    
    TriggerClientEvent('landonsloans:client:showStaffLoanData', src, loans, citizenid)
end)

-- Export functions for other resources
exports('GetCreditScore', function(citizenid)
    return exports[resourceName]:GetCreditScore(citizenid)
end)

exports('GetActiveLoans', function(citizenid)
    return exports[resourceName]:GetActiveLoans(citizenid)
end)

exports('ApplyForLoan', function(citizenid, loanType, amount, term, officer)
    return exports[resourceName]:ApplyForLoan(citizenid, loanType, amount, term, officer)
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
