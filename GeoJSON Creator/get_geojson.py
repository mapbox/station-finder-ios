import json
import urllib2
import sys

# We aren't going to register an API key for this, we are only making a one-off
# request to get the stations data. Don't do this for real apps!
if not len(sys.argv) == 2:
    print("Please enter the sample API key from http://developer.wmata.com/io-docs")
    print("Usage: $ python get_geojson.py <api_key>")
    sys.exit()
else:
    api_key = sys.argv[1]

# Get the station names and ids from the local file. This had to be manually 
# creeated, WMATA didn't bother to match up the station ids and codes. Sigh.
with open('station_ids.json', 'r') as f:
    station_id_data = json.loads(f.read())

station_ids = {}
for item in station_id_data:
    station_ids[item['name']] = item['id']

# Get the stations api data
try:
    url = 'http://api.wmata.com/Rail.svc/json/jStations?api_key=%s' % api_key
    request = urllib2.urlopen(url)
except urllib2.HTTPError:
    sys.exit("An error occurred while requesting the API data. Check your key.")

# Transform the api data response into JSON data
try:
    wmata_json = json.loads(request.read())
except ValueError:
    sys.exit("Uh oh, something happened when requesting the station JSON.")

# The line colors arrive as abbreviations, but we are going to save
# them with their full color names
line_colors = {
    'RD': 'Red',
    'BL': 'Blue',
    'OR': 'Orange',
    'SV': 'Silver',
    'YL': 'Yellow',
    'GR': 'Green',
}

# Loop over all the stations in the JSON data and turn them into features
features = []
for item in wmata_json['Stations']:
    
    # Construct a full street address
    address = "%s, %s, %s %s" % (item['Address']['Street'], item['Address']['City'], 
        item['Address']['State'], item['Address']['Zip'])
    
    # The line colors arrive as four separate properties, we will store
    # them as an array
    lines = []
    for key in ('LineCode1', 'LineCode2', 'LineCode3', 'LineCode4'):
        if item[key]:
            line_color = line_colors[item[key]]
            lines.append(line_color)

    # See if we can find the URL for the station realtime schedule page based 
    # on the data file we already have that stores the station ID code
    # based on the name of the station
    try:
        url = "http://www.wmata.com/rider_tools/pids/showpid.cfm?station_id=%s" % station_ids[item['Name']]
    except KeyError:
        print "Could not find key: %s" % item['Name']
        url = None
    
    features.append({
        "type": "Feature",
        "geometry": {
            "type": "Point",
            "coordinates": [
                item['Lon'],
                item['Lat']
            ]
        },
        "properties": {
            "address": address,
            "description": item['Name'],
            "marker-symbol": "rail-metro",
            "title": item['Name'],
            "url": url,
            "lines": lines
        }
    })

# Unbelievably, the same station can exist in the json
# feed more than once. Look for them and combine them.
stations_by_address = {}

for station in features:

    address = station['properties']['address']
    
    # See if this address has already been stored
    if stations_by_address.has_key(address):
        
        # Get the previously stored station
        previous_station = stations_by_address[address]
        
        # Get the previous and current station's lines
        previous_station_lines = previous_station['properties']['lines']
        current_station_lines = station['properties']['lines']
        
        # Combine the lines and save the unique items
        new_lines = list(set(previous_station_lines + current_station_lines))
        
        # Overwrite the stored lines with the new set
        previous_station['properties']['lines'] = new_lines

    # If the station wasn't already stored, store it
    else:
        stations_by_address[address] = station

# Now that we've filtered out duplicate stations, write 
# out the list of just the uniques
unique_features = [stations_by_address[key] for key in stations_by_address.keys()]

output = {}
output['type'] = 'FeatureCollection'
output['features'] = unique_features

with open('stations.geojson', 'w') as f:
    f.write(json.dumps(output, indent=4))

print "Done."