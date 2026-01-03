# Contributing to SSPP

Thank you for considering contributing to the Sales Signal Processing Platform! This document provides guidelines for contributing.

## Code of Conduct

Be respectful, professional, and inclusive in all interactions.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. Create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details
   - Logs/screenshots if applicable

### Suggesting Features

1. Check existing issues for similar suggestions
2. Create a new issue with:
   - Clear description of the feature
   - Use cases and benefits
   - Potential implementation approach

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**:
   - Follow coding standards
   - Add tests
   - Update documentation
4. **Commit with clear messages**:
   ```bash
   git commit -m "feat: add new signal type"
   ```
5. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
6. **Create Pull Request**

## Development Guidelines

### Code Style

- **TypeScript**: Follow established patterns
- **Formatting**: Use Prettier (configured in project)
- **Linting**: ESLint must pass
- **Naming**: Use descriptive, camelCase names

### Testing

- Write tests for new features
- Maintain >80% code coverage
- Run tests before committing:
  ```bash
  npm test
  npm run test:cov
  ```

### Commit Messages

Follow Conventional Commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Formatting
- `refactor:` Code restructuring
- `test:` Tests
- `chore:` Maintenance

Example: `feat(api): add rate limiting middleware`

### Branch Naming

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation
- `refactor/description` - Refactoring

## Project Structure

```
sspp/
├── services/
│   ├── api/              # API service
│   └── worker/           # Worker service
├── infrastructure/
│   ├── terraform/        # IaC
│   ├── k8s/             # Kubernetes
│   └── database/        # DB schemas
├── .github/
│   └── workflows/       # CI/CD
└── docs/                # Documentation
```

## Testing Locally

1. **Start infrastructure**:
   ```bash
   docker-compose up -d
   ```

2. **Run services**:
   ```bash
   # API
   cd services/api && npm run start:dev
   
   # Worker
   cd services/worker && npm run start:dev
   ```

3. **Run tests**:
   ```bash
   npm test
   ```

## Pull Request Process

1. Update README.md if needed
2. Update documentation
3. Add tests
4. Ensure CI passes
5. Request review from maintainers
6. Address review feedback
7. Squash commits if requested

## Review Process

Maintainers will review PRs for:
- Code quality
- Test coverage
- Documentation
- Performance impact
- Security implications

## Questions?

Open an issue or reach out to maintainers.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
