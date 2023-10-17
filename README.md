# Appx Package Uninstall Tool
A simple GUI to remove Appx Packages.

## Usage
1. Run the following command in PowerShell:
    ```ps
    irm "https://raw.githubusercontent.com/Aetopia/Appx-Package-Uninstall-Tool/main/AppxPackageUninstallTool.ps1" | iex
    ```

2. The GUI should show all current installed Appx Packages which can be obtained from the Microsoft Store.
3. Buttons:
    |Button|Function|
    |-|-|
    |Refresh|Requeries installed packages as well as clears any selections.
    |Select All|Select all Appx Packages to uninstall.
    |Uninstall|Uninstall selected packages.|