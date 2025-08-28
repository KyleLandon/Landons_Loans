local QBCore = exports['qb-core']:GetCoreObject()

-- Additional UI management functions
local currentUIType = nil

-- Extended UI Functions
RegisterNetEvent('landonsloans:client:openStaffMenu', function()
    OpenStaffMenu()
end)

function OpenStaffMenu()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local playerJob = PlayerData.job.name
    
    -- Check if player is authorized staff
    local isStaff = false
    for _, job in pairs(Config.StaffJobs) do
        if playerJob == job then
            isStaff = true
            break
        end
    end
    
    if not isStaff then
        QBCore.Functions.Notify('You are not authorized to access the staff menu.', 'error')
        return
    end
    
    SendNUIMessage({
        type = "showStaffMenu",
        data = {
            playerName = PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname,
            job = PlayerData.job.label
        }
    })
    
    SetNuiFocus(true, true)
    isUIOpen = true
    currentUIType = "staff"
end

-- Loan Calculator UI
function ShowLoanCalculator(maxAmount, interestRate)
    SendNUIMessage({
        type = "showLoanCalculator",
        data = {
            maxAmount = maxAmount,
            interestRate = interestRate,
            minTerm = Config.LoanTypes.automated.minTerm,
            maxTerm = Config.LoanTypes.automated.maxTerm
        }
    })
    
    SetNuiFocus(true, true)
    isUIOpen = true
    currentUIType = "calculator"
end

-- Early Payoff Calculator
function ShowEarlyPayoffCalculator(loanData)
    SendNUIMessage({
        type = "showEarlyPayoffCalculator",
        data = loanData
    })
    
    SetNuiFocus(true, true)
    isUIOpen = true
    currentUIType = "earlyPayoff"
end

-- Company Stats UI (for management)
function ShowCompanyStats(statsData)
    SendNUIMessage({
        type = "showCompanyStats",
        data = statsData
    })
    
    SetNuiFocus(true, true)
    isUIOpen = true
    currentUIType = "companyStats"
end

-- Additional NUI Callbacks
RegisterNUICallback('getLoanCalculation', function(data, cb)
    local amount = tonumber(data.amount)
    local term = tonumber(data.term)
    local interestRate = tonumber(data.interestRate)
    
    if amount and term and interestRate then
        local totalAmount = amount + (amount * (interestRate / 100))
        local dailyPayment = math.ceil(totalAmount / term)
        
        cb({
            success = true,
            totalAmount = totalAmount,
            dailyPayment = dailyPayment,
            totalInterest = totalAmount - amount
        })
    else
        cb({success = false, message = "Invalid calculation parameters"})
    end
end)

RegisterNUICallback('getEarlyPayoffQuote', function(data, cb)
    local loanId = tonumber(data.loanId)
    
    if loanId then
        TriggerServerEvent('landonsloans:server:getEarlyPayoffQuote', loanId)
        cb({success = true})
    else
        cb({success = false, message = "Invalid loan ID"})
    end
end)

RegisterNUICallback('processEarlyPayoff', function(data, cb)
    local loanId = tonumber(data.loanId)
    
    if loanId then
        TriggerServerEvent('landonsloans:server:processEarlyPayoff', loanId)
        
        SetNuiFocus(false, false)
        isUIOpen = false
        currentUIType = nil
        
        cb({success = true})
    else
        cb({success = false, message = "Invalid loan ID"})
    end
end)

RegisterNUICallback('staffLookupPlayer', function(data, cb)
    local citizenid = data.citizenid
    
    if citizenid then
        TriggerServerEvent('landonsloans:server:staffLookupPlayer', citizenid)
        cb({success = true})
    else
        cb({success = false, message = "Invalid citizen ID"})
    end
end)

RegisterNUICallback('staffProcessCollection', function(data, cb)
    local loanId = tonumber(data.loanId)
    local amount = tonumber(data.amount)
    local collectionType = data.collectionType
    
    if loanId and amount and collectionType then
        TriggerServerEvent('landonsloans:server:staffProcessCollection', loanId, amount, collectionType)
        
        SetNuiFocus(false, false)
        isUIOpen = false
        currentUIType = nil
        
        cb({success = true})
    else
        cb({success = false, message = "Invalid collection parameters"})
    end
end)

RegisterNUICallback('getCompanyStats', function(data, cb)
    TriggerServerEvent('landonsloans:server:getCompanyStats')
    cb({success = true})
end)

-- Advanced UI Events
RegisterNetEvent('landonsloans:client:showEarlyPayoffQuote', function(quoteData)
    SendNUIMessage({
        type = "showEarlyPayoffQuote",
        data = quoteData
    })
end)

RegisterNetEvent('landonsloans:client:showPlayerLookupResult', function(playerData)
    SendNUIMessage({
        type = "showPlayerLookupResult",
        data = playerData
    })
end)

RegisterNetEvent('landonsloans:client:updateCompanyStats', function(statsData)
    SendNUIMessage({
        type = "updateCompanyStats",
        data = statsData
    })
end)

-- Utility Functions
function FormatCurrency(amount)
    return "$" .. tostring(amount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

function FormatDate(dateString)
    -- Convert MySQL datetime to readable format
    if not dateString then return "N/A" end
    
    local year, month, day, hour, min, sec = dateString:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    if year then
        return string.format("%s/%s/%s %s:%s", month, day, year, hour, min)
    end
    
    return dateString
end

function CalculateDaysOverdue(dueDateString)
    if not dueDateString then return 0 end
    
    local year, month, day = dueDateString:match("(%d+)-(%d+)-(%d+)")
    if not year then return 0 end
    
    local dueDate = os.time({year = year, month = month, day = day})
    local currentDate = os.time()
    local diffDays = math.floor((currentDate - dueDate) / 86400)
    
    return math.max(0, diffDays)
end

-- Enhanced notification system
function ShowLoanNotification(message, type, duration)
    duration = duration or 5000
    
    if Config.Notifications.type == 'qb' then
        QBCore.Functions.Notify(message, type, duration)
    elseif Config.Notifications.type == 'okok' then
        exports['okokNotify']:Alert("Landon's Loans", message, duration, type)
    else
        -- Use custom notification UI
        SendNUIMessage({
            type = "showNotification",
            data = {
                message = message,
                type = type,
                duration = duration
            }
        })
    end
end

-- Progress tracking for loan applications
function ShowLoanProcessingProgress()
    SendNUIMessage({
        type = "showProgress",
        data = {
            message = "Processing loan application...",
            duration = 3000
        }
    })
end

function ShowPaymentProcessingProgress()
    SendNUIMessage({
        type = "showProgress",
        data = {
            message = "Processing payment...",
            duration = 2000
        }
    })
end

-- Export utility functions for other resources
exports('FormatCurrency', FormatCurrency)
exports('FormatDate', FormatDate)
exports('ShowLoanNotification', ShowLoanNotification)

-- Commands for staff (can be bound to keys)
RegisterCommand('loansmenu', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    local playerJob = PlayerData.job.name
    
    local isStaff = false
    for _, job in pairs(Config.StaffJobs) do
        if playerJob == job then
            isStaff = true
            break
        end
    end
    
    if isStaff then
        OpenStaffMenu()
    else
        QBCore.Functions.Notify('You are not authorized to access the staff menu.', 'error')
    end
end)

-- Key mapping for staff menu (F6 by default, can be changed)
RegisterKeyMapping('loansmenu', 'Open Loans Staff Menu', 'keyboard', 'F6')

print("[Landon's Loans] UI module loaded successfully")
