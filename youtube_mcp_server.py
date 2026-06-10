from mcp.server.fastmcp import FastMCP
import os
from dotenv import load_dotenv
import requests
from typing import List
import json

load_dotenv()

server = FastMCP("youtube-analytics-mcp")

YOUTUBE_API_KEY = os.getenv("YOUTUBE_API_KEY")
CHANNEL_ID = os.getenv("CHANNEL_ID")

# Step 2: YouTube API Client
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

#Step 3: Define MCP Tools
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
    
#Step 4: Run Server
if __name__ == "__main__":
    server.run()
