#--- Nvidia Graphics ---
choco feature enable -n=useRememberedArgumentsForUpgrades
cinst nvidia-display-driver --package-parameters="'/dch'"
