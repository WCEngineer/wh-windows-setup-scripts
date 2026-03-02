#--- PDF ---
try {
	winget install --id=PDFgear.PDFgear --exact --silent --accept-package-agreements --accept-source-agreements
} catch {
	choco install -y pdfgear
}
try {
	winget install --id=geeksoftwareGmbH.PDF24Creator --exact --silent --accept-package-agreements --accept-source-agreements
} catch {
	choco install -y pdf24
}

#--- Office Suite ---
winget install --id=ONLYOFFICE.DesktopEditors --exact --silent --accept-package-agreements --accept-source-agreements
