# Modules/GUI.ps1
# Windows 11 Fluent WPF GUI for HailUninstaller with Orphan Storage Leftovers Scanner

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing

function Show-HailUninstallerGUI {
    [CmdletBinding()]
    param(
        [string]$ConfigDir = ""
    )

    $scriptDir = Split-Path $PSScriptRoot -Parent
    if (-not $ConfigDir) {
        $ConfigDir = Join-Path $scriptDir "Config"
    }

    $logoPath = Join-Path $scriptDir "logo.png"

    # Define XAML for Windows 11 Fluent UI
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="HailUninstaller - Deep Application &amp; Storage Removal" Height="820" Width="1160"
        MinHeight="700" MinWidth="980"
        WindowStartupLocation="CenterScreen"
        Background="#F3F3F3"
        FontFamily="Segoe UI Variable Text, Segoe UI, sans-serif">
    
    <Window.Resources>
        <!-- Button Styles -->
        <Style x:Key="SecondaryButton" TargetType="Button">
            <Setter Property="Background" Value="#FFFFFF"/>
            <Setter Property="Foreground" Value="#1B1B1B"/>
            <Setter Property="BorderBrush" Value="#E0E0E0"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#FBFBFB"/>
                    <Setter Property="BorderBrush" Value="#CECECE"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style x:Key="TabButton" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#5C5C5C"/>
            <Setter Property="BorderThickness" Value="0,0,0,2"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="#0067C0"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="24,8"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#1873C4"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- Fluent Card Style -->
        <Style x:Key="CardBorder" TargetType="Border">
            <Setter Property="Background" Value="#FFFFFF"/>
            <Setter Property="BorderBrush" Value="#E5E5E5"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="8"/>
            <Setter Property="Padding" Value="16"/>
            <Setter Property="Margin" Value="6"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="46"/>   <!-- Title Bar -->
            <RowDefinition Height="Auto"/> <!-- Page Heading -->
            <RowDefinition Height="Auto"/> <!-- Mode Selector Tabs -->
            <RowDefinition Height="Auto"/> <!-- Actions / Search Bar -->
            <RowDefinition Height="*"/>    <!-- Main Content Area -->
            <RowDefinition Height="60"/>   <!-- Bottom Navigation Bar -->
        </Grid.RowDefinitions>

        <!-- Top Title Bar -->
        <Border Grid.Row="0" Background="#F3F3F3" Padding="16,10" BorderBrush="#EAEAEA" BorderThickness="0,0,0,1">
            <Grid>
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <Image Name="TitleLogo" Width="20" Height="20" Margin="0,0,8,0"/>
                    <TextBlock Text="HailUninstaller" FontSize="13" FontWeight="SemiBold" Foreground="#1B1B1B"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <TextBlock Text="Deep Application &amp; Storage Removal Tool" FontSize="11" Foreground="#707070" Margin="0,0,16,0"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Page Heading -->
        <StackPanel Grid.Row="1" Margin="24,14,24,6">
            <TextBlock Name="TxtMainTitle" Text="Storage &amp; Application Cleaner" FontSize="22" FontWeight="Bold" Foreground="#1B1B1B"/>
            <TextBlock Name="TxtSubTitle" Text="Detect and remove orphaned leftover folders from uninstalled apps or cleanly uninstall existing programs." FontSize="13" Foreground="#5C5C5C" Margin="0,4,0,0"/>
        </StackPanel>

        <!-- Mode Selector Tabs -->
        <Border Grid.Row="2" Margin="24,0,24,6" BorderBrush="#E5E5E5" BorderThickness="0,0,0,1">
            <StackPanel Orientation="Horizontal">
                <Button Name="TabOrphans" Content="🧹 Uninstalled Ghost Folders" Style="{StaticResource TabButton}" BorderBrush="#0067C0" Foreground="#0067C0"/>
                <Button Name="TabInstalled" Content="📦 Installed Applications" Style="{StaticResource TabButton}" Margin="12,0,0,0"/>
            </StackPanel>
        </Border>

        <!-- Action / Filter Bar -->
        <Grid Grid.Row="3" Margin="24,6,24,12">
            <StackPanel Orientation="Horizontal">
                <Button Name="BtnSelectHigh" Content="Select High Confidence" Style="{StaticResource SecondaryButton}" Margin="0,0,8,0"/>
                <Button Name="BtnSelectAll" Content="Select All" Style="{StaticResource SecondaryButton}" Margin="0,0,8,0"/>
                <Button Name="BtnSelectHeavy" Content="Select &gt; 100 MB" Style="{StaticResource SecondaryButton}" Margin="0,0,8,0"/>
                <Button Name="BtnClearSelection" Content="Clear Selection" Style="{StaticResource SecondaryButton}" Margin="0,0,8,0"/>
                <Button Name="BtnScanLeftovers" Content="Rescan Storage" Style="{StaticResource SecondaryButton}"/>
            </StackPanel>

            <Border HorizontalAlignment="Right" Background="#FFFFFF" BorderBrush="#E0E0E0" BorderThickness="1" CornerRadius="5" Padding="8,4" Width="260">
                <Grid>
                    <TextBlock Text="🔍" Foreground="#888888" VerticalAlignment="Center" Margin="2,0,6,0"/>
                    <TextBox Name="TxtSearch" BorderThickness="0" Background="Transparent" Margin="22,0,0,0" FontSize="12" VerticalAlignment="Center" ToolTip="Search applications or leftovers"/>
                </Grid>
            </Border>
        </Grid>

        <!-- Main Content Area -->
        <Grid Grid.Row="4" Margin="18,0,18,0">
            
            <!-- VIEW A: Orphaned Storage Folders List -->
            <Grid Name="ViewOrphans" Visibility="Visible">
                <Border Style="{StaticResource CardBorder}" Margin="6">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <Grid Margin="4,0,0,8">
                            <TextBlock Name="TxtOrphanHeader" Text="Detected Orphan Folders (Apps are NOT installed, but folders remain on disk)" FontWeight="SemiBold" FontSize="14" Foreground="#1B1B1B"/>
                            <TextBlock Name="TxtOrphanCount" Text="Scanning storage..." HorizontalAlignment="Right" FontSize="12" Foreground="#0067C0" FontWeight="SemiBold"/>
                        </Grid>
                        <ListBox Name="LstOrphans" Grid.Row="1" BorderThickness="0" Background="Transparent" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                            <ListBox.ItemTemplate>
                                <DataTemplate>
                                    <Border BorderBrush="#F0F0F0" BorderThickness="0,0,0,1" Padding="8,8" Background="Transparent">
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="Auto"/>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <CheckBox IsChecked="{Binding Selected, Mode=TwoWay}" VerticalAlignment="Center" Margin="0,0,12,0"/>
                                            <StackPanel Grid.Column="1" VerticalAlignment="Center">
                                                <TextBlock Text="{Binding Name}" FontWeight="Bold" FontSize="13" Foreground="#1B1B1B"/>
                                                <TextBlock Text="{Binding Path}" FontSize="11" Foreground="#707070" ToolTip="{Binding Path}"/>
                                            </StackPanel>
                                            <Border Grid.Column="2" Background="#FFF4CE" CornerRadius="4" Padding="6,2" VerticalAlignment="Center" Margin="12,0">
                                                <TextBlock Text="Uninstalled App" FontSize="11" Foreground="#9D5D00" FontWeight="SemiBold"/>
                                            </Border>
                                            <Border Grid.Column="3" Background="#EBF3FC" CornerRadius="4" Padding="8,2" VerticalAlignment="Center">
                                                <TextBlock Text="{Binding FormattedSize}" FontSize="12" Foreground="#0067C0" FontWeight="Bold"/>
                                            </Border>
                                        </Grid>
                                    </Border>
                                </DataTemplate>
                            </ListBox.ItemTemplate>
                        </ListBox>
                    </Grid>
                </Border>
            </Grid>

            <!-- VIEW B: Installed Applications Browser -->
            <Grid Name="ViewInstalled" Visibility="Collapsed">
                <Border Style="{StaticResource CardBorder}" Margin="6">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <TextBlock Text="Currently Installed Applications (Select to uninstall or deep scan)" FontWeight="SemiBold" FontSize="14" Margin="4,0,0,8"/>
                        <ListBox Name="LstApps" Grid.Row="1" BorderThickness="0" Background="Transparent" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                            <ListBox.ItemTemplate>
                                <DataTemplate>
                                    <Border BorderBrush="#F0F0F0" BorderThickness="0,0,0,1" Padding="8,10" Background="Transparent">
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <StackPanel Grid.Column="0">
                                                <TextBlock Text="{Binding DisplayName}" FontWeight="SemiBold" FontSize="13" Foreground="#1B1B1B"/>
                                                <TextBlock Text="{Binding Publisher}" FontSize="11" Foreground="#707070"/>
                                            </StackPanel>
                                            <TextBlock Grid.Column="1" Text="{Binding DisplayVersion}" FontSize="12" Foreground="#5C5C5C" VerticalAlignment="Center" Margin="16,0"/>
                                            <Border Grid.Column="2" Background="#EBF3FC" CornerRadius="4" Padding="6,2" VerticalAlignment="Center">
                                                <TextBlock Text="{Binding Type}" FontSize="11" Foreground="#0067C0" FontWeight="SemiBold"/>
                                            </Border>
                                        </Grid>
                                    </Border>
                                </DataTemplate>
                            </ListBox.ItemTemplate>
                        </ListBox>
                    </Grid>
                </Border>
            </Grid>

            <!-- VIEW C: Leftovers Cards Grid (Single App View) -->
            <ScrollViewer Name="ViewLeftoverCards" Visibility="Collapsed" VerticalScrollBarVisibility="Auto">
                <Grid Margin="0,0,0,12">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <Border Grid.Row="0" Grid.Column="0" Style="{StaticResource CardBorder}">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                                <TextBlock Text="📁" FontSize="16" Margin="0,0,6,0"/>
                                <TextBlock Text="AppData &amp; File Leftovers" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                            </StackPanel>
                            <StackPanel Name="PnlFilesList"/>
                        </StackPanel>
                    </Border>

                    <Border Grid.Row="0" Grid.Column="1" Style="{StaticResource CardBorder}">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                                <TextBlock Text="🔑" FontSize="16" Margin="0,0,6,0"/>
                                <TextBlock Text="Registry Remnants" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                            </StackPanel>
                            <StackPanel Name="PnlRegistryList"/>
                        </StackPanel>
                    </Border>

                    <Border Grid.Row="0" Grid.Column="2" Style="{StaticResource CardBorder}">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                                <TextBlock Text="⚙️" FontSize="16" Margin="0,0,6,0"/>
                                <TextBlock Text="Services &amp; Tasks" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                            </StackPanel>
                            <StackPanel Name="PnlServicesList"/>
                        </StackPanel>
                    </Border>

                    <Border Grid.Row="1" Grid.Column="0" Style="{StaticResource CardBorder}">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                                <TextBlock Text="🔗" FontSize="16" Margin="0,0,6,0"/>
                                <TextBlock Text="Shortcuts &amp; Startup" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                            </StackPanel>
                            <StackPanel Name="PnlShortcutsList"/>
                        </StackPanel>
                    </Border>

                    <Border Grid.Row="1" Grid.Column="1" Style="{StaticResource CardBorder}">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                                <TextBlock Text="🛡️" FontSize="16" Margin="0,0,6,0"/>
                                <TextBlock Text="Safety &amp; Backups" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                            </StackPanel>
                            <CheckBox Name="ChkCreateBackup" Content="Create restorable snapshot before removal" IsChecked="True" FontSize="12" Margin="0,4,0,8"/>
                            <TextBlock Text="Snapshots stored in %LocalAppData%\HailUninstaller\Backups" FontSize="11" Foreground="#707070" Margin="22,0,0,8"/>
                            <CheckBox Name="ChkOfficialUninstall" Content="Invoke official uninstaller first" IsChecked="True" FontSize="12" Margin="0,4,0,8"/>
                        </StackPanel>
                    </Border>

                    <Border Grid.Row="1" Grid.Column="2" Style="{StaticResource CardBorder}">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                                <TextBlock Text="📊" FontSize="16" Margin="0,0,6,0"/>
                                <TextBlock Text="Cleanup Summary" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                            </StackPanel>
                            <TextBlock Name="TxtSelectedSummary" Text="Selected: 0 items (0 MB)" FontSize="14" FontWeight="SemiBold" Foreground="#0067C0" Margin="0,0,0,6"/>
                            <TextBlock Text="Protected system files are automatically locked." FontSize="11" Foreground="#107C10" FontWeight="SemiBold"/>
                        </StackPanel>
                    </Border>
                </Grid>
            </ScrollViewer>

            <!-- VIEW D: Results & Summary -->
            <Grid Name="ViewStep3" Visibility="Collapsed">
                <Border Style="{StaticResource CardBorder}" Margin="6" Padding="40">
                    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" MaxWidth="500">
                        <TextBlock Name="TxtStatusHeading" Text="Cleanup Complete!" FontSize="22" FontWeight="Bold" Foreground="#107C10" TextAlignment="Center" Margin="0,0,0,10"/>
                        <TextBlock Name="TxtStatusDetails" Text="All approved leftovers have been safely removed." FontSize="13" Foreground="#5C5C5C" TextAlignment="Center" Margin="0,0,0,20"/>
                        <ProgressBar Name="PrgCleanup" Height="8" Margin="0,0,0,24" Maximum="100" Value="100"/>
                        <Border Background="#F9F9F9" BorderBrush="#EAEAEA" BorderThickness="1" CornerRadius="6" Padding="16" Margin="0,0,0,24">
                            <StackPanel>
                                <TextBlock Name="TxtResultStats" Text="Removed: 0 MB across 0 items" FontWeight="SemiBold" FontSize="13"/>
                                <TextBlock Name="TxtBackupId" Text="Backup: None" FontSize="11" Foreground="#707070" Margin="0,4,0,0"/>
                            </StackPanel>
                        </Border>
                        <Button Name="BtnRestoreRollback" Content="Undo / Restore Previous Backup" Style="{StaticResource SecondaryButton}" HorizontalAlignment="Center"/>
                    </StackPanel>
                </Border>
            </Grid>

        </Grid>

        <!-- Bottom Navigation Bar -->
        <Border Grid.Row="5" Background="#FFFFFF" BorderBrush="#E5E5E5" BorderThickness="0,1,0,0" Padding="24,10">
            <Grid>
                <!-- Summary Text -->
                <TextBlock Name="TxtBottomSummary" Text="Selected: 0 MB ready for removal" VerticalAlignment="Center" HorizontalAlignment="Left" FontWeight="SemiBold" FontSize="13" Foreground="#1B1B1B"/>

                <!-- Action Button -->
                <Button Name="BtnNext" Content="Clean Selected Items →" Style="{StaticResource PrimaryButton}" HorizontalAlignment="Right" MinWidth="180"/>
            </Grid>
        </Border>

    </Grid>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    # Set icon if logo.png exists
    if (Test-Path -LiteralPath $logoPath) {
        try {
            $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([System.Uri]::new($logoPath))
            $titleLogo = $window.FindName("TitleLogo")
            if ($titleLogo) {
                $titleLogo.Source = [System.Windows.Media.Imaging.BitmapFrame]::Create([System.Uri]::new($logoPath))
            }
        } catch { }
    }

    # Controls
    $tabOrphans = $window.FindName("TabOrphans")
    $tabInstalled = $window.FindName("TabInstalled")
    $btnSelectHigh = $window.FindName("BtnSelectHigh")
    $btnSelectAll = $window.FindName("BtnSelectAll")
    $btnSelectHeavy = $window.FindName("BtnSelectHeavy")
    $btnClearSelection = $window.FindName("BtnClearSelection")
    $btnScanLeftovers = $window.FindName("BtnScanLeftovers")
    $txtSearch = $window.FindName("TxtSearch")
    $lstOrphans = $window.FindName("LstOrphans")
    $lstApps = $window.FindName("LstApps")
    $viewOrphans = $window.FindName("ViewOrphans")
    $viewInstalled = $window.FindName("ViewInstalled")
    $viewLeftoverCards = $window.FindName("ViewLeftoverCards")
    $viewStep3 = $window.FindName("ViewStep3")
    $txtOrphanCount = $window.FindName("TxtOrphanCount")
    $txtBottomSummary = $window.FindName("TxtBottomSummary")
    $btnNext = $window.FindName("BtnNext")
    $chkCreateBackup = $window.FindName("ChkCreateBackup")
    $chkOfficialUninstall = $window.FindName("ChkOfficialUninstall")
    $txtStatusHeading = $window.FindName("TxtStatusHeading")
    $txtResultStats = $window.FindName("TxtResultStats")
    $txtBackupId = $window.FindName("TxtBackupId")
    $btnRestoreRollback = $window.FindName("BtnRestoreRollback")
    $pnlFilesList = $window.FindName("PnlFilesList")
    $pnlRegistryList = $window.FindName("PnlRegistryList")
    $pnlServicesList = $window.FindName("PnlServicesList")
    $pnlShortcutsList = $window.FindName("PnlShortcutsList")
    $txtSelectedSummary = $window.FindName("TxtSelectedSummary")

    # State
    $script:activeTab = "Orphans"  # "Orphans" or "Installed"
    $script:allOrphans = [System.Collections.ObjectModel.ObservableCollection[PSCustomObject]]::new()
    $script:allInstalledApps = @()
    $script:selectedApp = $null
    $script:latestBackupId = ""

    # Recalculate selection space
    $updateOrphanSummary = {
        $selCount = 0
        $selBytes = 0L
        foreach ($item in $script:allOrphans) {
            if ($item.Selected) {
                $selCount++
                $selBytes += [long]$item.Size
            }
        }
        $szStr = Format-Bytes $selBytes
        $txtBottomSummary.Text = "Selected: $selCount orphan folder(s) ($szStr) ready for removal"
    }

    # Load Orphan Folders
    $loadOrphansData = {
        $window.Cursor = [System.Windows.Input.Cursors]::Wait
        $txtOrphanCount.Text = "Scanning storage..."

        $rawOrphans = @(Scan-OrphanedStorageFolders -ConfigDir $ConfigDir)
        $script:allOrphans.Clear()

        $totalOrphanBytes = 0L
        foreach ($o in $rawOrphans) {
            $totalOrphanBytes += [long]$o.Size
            $script:allOrphans.Add([PSCustomObject]@{
                Category      = $o.Category
                Type          = $o.Type
                Path          = $o.Path
                Name          = $o.Name
                Size          = [long]$o.Size
                ItemCount     = $o.ItemCount
                FormattedSize = Format-Bytes $o.Size
                Score         = $o.Score
                Selected      = $false
                EvidenceDetails = $o.EvidenceDetails
            })
        }

        $lstOrphans.ItemsSource = $script:allOrphans
        $totalFormatted = Format-Bytes $totalOrphanBytes
        $txtOrphanCount.Text = "$($script:allOrphans.Count) folders found ($totalFormatted total)"
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        & $updateOrphanSummary
    }

    # Load Installed Apps
    $loadInstalledApps = {
        if ($script:allInstalledApps.Count -eq 0) {
            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            $script:allInstalledApps = @(Get-InstalledApplications)
            $lstApps.ItemsSource = $script:allInstalledApps
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        }
    }

    # Tab Switching
    $tabOrphans.Add_Click({
        $script:activeTab = "Orphans"
        $tabOrphans.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0067C0")
        $tabOrphans.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0067C0")
        $tabInstalled.BorderBrush = [System.Windows.Media.Brushes]::Transparent
        $tabInstalled.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5C5C5C")
        $viewOrphans.Visibility = [System.Windows.Visibility]::Visible
        $viewInstalled.Visibility = [System.Windows.Visibility]::Collapsed
        $viewLeftoverCards.Visibility = [System.Windows.Visibility]::Collapsed
        $btnNext.Content = "Clean Selected Items →"
        $btnSelectHeavy.Visibility = [System.Windows.Visibility]::Visible
        & $updateOrphanSummary
    })

    $tabInstalled.Add_Click({
        $script:activeTab = "Installed"
        $tabInstalled.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0067C0")
        $tabInstalled.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0067C0")
        $tabOrphans.BorderBrush = [System.Windows.Media.Brushes]::Transparent
        $tabOrphans.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5C5C5C")
        $viewOrphans.Visibility = [System.Windows.Visibility]::Collapsed
        $viewInstalled.Visibility = [System.Windows.Visibility]::Visible
        $viewLeftoverCards.Visibility = [System.Windows.Visibility]::Collapsed
        $btnNext.Content = "Scan Leftovers For App →"
        $btnSelectHeavy.Visibility = [System.Windows.Visibility]::Collapsed
        & $loadInstalledApps
        $txtBottomSummary.Text = "Select an installed application to scan its footprint."
    })

    # Search filter
    $txtSearch.Add_TextChanged({
        $filter = $txtSearch.Text.Trim()
        if ($script:activeTab -eq "Orphans") {
            if ([string]::IsNullOrWhiteSpace($filter)) {
                $lstOrphans.ItemsSource = $script:allOrphans
            } else {
                $filtered = @($script:allOrphans | Where-Object { $_.Name -like "*$filter*" -or $_.Path -like "*$filter*" })
                $lstOrphans.ItemsSource = $filtered
            }
        } elseif ($script:activeTab -eq "Installed") {
            if ([string]::IsNullOrWhiteSpace($filter)) {
                $lstApps.ItemsSource = $script:allInstalledApps
            } else {
                $filtered = @($script:allInstalledApps | Where-Object { $_.DisplayName -like "*$filter*" -or $_.Publisher -like "*$filter*" })
                $lstApps.ItemsSource = $filtered
            }
        }
    })

    # Button: Select All
    $btnSelectAll.Add_Click({
        if ($script:activeTab -eq "Orphans") {
            foreach ($o in $script:allOrphans) { $o.Selected = $true }
            $lstOrphans.Items.Refresh()
            & $updateOrphanSummary
        }
    })

    # Button: Select High / Top
    $btnSelectHigh.Add_Click({
        if ($script:activeTab -eq "Orphans") {
            foreach ($o in $script:allOrphans) {
                # Pre-select folders with size > 10MB
                $o.Selected = ($o.Size -ge 10MB)
            }
            $lstOrphans.Items.Refresh()
            & $updateOrphanSummary
        }
    })

    # Button: Select > 100 MB
    $btnSelectHeavy.Add_Click({
        if ($script:activeTab -eq "Orphans") {
            foreach ($o in $script:allOrphans) {
                $o.Selected = ($o.Size -ge 100MB)
            }
            $lstOrphans.Items.Refresh()
            & $updateOrphanSummary
        }
    })

    # Button: Clear Selection
    $btnClearSelection.Add_Click({
        if ($script:activeTab -eq "Orphans") {
            foreach ($o in $script:allOrphans) { $o.Selected = $false }
            $lstOrphans.Items.Refresh()
            & $updateOrphanSummary
        }
    })

    # Button: Rescan
    $btnScanLeftovers.Add_Click({
        & $loadOrphansData
    })

    # Bottom Action Button
    $btnNext.Add_Click({
        if ($script:activeTab -eq "Orphans") {
            # Collect selected items
            $selectedItems = @($script:allOrphans | Where-Object { $_.Selected })
            if ($selectedItems.Count -eq 0) {
                [System.Windows.MessageBox]::Show("Please select at least one orphaned folder to delete.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                return
            }

            $totalBytes = 0L
            foreach ($s in $selectedItems) { $totalBytes += [long]$s.Size }
            $szStr = Format-Bytes $totalBytes

            # HUMAN APPROVAL CONFIRMATION MODAL
            $msg = "HUMAN APPROVAL REQUIRED:`n`nAre you sure you want to delete $($selectedItems.Count) orphaned folder(s) totaling $szStr?`n`nThese folders belong to applications that are no longer installed on your system.`n`nContinue with permanent deletion?"
            $res = [System.Windows.MessageBox]::Show($msg, "Confirm Storage Cleanup - HailUninstaller", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
            
            if ($res -ne [System.Windows.MessageBoxResult]::Yes) {
                return
            }

            # Optional Backup
            $mockApp = [PSCustomObject]@{
                DisplayName     = "Orphaned_Storage_Cleanup"
                Publisher       = "HailUninstaller"
                InstallLocation = ""
            }

            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            $backupRes = New-CleanupBackup -Application $mockApp -SelectedItems $selectedItems
            $script:latestBackupId = $backupRes.BackupId

            # Cleanup
            $cRes = Invoke-CleanupItems -SelectedItems $selectedItems -HumanApproved
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow

            # Show Success View
            $viewOrphans.Visibility = [System.Windows.Visibility]::Collapsed
            $viewInstalled.Visibility = [System.Windows.Visibility]::Collapsed
            $viewStep3.Visibility = [System.Windows.Visibility]::Visible
            $txtResultStats.Text = "Freed: $(Format-Bytes $cRes.RemovedBytes) across $($cRes.RemovedCount) orphaned folder(s)!"
            $txtBackupId.Text = "Backup Snapshot: $($backupRes.BackupId)"
            $btnNext.Content = "Finish &amp; Exit"

        } elseif ($script:activeTab -eq "Installed") {
            if (-not $lstApps.SelectedItem) {
                [System.Windows.MessageBox]::Show("Please select an application to scan.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                return
            }
            $script:selectedApp = $lstApps.SelectedItem
            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            $leftovers = @(Start-DeepScan -Application $script:selectedApp -ConfigDir $ConfigDir)
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow

            # Populate Leftover Cards
            $pnlFilesList.Children.Clear()
            $pnlRegistryList.Children.Clear()
            $pnlServicesList.Children.Clear()
            $pnlShortcutsList.Children.Clear()

            foreach ($item in $leftovers) {
                $cb = [System.Windows.Controls.CheckBox]::new()
                $cb.FontSize = 12
                $cb.Margin = [System.Windows.Thickness]::new(0, 4, 0, 4)
                $label = if ($item.Path) { $item.Path } else { $item.Name }
                if ($label.Length -gt 45) { $label = "..." + $label.Substring($label.Length - 42) }
                if ($item.Size -gt 0) { $label += " (" + (Format-Bytes $item.Size) + ")" }
                $cb.Content = $label
                $cb.IsChecked = ($item.ConfidenceCategory -eq "HIGH" -and -not $item.IsProtected)
                $cb.IsEnabled = (-not $item.IsProtected)

                switch ($item.Category) {
                    "File"     { $pnlFilesList.Children.Add($cb) }
                    "Registry" { $pnlRegistryList.Children.Add($cb) }
                    "Service"  { $pnlServicesList.Children.Add($cb) }
                    "Task"     { $pnlServicesList.Children.Add($cb) }
                    "Shortcut" { $pnlShortcutsList.Children.Add($cb) }
                    Default    { $pnlFilesList.Children.Add($cb) }
                }
            }

            $viewInstalled.Visibility = [System.Windows.Visibility]::Collapsed
            $viewLeftoverCards.Visibility = [System.Windows.Visibility]::Visible
            $btnNext.Content = "Clean Selected Items →"
        }
    })

    # Restore Button
    $btnRestoreRollback.Add_Click({
        if ($script:latestBackupId) {
            $c = [System.Windows.MessageBox]::Show("Restore all deleted files and registry entries from backup '$($script:latestBackupId)'?", "Restore Snapshot", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
            if ($c -eq [System.Windows.MessageBoxResult]::Yes) {
                $rRes = Restore-CleanupBackup -BackupId $script:latestBackupId
                [System.Windows.MessageBox]::Show("Successfully restored $($rRes.RestoredCount) item(s)!", "Restore Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            }
        }
    })

    # Initial load: Scan and show Orphan Leftover Folders right away
    $window.Add_Loaded({
        & $loadOrphansData
    })

    # Launch GUI
    [void]$window.ShowDialog()
}
