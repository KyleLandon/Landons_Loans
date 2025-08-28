# Contributing to Landon's Loans

Thank you for your interest in contributing to Landon's Loans! This document provides guidelines for contributing to the project.

## Code of Conduct

- Be respectful and constructive in all interactions
- Focus on the issue, not the person
- Welcome newcomers and help them get started
- Follow the coding standards and conventions

## Getting Started

### Prerequisites
- FiveM Server with QBCore framework
- Basic knowledge of Lua scripting
- Understanding of MySQL/MariaDB
- Familiarity with HTML/CSS/JavaScript for UI changes

### Development Setup
1. Fork the repository
2. Clone your fork locally
3. Create a feature branch
4. Set up a test FiveM server
5. Install dependencies (qb-core, qb-target, oxmysql)

## Contribution Guidelines

### Reporting Issues
- Use the issue tracker to report bugs
- Include detailed reproduction steps
- Provide server/client console logs
- Specify FiveM and QBCore versions

### Suggesting Features
- Open an issue with the "enhancement" label
- Describe the feature and its benefits
- Consider backward compatibility
- Provide use cases and examples

### Code Contributions

#### Branch Naming
- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `hotfix/description` - Critical fixes
- `docs/description` - Documentation updates

#### Coding Standards
- Follow existing code style and formatting
- Use meaningful variable and function names
- Add comments for complex logic
- Ensure proper error handling

#### Lua Guidelines
- Use proper indentation (4 spaces)
- Avoid global variables
- Use local variables when possible
- Follow QBCore naming conventions

#### Database Changes
- Include migration scripts
- Update the SQL schema file
- Test with both MySQL and MariaDB
- Consider performance implications

#### UI Changes
- Maintain responsive design
- Test across different screen sizes
- Follow the existing color scheme
- Ensure accessibility standards

### Testing
- Test all functionality before submitting
- Verify database operations work correctly
- Check both client and server console for errors
- Test with multiple players when applicable

### Pull Request Process

1. **Before Submitting**
   - Rebase your branch on the latest main
   - Ensure all tests pass
   - Update documentation if needed
   - Add changelog entry

2. **Pull Request Template**
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## Testing
   - [ ] Tested on development server
   - [ ] Database operations verified
   - [ ] UI tested on multiple screen sizes
   - [ ] No console errors

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Documentation updated
   - [ ] Changelog updated
   ```

3. **Review Process**
   - Maintainers will review within 48 hours
   - Address feedback promptly
   - Be open to suggestions and changes
   - Update PR based on review comments

## Development Guidelines

### Database Conventions
- Use descriptive table and column names
- Include proper indexes for performance
- Use appropriate data types
- Add foreign key constraints where applicable

### API Design
- Maintain backward compatibility
- Use consistent naming patterns
- Provide proper error responses
- Document all exports and events

### Security Considerations
- Validate all user inputs
- Use server-side validation
- Prevent SQL injection
- Implement proper permission checks

### Performance Guidelines
- Optimize database queries
- Avoid unnecessary client-server communication
- Use efficient algorithms
- Consider server resource usage

## Documentation

### Code Documentation
- Document all public functions
- Include parameter descriptions
- Provide usage examples
- Explain complex algorithms

### User Documentation
- Update README for new features
- Include configuration examples
- Provide troubleshooting steps
- Add screenshots for UI changes

## Release Process

### Version Numbering
- Follow Semantic Versioning (SemVer)
- Major.Minor.Patch format
- Breaking changes increment major version
- New features increment minor version
- Bug fixes increment patch version

### Changelog
- Maintain CHANGELOG.md
- Group changes by type
- Include breaking changes section
- Reference related issues/PRs

## Community

### Communication
- Use GitHub Issues for bug reports and features
- Join community discussions
- Help other developers
- Share knowledge and best practices

### Recognition
- Contributors will be acknowledged in releases
- Significant contributions may result in collaborator status
- All contributions are valued and appreciated

## Resources

### Documentation
- [QBCore Documentation](https://docs.qbcore.org/)
- [FiveM Documentation](https://docs.fivem.net/)
- [Lua Reference](https://www.lua.org/manual/5.4/)

### Tools
- [Visual Studio Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/)
- [DBeaver](https://dbeaver.io/) - Database management
- [Postman](https://www.postman.com/) - API testing

Thank you for contributing to Landon's Loans! 🏦
