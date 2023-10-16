Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Web.Extensions
[void][System.Windows.Forms.Application]::EnableVisualStyles()

[hashtable]$AppxPackages = [ordered]@{}
[System.Windows.Forms.Form]$Form = [ System.Windows.Forms.Form]::new()
[System.Windows.Forms.TableLayoutPanel]$TableLayoutPanel1 = [System.Windows.Forms.TableLayoutPanel]::new()
[System.Windows.Forms.TableLayoutPanel]$TableLayoutPanel2 = [System.Windows.Forms.TableLayoutPanel]::new()
[System.Windows.Forms.ListView]$ListView = [System.Windows.Forms.ListView]::new()
[System.Windows.Forms.Button]$UninstallButton = [System.Windows.Forms.Button]::new()
[System.Windows.Forms.Button]$RefreshButton = [System.Windows.Forms.Button]::new()
[System.Windows.Forms.Button]$SelectAllButton = [System.Windows.Forms.Button]::new()

$Form.Text = 'Appx Package Uninstall Tool'
$Form.Font = [System.Drawing.SystemFonts]::MessageBoxFont
$Form.StartPosition = 'CenterScreen'
[void]$Form.Add_Resize({  
                $Form.Topmost = $false
                $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
                $Form.MinimizeBox = $Form.MaximizeBox = $false;
                $Form.ClientSize = [System.Drawing.Size]::new(800, 600)
                $ListView.Columns[0].Width = $ListView.ClientSize.Width })
                [void]$Form.Add_Load({ $RefreshButton.PerformClick() })
[void]$Form.Controls.Add($TableLayoutPanel1)

$TableLayoutPanel1.Dock = [System.Windows.Forms.DockStyle]::Fill
[void]$TableLayoutPanel1.Controls.Add($ListView, 0, 0);
[void]$TableLayoutPanel1.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Percent, 100));
[void]$TableLayoutPanel1.Controls.Add($TableLayoutPanel2, 0, 1);
[void]$TableLayoutPanel1.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 100));

$TableLayoutPanel2.Dock = [System.Windows.Forms.DockStyle]::Fill
[void]$TableLayoutPanel1.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Percent, 5.625));
$TableLayoutPanel2.Controls.Add($RefreshButton, 0, 0)
$TableLayoutPanel2.Controls.Add($SelectAllButton, 1, 0)
$TableLayoutPanel2.Controls.Add($UninstallButton, 2, 0)


$ListView.ShowItemToolTips = $ListView.CheckBoxes = $true
$ListView.Dock = [System.Windows.Forms.DockStyle]::Fill
$ListView.View = [System.Windows.Forms.View]::Details
$ListView.HeaderStyle = [System.Windows.Forms.ColumnHeaderStyle]::None
$ListView.add
[void]$ListView.Add_ItemChecked({ $UninstallButton.Enabled = [bool]($ListView.Items | Where-Object { $_.Checked }).Count } )
[void]$ListView.Columns.Add("")

$UninstallButton.Anchor = [System.Windows.Forms.AnchorStyles]::Right
$UninstallButton.Text = "Uninstall"
[void]$UninstallButton.Add_Click({
                if ([System.Windows.Forms.MessageBox]::Show("Uninstall Selected Appx Packages?",
                                "Uninstall",
                                [ System.Windows.Forms.MessageBoxButtons]::YesNo, 
                                [ System.Windows.Forms.MessageBoxIcon]::Question) -eq [System.Windows.Forms.DialogResult]::Yes) {
                        $ListView.Items | Where-Object { $_.Checked } | ForEach-Object { Get-AppxPackage $($AppxPackages[$_.Text]) | Remove-AppxPackage }
                        $RefreshButton.PerformClick()
                }
        })

$SelectAllButton.Text = "Select All"
[void]$SelectAllButton.Add_Click({ $ListView.Items | ForEach-Object { ([System.Windows.Forms.ListViewItem]$_).Checked = $true } })

$RefreshButton.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -band [System.Windows.Forms.AnchorStyles]::Left
$RefreshButton.Text = "Refresh"
[void]$RefreshButton.Add_Click({ 
                $AppxPackages.Clear()
                $ListView.Items.Clear()
                Get-AppxPackage | 
                Where-Object { $_.SignatureKind -eq "Store" -and !$_.IsFramework } | 
                Get-AppxPackageManifest | 
                ForEach-Object {   
                        $AppxPackages.Add($(
                                        if ($_.Package.Properties.DisplayName -like "ms-resource:*") 
                                        { $_.Package.Identity.Name } 
                                        else { $_.Package.Properties.DisplayName }),
                                $_.Package.Identity.Name)
                } 
                $AppxPackages.Keys | ForEach-Object { [void]$ListView.Items.Add($_) }
                $UninstallButton.Enabled = [bool]($ListView.Items | Where-Object { $_.Checked }).Count })


$Form.ClientSize = [System.Drawing.Size]::new(0, 0)
[void]$Form.Activate()
[void]$Form.ShowDialog()