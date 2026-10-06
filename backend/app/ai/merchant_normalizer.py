import re
from typing import Optional

# Map of cleaned lowercase names -> display name
MERCHANT_DISPLAY_NAMES: dict[str, str] = {
    "swiggy": "Swiggy",
    "zomato": "Zomato",
    "uber": "Uber",
    "ola": "Ola",
    "rapido": "Rapido",
    "netflix": "Netflix",
    "spotify": "Spotify",
    "amazon": "Amazon",
    "flipkart": "Flipkart",
    "myntra": "Myntra",
    "bigbasket": "BigBasket",
    "blinkit": "Blinkit",
    "jio": "Jio",
    "airtel": "Airtel",
    "bsnl": "BSNL",
    "paytm": "Paytm",
    "phonepe": "PhonePe",
    "gpay": "Google Pay",
    "googlepay": "Google Pay",
    "apollopharmacy": "Apollo Pharmacy",
    "1mg": "1mg",
    "practo": "Practo",
    "irctc": "IRCTC",
    "makemytrip": "MakeMyTrip",
    "goibibo": "Goibibo",
    "oyo": "OYO",
    "hdfc": "HDFC Bank",
    "sbi": "SBI",
    "icici": "ICICI Bank",
    "axis": "Axis Bank",
    "kotak": "Kotak Bank",
    "lic": "LIC",
    "byju": "BYJU'S",
    "unacademy": "Unacademy",
    "coursera": "Coursera",
    "udemy": "Udemy",
    "dmart": "D-Mart",
    "reliance": "Reliance",
    "mcdonalds": "McDonald's",
    "kfc": "KFC",
    "subway": "Subway",
    "dominos": "Domino's",
    "pizzahut": "Pizza Hut",
    "starbucks": "Starbucks",
    "ccd": "Cafe Coffee Day",
    "indigo": "IndiGo",
    "spicejet": "SpiceJet",
    "airindia": "Air India",
}

# Patterns to remove from merchant names
NOISE_PATTERNS = [
    r"\*\w+",           # *ABC123
    r"/\d+",            # /123456
    r"\s+\d{6,}",       # trailing long numbers
    r"\s+(pvt|ltd|llp|inc|corp|india|technologies|services|solutions)\.?$",  # suffixes
    r"^\d+\s+",         # leading numbers
    r"\s+#\w+",         # hash tags
]


def normalize_merchant(raw_name: Optional[str]) -> Optional[str]:
    if not raw_name:
        return None

    name = raw_name.strip()

    # Remove noise patterns
    for pattern in NOISE_PATTERNS:
        name = re.sub(pattern, "", name, flags=re.IGNORECASE).strip()

    # Collapse multiple spaces
    name = re.sub(r"\s+", " ", name).strip()

    if not name:
        return raw_name.strip()

    # Check alias map (normalize to lowercase, no spaces)
    cleaned_key = re.sub(r"[\s\-_]", "", name.lower())
    for key, display in MERCHANT_DISPLAY_NAMES.items():
        if cleaned_key.startswith(key) or key in cleaned_key:
            return display

    # Title case fallback
    return name.title()
