"""
Cloud Run compatible HTTP server wrapper for the YouTube MCP Server
Exposes the MCP server over HTTP for Cloud Run deployment
"""

import os
import sys
import asyncio
from mcp.server.fastmcp import FastMCP
import requests
from typing import List
import json
from dotenv import load_dotenv
from starlette.applications import Starlette
from starlette.responses import JSONResponse, PlainTextResponse
from starlette.routing import Route
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

YOUTUBE_API_KEY = os.getenv("YOUTUBE_API_KEY")
CHANNEL_ID = os.getenv("CHANNEL_ID")

# Validate configuration
if not YOUTUBE_API_KEY:
    logger.error("YOUTUBE_API_KEY not set in environment variables")
if not CHANNEL_ID:
    logger.error("CHANNEL_ID not set in environment variables")

logger.info(f"API Key set: {'Yes' if YOUTUBE_API_KEY else 'No'}")
logger.info(f"Channel ID set: {'Yes' if CHANNEL_ID else 'No'}")

# Create FastMCP server instance
server = FastMCP("youtube-analytics-mcp")

# ============ YouTube API Client ============
class YouTubeClient:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://www.googleapis.com/youtube/v3"

    def get_channel_stats(self, channel_id: str) -> dict:
        """Get subscriber count, view count, video count"""
        response = requests.get(
            f"{self.base_url}/channels",
            params={
                "part": "statistics,snippet",
                "id": channel_id,
                "key": self.api_key
            }
        )
        response.raise_for_status()
        channel = response.json()["items"][0]
        return {
            "title": channel["snippet"]["title"],
            "subscribers": channel["statistics"].get("subscriberCount", "Hidden"),
            "total_views": channel["statistics"]["viewCount"],
            "total_videos": channel["statistics"]["videoCount"]
        }

    def get_latest_videos(self, channel_id: str, max_results: int = 10) -> List[dict]:
        """Fetch latest uploaded videos"""
        response = requests.get(
            f"{self.base_url}/search",
            params={
                "part": "snippet",
                "channelId": channel_id,
                "order": "date",
                "type": "video",
                "maxResults": max_results,
                "key": self.api_key
            }
        )
        response.raise_for_status()

        videos = []
        for item in response.json()["items"]:
            videos.append({
                "video_id": item["id"]["videoId"],
                "title": item["snippet"]["title"],
                "published_at": item["snippet"]["publishedAt"],
                "description": item["snippet"]["description"]
            })
        return videos

    def get_video_stats(self, video_id: str) -> dict:
        """Get views, likes, comments for a video"""
        response = requests.get(
            f"{self.base_url}/videos",
            params={
                "part": "statistics,snippet,contentDetails",
                "id": video_id,
                "key": self.api_key
            }
        )
        response.raise_for_status()
        video = response.json()["items"][0]
        return {
            "title": video["snippet"]["title"],
            "views": video["statistics"].get("viewCount", "0"),
            "likes": video["statistics"].get("likeCount", "0"),
            "comments": video["statistics"].get("commentCount", "0"),
            "duration": video["contentDetails"]["duration"],
            "published_at": video["snippet"]["publishedAt"]
        }

    def search_videos(self, query: str, max_results: int = 5) -> List[dict]:
        """Search channel videos by keyword"""
        response = requests.get(
            f"{self.base_url}/search",
            params={
                "part": "snippet",
                "q": query,
                "type": "video",
                "maxResults": max_results,
                "key": self.api_key
            }
        )
        response.raise_for_status()

        results = []
        for item in response.json()["items"]:
            results.append({
                "video_id": item["id"]["videoId"],
                "title": item["snippet"]["title"],
                "channel": item["snippet"]["channelTitle"],
                "published_at": item["snippet"]["publishedAt"]
            })
        return results

    def get_playlist_videos(self, playlist_id: str, max_results: int = 50) -> List[dict]:
        """Fetch all videos from a playlist"""
        response = requests.get(
            f"{self.base_url}/playlistItems",
            params={
                "part": "snippet",
                "playlistId": playlist_id,
                "maxResults": max_results,
                "key": self.api_key
            }
        )
        response.raise_for_status()

        videos = []
        for item in response.json()["items"]:
            videos.append({
                "video_id": item["snippet"]["resourceId"]["videoId"],
                "title": item["snippet"]["title"],
                "position": item["snippet"]["position"]
            })
        return videos

