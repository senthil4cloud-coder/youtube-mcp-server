# YouTube Analytics MCP Server

A [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server that exposes YouTube API functionality through FastMCP. Query YouTube channel statistics, videos, and analytics directly from Claude or any MCP-compatible client.

## Features

- **Channel Statistics** - Get subscriber count, total views, and video count
- **Latest Videos** - Fetch recently uploaded videos from a channel
- **Video Analytics** - Retrieve views, likes, comments, and duration for specific videos
- **Video Search** - Search YouTube videos by keyword
- **Playlist Management** - Get all videos from a playlist

## Prerequisites

- Python 3.14+
- A [Google Cloud API key](https://console.cloud.google.com/) with YouTube Data API v3 enabled
- A YouTube channel ID (found in your channel settings or from the URL)

## Quick Start

### 1. Clone or Download

```bash
cd youtube-mcp-server
```

### 2. Set Up Environment Variables

Create or update the `.env` file with your credentials:

```env
YOUTUBE_API_KEY=your_google_api_key_here
CHANNEL_ID=your_youtube_channel_id_here
```

**Getting your credentials:**
- **API Key**: [Google Cloud Console](https://console.cloud.google.com/) → Create project → Enable YouTube Data API v3 → Create API key
- **Channel ID**: Visit your YouTube channel, check the URL or settings. Format: `UC_xxxxxxxxxxxxx`

### 3. Install Dependencies

The virtual environment is pre-configured. Activate it:

**PowerShell (Windows):**
```powershell
.\venv\Scripts\Activate.ps1
```

**Bash (Linux/Mac):**
```bash
source venv/bin/activate
```

### 4. Run the Server

```bash
python youtube_mcp_server.py
```

The server starts on stdio transport and waits for MCP client connections.

## Tools

### get_channel_stats
Get channel subscribers, total views, and video count.

**Parameters:**
- `channel_id` (string, required) - YouTube channel ID

**Example:**
```json
{
  "channel_id": "UC_xxxxxxxxxxxxx"
}
```

**Response:**
```json
{
  "title": "My Channel Name",
  "subscribers": "10000",
  "total_views": "500000",
  "total_videos": "42"
}
```

### get_latest_videos
Fetch recently uploaded videos from a channel.

**Parameters:**
- `channel_id` (string, required) - YouTube channel ID
- `max_results` (integer, optional) - Maximum number of results (default: 10)

**Example:**
```json
{
  "channel_id": "UC_xxxxxxxxxxxxx",
  "max_results": 5
}
```

**Response:**
```json
[
  {
    "video_id": "dQw4w9WgXcQ",
    "title": "Video Title",
    "published_at": "2025-01-15T10:30:00Z",
    "description": "Video description here"
  }
]
```

### get_video_stats
Get views, likes, comments, duration, and publish date for a specific video.

**Parameters:**
- `video_id` (string, required) - YouTube video ID

**Example:**
```json
{
  "video_id": "dQw4w9WgXcQ"
}
```

**Response:**
```json
{
  "title": "Video Title",
  "views": "5000000",
  "likes": "50000",
  "comments": "10000",
  "duration": "PT3M33S",
  "published_at": "2025-01-15T10:30:00Z"
}
```

### search_videos
Search YouTube videos by keyword.

**Parameters:**
- `query` (string, required) - Search query
- `max_results` (integer, optional) - Maximum number of results (default: 5)

**Example:**
```json
{
  "query": "python tutorial",
  "max_results": 10
}
```

**Response:**
```json
[
  {
    "video_id": "dQw4w9WgXcQ",
    "title": "Python Tutorial",
    "channel": "Channel Name",
    "published_at": "2025-01-10T12:00:00Z"
  }
]
```

### get_playlist_videos
Get all videos from a playlist.

**Parameters:**
- `playlist_id` (string, required) - YouTube playlist ID
- `max_results` (integer, optional) - Maximum number of results (default: 50)

**Example:**
```json
{
  "playlist_id": "PLxxxxxxxxxxxxxx",
  "max_results": 50
}
```

**Response:**
```json
[
  {
    "video_id": "dQw4w9WgXcQ",
    "title": "Video 1",
    "position": 1
  }
]
```

## Using with Claude

### Connect as MCP Server

1. Start the server: `python youtube_mcp_server.py`
2. In Claude, configure the MCP server connection pointing to this stdio-based server
3. Claude will automatically discover and use the 5 available tools

### Example Usage in Claude

"What are my latest 5 videos and their stats?"

Claude will use `get_latest_videos` to fetch your videos, then `get_video_stats` for each video to provide comprehensive analytics.

## Testing

Verify the server is working correctly:

```bash
python test_server.py
```

Expected output:
```
Server Name: youtube-analytics-mcp

Total Tools Registered: 5

Tools:
  - get_channel_stats
  - get_latest_videos
  - get_video_stats
  - search_videos
  - get_playlist_videos

[OK] Server configuration looks good!
```

## Troubleshooting

### "AttributeError: 'FastMCP' object has no attribute 'mcp'"
The decorator syntax is incorrect. Use `@server.tool()` not `@server.mcp.tool()`.

### "YOUTUBE_API_KEY not found"
Make sure `.env` file exists and contains `YOUTUBE_API_KEY=your_key`. The server uses `load_dotenv()` to load it.

### "401 Unauthorized" errors
Your API key is invalid or doesn't have YouTube Data API v3 enabled. Regenerate from Google Cloud Console.

### "404 Not Found" for channel/video
The channel ID or video ID is incorrect. Verify the ID format and that the resource is public.

## Development

See [CLAUDE.md](CLAUDE.md) for detailed architecture, development tasks, and implementation guidelines.

## License

MIT (or your chosen license)

## Support

For issues or questions about the YouTube API, see [Google's YouTube API Documentation](https://developers.google.com/youtube/v3).
