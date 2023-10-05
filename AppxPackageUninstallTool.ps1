Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web.Extensions
[void][System.Windows.Forms.Application]::EnableVisualStyles()



[System.Web.Script.Serialization.JavaScriptSerializer]$JavaScriptSerializer = [ System.Web.Script.Serialization.JavaScriptSerializer]::new()
$ProgressPreference = 'SilentlyContinue'
$JavaScriptSerializer.MaxJsonLength = ([string]$String = (Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/Aetopia/Appx-Package-Uninstall-Tool/main/Packages.json").Content).Length
$ProgressPreference = 'Continue'
[hashtable]$AppxPackages = [ordered]@{}
[hashtable] $Packages = $JavaScriptSerializer.Deserialize($String, ([ordered]@{}).GetType())

[System.Windows.Forms.Form]$Form = [ System.Windows.Forms.Form]::new()
[System.Windows.Forms.TableLayoutPanel]$TableLayoutPanel1 = [System.Windows.Forms.TableLayoutPanel]::new()
[System.Windows.Forms.TableLayoutPanel]$TableLayoutPanel2 = [System.Windows.Forms.TableLayoutPanel]::new()
[System.Windows.Forms.ListView]$ListView = [System.Windows.Forms.ListView]::new()
[System.Windows.Forms.Button]$Button1 = [System.Windows.Forms.Button]::new()
[System.Windows.Forms.Button]$Button2 = [System.Windows.Forms.Button]::new()

$Form.Text = 'Appx Package Uninstall Tool'
$Form.Font = [System.Drawing.SystemFonts]::MessageBoxFont
$Form.StartPosition = 'CenterScreen'
[void]$Form.Add_Resize({  
        $Form.Topmost = $false
        $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
        $Form.MinimizeBox = $Form.MaximizeBox = $false;
        $Form.ClientSize = [System.Drawing.Size]::new(800, 600)
        $ListView.Columns[0].Width = $ListView.ClientSize.Width })
        $Form.Add_Load({$Button2.PerformClick()})
[void]$Form.Controls.Add($TableLayoutPanel1)

$TableLayoutPanel1.Dock = [System.Windows.Forms.DockStyle]::Fill
[void]$TableLayoutPanel1.Controls.Add($ListView, 0, 0);
[void]$TableLayoutPanel1.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Percent, 100));
[void]$TableLayoutPanel1.Controls.Add($TableLayoutPanel2, 0, 1);
[void]$TableLayoutPanel1.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 100));

$TableLayoutPanel2.Dock = [System.Windows.Forms.DockStyle]::Fill
[void]$TableLayoutPanel1.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Percent, 5.625));
$TableLayoutPanel2.Controls.Add($Button1, 0, 0)
$TableLayoutPanel2.Controls.Add($Button2, 1, 0)

$ListView.ShowItemToolTips = $ListView.CheckBoxes = $true
$ListView.Dock = [System.Windows.Forms.DockStyle]::Fill
$ListView.View = [System.Windows.Forms.View]::Details
$ListView.HeaderStyle = [System.Windows.Forms.ColumnHeaderStyle]::None
$ListView.Add_ItemChecked({ 
        [System.Windows.Forms.ItemCheckedEventArgs]$ItemCheckedEventArgs = [System.Windows.Forms.ItemCheckedEventArgs]$_
        $Button1.Enabled = ($ListView.Items | Where-Object { $_.Checked }).Count   
        if ($Packages.Contains($AppxPackages[$ItemCheckedEventArgs.Item.Text])) {

            if ($Packages[$ItemCheckedEventArgs.Item.Text] | 
                Where-Object { $_ -in $AppxPackages.Values }) {
                $ItemCheckedEventArgs.Item.Checked = $false  
                $ItemCheckedEventArgs.Item.ForeColor = [System.Drawing.SystemColors]::GrayText
                $ItemCheckedEventArgs.Item.BackColor = [System.Drawing.SystemColors]::InactiveBorder
                $ItemCheckedEventArgs.Item.ToolTipText = "This package cannot be uninstalled because it depends on:`n$(
                                       ($AppxPackages.GetEnumerator() | Where-Object {$_.Value -in $Packages[$ItemCheckedEventArgs.Item.Text] }).Key -Join "`n")"
            }
        }
    } )
[void]$ListView.Columns.Add("")

$Button1.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -band [System.Windows.Forms.AnchorStyles]::Left
$Button1.Text = "Uninstall"
$Button1.Add_Click({
        if ([System.Windows.Forms.MessageBox]::Show("Uninstall Selected Appx Packages?",
                "Uninstall",
                [ System.Windows.Forms.MessageBoxButtons]::YesNo, 
                [ System.Windows.Forms.MessageBoxIcon]::Question) -eq [System.Windows.Forms.DialogResult]::Yes) {
            $ListView.Items | Where-Object { $_.Checked } | ForEach-Object {
                Write-Host $($AppxPackages[$_.Text])
            }
            & $Button2_Click
        }
    })

$Button2.Anchor = [System.Windows.Forms.AnchorStyles]::Right
$Button2.Text = "Refresh"
$Button2.Add_Click({ 
    $AppxPackages.Clear()
    $ListView.Items.Clear()
    Get-AppxPackage | 
    Where-Object { $_.SignatureKind -eq "Store" -and !$_.IsFramework } | 
    Get-AppxPackageManifest | 
    ForEach-Object {   
        $AppxPackages.Add($(
                if ($_.Package.Properties.DisplayName -eq "ms-resource:DisplayName") 
                { $_.Package.Identity.Name } 
                else { $_.Package.Properties.DisplayName }),
            $_.Package.Identity.Name)
    } 
    $AppxPackages.Keys | ForEach-Object {
        [System.Windows.Forms.ListViewItem] $ListViewItem = [System.Windows.Forms.ListViewItem]::new($_)
        $ListViewItem.ToolTipText = "This package can be uninstalled because it depends on nothing."
        [void]$ListView.Items.Add($ListViewItem) } 
})


$Form.ClientSize = [System.Drawing.Size]::new(0, 0)
$Form.Activate()
[void]$Form.ShowDialog()