youtube_client = YouTubeClient(YOUTUBE_API_KEY)

# ============ Define MCP Tools ============
@server.tool()
async def get_channel_stats(channel_id: str) -> str:
    """Get channel subscribers, total views, video count"""
    try:
        stats = youtube_client.get_channel_stats(channel_id)
        return json.dumps(stats, indent=2)
    except Exception as e:
        return f"Error: {str(e)}"

@server.tool()
async def get_latest_videos(channel_id: str, max_results: int = 10) -> str:
    """Fetch latest uploaded videos from channel"""
    try:
        videos = youtube_client.get_latest_videos(channel_id, max_results)
        return json.dumps(videos, indent=2)
    except Exception as e:
        return f"Error: {str(e)}"

@server.tool()
async def get_video_stats(video_id: str) -> str:
    """Get views, likes, comments for specific video"""
    try:
        stats = youtube_client.get_video_stats(video_id)
        return json.dumps(stats, indent=2)
    except Exception as e:
        return f"Error: {str(e)}"

@server.tool()
async def search_videos(query: str, max_results: int = 5) -> str:
    """Search YouTube videos by keyword"""
    try:
        results = youtube_client.search_videos(query, max_results)
        return json.dumps(results, indent=2)
    except Exception as e:
        return f"Error: {str(e)}"

@server.tool()
async def get_playlist_videos(playlist_id: str, max_results: int = 50) -> str:
    """Get all videos from a playlist"""
    try:
        videos = youtube_client.get_playlist_videos(playlist_id, max_results)
        return json.dumps(videos, indent=2)
    except Exception as e:
        return f"Error: {str(e)}"

# ============ Health Check Endpoints ============
async def health_check(request):
    """Health check endpoint for Cloud Run"""
    return JSONResponse({"status": "healthy", "service": "youtube-mcp-server"})

async def ready_check(request):
    """Readiness check endpoint"""
    try:
        tools = await server.list_tools()
        return JSONResponse({
            "status": "ready",
            "tools_registered": len(tools),
            "service": "youtube-mcp-server"
        })
    except Exception as e:
        logger.error(f"Error in ready check: {str(e)}")
        return JSONResponse({
            "status": "error",
            "message": str(e),
            "service": "youtube-mcp-server"
        }, status_code=500)

async def root_endpoint(request):
    """Root endpoint with service info"""
    return JSONResponse({
        "service": "YouTube MCP Server",
        "version": "1.0.0",
        "endpoints": {
            "/health": "Health check",
            "/ready": "Readiness check (lists tools)",
            "/mcp": "MCP protocol endpoint"
        }
    })

# ============ Starlette App with MCP ============
routes = [
    Route('/', root_endpoint),
    Route('/health', health_check),
    Route('/ready', ready_check),
]

app = Starlette(routes=routes)

# Mount the FastMCP server's ASGI app for MCP protocol support
# Use path prefix to avoid redirect issues
try:
    logger.info("Mounting FastMCP's streaming HTTP app for MCP protocol")
    # Mount without slash to avoid 307 redirect
    app.mount("/mcp", server.streamable_http_app, name="mcp")
    logger.info("MCP protocol app mounted successfully at /mcp")
except AttributeError as e:
    logger.error(f"streamable_http_app not available: {e}")
    try:
        logger.info("Trying fallback to sse_app")
        app.mount("/mcp", server.sse_app, name="mcp")
        logger.info("SSE app mounted successfully at /mcp")
    except AttributeError as e2:
        logger.error(f"Neither streamable_http_app nor sse_app available: {e2}")
        logger.warning("MCP protocol may not be available at /mcp")

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8080))
    logger.info(f"Starting server on 0.0.0.0:{port}")
    uvicorn.run(app, host="0.0.0.0", port=port)
