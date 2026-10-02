# Modules/GUI.ps1
# Windows 11 Fluent WPF GUI for HailUninstaller

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
        Title="HailUninstaller" Height="780" Width="1120"
        MinHeight="680" MinWidth="960"
        WindowStartupLocation="CenterScreen"
        Background="#F3F3F3"
        FontFamily="Segoe UI Variable Text, Segoe UI, sans-serif">
    
    <Window.Resources>
        <!-- Windows 11 Button Style -->
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
                    <TextBlock Text="Deep Application Removal Tool" FontSize="11" Foreground="#707070" Margin="0,0,16,0"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Page Heading -->
        <StackPanel Grid.Row="1" Margin="24,18,24,10">
            <TextBlock Name="TxtMainTitle" Text="Select Application" FontSize="22" FontWeight="Bold" Foreground="#1B1B1B"/>
            <TextBlock Name="TxtSubTitle" Text="Choose an application to remove its remaining footprint. Official uninstaller runs first." FontSize="13" Foreground="#5C5C5C" Margin="0,4,0,0"/>
        </StackPanel>

        <!-- Action / Filter Bar -->
        <Grid Grid.Row="2" Margin="24,8,24,14">
            <StackPanel Orientation="Horizontal">
                <Button Name="BtnSelectHigh" Content="Select High Confidence" Style="{StaticResource SecondaryButton}" Margin="0,0,8,0"/>
                <Button Name="BtnSelectAll" Content="Select All" Style="{StaticResource SecondaryButton}" Margin="0,0,8,0"/>
                <Button Name="BtnClearSelection" Content="Clear Selection" Style="{StaticResource SecondaryButton}" Margin="0,0,8,0"/>
                <Button Name="BtnScanLeftovers" Content="Rescan" Style="{StaticResource SecondaryButton}"/>
            </StackPanel>

            <Border HorizontalAlignment="Right" Background="#FFFFFF" BorderBrush="#E0E0E0" BorderThickness="1" CornerRadius="5" Padding="8,4" Width="260">
                <Grid>
                    <TextBlock Text="🔍" Foreground="#888888" VerticalAlignment="Center" Margin="2,0,6,0"/>
                    <TextBox Name="TxtSearch" BorderThickness="0" Background="Transparent" Margin="22,0,0,0" FontSize="12" VerticalAlignment="Center" ToolTip="Search applications or leftovers"/>
                </Grid>
            </Border>
        </Grid>

        <!-- Main Content Area: Tab/Wizard Controls -->
        <Grid Grid.Row="3" Margin="18,0,18,0">
            
            <!-- STEP 1: Application Selector -->
            <Grid Name="ViewStep1" Visibility="Visible">
                <Border Style="{StaticResource CardBorder}" Margin="6">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <TextBlock Text="Installed Applications (Registry, MSI, MSIX)" FontWeight="SemiBold" FontSize="14" Margin="4,0,0,8"/>
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

            <!-- STEP 2: Leftovers Cards Grid (Matches Reference Image) -->
            <ScrollViewer Name="ViewStep2" Visibility="Collapsed" VerticalScrollBarVisibility="Auto">
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

                    <!-- Card 1: AppData & Files -->
                    <Border Grid.Row="0" Grid.Column="0" Style="{StaticResource CardBorder}">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                                <TextBlock Text="📁" FontSize="16" Margin="0,0,6,0"/>
                                <TextBlock Text="AppData &amp; File Leftovers" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                                <TextBlock Text=" (?)" Foreground="#0067C0" FontSize="12" VerticalAlignment="Center" ToolTip="Files located in AppData, ProgramData, or install folders"/>
                            </StackPanel>
                            <StackPanel Name="PnlFilesList">
                                <!-- Checkbox items dynamically added -->
                            </StackPanel>
                        </StackPanel>
                    </Border>

                    <!-- Card 2: Registry Remnants -->
                    <Border Grid.Row="0" Grid.Column="1" Style="{StaticResource CardBorder}">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                                <TextBlock Text="🔑" FontSize="16" Margin="0,0,6,0"/>
                                <TextBlock Text="Registry Remnants" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                                <TextBlock Text=" (?)" Foreground="#0067C0" FontSize="12" VerticalAlignment="Center" ToolTip="HKCU and HKLM software registry keys"/>
                            </StackPanel>
                            <StackPanel Name="PnlRegistryList">
                                <!-- Checkbox items dynamically added -->
                            </StackPanel>
                        </StackPanel>
                    </Border>

                    <!-- Card 3: Services & Scheduled Tasks -->
                    <Border Grid.Row="0" Grid.Column="2" Style="{StaticResource CardBorder}">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                                <TextBlock Text="⚙️" FontSize="16" Margin="0,0,6,0"/>
                                <TextBlock Text="Services &amp; Tasks" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                                <TextBlock Text=" (?)" Foreground="#0067C0" FontSize="12" VerticalAlignment="Center" ToolTip="Background updater services and scheduled tasks"/>
                            </StackPanel>
                            <StackPanel Name="PnlServicesList">
                                <!-- Checkbox items dynamically added -->
                            </StackPanel>
                        </StackPanel>
                    </Border>

                    <!-- Card 4: Shortcuts & Startup -->
                    <Border Grid.Row="1" Grid.Column="0" Style="{StaticResource CardBorder}">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                                <TextBlock Text="🔗" FontSize="16" Margin="0,0,6,0"/>
                                <TextBlock Text="Shortcuts &amp; Startup" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                                <TextBlock Text=" (?)" Foreground="#0067C0" FontSize="12" VerticalAlignment="Center" ToolTip="Desktop and Start Menu shortcuts"/>
                            </StackPanel>
                            <StackPanel Name="PnlShortcutsList">
                                <!-- Checkbox items dynamically added -->
                            </StackPanel>
                        </StackPanel>
                    </Border>

                    <!-- Card 5: Safety Guardrails & Backups -->
                    <Border Grid.Row="1" Grid.Column="1" Style="{StaticResource CardBorder}">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                                <TextBlock Text="🛡️" FontSize="16" Margin="0,0,6,0"/>
                                <TextBlock Text="Safety &amp; Backups" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                                <TextBlock Text=" (?)" Foreground="#0067C0" FontSize="12" VerticalAlignment="Center" ToolTip="Safe restore mechanisms"/>
                            </StackPanel>
                            <CheckBox Name="ChkCreateBackup" Content="Create restorable snapshot before removal" IsChecked="True" FontSize="12" Margin="0,4,0,8"/>
                            <TextBlock Text="Snapshots stored in %LocalAppData%\HailUninstaller\Backups" FontSize="11" Foreground="#707070" Margin="22,0,0,8"/>
                            <CheckBox Name="ChkOfficialUninstall" Content="Invoke official uninstaller first (Recommended)" IsChecked="True" FontSize="12" Margin="0,4,0,8"/>
                            <TextBlock Text="Unregisters software components before deep clean" FontSize="11" Foreground="#707070" Margin="22,0,0,0"/>
                        </StackPanel>
                    </Border>

                    <!-- Card 6: Reclaim Summary -->
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

            <!-- STEP 3: Progress & Summary -->
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
        <Border Grid.Row="4" Background="#FFFFFF" BorderBrush="#E5E5E5" BorderThickness="0,1,0,0" Padding="24,10">
            <Grid>
                <!-- Back Button -->
                <Button Name="BtnBack" Content="← Back" Style="{StaticResource SecondaryButton}" HorizontalAlignment="Left" Width="80"/>

                <!-- Stepper Dots -->
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                    <Ellipse Name="Dot1" Width="8" Height="8" Fill="#0067C0" Margin="4,0"/>
                    <Ellipse Name="Dot2" Width="8" Height="8" Fill="#CCCCCC" Margin="4,0"/>
                    <Ellipse Name="Dot3" Width="8" Height="8" Fill="#CCCCCC" Margin="4,0"/>
                </StackPanel>

                <!-- Next / Action Button -->
                <Button Name="BtnNext" Content="Next →" Style="{StaticResource PrimaryButton}" HorizontalAlignment="Right" MinWidth="100"/>
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

    # Element lookups
    $btnNext = $window.FindName("BtnNext")
    $btnBack = $window.FindName("BtnBack")
    $btnSelectHigh = $window.FindName("BtnSelectHigh")
    $btnSelectAll = $window.FindName("BtnSelectAll")
    $btnClearSelection = $window.FindName("BtnClearSelection")
    $btnScanLeftovers = $window.FindName("BtnScanLeftovers")
    $txtSearch = $window.FindName("TxtSearch")
    $lstApps = $window.FindName("LstApps")
    $viewStep1 = $window.FindName("ViewStep1")
    $viewStep2 = $window.FindName("ViewStep2")
    $viewStep3 = $window.FindName("ViewStep3")
    $txtMainTitle = $window.FindName("TxtMainTitle")
    $txtSubTitle = $window.FindName("TxtSubTitle")
    $dot1 = $window.FindName("Dot1")
    $dot2 = $window.FindName("Dot2")
    $dot3 = $window.FindName("Dot3")
    $pnlFilesList = $window.FindName("PnlFilesList")
    $pnlRegistryList = $window.FindName("PnlRegistryList")
    $pnlServicesList = $window.FindName("PnlServicesList")
    $pnlShortcutsList = $window.FindName("PnlShortcutsList")
    $txtSelectedSummary = $window.FindName("TxtSelectedSummary")
    $chkCreateBackup = $window.FindName("ChkCreateBackup")
    $chkOfficialUninstall = $window.FindName("ChkOfficialUninstall")
    $txtStatusHeading = $window.FindName("TxtStatusHeading")
    $txtStatusDetails = $window.FindName("TxtStatusDetails")
    $txtResultStats = $window.FindName("TxtResultStats")
    $txtBackupId = $window.FindName("TxtBackupId")
    $btnRestoreRollback = $window.FindName("BtnRestoreRollback")

    # State
    $script:currentStep = 1
    $script:allInstalledApps = @(Get-InstalledApplications)
    $script:selectedApp = $null
    $script:currentCandidates = @()
    $script:candidateCheckboxes = [System.Collections.Generic.List[PSCustomObject]]::new()
    $script:latestBackupId = ""

    # Populate Applications List
    $lstApps.ItemsSource = $script:allInstalledApps

    # Search filter logic
    $txtSearch.Add_TextChanged({
        $filter = $txtSearch.Text.Trim()
        if ($script:currentStep -eq 1) {
            if ([string]::IsNullOrWhiteSpace($filter)) {
                $lstApps.ItemsSource = $script:allInstalledApps
            } else {
                $lstApps.ItemsSource = @($script:allInstalledApps | Where-Object { 
                    $_.DisplayName -like "*$filter*" -or $_.Publisher -like "*$filter*" 
                })
            }
        } elseif ($script:currentStep -eq 2) {
            foreach ($cbEntry in $script:candidateCheckboxes) {
                $cb = $cbEntry.CheckBox
                if ([string]::IsNullOrWhiteSpace($filter) -or $cb.Content -like "*$filter*") {
                    $cb.Visibility = [System.Windows.Visibility]::Visible
                } else {
                    $cb.Visibility = [System.Windows.Visibility]::Collapsed
                }
            }
        }
    })

    # Update summary recalculation
    $recalculateSummary = {
        $selectedCount = 0
        $selectedBytes = 0L
        foreach ($cbEntry in $script:candidateCheckboxes) {
            if ($cbEntry.CheckBox.IsChecked) {
                $selectedCount++
                $selectedBytes += [long]$cbEntry.Candidate.Size
            }
        }
        $szStr = Format-Bytes $selectedBytes
        $txtSelectedSummary.Text = "Selected: $selectedCount items ($szStr)"
    }

    # Helper to render leftover cards
    $renderLeftoverCards = {
        $pnlFilesList.Children.Clear()
        $pnlRegistryList.Children.Clear()
        $pnlServicesList.Children.Clear()
        $pnlShortcutsList.Children.Clear()
        $script:candidateCheckboxes.Clear()

        foreach ($c in $script:currentCandidates) {
            $cb = [System.Windows.Controls.CheckBox]::new()
            $cb.FontSize = 12
            $cb.Margin = [System.Windows.Thickness]::new(0, 4, 0, 4)

            $itemLabel = if ($c.Path) { $c.Path } else { $c.Name }
            if ($itemLabel.Length -gt 45) {
                $itemLabel = "..." + $itemLabel.Substring($itemLabel.Length - 42)
            }
            if ($c.Size -gt 0) {
                $itemLabel += " (" + (Format-Bytes $c.Size) + ")"
            }

            $cb.Content = $itemLabel
            $cb.ToolTip = "$($c.Category): $(if ($c.Path) { $c.Path } else { $c.Name })`nConfidence: $($c.Score)% ($($c.ConfidenceCategory))`nReason: $($c.EvidenceDetails -join '; ')"

            if ($c.IsProtected) {
                $cb.IsEnabled = $false
                $cb.IsChecked = $false
                $cb.Foreground = [System.Windows.Media.Brushes]::Red
            } else {
                $cb.IsChecked = ($c.ConfidenceCategory -eq "HIGH")
                $cb.Add_Checked({ & $recalculateSummary })
                $cb.Add_Unchecked({ & $recalculateSummary })
            }

            $script:candidateCheckboxes.Add([PSCustomObject]@{
                CheckBox  = $cb
                Candidate = $c
            })

            switch ($c.Category) {
                "File"     { $pnlFilesList.Children.Add($cb) }
                "Registry" { $pnlRegistryList.Children.Add($cb) }
                "Service"  { $pnlServicesList.Children.Add($cb) }
                "Task"     { $pnlServicesList.Children.Add($cb) }
                "Shortcut" { $pnlShortcutsList.Children.Add($cb) }
                Default    { $pnlFilesList.Children.Add($cb) }
            }
        }

        & $recalculateSummary
    }

    # Step transition logic
    $updateWizardView = {
        switch ($script:currentStep) {
            1 {
                $viewStep1.Visibility = [System.Windows.Visibility]::Visible
                $viewStep2.Visibility = [System.Windows.Visibility]::Collapsed
                $viewStep3.Visibility = [System.Windows.Visibility]::Collapsed
                $txtMainTitle.Text = "Select Application"
                $txtSubTitle.Text = "Choose an application to remove its remaining footprint. Official uninstaller runs first."
                $btnBack.IsEnabled = $false
                $btnNext.Content = "Next →"
                $btnNext.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0067C0")
                $dot1.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0067C0")
                $dot2.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#CCCCCC")
                $dot3.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#CCCCCC")
            }
            2 {
                $viewStep1.Visibility = [System.Windows.Visibility]::Collapsed
                $viewStep2.Visibility = [System.Windows.Visibility]::Visible
                $viewStep3.Visibility = [System.Windows.Visibility]::Collapsed
                $txtMainTitle.Text = "Application Leftovers &amp; System Footprint"
                $txtSubTitle.Text = "Select which leftovers you want to remove for $($script:selectedApp.DisplayName). Hover for confidence scoring."
                $btnBack.IsEnabled = $true
                $btnNext.Content = "Clean Selected Items →"
                $btnNext.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D83B01")
                $dot1.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#CCCCCC")
                $dot2.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0067C0")
                $dot3.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#CCCCCC")
            }
            3 {
                $viewStep1.Visibility = [System.Windows.Visibility]::Collapsed
                $viewStep2.Visibility = [System.Windows.Visibility]::Collapsed
                $viewStep3.Visibility = [System.Windows.Visibility]::Visible
                $txtMainTitle.Text = "Cleanup Status"
                $txtSubTitle.Text = "Operation finished. You can restore your system snapshot at any time."
                $btnBack.IsEnabled = $false
                $btnNext.Content = "Finish &amp; Exit"
                $btnNext.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#107C10")
                $dot1.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#CCCCCC")
                $dot2.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#CCCCCC")
                $dot3.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#107C10")
            }
        }
    }

    # Button: Select High Confidence
    $btnSelectHigh.Add_Click({
        foreach ($cbEntry in $script:candidateCheckboxes) {
            if (-not $cbEntry.Candidate.IsProtected) {
                $cbEntry.CheckBox.IsChecked = ($cbEntry.Candidate.ConfidenceCategory -eq "HIGH")
            }
        }
    })

    # Button: Select All
    $btnSelectAll.Add_Click({
        foreach ($cbEntry in $script:candidateCheckboxes) {
            if (-not $cbEntry.Candidate.IsProtected) {
                $cbEntry.CheckBox.IsChecked = $true
            }
        }
    })

    # Button: Clear Selection
    $btnClearSelection.Add_Click({
        foreach ($cbEntry in $script:candidateCheckboxes) {
            $cbEntry.CheckBox.IsChecked = $false
        }
    })

    # Button: Rescan
    $btnScanLeftovers.Add_Click({
        if ($script:selectedApp) {
            $script:currentCandidates = @(Start-DeepScan -Application $script:selectedApp -ConfigDir $ConfigDir)
            & $renderLeftoverCards
        }
    })

    # Button: Back
    $btnBack.Add_Click({
        if ($script:currentStep -gt 1) {
            $script:currentStep--
            & $updateWizardView
        }
    })

    # Button: Next / Action
    $btnNext.Add_Click({
        if ($script:currentStep -eq 1) {
            if (-not $lstApps.SelectedItem) {
                [System.Windows.MessageBox]::Show("Please select an application from the list.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                return
            }
            $script:selectedApp = $lstApps.SelectedItem
            
            # Run scan
            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            $script:currentCandidates = @(Start-DeepScan -Application $script:selectedApp -ConfigDir $ConfigDir)
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow

            & $renderLeftoverCards
            $script:currentStep = 2
            & $updateWizardView
        } elseif ($script:currentStep -eq 2) {
            $selectedForDeletion = [System.Collections.Generic.List[PSCustomObject]]::new()
            foreach ($cbEntry in $script:candidateCheckboxes) {
                if ($cbEntry.CheckBox.IsChecked -and -not $cbEntry.Candidate.IsProtected) {
                    $c = $cbEntry.Candidate
                    $c.Selected = $true
                    $selectedForDeletion.Add($c)
                }
            }

            if ($selectedForDeletion.Count -eq 0) {
                [System.Windows.MessageBox]::Show("No items are selected for deletion.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
                return
            }

            # Human confirmation check (Mandatory Human Intervention)
            $msg = "HUMAN APPROVAL REQUIRED:`n`nAre you sure you want to delete $($selectedForDeletion.Count) selected item(s) for $($script:selectedApp.DisplayName)?`n`nThis action cannot be undone without a backup snapshot."
            $confirm = [System.Windows.MessageBox]::Show($msg, "Confirm Deletion - HailUninstaller", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
            if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) {
                return
            }

            # Step 1: Optional official uninstaller
            if ($chkOfficialUninstall.IsChecked -and $script:selectedApp.UninstallString) {
                Invoke-NativeUninstall -Application $script:selectedApp -Quiet
            }

            # Step 2: Backup snapshot
            if ($chkCreateBackup.IsChecked) {
                $bRes = New-CleanupBackup -Application $script:selectedApp -SelectedItems $selectedForDeletion
                $script:latestBackupId = $bRes.BackupId
                $txtBackupId.Text = "Backup Snapshot: $($bRes.BackupId)"
            } else {
                $txtBackupId.Text = "Backup Snapshot: Disabled"
            }

            # Step 3: Cleanup
            $cRes = Invoke-CleanupItems -SelectedItems $selectedForDeletion -HumanApproved
            $txtResultStats.Text = "Removed: $(Format-Bytes $cRes.RemovedBytes) across $($cRes.RemovedCount) item(s)"

            $script:currentStep = 3
            & $updateWizardView
        } elseif ($script:currentStep -eq 3) {
            $window.Close()
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
        } else {
            [System.Windows.MessageBox]::Show("No backup snapshot available for immediate rollback.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        }
    })

    # Initialize view
    & $updateWizardView

    # Launch GUI window
    [void]$window.ShowDialog()
}
