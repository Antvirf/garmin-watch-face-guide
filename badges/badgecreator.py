"""
Python script to get ratings and downloads from Garmin Marketplace, and create repo badges for both.
"""
import re

import requests


def find_rating(text):
    """Given Garmin marketplace page for the app, extract rating value"""
    return re.search(r"class=\"rating\" title=\"(.*)\"", text).group(1)


def find_downloads(text):
    """Given Garmin marketplace page for the app, extract downloads value"""
    return re.search(r"glyphicon glyphicon-circle-arrow-down\"><\/span> <span>(\d*)<\/span><\/span>", text).group(1)


def create_badge(text, value):
    """Given a text and a number, generate an .svg badge"""
    url = f"https://img.shields.io/badge/{text}-{value}-brightgreen"
    svg_text = requests.get(url).text

    with open(text+".svg", "w") as writer:
        writer.write(svg_text)


if __name__ == "__main__":
    text = requests.get(
        r"https://apps.garmin.com/en-US/apps/{pending}"
    ).text

    downloads = find_downloads(text)
    rating = find_rating(text)

    create_badge("downloads", downloads)
    create_badge("rating", rating)
