# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#   Name:				xdnft-gallery
#   Description:		Powershell script to build a webpage from a folder of offers.
#   Author:				Steve Stepp
#   Created on:			April 27, 2024
#   Latest version:		0.2
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#   Update history:		
#   2024-04-27 SRS - Started
#   2024-04-29 SRS - Initial build - version 0.1
#   2024-05-04 ABM - MultiChain Settings - version 0.2
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#   Notes:	• This is based off offer files, so you need to have offer files saved off on the local drive first.
# 			• If MintGarden, Dexie support ABA also, need to add those in also.
#			• The script will download the full-size image and resize it to 200 pixels wide, keeping the aspect
#				ratio. Then the page will use the smaller resized version as thumbnails and link to the original.
#			• The sequence of the functions does matter, so be warned before moving functions around. Some are
#				setting global variable the when they run which other functions will need.
#
#   User Config
#			• Need to set the Spacescan URL below.
#			• The collectionID function below relys on my own XCHDEV API. You can bypass this by changing
#				"YOUR_COLLECTION_ID" in the return statement. You'll need to uncomment by removing the hashtag '#'
#				and then comment out the existing return by adding a hashtag before "return $response.col_id"
#			• All of the CSS is in one spot so it can be updated as desired.
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
Add-Type -AssemblyName System.Drawing


<#
	Creating a global variable called $chain.  This varriable will replace all the
	shell commands in the script where you need to call the blockchain.  This 
	will also set the spacescan api location for the remainder of the script.
#>
$Global:chain = "aba"
$Global:spacescan_url = "https://aba.spacescan.io/"
Function Set-Blockchain {
	param(
		[Parameter(Mandatory)]
    	[ValidateSet("chia","aba")] $blockchain
	)
	# Set spacescan uri to chia
	if($blockchain -eq "chia"){
		$Global:spacescan_url = "https://spacescan.io"
	}
	# Set spacescan uri to aba
	if($blockchain -eq "aba"){
		$Global:spacescan_url = "https://aba.spacescan.io/"
	}

	# Set blockchain 
	$Global:chain = $blockchain

}




function collectionID {
		param(
		[string]$pubdid,
		[string]$id
	)

	$url = "https://xchdev.com/xdapi/v1.php"
	$headers = @{
		"Content-Type" = "application/json"
		"API-KEY" = "YOUR_API_KEY_HERE"
	}
	$body = @{
		action = "get_col_id"
		did = "$pubdid"
		id = "$id"
	} | ConvertTo-Json

	$response = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $body -ContentType "application/json"
	#return "YOUR_COLLECTION_ID"
	return $response.col_id
}

function DownloadAndResize-Image {
    param (
        [string]$url,
        [string]$outputDirectory
    )

    $webClient = New-Object System.Net.WebClient
    $fileName = [System.IO.Path]::GetFileName($url)
    $tempImagePath = Join-Path -Path $outputDirectory -ChildPath $fileName
    $webClient.DownloadFile($url, $tempImagePath)
    $image = [System.Drawing.Image]::FromFile($tempImagePath)
    $newWidth = 200
    $newHeight = [math]::Round($image.Height * ($newWidth / $image.Width))
    $resizedImage = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($resizedImage)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($image, 0, 0, $newWidth, $newHeight)
    $resizedImagePath = Join-Path -Path $outputDirectory -ChildPath ("resized_" + $fileName)
    $resizedImage.Save($resizedImagePath)
    $image.Dispose()
    $resizedImage.Dispose()
    $graphics.Dispose()
    Remove-Item -Path $tempImagePath

    return "resized_" + $fileName
}

