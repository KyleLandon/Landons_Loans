local QBCore = exports['qb-core']:GetCoreObject()
local loanPed = nil
local isUIOpen = false

-- Initialize
CreateThread(function()
    -- Create the loan officer ped
    CreateLoanPed()
    
    -- Create blip if enabled
    if Config.Blip.enabled then
        CreateLoanBlip()
    end
end)

-- Create loan officer ped
function CreateLoanPed()
    local coords = Config.LoanPed.coords
    local pedModel = Config.LoanPed.model
    
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(100)
    end
    
    loanPed = CreatePed(4, pedModel, coords.x, coords.y, coords.z - 1, coords.w, false, true)
    SetEntityInvincible(loanPed, true)
    SetBlockingOfNonTemporaryEvents(loanPed, true)
    FreezeEntityPosition(loanPed, true)
    
    if Config.LoanPed.scenario then
        TaskStartScenarioInPlace(loanPed, Config.LoanPed.scenario, 0, true)
    end
    
    -- Add qb-target interaction
    exports['qb-target']:AddTargetEntity(loanPed, {
        options = {
            {
                label = "Check Credit Score",
                icon = "fas fa-credit-card",
                action = function()
                    CheckCreditScore()
                end
            },
            {
                label = "Apply for Loan",
                icon = "fas fa-hand-holding-usd",
                action = function()
                    OpenLoanUI()
                end
            },
            {
                label = "View Active Loans",
                icon = "fas fa-list",
                action = function()
                    ViewActiveLoans()
                end
            },
            {
                label = "Make Payment",
                icon = "fas fa-money-bill-wave",
                action = function()
                    OpenPaymentUI()
                end
            }
        },
        distance = 2.5
    })
    
    print("[Landon's Loans] Loan officer ped created successfully")
end

-- Create blip
function CreateLoanBlip()
    local coords = Config.LoanPed.coords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.label)
    EndTextCommandSetBlipName(blip)
end

-- Check credit score
function CheckCreditScore()
    print("[Landon's Loans] Client: Requesting credit score check")
    TriggerServerEvent('landonsloans:server:checkCreditScore')
end

-- Open loan application UI
function OpenLoanUI()
    if isUIOpen then return end
    
    print("[Landon's Loans] Client: Requesting loan data")
    -- Get loan data from server
    TriggerServerEvent('landonsloans:server:getLoanData')
end

-- View active loans
function ViewActiveLoans()
    TriggerServerEvent('landonsloans:server:getActiveLoans')
end

-- Open payment UI
function OpenPaymentUI()
    TriggerServerEvent('landonsloans:server:getActiveLoansForPayment')
end

-- Events
RegisterNetEvent('landonsloans:client:showCreditScore', function(creditScore)
    print("[Landon's Loans] Client: Received credit score: " .. tostring(creditScore))
    ShowCreditScoreUI(creditScore)
end)

RegisterNetEvent('landonsloans:client:receiveLoanData', function(loanData)
    print("[Landon's Loans] Client: Received loan data - Credit Score: " .. tostring(loanData.creditScore))
    ShowLoanApplicationUI(loanData)
end)

RegisterNetEvent('landonsloans:client:showActiveLoans', function(loans)
    ShowActiveLoansUI(loans)
end)

RegisterNetEvent('landonsloans:client:showPaymentUI', function(loans)
    ShowPaymentUI(loans)
end)

RegisterNetEvent('landonsloans:client:showStaffCreditData', function(creditData)
    ShowStaffCreditDataUI(creditData)
end)

RegisterNetEvent('landonsloans:client:showStaffLoanData', function(loans, citizenid)
    ShowStaffLoanDataUI(loans, citizenid)
end)

-- UI Functions
function ShowCreditScoreUI(creditScore)
    print("[Landon's Loans] ShowCreditScoreUI called with score: " .. tostring(creditScore))
    
    local scoreColor = "green"
    if creditScore < 600 then
        scoreColor = "red"
    elseif creditScore < 700 then
        scoreColor = "orange"
    end
    
    local creditRating = "Excellent"
    if creditScore < 580 then
        creditRating = "Poor"
    elseif creditScore < 620 then
        creditRating = "Fair"
    elseif creditScore < 680 then
        creditRating = "Good"
    elseif creditScore < 740 then
        creditRating = "Very Good"
    end
    
    print("[Landon's Loans] Sending NUI message for credit score UI")
    SendNUIMessage({
        type = "showCreditScore",
        data = {
            score = creditScore,
            rating = creditRating,
            color = scoreColor
        }
    })
    
    SetNuiFocus(true, true)
    isUIOpen = true
    print("[Landon's Loans] Credit score UI should now be visible")
