#--- Browsers ---
try {
	winget install --id=Google.Chrome --exact --silent --accept-package-agreements --accept-source-agreements
} catch {
	choco install -y googlechrome
}
try {
	winget install --id=Mozilla.Firefox --exact --silent --accept-package-agreements --accept-source-agreements
} catch {
	choco install -y firefox
}