function htmlHeader {
	
	$style = @"
	:root {
		--attrborder:	#333333;
		--linkcolor:	#2A9FD6;
		--background:	#D9D9DB;
		--foreground:	#4A7933;
		--imgborder:	#DDDDDD;
		--copied:		#6A50A8;
		--nftdetail:	#EEDDEE;
	}
	body {
		font-family: Arial, sans-serif;
		margin: 0;
		padding: 0;
		background-color: var(--background);
		opacity: 1;
	}
	#banner {
		width: 100%;
		max-width: 100vw;
		height: auto;
		opacity: 0.75; /* Set opacity to 75% for the banner image */
	}
	#creator {
		float:left;
		margin-top: -5px;
		margin-left: 0px;
		margin-right: 16px;
		font-family: 'Ubuntu', san-serif;
		font-size: 1em;
		font-weight: 400;
		display: inline-block;
		background: var(--background);
		padding: 20px;
		height:650px;
		max-width: 475px;
	}
	#creator img {
		border-radius: 5%;
	}
	#creator_did {
		cursor: pointer;
		color: var(--foreground);
	}
	#collectionID {
		cursor: pointer;
		color: var(--foreground);
	}
	#MinterDID {
		cursor: pointer;
		color: var(--foreground);
	}
	.nftid_icon {
		cursor: pointer;
		color: var(--foreground);
	}
	.owner_did {
		cursor: pointer;
		color: var(--foreground);
	}
	.owner_address {
		cursor: pointer;
		color: var(--foreground);
	}
	#nft_details {
		background: var(--nftdetail);
	}
   .gallery {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
		gap: 10px;
		padding: 20px;
	}
	.gallery img {
		max-width: 100%;
		height: auto;
		border: 1px solid var(--imgborder);
		border-radius: 8px;
		transition: transform 0.3s ease-in-out;
		cursor: pointer;
	}
	.gallery img:hover {
		transform: scale(1.15);
	}
	#gallery_title { padding-bottom: 10px; }
	.h1 {
		text-align: left;
		font-family: 'Ubuntu', sans-serif;
		font-size: 5em;
		font-weight: 700;
		display: flex;
		align-items: center;
	}
	.h3 {
		text-align: left;
		font-family: 'Ubuntu', sans-serif;
		font-size: 2.5em;
		font-weight: 600;
		display: flex;
	}
	.h4 {
		text-align: left;
		font-family: 'Ubuntu', sans-serif;
		font-size: 1.75em;
		font-weight: 500;
		display: flex;
	}
	.h5 {
		text-align: left;
		font-family: 'Ubuntu', sans-serif;
		font-size: 1.33em;
		font-weight: 500;
		display: flex;
	}
	.h6 {
		text-align: left;
		font-family: 'Ubuntu', san-serif;
		font-size: 1em;
		font-weight: 400;
		display: flex;
	}
	.copied {
		color: var(--copied);
		transition: color 1s ease;
	}
	a {
		text-decoration: none;
	}
	#nft_description { font-weight:normal; font-style:italic; font-size: 0.8rem; }
	.nft { font-size: 0.8rem; font-family: 'Ubuntu', sans-serif; }
	.minted_at { font-size: 0.7rem; font-family: 'Ubuntu', sans-serif; }
	.data td { font-size: 0.9rem; font-family: 'Ubuntu', sans-serif; }
	#creator_title { font-size: 1.0rem; font-weight: 500; font-family: 'Ubuntu', sans-serif; }
	#collection_stats_title { font-size: 1.1rem; font-weight: 500; font-family: 'Ubuntu', sans-serif; }
	.attribute { vertical-align: top; }
	fieldset { border-color: var(--attrborder); padding-top: 3px; padding-bottom: 3px; padding-left: 6px; padding-right: 6px; }
	legend { font-weight: normal; }
	bottompad { padding-bottom: 15px; }
	nft_box { overflow: hidden; }
	.burned { text-align: center; }
	.right { text-align: right; }
	.offer_box { cursor: pointer; }
	.copied-message { position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); background-color: #4CAF50; color: white; padding: 15px; border-radius: 5px; display: none; }
	.expand-button { 
		background-color: #D9D9DB; border: 1px solid gray; border-radius: 8px; color: gray; padding: 10px 50px; text-align: center; text-decoration: none; 
		display: inline-block; font-size: 18px; margin: 0px 0px; cursor: pointer; height: 35px; vertical-align: text-top; width: 100%;
	}
	.powered-by {
		position: fixed;
		top: 0;
		right: 0;
		padding: 2px 6px; 
		background: linear-gradient(135deg, #ff7e5f, #feb47b); /* Gradient background */
		color: #ffffff; 
		font-family: "Jersey 15", sans-serif;
		font-weight: 400;
		font-style: normal;
		font-size: 14px;
		border: 2px solid #ffffff;
		border-radius: 5px;
		text-transform: uppercase;
		letter-spacing: 1px;
		z-index: 9999;
	}
"@
	
	$html = ""
	$html += "<!DOCTYPE html>`n"
	$html += "<html lang=`"en`">`n"
	$html += "<head>`n"
	$html += "`t<meta charset=`"UTF-8`">`n"
	$html += "`t<meta name=`"viewport`" content=`"width=device-width, initial-scale=1, shrink-to-fit=no`">`n"
    $html += "`t<!-- Font Awesome icons (free version)-->`n"
    $html += "`t<script src='https://use.fontawesome.com/releases/v5.13.0/js/all.js' crossorigin='anonymous'></script>`n"
	$html += "`t<link rel='preconnect' href='https://fonts.googleapis.com'>`n"
	$html += "`t<link rel='preconnect' href='https://fonts.gstatic.com' crossorigin>`n"
	$html += "`t<link href='https://fonts.googleapis.com/css2?family=Barlow+Condensed&family=Dosis:wght@200&family=Luckiest+Guy&family=Passion+One:wght@400;700&display=swap' rel='stylesheet'>`n"
	$html += "`t<link href='https://fonts.googleapis.com/css2?family=Jersey+15&family=Sedgwick+Ave&display=swap' rel='stylesheet'>`n"
	$html += "`t<title>$CollectionName</title>`n"
	$html += "`t<style>`n"
	$html += "$style`n"
	$html += "`t</style>`n"
	$html += "</head>`n"
	$html += "<body>`n"
	$html += "<div class='powered-by'>Powered by <a href='https://github.com/steppsr/xdnft-gallery' target='_blank'>XDNFT-Gallery</a></div>`n"

	$html += "<img id='banner' src='$BannerFile' alt='Banner'>`n"
	# LEFT SIDE BAR
	$html += "<div>`n"
	$html += "`t<!-- #COLLECTION DETAILS -->`n"
	$html += "`t<div id='creator'>`n"
	$html += "`t`t<table class='data'>`n"
	$html += "`t`t<tr><th colspan=4><img class='icon' src='$IconFile' alt='Icon'></th></tr>`n"
	$html += "`t`t<tr><td colspan=4><hr></td></tr> <!-- DIVIDER -->`n"
	$html += "`t`t<tr><td colspan=4><span class='h3' id='galleryTitle'>$CollectionName</span><br></td></tr>`n"
	$html += "`t`t<tr><td colspan=4><span class='h5' id='galleryDesc'>$CollectionDesc</span></td></tr>`n"
	$html += "`t`t<tr><td colspan=4><span class='h6'><span id='collectionID' title='$ColID'>📋 $ColID</span></span><div id='collectionID_IDCopied' class='copied-message'>Copied!</div></td></tr>`n"
	$html += "`t<script>`n"
	$html += "`tdocument.addEventListener('DOMContentLoaded', function() {`n"
	$html += "`t	var textarea = document.getElementById('collectionID');`n"
	$html += "`t	var copiedMessage = document.getElementById('collectionID_IDCopied');`n"
	$html += "`t	textarea.addEventListener('click', function() {`n"
	$html += "`t        var titleValue = textarea.getAttribute('title');`n"
	$html += "`t        navigator.clipboard.writeText(titleValue);`n"
	$html += "`t	    copiedMessage.style.display = 'block';`n"
    $html += "`t	    setTimeout(function() {`n"
    $html += "`t		    copiedMessage.style.display = 'none';`n"
    $html += "`t		}, 2000);`n"
	$html += "`t	});`n"
	$html += "`t});`n"
	$html += "`t</script>`n"
	$html += "`t`t<tr><td colspan=4><hr></td></tr> <!-- DIVIDER -->`n"
	$html += "`t`t<tr><td colspan=4 id='creator_title' class='h5'>Creator</td></tr>`n"
	$html += "`t`t<tr><td colspan=4><span class='h6'><span id='MinterDID' title='$MinterDID'>📋 $MinterDID</span></span><div id='MinterID_IDCopied' class='copied-message'>Copied!</div></td></tr>`n"
	$html += "`t<script>`n"
	$html += "`tdocument.addEventListener('DOMContentLoaded', function() {`n"
	$html += "`t	var textarea = document.getElementById('MinterDID');`n"
	$html += "`t	var copiedMessage = document.getElementById('MinterDID_IDCopied');`n"
	$html += "`t	textarea.addEventListener('click', function() {`n"
	$html += "`t        var titleValue = textarea.getAttribute('title');`n"
	$html += "`t        navigator.clipboard.writeText(titleValue);`n"
	$html += "`t	    copiedMessage.style.display = 'block';`n"
    $html += "`t	    setTimeout(function() {`n"
    $html += "`t		    copiedMessage.style.display = 'none';`n"
    $html += "`t		}, 2000);`n"
	$html += "`t	});`n"
	$html += "`t});`n"
	$html += "`t</script>`n"
	$html += "`t`t<tr><td>🌎 Website</td><td colspan=3><span id='$Website'><a href='$Website' target='_blank'>$Website</a></span></td></tr>`n"
	$html += "`t`t<tr><td>❎ Twitter:</td><td colspan=3><span id='$Twitter'><a href='https://x.com/$Twitter' target='_blank'>$Twitter</a></span></td></tr>`n"
	$html += "`t`t<tr><td colspan=4><hr></td></tr> <!-- DIVIDER -->`n"
	$html += "`t`t<tr><td colspan=4><a href='" + $spacescan_url + "collection/$ColID' target='_blank' title='View Collection on Spacescan'>🛸 Spacescan</a></span></td></tr>`n"
	$html += "`t`t<tr><td colspan=4><hr></td></tr> <!-- DIVIDER -->`n"
	$html += "`t`t</table>`n"
	$html += "`t</div> <!-- CREATOR -->`n"
	$html += "</div> <!-- COLLECTION DETAILS -->`n"
	
	# GALLERY NFTS
	$html += "<div class='gallery'>"
	return $html
}

