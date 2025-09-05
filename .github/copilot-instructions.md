# Homebridge Dependency Bot GitHub Action

This repository contains a reusable GitHub Actions workflow that automates homebridge dependency updates for consuming repositories. It processes package.json files across multiple directories, updates specified homebridge packages to the latest versions matching configured patterns or tags, and creates pull requests with the changes.

**Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Working Effectively

### Prerequisites and Setup
- Ensure you have Node.js and npm installed:
  ```bash
  node --version  # Should show v20+ 
  npm --version   # Should show 10+
  ```
- Install YAML validation tools:
  ```bash
  sudo apt-get update && sudo apt-get install -y yamllint jq
  ```

### Validation and Testing
- **CRITICAL**: Validate YAML syntax before making changes:
  ```bash
  yamllint action.yml
  yq eval . action.yml > /dev/null && echo "YAML syntax is valid"
  ```
  - NEVER CANCEL: YAML validation is instant but yamllint may show style warnings
  - The workflow will fail if YAML syntax is invalid

- Validate configuration file structure:
  ```bash
  # Create a test config file to validate the expected format
  mkdir -p /tmp/test-config
  cat > /tmp/test-config/test-config.json << 'EOF'
{
  "git_user": {
    "name": "Test Bot",
    "email": "test@example.com"
  },
  "auto_merge": false,
  "directories": [
    {
      "directory": ".",
      "packages": [
        {
          "name": "homebridge",
          "tag": "beta"
        }
      ]
    }
  ]
}
EOF
  
  # Validate JSON structure
  jq . /tmp/test-config/test-config.json
  ```

### Testing the Action
- **This is a reusable workflow - it cannot be tested directly in this repository**
- To test changes, you must:
  1. Push changes to this repository
  2. Reference the updated action from a consuming repository (like homebridge-apt-pkg or docker-homebridge)
  3. Trigger the workflow in the consuming repository

- **VALIDATION SCENARIOS**: Always test these scenarios when modifying the action:
  1. **Configuration validation**: Test with valid and invalid config files
  2. **Package resolution**: Test both tag-based and pattern-based package selection
  3. **Multi-directory processing**: Test with multiple directories containing package.json files
  4. **Auto-merge scenarios**: Test both auto_merge: true and false configurations
  5. **Error handling**: Test with non-existent packages, invalid patterns, missing directories

### Manual Testing Commands
- **Test package version lookup**:
  ```bash
  # Verify package exists and get versions (1-3 seconds)
  npm view homebridge versions --json | head -10
  ```

- **Test pattern matching**:
  ```bash
  # Test regex pattern for beta versions
  npm view homebridge versions --json | jq -r '.[] | select(test("^1\\.[0-9]+\\.[0-9]+-beta\\.[0-9]+$"))' | tail -5
  ```

- **Test package installation simulation**:
  ```bash
  # Create test environment and install package
  mkdir -p /tmp/test-install && cd /tmp/test-install
  echo '{"name": "test", "version": "1.0.0", "dependencies": {}}' > package.json
  npm install homebridge@latest --save-exact --package-lock=false
  cat package.json  # Verify exact version was installed
  ```

- **Test error scenarios**:
  ```bash
  # Test invalid package name (should fail within 1 second)
  npm view nonexistent-package-12345 versions --json 2>/dev/null || echo "Expected: Package not found"
  
  # Test pattern with no matches (should return 0)
  npm view homebridge versions --json | jq -r '.[] | select(test("^999\\.[0-9]+\\.[0-9]+$"))' | wc -l
  ```

### Configuration File Format
The action expects a JSON configuration file (default: `.github/homebridge-dependency-bot.json`) with this structure:

```json
{
  "git_user": {
    "name": "Homebridge Dependency Bot",
    "email": "actions@github.com"
  },
  "auto_merge": true|false,
  "directories": [
    {
      "directory": "path/to/package/directory",
      "packages": [
        {
          "name": "package-name",
          "tag": "beta"  // OR use "pattern" instead
        },
        {
          "name": "another-package",
          "pattern": "^\\d+\\.\\d+\\.\\d+-beta\\.\\d+$"
        }
      ]
    }
  ]
}
```

**CRITICAL VALIDATION RULES:**
- Each package must have EITHER "tag" OR "pattern" - never both, never neither
- Directory paths must exist in the consuming repository
- Patterns are regex strings that must be properly escaped for JSON

