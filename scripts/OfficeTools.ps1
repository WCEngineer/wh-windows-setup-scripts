#--- PDF ---
try { choco uninstall -y adobereader } catch {}
try { winget uninstall Adobe.Acrobat.Reader.32-bit --all-versions --silent --purge } catch {}
try { winget uninstall Adobe.Acrobat.Reader.64-bit --all-versions --silent --purge } catch {}
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
# winget install --id=ONLYOFFICE.DesktopEditors --exact --silent --accept-package-agreements --accept-source-agreements