end

function ShowLoanApplicationUI(loanData)
    SendNUIMessage({
        type = "showLoanApplication",
        data = loanData
    })
    
    SetNuiFocus(true, true)
    isUIOpen = true
end

function ShowActiveLoansUI(loans)
    if isUIOpen then
        -- Close any existing UI first
        SetNuiFocus(false, false)
        Wait(100)
    end
    
    SendNUIMessage({
        type = "showActiveLoans",
        data = {
            loans = loans
        }
    })
    
    SetNuiFocus(true, true)
    isUIOpen = true
end

function ShowPaymentUI(loans)
    SendNUIMessage({
        type = "showPaymentUI",
        data = {
            loans = loans
        }
    })
    
    SetNuiFocus(true, true)
    isUIOpen = true
end

function ShowStaffCreditDataUI(creditData)
    SendNUIMessage({
        type = "showStaffCreditData",
        data = creditData
    })
    
    SetNuiFocus(true, true)
    isUIOpen = true
end

function ShowStaffLoanDataUI(loans, citizenid)
    SendNUIMessage({
        type = "showStaffLoanData",
        data = {
            loans = loans,
            citizenid = citizenid
        }
    })
    
    SetNuiFocus(true, true)
    isUIOpen = true
end

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    isUIOpen = false
    
    -- Ensure cursor is disabled and player can move
    DisplayRadar(true)
    EnableControlAction(0, 1, true)  -- LookLeftRight
    EnableControlAction(0, 2, true)  -- LookUpDown
    EnableControlAction(0, 30, true) -- MoveLeftRight
    EnableControlAction(0, 31, true) -- MoveUpDown
    
    cb('ok')
end)

RegisterNUICallback('applyForLoan', function(data, cb)
    local amount = tonumber(data.amount)
    local term = tonumber(data.term)
    
    if not amount or not term then
        cb({success = false, message = "Invalid loan parameters"})
        return
    end
    
    TriggerServerEvent('landonsloans:server:applyForLoan', amount, term)
    
    SetNuiFocus(false, false)
    isUIOpen = false
    
    cb({success = true})
end)

RegisterNUICallback('makePayment', function(data, cb)
    local loanId = tonumber(data.loanId)
    local amount = tonumber(data.amount)
    
    if not loanId or not amount then
        cb({success = false, message = "Invalid payment parameters"})
        return
    end
    
    TriggerServerEvent('landonsloans:server:makePayment', loanId, amount)
    
    SetNuiFocus(false, false)
    isUIOpen = false
    
    cb({success = true})
end)

RegisterNUICallback('staffApplyLoan', function(data, cb)
    local citizenid = data.citizenid
    local amount = tonumber(data.amount)
    local term = tonumber(data.term)
    local interestRate = tonumber(data.interestRate)
    
    if not citizenid or not amount or not term or not interestRate then
        cb({success = false, message = "Invalid loan parameters"})
        return
    end
    
    TriggerServerEvent('landonsloans:server:staffApplyLoan', citizenid, amount, term, interestRate)
    
    SetNuiFocus(false, false)
    isUIOpen = false
    
    cb({success = true})
end)

-- Custom notification event
RegisterNetEvent('landonsloans:notify', function(message, type)
    -- Custom notification implementation if needed
    QBCore.Functions.Notify(message, type, 5000)
end)

-- Force close UI if it gets stuck
CreateThread(function()
    while true do
        Wait(0)
        if isUIOpen then
            -- Force close on ESC key
            if IsControlJustPressed(0, 322) then -- ESC key
                SetNuiFocus(false, false)
                isUIOpen = false
                SendNUIMessage({type = "forceClose"})
            end
            
            -- Disable some controls while UI is open
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 18, true)  -- Enter/Confirm
            DisableControlAction(0, 322, false) -- ESC (allow ESC to work)
        end
    end
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if loanPed then
            DeleteEntity(loanPed)
        end
        -- Ensure UI is closed on resource stop
        SetNuiFocus(false, false)
        isUIOpen = false
    end
end)

print("[Landon's Loans] Client module loaded successfully")
