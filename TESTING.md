# Testing and Release Guide

This document explains the testing and release processes for the Homebridge Dependency Bot.

## Testing

### Automated Testing

The repository includes comprehensive automated testing through GitHub Actions:

#### 1. CI Workflow (`.github/workflows/ci.yml`)
- **Triggers**: Push to `main`/`develop`, pull requests
- **Purpose**: Validates YAML syntax and action structure
- **Tests**:
  - YAML linting with `yamllint`
  - Action structure validation
  - Required inputs/outputs verification
  - Action parsing validation

#### 2. Test Workflow (`.github/workflows/test.yml`)  
- **Triggers**: Push to `main`/`develop`, pull requests
- **Purpose**: Tests action functionality with different configurations
- **Test Scenarios**:
  - Valid configuration handling
  - Invalid configuration rejection (both tag and pattern)
  - Invalid configuration rejection (neither tag nor pattern)
  - Package resolution testing
  - Output validation

### Manual Testing

#### Local Configuration Testing

Use the provided test script to validate configuration files locally:

```bash
# Run the configuration validator
./test-configs/validate-configs.sh
```

#### Test Configuration Files

The `test-configs/` directory contains example configuration files:

- `valid-tag-config.json` - Basic tag-based configuration
- `valid-pattern-config.json` - Pattern-based configuration  
- `multi-directory-config.json` - Multi-directory setup
- `invalid-both-tag-pattern.json` - Invalid: both tag and pattern
- `invalid-neither-tag-pattern.json` - Invalid: neither tag nor pattern

#### Manual Action Testing

To test the action manually with a specific configuration:

```bash
# Create a test scenario
mkdir -p test-scenario
cp test-configs/valid-tag-config.json test-scenario/.github/homebridge-dependency-bot.json

# Create a test package.json
echo '{"name": "test", "version": "1.0.0", "dependencies": {"homebridge": "1.0.0"}}' > test-scenario/package.json

# Test the action (this would normally be done in a consuming repository)
# The action can be tested by pushing changes and using it in a workflow
```

### Validation Commands

#### YAML Validation
```bash
# Validate action.yml syntax
yamllint action.yml

# Check YAML structure
yq eval -o=json action.yml | jq '.'
```

#### Configuration Validation  
```bash
# Validate a configuration file
jq '.' config-file.json

# Test package resolution
npm view homebridge@beta version
npm view homebridge versions --json | jq -r '.[] | select(test("^1\\.\\d+\\.\\d+-beta\\.\\d+$"))' | tail -5
```

## Release Process

### Automated Releases

#### 1. Release Workflow (`.github/workflows/release.yml`)
- **Triggers**: 
  - Push to version tags (e.g., `v1.0.0`)
  - Manual workflow dispatch with version input
- **Process**:
  1. Validates YAML and action structure
  2. Checks version format (semantic versioning)
  3. Generates release notes from commits
  4. Creates GitHub release
  5. Updates major version tag (e.g., `v1` points to `v1.2.3`)

### Manual Release Steps

#### 1. Prepare for Release
```bash
# Ensure all tests pass
git push origin main

# Check CI status in GitHub Actions
```

#### 2. Create Release
```bash
# Tag the release (triggers automated release)
git tag v1.0.0
git push origin v1.0.0

# Or use manual workflow dispatch in GitHub Actions
```

#### 3. Verify Release
- Check GitHub Releases page for new release
- Verify major version tag is updated (e.g., `v1` → `v1.0.0`)
- Test the released version in a consuming repository

### Version Strategy

- **Semantic Versioning**: `v{major}.{minor}.{patch}`
- **Major Version Tags**: `v1`, `v2`, etc. (always point to latest patch)
- **Branch Strategy**: 
  - `main` - stable releases
  - `develop` - development work
  - Feature branches for major changes

### Release Notes

Release notes are automatically generated from:
- Commit messages since the last tag
- Usage example with the new version tag
- Standard template for consistency

## Troubleshooting

### Common Test Failures

#### YAML Linting Errors
```bash
# Check line length (max 80 characters)
yamllint action.yml

# Common issues:
# - Missing document start (---)
# - Lines too long 
# - Trailing spaces
# - Missing newline at end of file
```

#### Configuration Validation Errors
```bash
# Test configuration locally
./test-configs/validate-configs.sh

# Common issues:
# - Invalid JSON syntax
# - Missing required fields
# - Both tag and pattern specified
# - Neither tag nor pattern specified
```

#### Action Test Failures
- Check that test scenarios have valid package.json files
- Verify network connectivity for npm package resolution
- Ensure test directories are properly structured

### Pre-release Checklist

- [ ] All CI tests passing
- [ ] Manual configuration testing completed
- [ ] Documentation updated if needed
- [ ] Version follows semantic versioning
- [ ] No breaking changes without major version bump

### Post-release Verification

- [ ] GitHub release created successfully
- [ ] Major version tag updated
- [ ] Release notes generated correctly
- [ ] Action works when referenced by tag in consuming repositories

## Integration Testing

While this repository contains comprehensive self-tests, the ultimate test is using the action in a consuming repository:

1. **homebridge-apt-pkg** - Uses this action for dependency updates
2. **docker-homebridge** - Uses this action for dependency updates

After any release, verify the action works correctly in these consuming repositories.