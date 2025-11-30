#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
    CallToolRequestSchema,
    ErrorCode,
    ListToolsRequestSchema,
    McpError,
} from "@modelcontextprotocol/sdk/types.js";
import axios, { AxiosInstance } from "axios";
import * as dotenv from "dotenv";

dotenv.config();

const API_KEY = process.env.RENDER_API_KEY;

if (!API_KEY) {
    console.error("Error: RENDER_API_KEY environment variable is required");
    process.exit(1);
}

const apiClient: AxiosInstance = axios.create({
    baseURL: "https://api.render.com/v1",
    headers: {
        Authorization: `Bearer ${API_KEY}`,
        Accept: "application/json",
    },
});

const server = new Server(
    {
        name: "render-mcp-server",
        version: "1.0.0",
    },
    {
        capabilities: {
            tools: {},
        },
    }
);

interface ListServicesArgs {
    limit?: number;
    cursor?: string;
}

interface GetServiceArgs {
    serviceId: string;
}

interface DeployServiceArgs {
    serviceId: string;
    clearCache?: boolean;
}

interface ListDeploysArgs {
    serviceId: string;
    limit?: number;
}

interface GetDeployArgs {
    serviceId: string;
    deployId: string;
}

server.setRequestHandler(ListToolsRequestSchema, async () => {
    return {
        tools: [
            {
                name: "list_services",
                description: "List all services on Render",
                inputSchema: {
                    type: "object",
                    properties: {
                        limit: {
                            type: "number",
                            description: "Limit the number of results",
                        },
                        cursor: {
                            type: "string",
                            description: "Cursor for pagination",
                        },
                    },
                },
            },
            {
                name: "get_service",
                description: "Get details of a specific service",
                inputSchema: {
                    type: "object",
                    properties: {
                        serviceId: {
                            type: "string",
                            description: "The ID of the service",
                        },
                    },
                    required: ["serviceId"],
                },
            },
            {
                name: "deploy_service",
                description: "Trigger a new deploy for a service",
                inputSchema: {
                    type: "object",
                    properties: {
                        serviceId: {
                            type: "string",
                            description: "The ID of the service",
                        },
                        clearCache: {
                            type: "boolean",
                            description: "Whether to clear the build cache",
                        },
                    },
                    required: ["serviceId"],
                },
            },
            {
                name: "list_deploys",
                description: "List deploys for a service",
                inputSchema: {
                    type: "object",
                    properties: {
                        serviceId: {
                            type: "string",
                            description: "The ID of the service",
                        },
                        limit: {
                            type: "number",
                            description: "Limit the number of results",
                        },
                    },
                    required: ["serviceId"],
                },
            },
            {
                name: "get_deploy",
                description: "Get details of a specific deploy",
                inputSchema: {
                    type: "object",
                    properties: {
                        serviceId: {
                            type: "string",
                            description: "The ID of the service",
                        },
                        deployId: {
                            type: "string",
                            description: "The ID of the deploy",
                        },
                    },
                    required: ["serviceId", "deployId"],
                },
            },
            {
                name: "create_service",
                description: "Create a new service on Render (e.g., Redis, Web Service)",
                inputSchema: {
                    type: "object",
                    properties: {
                        type: {
                            type: "string",
                            description: "Type of service (redis, web_service, etc.)",
                            enum: ["redis", "web_service", "static_site", "cron_job", "worker", "private_service"],
                        },
                        name: {
                            type: "string",
                            description: "Name of the service",
                        },
                        ownerId: {
                            type: "string",
                            description: "ID of the owner (user or team)",
                        },
                        repo: {
                            type: "string",
                            description: "Repository URL (if applicable)",
                        },
                        branch: {
                            type: "string",
                            description: "Branch to deploy (if applicable)",
                        },
                        envVars: {
                            type: "array",
                            description: "Environment variables",
                            items: {
                                type: "object",
                                properties: {
                                    key: { type: "string" },
                                    value: { type: "string" },
                                },
                            },
                        },
                        plan: {
                            type: "string",
                            description: "Service plan (e.g., starter, standard)",
                        },
                        region: {
                            type: "string",
                            description: "Region (e.g., oregon, frankfurt, singapore)",
                        },
                    },
                    required: ["type", "name", "ownerId"],
                },
            },
            {
                name: "create_blueprint",
                description: "Create a new Blueprint (Infrastructure as Code) on Render",
                inputSchema: {
                    type: "object",
                    properties: {
                        title: {
                            type: "string",
                            description: "Title of the Blueprint",
                        },
                        ownerId: {
                            type: "string",
                            description: "ID of the owner (user or team)",
                        },
                        repo: {
                            type: "string",
                            description: "Repository URL (e.g., https://github.com/user/repo)",
                        },
                        branch: {
                            type: "string",
                            description: "Branch to use (default: main)",
                        },
                        autoSync: {
                            type: "boolean",
                            description: "Whether to auto-sync changes (default: true)",
                        },
                    },
                    required: ["title", "ownerId", "repo"],
                },
            },
            {
                name: "list_owners",
                description: "List owners (users and teams) to get ownerId",
                inputSchema: {
                    type: "object",
                    properties: {},
                },
            },
        ],
    };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
    try {
        switch (request.params.name) {
            case "list_services": {
                const args = request.params.arguments as unknown as ListServicesArgs;
                const response = await apiClient.get("/services", {
                    params: {
                        limit: args.limit,
                        cursor: args.cursor,
                    },
                });
                return {
                    content: [
                        {
                            type: "text",
                            text: JSON.stringify(response.data, null, 2),
                        },
                    ],
                };
            }

            case "get_service": {
                const args = request.params.arguments as unknown as GetServiceArgs;
                const response = await apiClient.get(`/services/${args.serviceId}`);
                return {
                    content: [
                        {
                            type: "text",
                            text: JSON.stringify(response.data, null, 2),
                        },
                    ],
                };
            }

            case "create_service": {
                const args = request.params.arguments as any;
                const response = await apiClient.post("/services", args);
                return {
                    content: [
                        {
                            type: "text",
                            text: JSON.stringify(response.data, null, 2),
                        },
                    ],
                };
            }

            case "create_blueprint": {
                const args = request.params.arguments as any;
                const response = await apiClient.post("/blueprints", args);
                return {
                    content: [
                        {
                            type: "text",
                            text: JSON.stringify(response.data, null, 2),
                        },
                    ],
                };
            }

            case "list_owners": {
                const response = await apiClient.get("/owners");
                return {
                    content: [
                        {
                            type: "text",
                            text: JSON.stringify(response.data, null, 2),
                        },
                    ],
                };
            }

            case "deploy_service": {
                const args = request.params.arguments as unknown as DeployServiceArgs;
                const response = await apiClient.post(`/services/${args.serviceId}/deploys`, {
                    clearCache: args.clearCache ? "clear" : "do_not_clear",
                });
                return {
                    content: [
                        {
                            type: "text",
                            text: JSON.stringify(response.data, null, 2),
                        },
                    ],
                };
            }

            case "list_deploys": {
                const args = request.params.arguments as unknown as ListDeploysArgs;
                const response = await apiClient.get(`/services/${args.serviceId}/deploys`, {
                    params: {
                        limit: args.limit,
                    },
                });
                return {
                    content: [
                        {
                            type: "text",
                            text: JSON.stringify(response.data, null, 2),
                        },
                    ],
                };
            }

            case "get_deploy": {
                const args = request.params.arguments as unknown as GetDeployArgs;
                const response = await apiClient.get(
                    `/services/${args.serviceId}/deploys/${args.deployId}`
                );
                return {
                    content: [
                        {
                            type: "text",
                            text: JSON.stringify(response.data, null, 2),
                        },
                    ],
                };
            }

            default:
                throw new McpError(
                    ErrorCode.MethodNotFound,
                    `Unknown tool: ${request.params.name}`
                );
        }
    } catch (error: any) {
        if (axios.isAxiosError(error)) {
            const errorMessage =
                error.response?.data?.message || error.message || "Unknown API error";
            return {
                content: [
                    {
                        type: "text",
                        text: `Render API Error: ${errorMessage}`,
                    },
                ],
                isError: true,
            };
        }
        throw error;
    }
});

async function runServer() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("Render MCP Server running on stdio");
}

runServer().catch((error) => {
    console.error("Fatal error running server:", error);
    process.exit(1);
});