function htmlFooter {
	$html = "</div> <!-- GALLERY -->`n"
	$html += "</body>`n"
	$html += "</html>`n"
	return $html
}

function nftHTML {
	param(
		[string]$nft_id,
		[string]$owner_did,
		[string]$minter_did,
		[string]$royalty_percentage,
		[string]$data_file,
		[string]$metadata_file,
		[string]$license_file,
		[string]$format,
		[string]$nft_name,
		[string]$nft_desc,
		[string]$mint_tool,
		[string]$sensitive,
		$collection_attributes,
		$attributes,
		[string]$requested,
		[string]$offer_code
	)
	
	$resized_filename = DownloadAndResize-Image -url $data_file -outputDirectory $OutputFolder
	
	# NFT-BOX
	$html = "<div class='nft_box'> <!-- NFT BOX -->`n"
	$html += "<fieldset>`n"
	$html += "<a href='$data_file' target='_blank'><img src='$resized_filename' alt='$data_file'></a> <!-- NFT IMAGE -->`n"

	# Start a 'foldable' section for the NFT Box. There will be a toggle button to Expand or Collapse this section of the box.
	$html += "<p> <div class='hidden-content' style='display: none;'><table>`n"
	
	# Create a short code for the NFT ID
	if ($nft_id.Length -gt 15) {
		$nft_id_short = $nft_id.Substring(0, 10) + "..." + $nft_id.Substring($nft_id.Length - 5)
	} else {
		$nft_id_short = ""
	}

	$html += "`t<tr><td colspan=2 class='nftid'><span class='nftid_icon h6' title='$nft_id'><span class='nftid_icon h6' id='$nft_id' title='$nft_id'>$nft_id_short 📋</span></span><br>`n"
	$html += "`t<span id='nft_description'>$nft_desc</span>`n"
	$html += "`t<div id='" + $nft_id + "_IDCopied' class='copied-message'>Copied!</div></td></tr>`n"
	$html += "`t</td></tr>`n"
	$html += "`t<script>`n"
	$html += "`tdocument.addEventListener('DOMContentLoaded', function() {`n"
	$html += "`t	var textarea = document.getElementById('" + $nft_id + "');`n"
	$html += "`t	var copiedMessage = document.getElementById('" + $nft_id + "_IDCopied');`n"
	$html += "`t	textarea.addEventListener('click', function() {`n"
	$html += "`t      var titleValue = textarea.getAttribute('title');`n"
	$html += "`t      navigator.clipboard.writeText(titleValue);`n"
	$html += "`t		copiedMessage.style.display = 'block';`n"
    $html += "`t		setTimeout(function() {`n"
    $html += "`t		    copiedMessage.style.display = 'none';`n"
    $html += "`t		}, 2000);`n"
	$html += "`t	});`n"
	$html += "`t});`n"
	$html += "`t</script>`n"
	
	$html += "`t<tr><td colspan=2><hr></td></tr>`n"

	# Loop through all the NFT attributes and build up an HTML string for them.
	$attributes_html = ""
	foreach($attr in $attributes) {
		if($attr.value.Length -gt 25) {
			$attributes_html += "`t`t<tr><td class='attribute' colspan=2>" + $attr.trait_type + "<br>" + $attr.value + "</td></tr>`n"
		} else {
			$attributes_html += "`t`t<tr><td class='attribute'>" + $attr.trait_type + "</td><td class='attribute right'>&nbsp;&nbsp;&nbsp;&nbsp;" + $attr.value + "</td></tr>`n"
		}
	}
	$html += "`t<tr><td colspan=2 class='nft'>Attributes:</td></tr>`n"
	$html += "`t<tr><td colspan=2><table class='nft'>$attributes_html</table></td></tr>`n"
	$html += "`t<tr><td colspan=2><hr></td></tr>`n"
	$html += "`t<tr><td class='nft'>Format:</td><td class='right'><span id='nft_format' class='nft'>$format</span></td></tr>`n"
	$html += "`t<tr><td class='nft'>Sensitive</td><td class='right'><span id='nft_sensitive' class='nft'>$sensitive</span></td></tr>`n"
	$html += "`t<tr><td class='nft'>Mint tool</td><td class='right'><span id='nft_mint_tool' class='nft'>$mint_tool</span></td></tr>`n"

	$html += "`t<tr><td colspan=2><hr></td></tr>`n"

	# Create a short code for the Minter DID / Creator DID
	if ($minter_did.Length -gt 25) {
		$minter_short = $minter_did.Substring(0, 15) + "..." + $minter_did.Substring($minter_did.Length - 10)
	} else {
		$minter_short = ""
	}

	# Set MinterDIDShort and MinterDID as Global Variables
	Set-Variable -Name MinterDIDShort -Value $minter_short -Scope Global
	Set-Variable -Name MinterDID -Value $minter_did -Scope Global

	# Create a short code for the Owner DID
	if ($owner_did.Length -gt 25) {
		$owner_short = $owner_did.Substring(0, 15) + "..." + $owner_did.Substring($owner_did.Length - 10)
	} else {
		$owner_short = ""
	}

	$html += "`t<tr><td colspan=2 class='nft'>Owner: <span id='" + $owner_did + "_owner_did' title='$owner_did'>$owner_short</span></td></tr>`n"

	$html += "`t<tr><td colspan=2>&nbsp;</td></tr>`n"

	# Loop through all the Collection attributes and set Global Variables for the values.
	$collection_attributes_summary = ""
	foreach($col_attr in $collection_attributes) {
		if($col_attr.type.ToLower() -eq "banner") {
			Set-Variable -Name BannerFile -Value $col_attr.value -Scope Global
		}
		if($col_attr.type.ToLower() -eq "icon") {
			Set-Variable -Name IconFile -Value $col_attr.value -Scope Global
		}
		if($col_attr.type.ToLower() -eq "website") {
			Set-Variable -Name Website -Value $col_attr.value -Scope Global
		}
		if($col_attr.type.ToLower() -eq "twitter") {
			Set-Variable -Name Twitter -Value $col_attr.value -Scope Global
		}
	}
	
	$html += "</table>`n</div>`n"

	# Create a button to 'fold' the NFT box.
	$html += "<button class='expand-button' onclick='toggleContent(this)'><i class='fa fa-chevron-down'></i></button></p>`n"

	# BELOW THE FOLD
	$html += "`t<table>`n"
	$royalty_html = $royalty_percentage / 100
	$html += "`t<tr><td class='nft'>Royalty:</td><td class='right'><span id='nft_format' class='nft'>$royalty_html %</span></td></tr>`n"
	$parts = $requested -split '\s+'
	$unit_of_measure = $parts[2]
	$amount = $parts[1]
	$price = $amount / (1 + ($royalty_percentage / 10000))
	$html += "`t<tr><td class='nft'>Price:</td><td class='right'><span id='nft_format' class='nft'>$price $unit_of_measure</span></td></tr>`n"
	$html += "`t<tr><td class='nft'>Total:</td><td class='right'><span id='nft_format' class='nft'>$amount $unit_of_measure</span></td></tr>`n"
	$html += "`t<tr><td colspan=2 class='nft'><textarea id='" + $nft_id + "_offer' rows='5' cols='22' class='offer_box' readonly title='Click to Copy'>$offer_code</textarea>`n"
	$html += "<div id='" + $nft_id + "_copiedMessage' class='copied-message'>Copied!</div></td></tr>`n"
	
	$html += "<script>`n"
	$html += "document.addEventListener('DOMContentLoaded', function() {`n"
	$html += "	var textarea = document.getElementById('" + $nft_id + "_offer');`n"
	$html += "	var copiedMessage = document.getElementById('" + $nft_id + "_copiedMessage');`n"
	$html += "	textarea.addEventListener('click', function() {`n"
	$html += "		textarea.select();`n"
	$html += "		document.execCommand('copy');`n"
	$html += "		textarea.setSelectionRange(0, 0);`n"
	$html += "		copiedMessage.style.display = 'block';`n"
    $html += "		setTimeout(function() {`n"
    $html += "		    copiedMessage.style.display = 'none';`n"
    $html += "		}, 2000);`n"
	$html += "	});`n"
	$html += "});`n"
	$html += "</script>`n"
	$html += "`t<tr><td colspan=2 class='nft'><a href='https://aba.spacescan.io/nft/$nft_id' target='_blank' title='View on Spacescan'>🛸</a>&nbsp;&nbsp;<a href='$data_file' target='_blank' title='Image File'>🖼️</a>&nbsp;&nbsp;<a href='$metadata_file' target='_blank' title='Metadata File'>Ⓜ️</a>&nbsp;&nbsp;<a href='$license_file' target='_blank' title='License File'>📜</a></td></tr>"
	$html += "`t</table>`n"

	$nft_name_html = ""
	$needle = $CollectionName + ":"
	if ($nft_name -match $needle) {
		$nft_name_html = $nft_name.Replace($needle, "").Trim()
	} else {
		$nft_name_html = $nft_name
	}
	$html += "<legend>$nft_name_html</legend></fieldset>`n"
	$html += "</div> <!-- NFT_BOX -->`n"
	# END NFT BOX

	return $html
}

