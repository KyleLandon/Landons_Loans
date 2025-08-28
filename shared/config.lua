Config = {}

-- Main Configuration
Config.Debug = false
Config.DefaultCreditScore = 650
Config.MaxCreditScore = 850
Config.MinCreditScore = 300

-- Ped Configuration
Config.LoanPed = {
    model = `a_m_m_business_01`,
    coords = vector4(-81.25, -835.7, 40.56, 159.15),
    scenario = "WORLD_HUMAN_CLIPBOARD"
}

-- Credit Score Calculation Weights
Config.CreditWeights = {
    liquidity = 0.25,      -- 25%
    activeLoans = 0.25,    -- 25%
    paymentHistory = 0.30, -- 30%
    utilization = 0.10,    -- 10%
    accountAge = 0.10      -- 10%
}

-- Credit Score Points System
Config.CreditPoints = {
    liquidity = {
        cap = 500000,      -- $500k cap for liquidity calculation
        maxPoints = 200    -- Maximum points from liquidity
    },
    activeLoans = {
        perLoan = -20,     -- -20 points per active loan
        perDollar = -0.01  -- -0.01 points per dollar borrowed
    },
    paymentHistory = {
        perfect = 150,     -- +150 for perfect payment history
        latePayment = -50, -- -50 per late payment
        default = -150     -- -150 per default
    },
    utilization = {
        maxPenalty = -50   -- -50 points at 100% utilization
    },
    accountAge = {
        perDay = 1,        -- +1 point per in-game day
        maxPoints = 50     -- Maximum 50 points from account age
    }
}

-- Interest Rate Brackets (based on credit score)
Config.InterestRates = {
    automated = {
        [750] = 5,   -- 750-850: 5%
        [700] = 8,   -- 700-749: 8%
        [650] = 12,  -- 650-699: 12%
        [600] = 18,  -- 600-649: 18%
        [550] = 25   -- 550-599: 25%
    },
    player = {
        [750] = {min = 2, max = 6},    -- 750-850: 3-6%
        [700] = {min = 5, max = 10},   -- 700-749: 5-10%
        [650] = {min = 8, max = 15},   -- 650-699: 8-15%
        [600] = {min = 12, max = 20},  -- 600-649: 12-20%
        [550] = {min = 18, max = 30}   -- 550-599: 18-30%
    }
}

-- Loan Configuration
Config.LoanTypes = {
    automated = {
        minAmount = 1000,     -- $1,000 minimum
        maxAmount = 10000,    -- $10,000 maximum
        minTerm = 7,          -- 7 days minimum
        maxTerm = 14,         -- 14 days maximum
        maxActiveLoans = 1,   -- Maximum 1 active automated loan
        minCreditScore = 600  -- Minimum 600 credit score required
    },
    player = {
        minAmount = 5000,     -- $5,000 minimum
        maxAmount = 500000,   -- $500,000 maximum
        minTerm = 7,          -- 7 days minimum
        maxTerm = 90,         -- 90 days maximum
        maxActiveLoans = 3,   -- Maximum 3 active player loans
        minCreditScore = 0    -- No minimum (staff discretion)
    }
}

-- Payment Configuration
Config.Payments = {
    autoDeductionHour = 12,    -- 12:00 PM game time for auto deductions
    latePaymentFeePercent = 5, -- 5% late fee
    defaultAfterMissed = 3,    -- Default after 3 missed payments
    earlyPaymentAllowed = true -- Allow early repayment
}

-- Default Penalties
Config.Penalties = {
    missedPayment = {
        creditScoreReduction = -50,
        balanceIncrease = 5 -- 5% increase to balance
    },
    default = {
        creditScoreReduction = -150,
        flagDuration = 30 -- Days flagged as defaulted
    }
}

-- Staff Job Names (who can handle player loans)
Config.StaffJobs = {
    'police',    -- Example: Police can act as loan officers
    'banker',    -- Custom banker job
    'admin'      -- Admin job
}

-- Commission Structure for Staff Loans
Config.Commission = {
    loanOfficer = 0.02,  -- 2% commission on loan amount for officer
    collector = 0.05     -- 5% commission on collected amounts
}

-- Company Configuration
Config.Company = {
    name = "Landon's Loans",
    account = "landons_loans",
    startingBalance = 1000000, -- $1M starting balance
    profitMargin = 0.60        -- 60% of interest goes to profit
}

-- Notification Configuration
Config.Notifications = {
    type = 'qb', -- 'qb', 'okok', 'custom'
    duration = 5000
}

-- Menu Configuration
Config.Menu = {
    position = 'top-left',
    theme = 'dark'
}

-- Blip Configuration (optional)
Config.Blip = {
    enabled = true,
    sprite = 207,
    color = 2,
    scale = 0.8,
    label = "Landon's Loans"
}

-- Repo System Configuration
Config.Repo = {
    enabled = true,
    warningDays = 3,        -- Days before repo warning
    repoAfterDays = 7,      -- Days before actual repo
    repoPercentage = 0.75   -- 75% of vehicle value goes to loan balance
}

-- Garnishment System Configuration
Config.Garnishment = {
    enabled = true,
    percentage = 0.15,      -- 15% of paycheck goes to loan payment
    minPaycheck = 1000      -- Minimum paycheck before garnishment
}
