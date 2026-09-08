
The core functionality of the system is to manage items and location of where those items are located.

The functionality includes:
* adding item name and details which creates corresponding qrcode
* scanning a qr code to identify the item and to mark the gps coordinates of the item
* ability to see a list of items based on location
* ability to name a location based on gps coordinate space
* ability to set a location based on address for an item (eg. shipping a laptop to remote)

Primary business drivers:
* managing event equipment and band items
* managing assets and locations

Progressive usage:
* Mobile app will allow adding items, scan and mark items with gps saving in a local db 
* Mobile app upsell will add team support with followup crdt support for syncing with api and ability to use the app
* App will allow more management of item details and ability to add custom fields such as specific area when scanned
