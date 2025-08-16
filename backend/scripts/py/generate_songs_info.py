import json
import random
from datetime import datetime
from typing import Any, Dict, List

import requests


class IncompetechMusicClient:
    def __init__(self):
        self.base_url = "https://incompetech.com/music/royalty-free"
        self.download_base = (
            "https://incompetech.com/music/royalty-free/mp3-royaltyfree"
        )
        self.session = requests.Session()
        self.session.headers.update(
            {"Accept": "application/json", "User-Agent": "IncompetechMusicFinder/1.0"}
        )

    def get_all_pieces(self) -> List[Dict[str, Any]]:
        """Get all music pieces from the API"""
        url = f"{self.base_url}/pieces.json"
        response = self.session.get(url)
        response.raise_for_status()
        return response.json()

    def find_mood_pieces(self, moods: List[str]) -> List[Dict[str, Any]]:
        """
        Find pieces matching specific moods/feels
        Args:
            moods: List of mood keywords to search for
        Returns:
            List of pieces that match any of the specified moods
        """
        all_pieces = self.get_all_pieces()
        return [
            piece
            for piece in all_pieces
            if any(mood.lower() in piece.get("feel", "").lower() for mood in moods)
        ]

    def process_pieces(self, pieces: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Process pieces with:
        - Randomly select 4 as "free"
        - Mark others as "pro"
        - Add proper download URLs
        """
        # Shuffle and select 4 random pieces
        shuffled = pieces.copy()
        random.shuffle(shuffled)
        free_pieces = shuffled[:4]

        # Add access level and corrected download URL
        for piece in pieces:
            piece["access"] = "free" if piece in free_pieces else "pro"
            piece["download_url"] = f"{self.download_base}/{piece['filename']}"
            # Add additional useful fields
            piece["metadata_url"] = (
                f"{self.base_url}/{piece['filename'].replace('.mp3', '')}"
            )

        return pieces

    def save_to_json(self, data: List[Dict[str, Any]], filename: str):
        """Save data to JSON file with proper formatting"""
        with open(filename, "w") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)


if __name__ == "__main__":
    client = IncompetechMusicClient()

    try:
        # 1. Find pieces with target moods
        target_moods = ["bright", "relaxed", "uplifting"]
        mood_pieces = client.find_mood_pieces(target_moods)[0:20]

        # 2. Process with access levels and proper URLs
        processed_pieces = client.process_pieces(mood_pieces)

        # 3. Save to JSON
        output_file = "../../extras/mood_music_catalog.json"
        client.save_to_json(
            {
                "generated_at": datetime.now().isoformat(),
                "total_pieces": len(processed_pieces),
                "free_count": sum(1 for p in processed_pieces if p["access"] == "free"),
                "pieces": processed_pieces,
            },
            output_file,
        )

        # Print summary
        print(f"Generated catalog with {len(processed_pieces)} pieces")
        print(
            f"- Free access: {sum(1 for p in processed_pieces if p['access'] == 'free')} pieces"
        )
        print(
            f"- Pro access: {sum(1 for p in processed_pieces if p['access'] == 'pro')} pieces"
        )
        print(f"Saved to {output_file}")

    except requests.exceptions.RequestException as e:
        print(f"Error accessing the API: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")
