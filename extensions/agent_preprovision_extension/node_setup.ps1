# Script file to create tmp directory in windows nodes
# Also pulls images on the node

Write-Host "Prepulling all test images"

Start-BitsTransfer https://raw.githubusercontent.com/e2e-win/k8s_images/master/Utils.ps1
Start-BitsTransfer https://raw.githubusercontent.com/e2e-win/k8s_images/master/PullImages.ps1

./PullImages.ps1


Write-Host "$(date)- Creating tmp directory"

mkdir C:\tmp
mkdir C:\tmp\home
