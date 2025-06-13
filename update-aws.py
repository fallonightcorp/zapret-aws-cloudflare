import requests
import os

# Path to the IP list file
list_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'lists', 'list-aws-amazon.txt')

# URL to fetch AWS IP ranges
url = 'https://ip-ranges.amazonaws.com/ip-ranges.json'

# Set a timeout of 10 seconds
try:
    response = requests.get(url, timeout=10)
    
    if response.status_code == 200:
        data = response.json()
        ip_list = []

        # Extract Amazon IP ranges
        for prefix in data['prefixes']:
            if prefix['service'] == 'AMAZON':
                ip_list.append(prefix['ip_prefix'])

        # Save the IPs to the file
        with open(list_path, 'w', encoding='utf-8') as file:
            file.write('\n'.join(ip_list))

        print(f"[INFO] IP updated: {len(ip_list)} IPs added.")
    else:
        print(f"[ERROR] Failed to fetch data. Error code: {response.status_code}")

except requests.exceptions.RequestException as e:
    # If the request fails (timeout or other issue), print error and continue
    print("[ERROR] Request failed: Timeout or other error.")
    print("[INFO] Using the current IP list.")
    exit(1)  # Exit with an error code
