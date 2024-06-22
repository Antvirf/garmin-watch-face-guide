"""
Python script to get ratings and downloads from Garmin Marketplace, and create repo badges for both.
"""

import json
import requests

GARMIN_APP_IDENTIFIER = "38b1b25e-3cf7-4993-9fd9-7ced64eb3564"


def create_badge(text, value):
    """Given a text and a number, generate an .svg badge"""
    response = requests.get(f"https://img.shields.io/badge/{text}-{value}-brightgreen")
    response.raise_for_status()
    svg_text = response.text

    with open(text + ".svg", "w") as writer:
        writer.write(svg_text)


if __name__ == "__main__":
    response = requests.get(
        f"https://apps.garmin.com/api/appsLibraryExternalServices/api/asw/apps/{GARMIN_APP_IDENTIFIER}?"
    )
    response.raise_for_status()
    response_json = json.loads(response.text)

    try:
        downloads = response_json["downloadCount"]
        rating = response_json["averageRating"]
    except KeyError:
        print(
            "Something went wrong parsing the JSON response, check its contents below:"
        )
        print(
            json.dumps(
                response_json,
                indent=4,
                sort_keys=True,
            )
        )

    create_badge("downloads", downloads)
    create_badge("rating", rating)
