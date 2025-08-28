# Landon's Loans - QBCore Credit & Loan System

A comprehensive credit and loan system for FiveM QBCore servers, featuring dynamic credit scoring, automated loans, staff-managed loans, and realistic payment processing.

## Features

### 🏦 Credit Score System
- **Range**: 300-850 (default: 650)
- **Dynamic calculation** based on:
  - **Liquidity (25%)**: Bank balance up to $500k cap
  - **Active Loans (25%)**: Number and amount of current loans
  - **Payment History (30%)**: On-time payments, late payments, defaults
  - **Utilization (10%)**: Current debt vs available credit
  - **Account Age (10%)**: Length of credit history

### 💰 Loan Types

#### Automated Loans (NPC/UI)
- **Amounts**: $1,000 - $10,000
- **Interest Rates**: 15-25% based on credit score
- **Terms**: 7-14 in-game days
- **Limitations**: Max 1 active loan, requires 600+ credit score

#### Player Loans (Staff Managed)
- **Amounts**: $5,000 - $500,000
- **Interest Rates**: 3-30% (staff discretion within brackets)
- **Terms**: 7-90 in-game days
- **Limitations**: Max 3 active loans, staff approval required

### 📊 Interest Rate Brackets
- **750-850**: 5% auto, 3-6% staff
- **700-749**: 8% auto, 5-10% staff
- **650-699**: 12% auto, 8-15% staff
- **600-649**: 18% auto, 12-20% staff
- **550-599**: 25% auto, 18-30% staff
- **<550**: Denied auto, staff override only

### ⚡ Automated Systems
- **Daily payment deductions** from bank accounts
- **Default checking** and penalty application
- **Credit score updates** based on payment behavior
- **Late fee application** (5% of balance)

### 🎭 Roleplay Features
- **Loan Officer positions** for staff
- **Collection activities** and repo system
- **Company profit tracking** and commission structure
- **Detailed transaction logging**

## Installation

### 1. Dependencies
Ensure you have these resources installed:
- `qb-core`
- `qb-target`
- `oxmysql`

### 2. Database Setup
Run the SQL file to create required tables:
```sql
-- Execute sql/landons_loans.sql in your database
```

### 3. Resource Installation
1. Place the `landons-loans` folder in your resources directory
2. Add to your `server.cfg`:
```
ensure landons-loans
```

### 4. Configuration
Edit `shared/config.lua` to customize:
- Staff job names
- Interest rates
- Loan limits
- Payment schedules
- Ped location

## Usage

### For Players

#### 🏪 Loan Office Interaction
Visit the loan office at the configured location (default: `-81.25, -835.7, 40.56`) and interact with the loan officer ped.

**Available Options:**
- **Check Credit Score**: View your current credit rating and tips for improvement
- **Apply for Loan**: Submit automated loan applications
- **View Active Loans**: See all your current loans and payment schedules
- **Make Payment**: Pay down loan balances manually

#### 💳 Credit Score Management
Your credit score updates automatically based on:
- Bank balance maintenance
- Timely loan payments
- Number of active loans
- Credit utilization
- Account age

### For Staff

#### 🎯 Staff Commands
- `/creditcheck [citizenid]` - Check any player's credit score
- `/loanstatus [citizenid]` - View active loans for a player
- `/loansmenu` - Open staff menu (or press F6)

#### 🏢 Staff Menu Features
- **Issue Player Loans**: Create custom loans with flexible terms
- **Player Lookup**: Search citizen records and credit information
- **Collections**: Track overdue accounts and manage collections
- **Reports**: View company statistics and performance metrics

## Configuration

### Credit Scoring
```lua
Config.CreditWeights = {
    liquidity = 0.25,      -- 25% - Bank balance impact
    activeLoans = 0.25,    -- 25% - Current loan burden
    paymentHistory = 0.30, -- 30% - Payment track record
    utilization = 0.10,    -- 10% - Credit usage ratio
    accountAge = 0.10      -- 10% - Credit history length
}
```

### Loan Limits
```lua
Config.LoanTypes = {
    automated = {
        minAmount = 1000,     -- $1,000 minimum
        maxAmount = 10000,    -- $10,000 maximum
        minTerm = 7,          -- 7 days minimum
        maxTerm = 14,         -- 14 days maximum
        maxActiveLoans = 1,   -- 1 loan max
        minCreditScore = 600  -- 600 minimum score
    }
}
```

