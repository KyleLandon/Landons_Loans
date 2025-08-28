# 🏦 Landon's Loans - Installation Guide

## Quick Installation Steps

### 1. Database Setup
Execute the SQL file in your MySQL/MariaDB database:
```sql
-- Copy and paste the contents of sql/landons_loans.sql into your database management tool
-- This will create all required tables and indexes
```

### 2. Resource Installation
1. Place the `LandonsLoans` folder in your server's resources directory:
   ```
   resources/
   └── [qb]/
       └── LandonsLoans/
   ```

2. Add to your `server.cfg`:
   ```
   ensure LandonsLoans
   ```

### 3. Configuration
Edit `shared/config.lua` to match your server setup:

```lua
-- Update staff job names to match your server
Config.StaffJobs = {
    'police',    -- Change to your police job name
    'admin',     -- Change to your admin job name
    'banker'     -- Add any other staff jobs
}

-- Update ped location if needed
Config.LoanPed = {
    model = `a_m_m_business_01`,
    coords = vector4(-81.25, -835.7, 40.56, 159.15), -- Change if desired
    scenario = "WORLD_HUMAN_CLIPBOARD"
}
```

### 4. Testing Setup

#### For Development/Testing:
1. **Give yourself admin permissions** in your QBCore admin system
2. **Restart the server** or use `refresh` and `start LandonsLoans`
3. **Go to the loan office** at coordinates `-81.25, -835.7, 40.56`
4. **Test the interactions** with the loan officer ped

#### Initial Test Commands:
```
/creditcheck [your-citizenid]  -- Check your credit score
/loansmenu                     -- Open staff menu (if you have permissions)
```

### 5. Troubleshooting

#### Common Issues:

**"No such export" errors:**
- Make sure resource name matches folder name (`LandonsLoans`)
- Restart the resource completely

**Ped not spawning:**
- Verify `qb-target` is installed and working
- Check coordinates in config
- Make sure model hash is valid

**Database errors:**
- Ensure `oxmysql` is running
- Verify SQL tables were created successfully
- Check database connection

**UI not opening:**
- Press F12 in-game and check browser console for errors
- Verify all HTML/CSS/JS files are present
- Check client console (F8) for Lua errors

### 6. Quick Test Checklist

- [ ] Resource starts without errors
- [ ] Loan officer ped spawns at location
- [ ] Can interact with ped using qb-target
- [ ] Credit score displays when checked
- [ ] Can apply for loans (with sufficient credit)
- [ ] Database tables populate with data
- [ ] Staff commands work for authorized jobs

### 7. Server Console Output

When working correctly, you should see these messages:
```
[Landon's Loans] Database tables initialized successfully
[Landon's Loans] Credit scoring system loaded successfully
[Landon's Loans] Loan management system loaded successfully
[Landon's Loans] Payment processing system loaded successfully
[Landon's Loans] Main server module loaded successfully
[Landon's Loans] Client module loaded successfully
[Landon's Loans] UI module loaded successfully
[Landon's Loans] Loan officer ped created successfully
```

### 8. Next Steps

Once installed and working:
1. **Test with multiple players** to verify multiplayer functionality
2. **Customize interest rates** and loan limits in config
3. **Train staff members** on loan officer commands
4. **Monitor database** for performance and data integrity

## Support

If you encounter issues:
1. Check server/client console for error messages
2. Verify all dependencies are installed
3. Review this installation guide
4. Check the troubleshooting section in README.md

---

**Dependencies Required:**
- `qb-core` (Latest version)
- `qb-target` (For ped interactions)
- `oxmysql` (For database operations)

**Compatible with:**
- QBCore Framework (Latest)
- MySQL 5.7+ / MariaDB 10.2+
- FiveM Latest Artifacts