function getNFTDataAsJSON {
     param(
        [string]$launcher_coin_id,
		[string]$fingerprint,
		[string]$input_folder
    )
	
	$getinfo_object = aba wallet nft get_info -f $fingerprint -ni $launcher_coin_id
	
	$nft_id = $getinfo_object | Select-String -Pattern "NFT identifier: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
	$owner_did = $getinfo_object | Select-String -Pattern "Owner DID: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
	$minter_did = $getinfo_object | Select-String -Pattern "Minter DID: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
	$royalty_percentage = $getinfo_object | Select-String -Pattern "Royalty percentage: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
	$data_file = $getinfo_object | Select-String -Pattern "^URIs:" -Context 0,1 | ForEach-Object { $_.Context.PostContext.Trim() }
	$metadata_file = $getinfo_object | Select-String -Pattern "Metadata URIs:" -Context 0,1 | ForEach-Object { $_.Context.PostContext.Trim() }
	$license_file = $getinfo_object | Select-String -Pattern "License URIs:" -Context 0,1 | ForEach-Object { $_.Context.PostContext.Trim() }
	$jsonString = Invoke-RestMethod -Uri $metadata_file -Method Get
	$offer_file = $input_folder + "\" + $launcher_coin_id + ".offer"
	$offer_code = Get-Content -Path $offer_file
	$format = $jsonString.format
	$nft_name = $jsonString.name
	$nft_desc = $jsonString.description
	$mint_tool = $jsonString.minting_tool
	$sensitive = $jsonString.sensitive_content
	$collection_id = collectionID -pubdid $minter_did -id $jsonString.collection.id
	$collection_name = $jsonString.collection.name
	$collection_attributes = $jsonString.collection.attributes
	$attributes = $jsonString.attributes
	$offer_object = aba wallet take_offer -f $fingerprint -e $offer_code
	$requested = $offer_object | Select-String -Pattern "^Total Amounts Requested:" -Context 0,1 | ForEach-Object { $_.Context.PostContext.Trim() }

	# set some globals
	Set-Variable -Name CollectionDesc -Value $nft_desc -Scope Global
	Set-Variable -Name ColID -Value $collection_id -Scope Global
	Set-Variable -Name CollectionName -Value $collection_name -Scope Global
	
	return nftHTML `
		-nft_id $nft_id `
		-owner_id $owner_id `
		-minter_did $minter_did `
		-royalty_percentage $royalty_percentage `
		-data_file $data_file `
		-metadata_file $metadata_file `
		-license_file $license_file `
		-format $format `
		-nft_name $nft_name `
		-nft_desc $nft_desc `
		-mint_tool $mint_tool `
		-sensitive $sensitive `
		-collection_attributes $collection_attributes `
		-attributes $attributes `
		-requested $requested `
		-offer_code $offer_code
}

# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
# MAIN 
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

# BANNER
Write-Host @"
______________________________________________________________
         _        __ _                    _ _                 
__  ____| |_ __  / _| |_       __ _  __ _| | | ___ _ __ _   _ 
\ \/ / _' | '_ \| |_| __|____ / _' |/ _' | | |/ _ \ '__| | | |
 >  < (_| | | | |  _| ||_____| (_| | (_| | | |  __/ |  | |_| |
/_/\_\__,_|_| |_|_|  \__|     \__, |\__,_|_|_|\___|_|   \__, |
                              |___/                     |___/ 
--------------------------------------------------------------
"@

<#	TODO - Get script configured to ask for the blockchain and use that in the CLI commands. For example: 'chia' or 'aba'
# SCRIPT ARGUMENTS
for ($i = 0; $i -lt $args.Length; $i++) {
    switch ($args[$i]) {
        "-b" {
            # Ensure there is an argument after "-b"
            if ($i + 1 -lt $args.Length) {
                $blockchain = $args[$i + 1]
            } else {
                $blockchain = ""
            }
        }
    }
}

# LETS MAKE SURE THE BLOCKCHAIN IS PASSED IN AS A PARAMENTER
if ([string]::IsNullOrEmpty($blockchain)) {
    Write-Host "Missing the blockchain input parameter '-b'."
	Write-Host "USAGE:  .\xdnft-gallery.ps1 -b <blockchain>"
    exit
}
#>

# FINGERPRINT SELECTION
Write-Host ""
Write-Host "--Fingerprint Selection--"
$fingers = aba keys show | Select-String -Pattern "Label: (.*)", "Fingerprint: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value }
$outcount = 1
$loopcount = 1
foreach ($record in $fingers) {
	if ($loopcount % 2 -eq 1) {
		#Write-Host "$number is an odd number."
		$option = [string]$outcount + ": " + [string]$record + " - "
	} else {
		#Write-Host "$number is not an odd number."
		$option += [string]$record
		Write-Host $option
		$outcount++
	}
	$loopcount++
}
$choice = Read-Host "Choose fingerprint to use"
$choice = [int]$choice * 2 - 1
$fingerprint = $fingers[$choice]
Write-Host "Selected fingerprint: $fingerprint" 
Write-Host ""

# WALLET ID SELECTION
Write-Host ""
Write-Host "--Wallet ID Selection--"
$wallet_ids = aba wallet show -w nft -f $fingerprint | Select-String -Pattern "(.*) NFT Wallet:", "-Wallet ID: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
$outcount = 1
$loopcount = 1
foreach ($record in $wallet_ids) {
	if ($loopcount % 2 -eq 1) {
		#Write-Host "$number is an odd number."
		$option = [string]$outcount + ": " + [string]$record + " - "
	} else {
		#Write-Host "$number is not an odd number."
		$option += [string]$record
		Write-Host $option
		$outcount++
	}
	$loopcount++
}
$choice = Read-Host "Choose Wallet ID to use"
$choice = [int]$choice * 2 - 1
$wallet_id = $wallet_ids[$choice]
Write-Host "Selected Wallet ID: $wallet_id" 
Write-Host ""

# PATH SELECTION
Write-Host ""
Write-Host "--Path Selection--"
$app_folder = Get-Location | Select-String ":"
$input_folder = Read-Host "Input folder (path to offers)"
$output_folder = Read-Host "Output folder (path for HTML output)"

# Create the output directory if it doesn't exist
if (-not (Test-Path $output_folder)) {
    New-Item -ItemType Directory -Path $output_folder | Out-Null
}
Set-Variable -Name OutputFolder -Value $output_folder -Scope Global

# GET LIST OF OFFER FILES FROM INPUT PATH
$offer_files = Get-ChildItem -Path $input_folder -Filter "*.offer"

Write-Host ""
Write-Host "--Offer Files--"

$output = ""
foreach ($offer in $offer_files) {
	Write-Host "$offer"
	$result = getNFTDataAsJSON -fingerprint $fingerprint -launcher_coin_id $offer.BaseName -input_folder $input_folder

	# One time Javascript Functions
	$result += "<script>`n"
    $result += "function toggleContent(button) {`n"
    $result += "    var content = button.previousElementSibling;`n"
    $result += "    if (content.style.display === 'none' || content.style.display === '') {`n"
    $result += "        content.style.display = 'block';`n"
    $result += "        button.innerHTML = '<i class=`"fa fa-chevron-up`"></i>';`n"
    $result += "    } else {`n"
    $result += "        content.style.display = 'none';`n"
    $result += "        button.innerHTML = '<i class=`"fa fa-chevron-down`"></i>';`n"
    $result += "    }`n"
    $result += "}`n"
	$result += "</script>`n"

	# Need to add a small delay when processing each offer file to allow the system to download & resize images.
	# With a sleep for 1 second, I was running into corrupt images occasionally.
	Start-Sleep -Seconds 1
	$output += $result + "`n"
}
$header = htmlHeader
$footer = htmlFooter
$output = $header + $output + $footer

$output_file = $output_folder + "\" + "index.html"

# Be sure to Encode the Output file as Utf8 so the Emojis will work.
$output | Set-Content -Path $output_file -Encoding Utf8
