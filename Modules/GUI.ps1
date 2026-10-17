# Modules/GUI.ps1
# Windows 11 Fluent WPF GUI v2.0 for HailUninstaller
# Integrates Orphan Storage Cleaner, Batch App Removal, Heuristic Quiet Engine, Forced Uninstall, Hunter Mode, and Backup Manager.

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms

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

    # Define XAML for Windows 11 Fluent UI v2.0
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="HailUninstaller - Deep Application &amp; Storage Removal" Height="840" Width="1200"
        MinHeight="720" MinWidth="1020"
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
            <Setter Property="Padding" Value="14,8"/>
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
            <Setter Property="Padding" Value="20,8"/>
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
                    <Border Background="#E1DFDD" CornerRadius="4" Padding="6,1" Margin="8,0,0,0" VerticalAlignment="Center">
                        <TextBlock Text="v2.0 Advanced" FontSize="10" FontWeight="Bold" Foreground="#444444"/>
                    </Border>
                </StackPanel>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <TextBlock Text="Deep Application &amp; Storage Removal Suite" FontSize="11" Foreground="#707070" Margin="0,0,16,0"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Page Heading -->
        <StackPanel Grid.Row="1" Margin="24,12,24,4">
            <TextBlock Name="TxtMainTitle" Text="Storage &amp; Application Cleaner" FontSize="20" FontWeight="Bold" Foreground="#1B1B1B"/>
            <TextBlock Name="TxtSubTitle" Text="Isolate uninstalled app ghost folders, execute quiet batch uninstalls, or purge stubborn software." FontSize="12" Foreground="#5C5C5C" Margin="0,2,0,0"/>
        </StackPanel>

        <!-- Mode Selector Tabs -->
        <Border Grid.Row="2" Margin="24,0,24,6" BorderBrush="#E5E5E5" BorderThickness="0,0,0,1">
            <StackPanel Orientation="Horizontal">
                <Button Name="TabOrphans" Content="🧹 Ghost Folders" Style="{StaticResource TabButton}" BorderBrush="#0067C0" Foreground="#0067C0"/>
                <Button Name="TabInstalled" Content="📦 Installed Applications" Style="{StaticResource TabButton}" Margin="8,0,0,0"/>
                <Button Name="TabForced" Content="🎯 Forced Uninstall" Style="{StaticResource TabButton}" Margin="8,0,0,0"/>
                <Button Name="TabHunter" Content="⚡ Hunter Mode" Style="{StaticResource TabButton}" Margin="8,0,0,0"/>
                <Button Name="TabBackups" Content="🕒 Backups &amp; Rollback" Style="{StaticResource TabButton}" Margin="8,0,0,0"/>
            </StackPanel>
        </Border>

        <!-- Action / Filter Bar -->
        <Grid Grid.Row="3" Margin="24,4,24,8">
            <StackPanel Orientation="Horizontal">
                <Button Name="BtnScanAction" Content="🔍 Scan Storage Leftovers" Style="{StaticResource PrimaryButton}" Margin="0,0,8,0" Padding="14,6"/>
                <Button Name="BtnSelectHigh" Content="Select High Confidence" Style="{StaticResource SecondaryButton}" Margin="0,0,6,0" IsEnabled="False"/>
                <Button Name="BtnSelectAll" Content="Select All" Style="{StaticResource SecondaryButton}" Margin="0,0,6,0" IsEnabled="False"/>
                <Button Name="BtnSelectHeavy" Content="Select &gt; 100 MB" Style="{StaticResource SecondaryButton}" Margin="0,0,6,0" IsEnabled="False"/>
                <Button Name="BtnClearSelection" Content="Clear Selection" Style="{StaticResource SecondaryButton}" Margin="0,0,6,0" IsEnabled="False"/>
            </StackPanel>

            <Border HorizontalAlignment="Right" Background="#FFFFFF" BorderBrush="#E0E0E0" BorderThickness="1" CornerRadius="5" Padding="8,4" Width="260">
                <Grid>
                    <TextBlock Text="🔍" Foreground="#888888" VerticalAlignment="Center" Margin="2,0,6,0"/>
                    <TextBox Name="TxtSearch" BorderThickness="0" Background="Transparent" Margin="22,0,0,0" FontSize="12" VerticalAlignment="Center" ToolTip="Search current items..."/>
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
                            <TextBlock Name="TxtOrphanHeader" Text="Detected Orphan Folders (Applications are NOT installed, but folders remain)" FontWeight="SemiBold" FontSize="13" Foreground="#1B1B1B"/>
                            <TextBlock Name="TxtOrphanCount" Text="Click 'Scan Storage Leftovers' to begin." HorizontalAlignment="Right" FontSize="12" Foreground="#707070" FontWeight="SemiBold"/>
                        </Grid>

                        <!-- Empty State Prompt -->
                        <Border Name="PnlScanPrompt" Grid.Row="1" Background="#FAFAFA" BorderBrush="#EEEEEE" BorderThickness="1" CornerRadius="6" Padding="32" VerticalAlignment="Center" HorizontalAlignment="Center">
                            <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center" MaxWidth="500">
                                <TextBlock Text="💾" FontSize="38" HorizontalAlignment="Center" Margin="0,0,0,10"/>
                                <TextBlock Text="Ready to Deep-Scan Storage Drives" FontSize="17" FontWeight="Bold" Foreground="#1B1B1B" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                                <TextBlock Text="HailUninstaller will deeply analyze AppData, ProgramData, and drive roots to safely discover folders whose applications have already been uninstalled." FontSize="12" Foreground="#666666" TextWrapping="Wrap" TextAlignment="Center" Margin="0,0,0,18"/>
                                <Button Name="BtnStartScanHero" Content="🔍 Scan Storage Now" Style="{StaticResource PrimaryButton}" HorizontalAlignment="Center" Padding="24,8" FontSize="13"/>
                            </StackPanel>
                        </Border>

                        <ListBox Name="LstOrphans" Grid.Row="1" BorderThickness="0" Background="Transparent" ScrollViewer.HorizontalScrollBarVisibility="Disabled" Visibility="Collapsed">
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
                        <Grid Margin="4,0,0,8">
                            <TextBlock Text="Installed Applications (Select an app or check multiple for batch removal)" FontWeight="SemiBold" FontSize="13"/>
                            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                                <Button Name="BtnAppNormalUninstall" Content="Standard Uninstall" Style="{StaticResource SecondaryButton}" Margin="0,0,6,0"/>
                                <Button Name="BtnAppQuietUninstall" Content="⚡ Silent Uninstall" Style="{StaticResource SecondaryButton}" Margin="0,0,6,0" ToolTip="Heuristically executes unattended without wizard prompts"/>
                                <Button Name="BtnAppDeepScan" Content="🔍 Deep Scan Leftovers" Style="{StaticResource PrimaryButton}" Padding="14,4"/>
                            </StackPanel>
                        </Grid>
                        <ListBox Name="LstApps" Grid.Row="1" BorderThickness="0" Background="Transparent" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
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
                                            <CheckBox IsChecked="{Binding Selected, Mode=TwoWay}" VerticalAlignment="Center" Margin="0,0,10,0"/>
                                            <StackPanel Grid.Column="1">
                                                <TextBlock Text="{Binding DisplayName}" FontWeight="SemiBold" FontSize="13" Foreground="#1B1B1B"/>
                                                <TextBlock Text="{Binding Publisher}" FontSize="11" Foreground="#707070"/>
                                            </StackPanel>
                                            <TextBlock Grid.Column="2" Text="{Binding DisplayVersion}" FontSize="12" Foreground="#5C5C5C" VerticalAlignment="Center" Margin="16,0"/>
                                            <Border Grid.Column="3" Background="#EBF3FC" CornerRadius="4" Padding="6,2" VerticalAlignment="Center">
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

            <!-- VIEW C: Forced Uninstall / Target Path Purge -->
            <Grid Name="ViewForced" Visibility="Collapsed">
                <Border Style="{StaticResource CardBorder}" Margin="6" Padding="24">
                    <StackPanel MaxWidth="680" HorizontalAlignment="Center" VerticalAlignment="Center">
                        <TextBlock Text="🎯 Forced Uninstall &amp; Target Purge" FontSize="18" FontWeight="Bold" Foreground="#1B1B1B" HorizontalAlignment="Center" Margin="0,0,0,6"/>
                        <TextBlock Text="Purge corrupted, half-uninstalled, or unlisted applications directly from their folder or binary." FontSize="12" Foreground="#666666" TextAlignment="Center" TextWrapping="Wrap" Margin="0,0,0,20"/>

                        <Border Background="#F9F9F9" BorderBrush="#EAEAEA" BorderThickness="1" CornerRadius="6" Padding="16" Margin="0,0,0,16">
                            <StackPanel>
                                <TextBlock Text="Target Folder Path or Application Name:" FontSize="12" FontWeight="SemiBold" Margin="0,0,0,6"/>
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="Auto"/>
                                    </Grid.ColumnDefinitions>
                                    <TextBox Name="TxtForcedTarget" Height="32" VerticalContentAlignment="Center" Padding="8,4" FontSize="12" Background="#FFFFFF" BorderBrush="#CCCCCC" BorderThickness="1"/>
                                    <Button Name="BtnBrowseForcedFolder" Grid.Column="1" Content="📁 Browse Folder" Style="{StaticResource SecondaryButton}" Margin="6,0,0,0"/>
                                    <Button Name="BtnBrowseForcedExe" Grid.Column="2" Content="⚙ Browse Exe" Style="{StaticResource SecondaryButton}" Margin="6,0,0,0"/>
                                </Grid>
                            </StackPanel>
                        </Border>

                        <Button Name="BtnRunForcedScan" Content="🔍 Scan &amp; Discover Remnants" Style="{StaticResource PrimaryButton}" HorizontalAlignment="Center" Padding="28,10" FontSize="14"/>
                    </StackPanel>
                </Border>
            </Grid>

            <!-- VIEW D: Hunter Mode / Process Targeter -->
            <Grid Name="ViewHunter" Visibility="Collapsed">
                <Border Style="{StaticResource CardBorder}" Margin="6">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <Grid Margin="4,0,0,8">
                            <TextBlock Text="Active User Processes (Target running programs to stop and purge)" FontWeight="SemiBold" FontSize="13"/>
                            <Button Name="BtnRefreshHunter" Content="🔄 Refresh Processes" Style="{StaticResource SecondaryButton}" HorizontalAlignment="Right"/>
                        </Grid>
                        <ListBox Name="LstHunter" Grid.Row="1" BorderThickness="0" Background="Transparent" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                            <ListBox.ItemTemplate>
                                <DataTemplate>
                                    <Border BorderBrush="#F0F0F0" BorderThickness="0,0,0,1" Padding="8,8" Background="Transparent">
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                                <ColumnDefinition Width="Auto"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <StackPanel Grid.Column="0">
                                                <TextBlock Text="{Binding ProcessName}" FontWeight="Bold" FontSize="13" Foreground="#1B1B1B"/>
                                                <TextBlock Text="{Binding WindowTitle}" FontSize="11" Foreground="#555555"/>
                                                <TextBlock Text="{Binding Path}" FontSize="10" Foreground="#888888" ToolTip="{Binding Path}"/>
                                            </StackPanel>
                                            <TextBlock Grid.Column="1" Text="{Binding Publisher}" FontSize="11" Foreground="#666666" VerticalAlignment="Center" Margin="12,0"/>
                                            <Border Grid.Column="2" Background="#EFEFEF" CornerRadius="4" Padding="6,2" VerticalAlignment="Center" Margin="10,0">
                                                <TextBlock Text="{Binding MemoryMB, StringFormat={}{0} MB}" FontSize="11" FontWeight="SemiBold"/>
                                            </Border>
                                            <Button Grid.Column="3" Name="BtnTargetProcess" Content="🎯 Deep Clean" Tag="{Binding}" Style="{StaticResource PrimaryButton}" Padding="12,4" FontSize="11"/>
                                        </Grid>
                                    </Border>
                                </DataTemplate>
                            </ListBox.ItemTemplate>
                        </ListBox>
                    </Grid>
                </Border>
            </Grid>

            <!-- VIEW E: Leftover Cards Grid (Detailed Subsystem Review) -->
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

                    <!-- Header with Back Button -->
                    <Grid Grid.Row="0" Grid.ColumnSpan="3" Margin="8,4,8,8">
                        <Button Name="BtnBackFromCards" Content="← Back to List" Style="{StaticResource SecondaryButton}" HorizontalAlignment="Left"/>
                        <TextBlock Name="TxtCardsTargetTitle" Text="Leftovers for Application" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                            <Button Name="BtnSelectAllCards" Content="Select All" Style="{StaticResource SecondaryButton}" Margin="0,0,6,0"/>
                            <Button Name="BtnClearAllCards" Content="Clear" Style="{StaticResource SecondaryButton}"/>
                        </StackPanel>
                    </Grid>

                    <!-- Card 1: Files & Folders -->
                    <Border Grid.Row="1" Grid.Column="0" Style="{StaticResource CardBorder}">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
                                <TextBlock Text="📁" FontSize="15" Margin="0,0,6,0"/>
                                <TextBlock Text="Files &amp; Storage" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                            </StackPanel>
                            <StackPanel Name="PnlFilesList"/>
                        </StackPanel>
                    </Border>

                    <!-- Card 2: Registry -->
                    <Border Grid.Row="1" Grid.Column="1" Style="{StaticResource CardBorder}">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
                                <TextBlock Text="🗝️" FontSize="15" Margin="0,0,6,0"/>
                                <TextBlock Text="Windows Registry" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                            </StackPanel>
                            <StackPanel Name="PnlRegistryList"/>
                        </StackPanel>
                    </Border>

                    <!-- Card 3: Services & Shortcuts -->
                    <Border Grid.Row="1" Grid.Column="2" Style="{StaticResource CardBorder}">
                        <StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
                                <TextBlock Text="⚙️" FontSize="15" Margin="0,0,6,0"/>
                                <TextBlock Text="Services &amp; Shortcuts" FontWeight="Bold" FontSize="13" VerticalAlignment="Center"/>
                            </StackPanel>
                            <StackPanel Name="PnlServicesList"/>
                            <StackPanel Name="PnlShortcutsList" Margin="0,8,0,0"/>
                        </StackPanel>
                    </Border>
                </Grid>
            </ScrollViewer>

            <!-- VIEW F: Backups & Rollback History -->
            <Grid Name="ViewBackups" Visibility="Collapsed">
                <Border Style="{StaticResource CardBorder}" Margin="6">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <Grid Margin="4,0,0,8">
                            <TextBlock Text="Safety Backup Snapshots (Restorable points created before cleanups)" FontWeight="SemiBold" FontSize="13"/>
                            <Button Name="BtnRestoreSelectedBackup" Content="↺ Restore Selected Backup" Style="{StaticResource PrimaryButton}" HorizontalAlignment="Right" Padding="14,4"/>
                        </Grid>
                        <ListBox Name="LstBackups" Grid.Row="1" BorderThickness="0" Background="Transparent">
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
                                                <TextBlock Text="{Binding ApplicationName}" FontWeight="Bold" FontSize="13" Foreground="#1B1B1B"/>
                                                <TextBlock Text="{Binding BackupId}" FontSize="11" Foreground="#707070"/>
                                            </StackPanel>
                                            <TextBlock Grid.Column="1" Text="{Binding CreatedAt}" FontSize="12" Foreground="#666666" VerticalAlignment="Center" Margin="16,0"/>
                                            <Border Grid.Column="2" Background="#EBF3FC" CornerRadius="4" Padding="8,3" VerticalAlignment="Center">
                                                <TextBlock Text="{Binding TotalItems, StringFormat={}{0} Items}" FontSize="11" FontWeight="SemiBold" Foreground="#0067C0"/>
                                            </Border>
                                        </Grid>
                                    </Border>
                                </DataTemplate>
                            </ListBox.ItemTemplate>
                        </ListBox>
                    </Grid>
                </Border>
            </Grid>

            <!-- VIEW G: Summary & Results -->
            <Grid Name="ViewStep3" Visibility="Collapsed">
                <Border Style="{StaticResource CardBorder}" Margin="6" Padding="40">
                    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" MaxWidth="520">
                        <TextBlock Name="TxtStatusHeading" Text="Cleanup Complete!" FontSize="22" FontWeight="Bold" Foreground="#107C10" TextAlignment="Center" Margin="0,0,0,10"/>
                        <TextBlock Name="TxtStatusDetails" Text="All human-approved leftovers have been safely removed." FontSize="13" Foreground="#5C5C5C" TextAlignment="Center" Margin="0,0,0,20"/>
                        <ProgressBar Name="PrgCleanup" Height="8" Margin="0,0,0,24" Maximum="100" Value="100"/>
                        <Border Background="#F9F9F9" BorderBrush="#EAEAEA" BorderThickness="1" CornerRadius="6" Padding="16" Margin="0,0,0,24">
                            <StackPanel>
                                <TextBlock Name="TxtResultStats" Text="Removed: 0 MB across 0 items" FontWeight="SemiBold" FontSize="13"/>
                                <TextBlock Name="TxtBackupId" Text="Backup: None" FontSize="11" Foreground="#707070" Margin="0,4,0,0"/>
                            </StackPanel>
                        </Border>
                        <Button Name="BtnReturnHome" Content="← Return to Scanner" Style="{StaticResource SecondaryButton}" HorizontalAlignment="Center"/>
                    </StackPanel>
                </Border>
            </Grid>

        </Grid>

        <!-- Bottom Navigation Bar -->
        <Border Grid.Row="5" Background="#FFFFFF" BorderBrush="#E5E5E5" BorderThickness="0,1,0,0" Padding="24,10">
            <Grid>
                <TextBlock Name="TxtBottomSummary" Text="HailUninstaller ready." VerticalAlignment="Center" HorizontalAlignment="Left" FontWeight="SemiBold" FontSize="13" Foreground="#1B1B1B"/>
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

    # Bind Controls
    $tabOrphans = $window.FindName("TabOrphans")
    $tabInstalled = $window.FindName("TabInstalled")
    $tabForced = $window.FindName("TabForced")
    $tabHunter = $window.FindName("TabHunter")
    $tabBackups = $window.FindName("TabBackups")

    $btnScanAction = $window.FindName("BtnScanAction")
    $btnSelectHigh = $window.FindName("BtnSelectHigh")
    $btnSelectAll = $window.FindName("BtnSelectAll")
    $btnSelectHeavy = $window.FindName("BtnSelectHeavy")
    $btnClearSelection = $window.FindName("BtnClearSelection")
    $txtSearch = $window.FindName("TxtSearch")

    $viewOrphans = $window.FindName("ViewOrphans")
    $viewInstalled = $window.FindName("ViewInstalled")
    $viewForced = $window.FindName("ViewForced")
    $viewHunter = $window.FindName("ViewHunter")
    $viewLeftoverCards = $window.FindName("ViewLeftoverCards")
    $viewBackups = $window.FindName("ViewBackups")
    $viewStep3 = $window.FindName("ViewStep3")

    $pnlScanPrompt = $window.FindName("PnlScanPrompt")
    $btnStartScanHero = $window.FindName("BtnStartScanHero")
    $lstOrphans = $window.FindName("LstOrphans")
    $txtOrphanCount = $window.FindName("TxtOrphanCount")

    $lstApps = $window.FindName("LstApps")
    $btnAppNormalUninstall = $window.FindName("BtnAppNormalUninstall")
    $btnAppQuietUninstall = $window.FindName("BtnAppQuietUninstall")
    $btnAppDeepScan = $window.FindName("BtnAppDeepScan")

    $txtForcedTarget = $window.FindName("TxtForcedTarget")
    $btnBrowseForcedFolder = $window.FindName("BtnBrowseForcedFolder")
    $btnBrowseForcedExe = $window.FindName("BtnBrowseForcedExe")
    $btnRunForcedScan = $window.FindName("BtnRunForcedScan")

    $lstHunter = $window.FindName("LstHunter")
    $btnRefreshHunter = $window.FindName("BtnRefreshHunter")

    $btnBackFromCards = $window.FindName("BtnBackFromCards")
    $txtCardsTargetTitle = $window.FindName("TxtCardsTargetTitle")
    $btnSelectAllCards = $window.FindName("BtnSelectAllCards")
    $btnClearAllCards = $window.FindName("BtnClearAllCards")
    $pnlFilesList = $window.FindName("PnlFilesList")
    $pnlRegistryList = $window.FindName("PnlRegistryList")
    $pnlServicesList = $window.FindName("PnlServicesList")
    $pnlShortcutsList = $window.FindName("PnlShortcutsList")

    $lstBackups = $window.FindName("LstBackups")
    $btnRestoreSelectedBackup = $window.FindName("BtnRestoreSelectedBackup")

    $txtResultStats = $window.FindName("TxtResultStats")
    $txtBackupId = $window.FindName("TxtBackupId")
    $btnReturnHome = $window.FindName("BtnReturnHome")

    $txtBottomSummary = $window.FindName("TxtBottomSummary")
    $btnNext = $window.FindName("BtnNext")

    # State
    $script:activeTab = "Orphans"
    $script:allOrphans = [System.Collections.ObjectModel.ObservableCollection[PSCustomObject]]::new()
    $script:allInstalledApps = @()
    $script:currentLeftoverItems = @()
    $script:activeTargetApp = $null
    $script:latestBackupId = ""

    # Helper: Set Tab UI Active State
    $setTabActive = {
        param($activeBtn)
        $tabs = @($tabOrphans, $tabInstalled, $tabForced, $tabHunter, $tabBackups)
        foreach ($t in $tabs) {
            if ($t -eq $activeBtn) {
                $t.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0067C0")
                $t.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0067C0")
            } else {
                $t.BorderBrush = [System.Windows.Media.Brushes]::Transparent
                $t.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5C5C5C")
            }
        }
    }

    # Helper: Switch Active View cleanly
    $switchView = {
        param($targetView)
        $views = @($viewOrphans, $viewInstalled, $viewForced, $viewHunter, $viewLeftoverCards, $viewBackups, $viewStep3)
        foreach ($v in $views) {
            $v.Visibility = if ($v -eq $targetView) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
        }
    }

    # Summary updater for Orphans
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
        $txtBottomSummary.Text = "Selected: $selCount orphan folder(s) ($szStr) ready for removal."
    }

    # Load Orphans Function
    $loadOrphansData = {
        $window.Cursor = [System.Windows.Input.Cursors]::Wait
        $txtOrphanCount.Text = "Scanning storage for uninstalled app leftovers..."
        $btnScanAction.IsEnabled = $false

        $rawOrphans = @(Scan-OrphanedStorageFolders -ConfigDir $ConfigDir)
        $script:allOrphans.Clear()

        $totalOrphanBytes = 0L
        foreach ($o in $rawOrphans) {
            $totalOrphanBytes += [long]$o.Size
            $script:allOrphans.Add([PSCustomObject]@{
                Category      = $o.Category
                SubCategory   = $o.SubCategory
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

        if ($pnlScanPrompt) { $pnlScanPrompt.Visibility = [System.Windows.Visibility]::Collapsed }
        $lstOrphans.Visibility = [System.Windows.Visibility]::Visible
        $lstOrphans.ItemsSource = $script:allOrphans

        $btnSelectHigh.IsEnabled = $true
        $btnSelectAll.IsEnabled = $true
        $btnSelectHeavy.IsEnabled = $true
        $btnClearSelection.IsEnabled = $true
        $btnScanAction.IsEnabled = $true
        $btnScanAction.Content = "🔄 Rescan Storage"

        $totalFormatted = Format-Bytes $totalOrphanBytes
        $txtOrphanCount.Text = "$($script:allOrphans.Count) folders found ($totalFormatted total)"
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        & $updateOrphanSummary
    }

    # Load Installed Applications
    $loadInstalledApps = {
        if ($script:allInstalledApps.Count -eq 0) {
            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            $script:allInstalledApps = @(Get-InstalledApplications -IncludeAppX)
            $lstApps.ItemsSource = $script:allInstalledApps
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        }
    }

    # Load Hunter Processes
    $loadHunterProcesses = {
        $window.Cursor = [System.Windows.Input.Cursors]::Wait
        $targets = @(Get-RunningHunterTargets -ConfigDir $ConfigDir)
        $lstHunter.ItemsSource = $targets
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
    }

    # Load Backups
    $loadBackupsData = {
        $window.Cursor = [System.Windows.Input.Cursors]::Wait
        $backups = @(Get-CleanupBackups)
        $lstBackups.ItemsSource = $backups
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
    }

    # Display Leftover Cards for any Scored Result Set
    $displayLeftoverCards = {
        param($app, $leftovers)
        $script:activeTargetApp = $app
        $script:currentLeftoverItems = @($leftovers)
        $txtCardsTargetTitle.Text = "Leftovers: $($app.DisplayName)"

        $pnlFilesList.Children.Clear()
        $pnlRegistryList.Children.Clear()
        $pnlServicesList.Children.Clear()
        $pnlShortcutsList.Children.Clear()

        foreach ($item in $leftovers) {
            $cb = [System.Windows.Controls.CheckBox]::new()
            $cb.FontSize = 12
            $cb.Margin = [System.Windows.Thickness]::new(0, 4, 0, 4)
            $cb.Tag = $item

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

        & $switchView $viewLeftoverCards
        $btnNext.Content = "Clean Selected Items →"
        $btnNext.Visibility = [System.Windows.Visibility]::Visible
        $txtBottomSummary.Text = "Review detected remnants. Uncheck any items you wish to preserve."
    }

    # Tab 1: Orphans
    $tabOrphans.Add_Click({
        $script:activeTab = "Orphans"
        & $setTabActive $tabOrphans
        & $switchView $viewOrphans
        $btnScanAction.Visibility = [System.Windows.Visibility]::Visible
        $btnSelectHigh.Visibility = [System.Windows.Visibility]::Visible
        $btnSelectAll.Visibility = [System.Windows.Visibility]::Visible
        $btnSelectHeavy.Visibility = [System.Windows.Visibility]::Visible
        $btnClearSelection.Visibility = [System.Windows.Visibility]::Visible
        $btnNext.Content = "Delete Selected Ghost Folders →"
        $btnNext.Visibility = [System.Windows.Visibility]::Visible
        & $updateOrphanSummary
    })

    # Tab 2: Installed Apps
    $tabInstalled.Add_Click({
        $script:activeTab = "Installed"
        & $setTabActive $tabInstalled
        & $switchView $viewInstalled
        $btnScanAction.Visibility = [System.Windows.Visibility]::Collapsed
        $btnSelectHigh.Visibility = [System.Windows.Visibility]::Collapsed
        $btnSelectAll.Visibility = [System.Windows.Visibility]::Visible
        $btnSelectHeavy.Visibility = [System.Windows.Visibility]::Collapsed
        $btnClearSelection.Visibility = [System.Windows.Visibility]::Visible
        $btnNext.Content = "Scan Leftovers For App →"
        $btnNext.Visibility = [System.Windows.Visibility]::Visible
        & $loadInstalledApps
        $txtBottomSummary.Text = "Select an installed application to uninstall or deep scan."
    })

    # Tab 3: Forced Uninstall
    $tabForced.Add_Click({
        $script:activeTab = "Forced"
        & $setTabActive $tabForced
        & $switchView $viewForced
        $btnScanAction.Visibility = [System.Windows.Visibility]::Collapsed
        $btnSelectHigh.Visibility = [System.Windows.Visibility]::Collapsed
        $btnSelectAll.Visibility = [System.Windows.Visibility]::Collapsed
        $btnSelectHeavy.Visibility = [System.Windows.Visibility]::Collapsed
        $btnClearSelection.Visibility = [System.Windows.Visibility]::Collapsed
        $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
        $txtBottomSummary.Text = "Specify a leftover folder or executable to purge broken software."
    })

    # Tab 4: Hunter Mode
    $tabHunter.Add_Click({
        $script:activeTab = "Hunter"
        & $setTabActive $tabHunter
        & $switchView $viewHunter
        $btnScanAction.Visibility = [System.Windows.Visibility]::Collapsed
        $btnSelectHigh.Visibility = [System.Windows.Visibility]::Collapsed
        $btnSelectAll.Visibility = [System.Windows.Visibility]::Collapsed
        $btnSelectHeavy.Visibility = [System.Windows.Visibility]::Collapsed
        $btnClearSelection.Visibility = [System.Windows.Visibility]::Collapsed
        $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
        & $loadHunterProcesses
        $txtBottomSummary.Text = "Inspect active processes to trace their origin and remove."
    })

    # Tab 5: Backups
    $tabBackups.Add_Click({
        $script:activeTab = "Backups"
        & $setTabActive $tabBackups
        & $switchView $viewBackups
        $btnScanAction.Visibility = [System.Windows.Visibility]::Collapsed
        $btnSelectHigh.Visibility = [System.Windows.Visibility]::Collapsed
        $btnSelectAll.Visibility = [System.Windows.Visibility]::Collapsed
        $btnSelectHeavy.Visibility = [System.Windows.Visibility]::Collapsed
        $btnClearSelection.Visibility = [System.Windows.Visibility]::Collapsed
        $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
        & $loadBackupsData
        $txtBottomSummary.Text = "Select any previous backup snapshot to restore deleted items."
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

    # Selection buttons
    $btnSelectHigh.Add_Click({
        if ($script:activeTab -eq "Orphans") {
            foreach ($o in $script:allOrphans) { $o.Selected = ($o.Size -ge 10MB) }
            $lstOrphans.Items.Refresh()
            & $updateOrphanSummary
        }
    })

    $btnSelectAll.Add_Click({
        if ($script:activeTab -eq "Orphans") {
            foreach ($o in $script:allOrphans) { $o.Selected = $true }
            $lstOrphans.Items.Refresh()
            & $updateOrphanSummary
        } elseif ($script:activeTab -eq "Installed") {
            foreach ($a in $script:allInstalledApps) { $a.Selected = $true }
            $lstApps.Items.Refresh()
        }
    })

    $btnSelectHeavy.Add_Click({
        if ($script:activeTab -eq "Orphans") {
            foreach ($o in $script:allOrphans) { $o.Selected = ($o.Size -ge 100MB) }
            $lstOrphans.Items.Refresh()
            & $updateOrphanSummary
        }
    })

    $btnClearSelection.Add_Click({
        if ($script:activeTab -eq "Orphans") {
            foreach ($o in $script:allOrphans) { $o.Selected = $false }
            $lstOrphans.Items.Refresh()
            & $updateOrphanSummary
        } elseif ($script:activeTab -eq "Installed") {
            foreach ($a in $script:allInstalledApps) { $a.Selected = $false }
            $lstApps.Items.Refresh()
        }
    })

    # Trigger Orphan Scan
    $btnScanAction.Add_Click({ & $loadOrphansData })
    if ($btnStartScanHero) { $btnStartScanHero.Add_Click({ & $loadOrphansData }) }

    # App Actions: Standard Uninstall
    $btnAppNormalUninstall.Add_Click({
        if (-not $lstApps.SelectedItem) {
            [System.Windows.MessageBox]::Show("Please select an application to uninstall.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            return
        }
        $app = $lstApps.SelectedItem
        $res = [System.Windows.MessageBox]::Show("Launch official uninstaller for '$($app.DisplayName)'?", "Standard Uninstall", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            Invoke-NativeUninstall -Application $app -Quiet:$false
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
            $script:allInstalledApps = @()
            & $loadInstalledApps
        }
    })

    # App Actions: Quiet Uninstall
    $btnAppQuietUninstall.Add_Click({
        if (-not $lstApps.SelectedItem) {
            [System.Windows.MessageBox]::Show("Please select an application to quietly uninstall.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            return
        }
        $app = $lstApps.SelectedItem
        $res = [System.Windows.MessageBox]::Show("Run silent / unattended uninstaller for '$($app.DisplayName)'?`n`nHailUninstaller will automatically inject quiet parameters.", "Quiet Uninstall", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            Invoke-NativeUninstall -Application $app -Quiet:$true
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
            $script:allInstalledApps = @()
            & $loadInstalledApps
        }
    })

    # App Actions: Deep Scan
    $btnAppDeepScan.Add_Click({
        if (-not $lstApps.SelectedItem) {
            [System.Windows.MessageBox]::Show("Please select an application to deep-scan.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            return
        }
        $app = $lstApps.SelectedItem
        $window.Cursor = [System.Windows.Input.Cursors]::Wait
        $leftovers = @(Start-DeepScan -Application $app -ConfigDir $ConfigDir)
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
        & $displayLeftoverCards $app $leftovers
    })

    # Forced Uninstall: Browse Folder
    $btnBrowseForcedFolder.Add_Click({
        $dlg = [System.Windows.Forms.FolderBrowserDialog]::new()
        $dlg.Description = "Select target application folder to purge"
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtForcedTarget.Text = $dlg.SelectedPath
        }
    })

    # Forced Uninstall: Browse Exe
    $btnBrowseForcedExe.Add_Click({
        $dlg = [System.Windows.Forms.OpenFileDialog]::new()
        $dlg.Filter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*"
        $dlg.Title = "Select target application executable"
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtForcedTarget.Text = $dlg.FileName
        }
    })

    # Forced Uninstall: Run Scan
    $btnRunForcedScan.Add_Click({
        $target = $txtForcedTarget.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($target)) {
            [System.Windows.MessageBox]::Show("Please enter or browse to a target folder or program name.", "Forced Uninstall", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            return
        }
        $window.Cursor = [System.Windows.Input.Cursors]::Wait
        $res = Start-ForcedUninstall -Target $target -ConfigDir $ConfigDir
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow

        $syntheticApp = [PSCustomObject]@{
            DisplayName     = $res.TargetName
            Publisher       = $res.TargetPublisher
            InstallLocation = $res.TargetPath
        }
        & $displayLeftoverCards $syntheticApp $res.Candidates
    })

    # Hunter Mode: Target Running Process
    $btnRefreshHunter.Add_Click({ & $loadHunterProcesses })
    $window.AddHandler([System.Windows.Controls.Button]::ClickEvent, [System.Windows.RoutedEventHandler]{
        param($sender, $e)
        if ($e.OriginalSource -is [System.Windows.Controls.Button] -and $e.OriginalSource.Name -eq "BtnTargetProcess") {
            $procTarget = $e.OriginalSource.Tag
            if ($procTarget) {
                $confirm = [System.Windows.MessageBox]::Show("Target and trace remnants for process '$($procTarget.ProcessName)' (PID: $($procTarget.Id))?`n`nLocation: $($procTarget.Path)", "Hunter Target", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
                if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
                    $window.Cursor = [System.Windows.Input.Cursors]::Wait
                    $res = Invoke-HunterTarget -Target $procTarget -TerminateProcess:$true -ConfigDir $ConfigDir
                    $window.Cursor = [System.Windows.Input.Cursors]::Arrow

                    $syntheticApp = [PSCustomObject]@{
                        DisplayName     = $res.TargetName
                        Publisher       = $res.TargetPublisher
                        InstallLocation = $res.TargetPath
                    }
                    & $displayLeftoverCards $syntheticApp $res.Candidates
                }
            }
        }
    })

    # Leftover Cards: Select All / Clear
    $btnSelectAllCards.Add_Click({
        foreach ($pnl in @($pnlFilesList, $pnlRegistryList, $pnlServicesList, $pnlShortcutsList)) {
            foreach ($child in $pnl.Children) {
                if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsEnabled) {
                    $child.IsChecked = $true
                }
            }
        }
    })

    $btnClearAllCards.Add_Click({
        foreach ($pnl in @($pnlFilesList, $pnlRegistryList, $pnlServicesList, $pnlShortcutsList)) {
            foreach ($child in $pnl.Children) {
                if ($child -is [System.Windows.Controls.CheckBox]) {
                    $child.IsChecked = $false
                }
            }
        }
    })

    $btnBackFromCards.Add_Click({
        & $switchView $viewInstalled
        $btnNext.Content = "Scan Leftovers For App →"
    })

    # Restore Button
    $btnRestoreSelectedBackup.Add_Click({
        if (-not $lstBackups.SelectedItem) {
            [System.Windows.MessageBox]::Show("Please select a backup snapshot from the list.", "Restore", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            return
        }
        $backup = $lstBackups.SelectedItem
        $c = [System.Windows.MessageBox]::Show("Restore all deleted files and registry entries from snapshot '$($backup.BackupId)'?", "Restore Snapshot", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($c -eq [System.Windows.MessageBoxResult]::Yes) {
            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            $rRes = Restore-CleanupBackup -BackupId $backup.BackupId
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
            [System.Windows.MessageBox]::Show("Successfully restored $($rRes.RestoredCount) item(s)! (Failed: $($rRes.FailedCount))", "Restore Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        }
    })

    $btnReturnHome.Add_Click({
        & $tabOrphans.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
    })

    # Bottom Main Action Button ($btnNext)
    $btnNext.Add_Click({
        # SCENARIO 1: Cleaning Orphan Ghost Folders
        if ($viewOrphans.Visibility -eq [System.Windows.Visibility]::Visible) {
            $selectedItems = @($script:allOrphans | Where-Object { $_.Selected })
            if ($selectedItems.Count -eq 0) {
                [System.Windows.MessageBox]::Show("Please select at least one orphan folder to delete.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                return
            }

            $totalBytes = 0L
            foreach ($s in $selectedItems) { $totalBytes += [long]$s.Size }
            $szStr = Format-Bytes $totalBytes

            # STRICT HUMAN APPROVAL MODAL
            $msg = "HUMAN APPROVAL REQUIRED:`n`nAre you sure you want to delete $($selectedItems.Count) orphaned folder(s) totaling $szStr?`n`nThese folders belong to applications that are no longer installed on your system.`n`nContinue with permanent deletion?"
            $res = [System.Windows.MessageBox]::Show($msg, "Confirm Storage Cleanup - HailUninstaller", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
            
            if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }

            $mockApp = [PSCustomObject]@{
                DisplayName     = "Orphaned_Storage_Cleanup"
                Publisher       = "HailUninstaller"
                InstallLocation = ""
            }

            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            $backupRes = New-CleanupBackup -Application $mockApp -SelectedItems $selectedItems
            $script:latestBackupId = $backupRes.BackupId

            $cRes = Invoke-CleanupItems -SelectedItems $selectedItems -HumanApproved
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow

            & $switchView $viewStep3
            $txtResultStats.Text = "Freed: $(Format-Bytes $cRes.RemovedBytes) across $($cRes.RemovedCount) orphaned folder(s)!"
            $txtBackupId.Text = "Backup Snapshot: $($backupRes.BackupId)"
            $btnNext.Visibility = [System.Windows.Visibility]::Collapsed

        # SCENARIO 2: Scanning Selected App from Installed List
        } elseif ($viewInstalled.Visibility -eq [System.Windows.Visibility]::Visible) {
            if (-not $lstApps.SelectedItem) {
                [System.Windows.MessageBox]::Show("Please select an application to scan.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                return
            }
            $app = $lstApps.SelectedItem
            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            $leftovers = @(Start-DeepScan -Application $app -ConfigDir $ConfigDir)
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
            & $displayLeftoverCards $app $leftovers

        # SCENARIO 3: Cleaning Selected Remnants from Leftover Cards View
        } elseif ($viewLeftoverCards.Visibility -eq [System.Windows.Visibility]::Visible) {
            $selectedRemnants = [System.Collections.Generic.List[PSCustomObject]]::new()
            foreach ($pnl in @($pnlFilesList, $pnlRegistryList, $pnlServicesList, $pnlShortcutsList)) {
                foreach ($child in $pnl.Children) {
                    if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsChecked -and $child.Tag) {
                        $item = $child.Tag
                        $item.Selected = $true
                        $selectedRemnants.Add($item)
                    }
                }
            }

            if ($selectedRemnants.Count -eq 0) {
                [System.Windows.MessageBox]::Show("No leftover items are selected for cleanup.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                return
            }

            $totalBytes = 0L
            foreach ($sr in $selectedRemnants) { $totalBytes += [long]$sr.Size }
            $szStr = Format-Bytes $totalBytes

            # STRICT HUMAN APPROVAL MODAL
            $targetName = if ($script:activeTargetApp) { $script:activeTargetApp.DisplayName } else { "Target Application" }
            $msg = "HUMAN APPROVAL REQUIRED:`n`nPermanently delete $($selectedRemnants.Count) approved leftover remnant(s) for '$targetName' ($szStr)?`n`nA safety backup snapshot will be created before deletion.`n`nContinue with cleanup?"
            $res = [System.Windows.MessageBox]::Show($msg, "Confirm Remnant Removal - HailUninstaller", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
            
            if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }

            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            $backupRes = New-CleanupBackup -Application $script:activeTargetApp -SelectedItems $selectedRemnants
            $script:latestBackupId = $backupRes.BackupId

            $cRes = Invoke-CleanupItems -SelectedItems $selectedRemnants -HumanApproved
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow

            & $switchView $viewStep3
            $txtResultStats.Text = "Freed: $(Format-Bytes $cRes.RemovedBytes) across $($cRes.RemovedCount) remnant item(s)!"
            $txtBackupId.Text = "Backup Snapshot: $($backupRes.BackupId)"
            $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
        }
    })

    # Window Loaded: Immediate instant launch
    $window.Add_Loaded({
        $txtBottomSummary.Text = "HailUninstaller v2.0 ready. Click 'Scan Storage Leftovers' or switch tabs."
    })

    # Launch GUI dialog
    [void]$window.ShowDialog()
}
