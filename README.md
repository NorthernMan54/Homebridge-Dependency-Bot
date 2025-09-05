# Homebridge Dependency Bot

A GitHub composite action that automatically manages package.json dependencies for Homebridge release streams. This action creates pull requests with dependency updates and can automatically merge them when configured.

## Features

- 🔄 Automatic dependency updates for beta/alpha release streams
- 🔧 Configurable package targeting with tags or version patterns
- 📝 Automatic pull request creation with detailed commit messages
- 🤖 Optional auto-merge functionality with PR approval
- 📁 Multi-directory support for monorepo structures
- 🔒 Secure token handling using GitHub's built-in authentication

## Usage

### Basic Example

```yaml
name: Update Dependencies
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  update-dependencies:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - name: Update Beta Dependencies
        uses: NorthernMan54/Homebridge-Dependency-Bot@latest
        with:
          config_file: '.github/homebridge-dependency-bot.json'
          release_stream: 'beta'
```

### With Auto-merge

```yaml
name: Update Dependencies with Auto-merge
on:
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:

jobs:
  update-dependencies:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
      # Additional permissions needed for auto-merge
      metadata: read
      checks: read
    steps:
      - name: Update Beta Dependencies
        uses: NorthernMan54/Homebridge-Dependency-Bot@latest
        with:
          config_file: '.github/homebridge-dependency-bot.json'
          release_stream: 'beta'
```

### Multiple Release Streams

```yaml
name: Update All Dependencies
on:
  schedule:
    - cron: '0 2 * * *'
  workflow_dispatch:

jobs:
  update-beta:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - name: Update Beta Dependencies
        uses: NorthernMan54/Homebridge-Dependency-Bot@latest
        with:
          release_stream: 'beta'

  update-alpha:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - name: Update Alpha Dependencies
        uses: NorthernMan54/Homebridge-Dependency-Bot@latest
        with:
          release_stream: 'alpha'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `config_file` | Path to the dependency bot configuration file | No | `.github/homebridge-dependency-bot.json` |
| `release_stream` | Release stream to update (beta or alpha) | No | `beta` |

## Outputs

| Output | Description |
|--------|-------------|
| `changes_detected` | Whether changes were detected in any directories (`true`/`false`) |
| `changed_dirs` | Comma-separated list of directories with changes |
| `auto_merge` | Whether auto-merge is enabled (`true`/`false`) |
| `branch_name` | The name of the branch created (if changes detected) |
| `pr_number` | The number of the pull request created (if changes detected) |

## Token Handling

**Important**: This action handles authentication automatically using GitHub's built-in `github.token`. You do **NOT** need to manually pass a `GH_TOKEN` parameter.

The action uses `github.token` for:
- Checking out the repository with write access
- Creating branches and commits
- Creating pull requests
- Approving and merging PRs (when auto-merge is enabled)

### Required Permissions

Your workflow must include the following permissions:

```yaml
permissions:
  contents: write        # Required for creating branches and commits
  pull-requests: write   # Required for creating and managing PRs
  metadata: read         # Required for auto-merge functionality
  checks: read          # Required for auto-merge functionality
```

## Configuration File

Create a configuration file (default: `.github/homebridge-dependency-bot.json`) in your repository:

### Basic Configuration

```json
{
  "git_user": {
    "name": "Homebridge Dependency Bot",
    "email": "actions@github.com"
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
```

### Advanced Configuration with Patterns

```json
{
  "git_user": {
    "name": "My Dependency Bot",
    "email": "bot@example.com"
  },
  "auto_merge": true,
  "directories": [
    {
      "directory": ".",
      "packages": [
        {
          "name": "homebridge",
          "tag": "beta"
        },
        {
          "name": "@homebridge/plugin-ui-utils",
          "pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+-beta\\.[0-9]+$"
        }
      ]
    },
    {
      "directory": "sub-project",
      "packages": [
        {
          "name": "homebridge",
          "tag": "alpha"
        }
      ]
    }
  ]
}
```

### Configuration Options

| Field | Description | Required | Default |
|-------|-------------|----------|---------|
| `git_user.name` | Name for Git commits | No | `"Homebridge Dependency Bot"` |
| `git_user.email` | Email for Git commits | No | `"actions@github.com"` |
| `auto_merge` | Enable automatic PR approval and merge | No | `false` |
| `directories` | Array of directories to process | Yes | - |
| `directories[].directory` | Path to directory containing package.json | Yes | - |
| `directories[].packages` | Array of packages to update | Yes | - |
| `directories[].packages[].name` | NPM package name | Yes | - |
| `directories[].packages[].tag` | NPM dist-tag to install (e.g., "beta", "alpha") | No* | - |
| `directories[].packages[].pattern` | Regex pattern to match versions | No* | - |

*Note: Each package must specify either `tag` OR `pattern`, but not both.

### Pattern Examples

For beta versions: `^[0-9]+\\.[0-9]+\\.[0-9]+-beta\\.[0-9]+$`
For alpha versions: `^[0-9]+\\.[0-9]+\\.[0-9]+-alpha\\.[0-9]+$`
For release candidates: `^[0-9]+\\.[0-9]+\\.[0-9]+-rc\\.[0-9]+$`

## Example Workflow Output

When the action runs successfully, you'll see output like:

```
🤖 homebridge beta Dependency Bot - Update Dependencies
Config file loaded: /github/workspace/.github/homebridge-dependency-bot.json
Git identity configured: Homebridge Dependency Bot <actions@github.com>
Found 1 directories in config
Processing directory: .
Found 1 packages in .
Installing homebridge@1.6.0-beta.1 in .
Changes detected in .
Branch pushed: update/beta-1693920000
Pull request created: #123 (https://github.com/owner/repo/pull/123)
```

## Security Considerations

- The action automatically uses GitHub's secure `github.token` - no manual token configuration needed
- Tokens are never exposed as workflow inputs or environment variables
- Auto-merge functionality requires appropriate repository permissions
- Consider using branch protection rules for additional security

## Troubleshooting

### Common Issues

**Config file not found**: Ensure your config file exists at the specified path (default: `.github/homebridge-dependency-bot.json`)

**Permission denied**: Verify your workflow has the required permissions (see Token Handling section)

**Package not found**: Check that the package name is correct and the tag/pattern matches available versions

**Auto-merge fails**: Ensure your repository settings allow auto-merge and the workflow token has sufficient permissions

### Debug Mode

Add `ACTIONS_STEP_DEBUG: true` to your workflow environment variables for detailed debugging output:

```yaml
env:
  ACTIONS_STEP_DEBUG: true
```

## Contributing

This action is used by homebridge-apt-pkg and docker-homebridge projects. Feel free to submit issues or pull requests.

## License

This project is licensed under the same terms as the Homebridge project.