### Staff Authorization
```lua
Config.StaffJobs = {
    'police',    -- Police can manage loans
    'banker',    -- Custom banker job
    'admin'      -- Admin access
}
```

## API Reference

### Exports

#### Client Exports
```lua
-- Format currency for display
exports['landons-loans']:FormatCurrency(amount)

-- Show loan notification
exports['landons-loans']:ShowLoanNotification(message, type, duration)

-- Format date for display
exports['landons-loans']:FormatDate(dateString)
```

#### Server Exports
```lua
-- Get player's credit score
local score = exports['landons-loans']:GetCreditScore(citizenid)

-- Get active loans for player
local loans = exports['landons-loans']:GetActiveLoans(citizenid)

-- Apply for a loan programmatically
local result = exports['landons-loans']:ApplyForLoan(citizenid, loanType, amount, term, officer)

-- Process a payment
local result = exports['landons-loans']:MakePayment(loanId, amount, citizenid, paymentType)

-- Update credit score
exports['landons-loans']:UpdateCreditScore(citizenid)
```

### Events

#### Client Events
```lua
-- Show credit score UI
TriggerEvent('landonsloans:client:showCreditScore', creditScore)

-- Open loan application
TriggerEvent('landonsloans:client:receiveLoanData', loanData)

-- Display active loans
TriggerEvent('landonsloans:client:showActiveLoans', loans)
```

#### Server Events
```lua
-- Check player credit score
TriggerServerEvent('landonsloans:server:checkCreditScore')

-- Apply for automated loan
TriggerServerEvent('landonsloans:server:applyForLoan', amount, term)

-- Make loan payment
TriggerServerEvent('landonsloans:server:makePayment', loanId, amount)
```

## Database Schema

### Tables Created
- `landons_credit_scores` - Player credit score data
- `landons_loans` - Active and historical loans
- `landons_payments` - Payment transaction history
- `landons_company_account` - Company financial data
- `landons_company_logs` - Transaction and activity logs

## Default Penalties

### Missed Payments
- **Credit Score**: -50 points
- **Late Fee**: 5% of daily payment amount
- **Account Status**: Marked as late

### Loan Defaults
- **Credit Score**: -150 points
- **Account Status**: Flagged for 30 days
- **Loan Access**: Denied automated loans

## Commission Structure

### Staff Earnings
- **Loan Officers**: 2% commission on issued loan amounts
- **Collectors**: 5% commission on collected payments

### Company Profit
- **Interest Income**: 60% goes to company profit
- **Late Fees**: 100% company revenue
- **Processing Fees**: Various administrative charges

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   - Verify oxmysql is running
   - Check database credentials
   - Ensure tables are created

2. **Ped Not Spawning**
   - Verify qb-target is installed
   - Check coordinates in config
   - Ensure model hash is valid

3. **UI Not Opening**
   - Check browser console for errors
   - Verify NUI resource permissions
   - Ensure all HTML/CSS/JS files are present

4. **Credit Scores Not Updating**
   - Check MySQL.Async operations
   - Verify export function calls
   - Review server console for errors

### Debug Mode
Enable debug mode in config for detailed logging:
```lua
Config.Debug = true
```

## Support & Updates

### Version Information
- **Current Version**: 1.0.0
- **QBCore Compatibility**: Latest
- **Last Updated**: 2024

### Contributing
1. Fork the repository
2. Create feature branch
3. Make changes with proper testing
4. Submit pull request with documentation

### License
This script is provided as-is for educational and roleplay purposes. Please respect the original author's work and any applicable licenses.

---

## Future Enhancements

### Planned Features
- **Credit Cards**: Revolving credit system
- **Collateral Loans**: Vehicle and property-backed lending
- **Co-signers**: Joint loan applications
- **Investment Options**: Savings accounts and CDs
- **Insurance Products**: Loan protection insurance
- **Mobile Banking**: Phone app integration

### Enhancement Requests
Submit feature requests through the appropriate channels with detailed descriptions and use cases.

---

**Created by**: Landon's Loans Development Team  
**For**: FiveM QBCore Roleplay Servers  
**Contact**: [Your Contact Information]
