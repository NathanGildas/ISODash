# Setup Instructions

## Security Configuration

This project requires a proxy server to handle CORS requests to your OpenProject instance. For security reasons, the actual proxy server configuration is not included in the repository.

### Setting up the Proxy Server

1. **Copy the template file:**
   ```bash
   cp lib/proxy_server.dart.example lib/proxy_server.dart
   ```

2. **Configure your OpenProject URL using one of these methods:**

   **Option A: Environment Variable (Recommended)**
   ```bash
   export OPENPROJECT_URL="https://your-openproject-instance.com"
   dart lib/proxy_server.dart
   ```

   **Option B: Configuration File**
   ```bash
   cp config.json.example config.json
   # Edit config.json with your OpenProject URL
   dart lib/proxy_server.dart
   ```

3. **Run the proxy server:**
   ```bash
   dart lib/proxy_server.dart
   ```

The proxy server will run on `http://localhost:8080` and proxy requests to your configured OpenProject instance.

## Important Security Notes

- **Never commit** `lib/proxy_server.dart` or `config.json` to version control
- These files are already in `.gitignore` to prevent accidental commits
- Always use environment variables in production environments
- Consider using Docker secrets or similar for containerized deployments