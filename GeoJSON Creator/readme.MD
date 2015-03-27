#WMATA Station JSON to Geojson Converter#

To keep this guide simple, we're going to use Geojson, a standard way of storing geographic 
data and related properties in JSON format.

In order to use the Python script, you'll have to either register an API key or find the 
sample one on this page: https://developer.wmata.com/demokey

*Note: If this was a production application that was hitting the WMATA API, we'd register an 
API key. For this script, since it is only meant to run once, it is not a big deal.*

##Usage##

    $ python get_geojson.py <API KEY>

##Output##

The script will output `stations.geojson`. You can copy that to the application bundle for use in the demo app.
