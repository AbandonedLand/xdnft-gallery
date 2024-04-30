# xdnft-gallery

This Windows Powershell script will scan a folder with Offer files and build an NFT website for the offers. 

### Notes

* This is based off offer files, so you need to have offer files saved off on the local drive first.
* If MintGarden, Dexie support ABA also, need to add those in also.
* The script will download the full-size image and resize it to 200 pixels wide, keeping the aspect ratio. Then the page will use the smaller resized version as thumbnails and link to the original.
* The sequence of the functions does matter, so be warned before moving functions around. Some are setting global variable the when they run which other functions will need.

### User Config

* Need to set the Spacescan URL at the top of the script.
* The collectionID function at the top of the script relys on my own XCHDEV API. You can bypass this by changing "YOUR_COLLECTION_ID" in the return statement. You'll need to uncomment by removing the hashtag '#' and then comment out the existing return by adding a hashtag before "return $response.col_id"
* All of the CSS is in one spot so it can be updated as desired.

### Output

The script will create an `index.html` file in the output folder you are prompted for when the script runs. If the folder does already exist it will get created. All the images for the NFT will allow be downloaded and a resized version stored in that same folder. So, you will have all the necessary website files all in one, easy to upload folder.

### Running the script

```PowerShell
.\xdnft-gallery.ps1
```

### Update History

* 2024-04-29 SRS - Initial build - version 0.1
* 2024-04-27 SRS - Started
