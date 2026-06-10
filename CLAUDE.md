# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

YouTube Analytics MCP Server - A Model Context Protocol (MCP) server that exposes YouTube API functionality through FastMCP. Allows Claude and other MCP clients to query YouTube channel statistics, videos, and analytics.

**Stack:** Python 3.14, FastMCP 3.4.2, Google API Python Client

## Architecture

### Core Components

1. **Main Server** (`youtube_mcp_server.py`)
   - FastMCP server instance (`server = FastMCP("youtube-analytics-mcp")`)
   - Async tool decorators with error handling
   - Returns JSON responses from all tools

2. **YouTubeClient Class** (lines 16-130)
   - Encapsulates YouTube API v3 interactions
   - Methods:
     - `get_channel_stats(channel_id)` - Retrieves channel statistics (subscribers, views, video count)
     - `get_latest_videos(channel_id, max_results)` - Fetches recent uploads
     - `get_video_stats(video_id)` - Gets video-level metrics (views, likes, comments, duration)
     - `search_videos(query, max_results)` - Keyword-based video search
     - `get_playlist_videos(playlist_id, max_results)` - Fetches all videos from a playlist
   - Uses `requests` library to call Google's REST API endpoints
   - All methods call `.raise_for_status()` on responses for error handling

3. **MCP Tool Definitions** (lines 135-178)
   - 5 async tools decorated with `@server.tool()` (NOT `@server.mcp.tool()`)
   - Each tool wraps a YouTubeClient method and returns JSON
   - Common pattern: try/except with `json.dumps()` for serialization

### Configuration

- **Environment Variables** (`.env`):
  - `YOUTUBE_API_KEY` - Google API key for YouTube Data API v3
  - `CHANNEL_ID` - Default channel ID for operations
  - Load via `load_dotenv()` at startup

## Common Development Tasks

### Running the Server

```powershell
cd C:\code\youtube-mcp-server
.\venv\Scripts\python.exe youtube_mcp_server.py
```

The server starts on stdio transport by default and waits for MCP client connections.

### Testing the Server Configuration

```powershell
# Validates server loads correctly and lists all registered tools
.\venv\Scripts\python.exe test_server.py
```

Expected output: All 5 tools registered with correct parameter schemas.

### Activating Virtual Environment

```powershell
.\venv\Scripts\Activate.ps1
```

Then use `python` directly instead of full path.

### Installing Dependencies

Dependencies are pre-installed in venv/. To update or add packages:

```powershell
.\venv\Scripts\pip.exe install <package-name>
```

## Key Implementation Details

### Async/Await

- All tool functions are `async def` even though YouTubeClient methods are synchronous
- Server runtime handles async dispatch automatically
- FastMCP's `list_tools()` and other server methods are async and require `await`

### Error Handling in Tools

Each tool catches exceptions and returns error messages as strings (not exceptions):
```python
try:
    result = youtube_client.method(...)
    return json.dumps(result, indent=2)
except Exception as e:
    return f"Error: {str(e)}"
```

This ensures MCP doesn't crash on API failures.

### API Response Structure

YouTube API responses use nested dictionaries accessed via:
- `response.json()["items"][0]` - First result item
- `snippet` - Video/channel metadata (title, publishedAt, description)
- `statistics` - Quantitative data (views, likes, comments, subscriberCount)
- `contentDetails` - Video-specific info (duration, definition)

## Common Fixes

### Decorator Syntax
- **Wrong:** `@server.mcp.tool()` - FastMCP object has no `mcp` attribute
- **Correct:** `@server.tool()` - Direct decorator on server instance

### Server Launch Method
- **Wrong:** `asyncio.run(server.main())` - FastMCP has no `main()` method
- **Correct:** `server.run()` - Runs stdio transport by default

## Testing New Tools

When adding new YouTube API endpoints:

1. Add method to `YouTubeClient` class
2. Add async tool function with `@server.tool()` decorator
3. Wrap API calls with `try/except` and return JSON
4. Test via `test_server.py` to verify registration
5. Test via MCP client (Claude, etc.) to verify API response handling

## Dependencies Overview

- **mcp (1.27.2)** - Model Context Protocol core
- **fastmcp (3.4.2)** - FastMCP framework for building MCP servers
- **google-api-python-client (2.197.0)** - Google APIs SDK (not directly used, but part of google-auth chain)
- **google-auth (2.53.0)** - Authentication for Google APIs
- **requests (2.34.2)** - HTTP client for API calls
- **python-dotenv (1.2.2)** - Environment variable loading from .env
- **pydantic (2.13.4)** - Data validation (used by FastMCP for schemas)