## Common Tasks

### Modifying the Action Logic
1. **Always validate YAML syntax first**:
   ```bash
   yamllint action.yml
   ```

2. **Check for common issues**:
   - Line length (yamllint enforces 80 character limit)
   - Trailing spaces
   - Document start marker (`---`)
   - Proper YAML indentation

3. **Test configuration validation logic**:
   ```bash
   # The action includes extensive config validation - test edge cases
   # Review lines 67-85 in action.yml for validation logic
   ```

### Adding New Package Support
1. Update the package processing logic (lines 114-134 in action.yml)
2. Ensure both tag-based and pattern-based installation work:
   - Tag-based: `npm install package@tag --save-exact`
   - Pattern-based: Uses `npm view package versions --json` with regex filtering

### Debugging Workflow Issues
- **Check consuming repository setup**:
  - Verify the configuration file exists at the specified path
  - Ensure all referenced directories contain package.json files
  - Validate that the GH_TOKEN secret has appropriate permissions

- **Common failure points**:
  - Invalid package names or tags
  - Regex patterns that don't match any versions
  - Missing directories in the consuming repository
  - Insufficient GitHub token permissions for PR creation/merging

### Repository References
- **Consuming repositories**: homebridge-apt-pkg, docker-homebridge
- **Action location**: Referenced as `NorthernMan54/Homebridge-Dependency-Bot@main` or specific version
- **Configuration path**: Default `.github/homebridge-dependency-bot.json`

## File Structure Reference

```
.
├── .github/
│   └── copilot-instructions.md (this file)
├── action.yml (main workflow definition)
└── .git/ (git repository data)
```

### action.yml Overview
- **Lines 1-33**: Workflow metadata, inputs, secrets, outputs
- **Lines 34-46**: Job definition and outputs
- **Lines 47-56**: Checkout and Node.js setup
- **Lines 57-92**: Configuration file loading and validation
- **Lines 93-97**: Git identity configuration  
- **Lines 98-134**: Package processing and installation
- **Lines 135-168**: Change detection and staging
- **Lines 169-180**: Branch creation and push
- **Lines 181-196**: Pull request creation
- **Lines 197-216**: Auto-approval and merge (if enabled)

## Timing Expectations
- **Configuration validation**: < 2 seconds
- **Package version lookup**: 1-3 seconds per package (npm view command)
- **Package installation**: 3-30 seconds per package (depends on package size and dependencies)
- **PR creation and merge**: 5-15 seconds
- **NEVER CANCEL**: The entire workflow typically completes in 1-3 minutes depending on number of packages
- **Error scenarios**: Invalid package lookups fail within 1 second

## Integration Guidelines
- This action is designed to be called from other repositories using `workflow_call`
- Consuming repositories must provide a GH_TOKEN secret for PR operations
- The action outputs can be used by calling workflows for additional processing
- Auto-merge requires both a GH_TOKEN secret AND auto_merge: true in config

## Troubleshooting
- **"Config file not found"**: Verify the config_file input path is correct
- **"Package installation failed"**: Check package name, tag, or pattern validity using `npm view package-name versions --json`
- **"Failed to create PR"**: Verify GH_TOKEN permissions include PR creation and repository write access
- **"No versions found matching pattern"**: Test regex pattern against actual package versions:
  ```bash
  # Debug pattern matching
  npm view package-name versions --json | jq -r '.[] | select(test("YOUR_PATTERN_HERE"))'
  ```
- **"Both tag and pattern defined"**: Each package must have EITHER tag OR pattern, never both
- **"Neither tag nor pattern defined"**: Each package must have at least one of tag OR pattern
- **YAML validation errors**: Run `yamllint action.yml` to identify syntax issues like line length, trailing spaces
- **Permission errors during auto-merge**: Ensure GH_TOKEN secret has sufficient permissions and auto_merge is enabled in config

### Common Error Messages and Solutions
1. **`npm ERR! 404 Not Found`**: Package name is incorrect or doesn't exist
2. **`jq: error: Invalid regular expression`**: Pattern string has invalid regex syntax
3. **`fatal: could not read Password for 'https://github.com'`**: GitHub token is missing or invalid
4. **`No changes detected in any directories`**: All packages are already at target versions
5. **`Directory not found`**: Directory path in config doesn't exist in the consuming repository