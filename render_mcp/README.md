# Render MCP Server

This is a Model Context Protocol (MCP) server that interfaces with the Render API.

## Features

- **list_services**: List all services on Render.
- **get_service**: Get details of a specific service.
- **deploy_service**: Trigger a new deploy for a service.
- **list_deploys**: List deploys for a service.
- **get_deploy**: Get details of a specific deploy.

## Setup

1.  Install dependencies:
    ```bash
    npm install
    ```

2.  Build the server:
    ```bash
    npm run build
    ```

3.  Set the `RENDER_API_KEY` environment variable. You can create a `.env` file in the root directory:
    ```
    RENDER_API_KEY=your_api_key_here
    ```

## Usage

To run the server:

```bash
npm start
```

Or for development:

```bash
npm run dev
```

## MCP Configuration

Add this server to your MCP configuration (e.g., in Claude Desktop or other MCP clients):

```json
{
  "mcpServers": {
    "render": {
      "command": "node",
      "args": ["/path/to/render_mcp/dist/index.js"],
      "env": {
        "RENDER_API_KEY": "your_api_key_here"
      }
    }
  }
}
```
