# Homebridge Dependency Bot

A GitHub composite action that automatically manages package.json dependencies for Homebridge release streams. This action creates pull requests with dependency updates and can automatically merge them when configured.

## Features

- 🔄 Automatic dependency updates for stable/beta/alpha release streams
- 🔧 Configurable package targeting with tags or version patterns
- 📝 Automatic pull request creation with detailed commit messages
- 🤖 Optional auto-merge functionality with PR approval
- 📁 Multi-directory support for monorepo structures
- 🔒 Secure token handling using GitHub's built-in authentication
- Leveraged by:
  * homebridge/homebridge-apt-pkg
  * homebridge/docker-image
  * homebridge/homebridge-vm-image

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
        uses: homebridge/dependency-bot@latest
        with:
          config_file: '.github/homebridge-dependency-bot.json'
          release_stream: 'beta'
```

### With Auto-merge (Two Token Approach)

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
        uses: homebridge/dependency-bot@latest
        with:
          config_file: '.github/homebridge-dependency-bot.json'
          release_stream: 'beta'
          GH_TOKEN: ${{ secrets.GH_TOKEN }}  # Separate token for PR approval
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
        uses: homebridge/dependency-bot@latest
        with:
          release_stream: 'beta'

  update-alpha:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - name: Update Alpha Dependencies
        uses: homebridge/dependency-bot@latest
        with:
          release_stream: 'alpha'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `config_file` | Path to the dependency bot configuration file | No | `.github/homebridge-dependency-bot.json` |
| `release_stream` | Release stream to update (beta or alpha) | No | `beta` |
| `GH_TOKEN` | GitHub token with PR approval permissions (see Token Handling section) | No | Uses `github.token` if not provided |

## Outputs

| Output | Description |
|--------|-------------|
| `changes_detected` | Whether changes were detected in any directories (`true`/`false`) |
| `changed_dirs` | Comma-separated list of directories with changes |
| `auto_merge` | Whether auto-merge is enabled (`true`/`false`) |
| `branch_name` | The name of the branch created (if changes detected) |
| `pr_number` | The number of the pull request created (if changes detected) |

## Token Handling

This action supports two different approaches for token handling to work around GitHub's security restrictions:

### Single Token Approach (Basic)

For basic usage without auto-merge, the action uses GitHub's built-in `github.token` automatically:

```yaml
steps:
  - name: Update Dependencies
    uses: homebridge/dependency-bot@latest
    with:
      config_file: '.github/homebridge-dependency-bot.json'
      release_stream: 'beta'
```

### Two Token Approach (Auto-merge)

For auto-merge functionality, GitHub's security rules prevent a bot from creating a PR and then approving it with the same token. To work around this, use two different tokens:

```yaml
steps:
  - name: Update Dependencies with Auto-merge
    uses: homebridge/dependency-bot@latest
    with:
      config_file: '.github/homebridge-dependency-bot.json'
      release_stream: 'beta'
      GH_TOKEN: ${{ secrets.GH_TOKEN }}
```

**Token Setup:**
- `secrets.GITHUB_TOKEN` (automatic): Used for repository operations (checkout, push, create PR)
- `secrets.GH_TOKEN` (manual): A separate token with only PR approval permissions

**How to create the approval token:**
1. Create a Personal Access Token (classic) or Fine-grained token
2. Grant only the minimum permissions needed: `pull_requests: write`
3. Add it as a repository secret named `GH_TOKEN`

**⚠️ Security Note:** Always pass `GH_TOKEN` as a secret (`${{ secrets.GH_TOKEN }}`) in your workflow. Never expose token values directly in your workflow files.

### Token Usage Summary

The action uses tokens for different operations:
- **Repository operations** (checkout, push, create PR): Always uses `github.token`
- **PR approval/merge** (approve, merge): Uses `GH_TOKEN` input if provided, fallback to `github.token`

### Required Permissions

Your workflow must include the following permissions:

```yaml
permissions:
  contents: write        # Required for creating branches and commits
  pull-requests: write   # Required for creating and managing PRs
  metadata: read         # Required for auto-merge functionality
  checks: read           # Required for auto-merge functionality
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

- **Two-token security**: For auto-merge functionality, use separate tokens to prevent bot self-approval security issues
- **Minimal permissions**: Grant only the minimum required permissions to each token
- Repository operations use the standard `github.token` automatically
- PR approval operations can use a separate `GH_TOKEN` with limited permissions
- Tokens are handled securely and never exposed in logs or environment variables
- Consider using branch protection rules for additional security

## Troubleshooting

### Common Issues

**Config file not found**: Ensure your config file exists at the specified path (default: `.github/homebridge-dependency-bot.json`)

**Permission denied**: Verify your workflow has the required permissions (see Token Handling section)

**Package not found**: Check that the package name is correct and the tag/pattern matches available versions

**Auto-merge fails**: For auto-merge functionality, ensure you're using the two-token approach with a separate `GH_TOKEN` that has PR approval permissions. GitHub prevents bots from self-approving PRs with the same token used to create them.

**Token setup issues**: Create a Personal Access Token with `pull_requests: write` permission and add it as a repository secret named `GH_TOKEN`

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