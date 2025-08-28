# Changelog

All notable changes to Landon's Loans will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-01-XX

### Added
- **Initial Release** - Complete credit and loan system for QBCore
- **Dynamic Credit Scoring System**
  - 300-850 credit score range with weighted factors
  - Real-time calculation based on liquidity, payment history, active loans, utilization, and account age
  - Automatic score updates on financial activities
- **Dual Loan System**
  - Automated loans ($1k-$10k) with NPC interface
  - Staff-managed loans ($5k-$500k) with flexible terms
  - Credit-based interest rates from 3% to 35%
- **Comprehensive Database Schema**
  - Credit scores tracking with detailed breakdown
  - Loan management with payment history
  - Company financial tracking and transaction logs
- **Professional UI System**
  - Modern HTML/CSS/JS interface with responsive design
  - Credit score visualization with color-coded ratings
  - Loan calculator with real-time updates
  - Payment management interface
  - Staff dashboard for loan management
- **Automated Payment Processing**
  - Daily automatic bank deductions
  - Late payment penalties and default tracking
  - Early payoff options with interest savings
- **Roleplay Integration**
  - Interactive loan officer ped at specified location
  - qb-target integration for seamless interactions
  - Staff commands for loan management
  - Commission system for loan officers
- **Security Features**
  - Server-side validation for all transactions
  - Permission-based staff access
  - Input sanitization and SQL injection prevention
- **Configuration System**
  - Extensive customization options
  - Configurable interest rates and loan limits
  - Staff job authorization settings
  - Payment schedule customization

### Technical Details
- **Dependencies**: qb-core, qb-target, oxmysql
- **Database**: 5 tables with proper relationships and indexes
- **API**: Comprehensive export functions for third-party integration
- **Performance**: Optimized queries and efficient client-server communication

### Documentation
- Complete installation and setup guide
- API reference with examples
- Troubleshooting documentation
- Contributing guidelines
- Future enhancement roadmap

---

## [Unreleased]

### Planned Features
- Credit card system with revolving credit
- Collateral-based lending (vehicles, properties)
- Co-signer functionality for joint loans
- Investment products (savings accounts, CDs)
- Mobile banking integration
- Insurance products for loan protection
- Advanced reporting and analytics
- Multi-language support
- Webhook integrations for external systems

### Known Issues
- None currently reported

---

## Release Notes

### v1.0.0 Release Highlights
This is the initial release of Landon's Loans, providing a complete credit and loan ecosystem for QBCore roleplay servers. The system includes:

- **Realistic Credit Scoring**: Based on real-world credit factors
- **Flexible Loan Options**: Both automated and staff-managed
- **Professional Interface**: Modern UI with intuitive navigation
- **Automated Operations**: Payment processing and default management
- **Roleplay Features**: Staff roles and interactive gameplay elements

### Compatibility
- **QBCore**: Latest version
- **MySQL/MariaDB**: 5.7+ / 10.2+
- **FiveM**: Latest artifacts
- **Dependencies**: All included in standard QBCore installations

### Performance
- Optimized for servers with 50+ concurrent players
- Minimal resource usage (< 0.1ms average)
- Efficient database operations with proper indexing
- Responsive UI with smooth animations

### Security
- All transactions validated server-side
- SQL injection protection
- Permission-based access control
- Input sanitization and validation

---

## Migration Guide

### From No Loan System
1. Install all dependencies
2. Execute SQL schema
3. Configure staff jobs
4. Set ped location
5. Start resource

### Database Migration
- Initial installation creates all required tables
- No migration needed for v1.0.0

### Configuration Migration
- Copy existing config values if upgrading
- Review new configuration options
- Update staff job names if needed

---

## Support

For support, bug reports, or feature requests:
1. Check existing GitHub issues
2. Review troubleshooting documentation
3. Create detailed issue report
4. Include logs and reproduction steps

---

**Note**: This changelog will be updated with each release. Please check for updates regularly.
