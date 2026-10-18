# Modules/GUI.ps1
# Windows 11 Fluent WPF GUI v0.0.1 for HailUninstaller
# Features:
# - Zero-freeze Asynchronous Runspace Execution Engine (60 FPS responsiveness)
# - Real-Time CMD Console Logging Synchronization (timestamped, color-coded stream)
# - Interactive Circular Scanning Animation inside Scan Buttons (WPF RotateTransform Storyboard)
# - Fluid Page Transitions & Button Micro-interactions (Fade + Slide ease-out)
# - Full Integration: Orphan Storage Cleaner, Batch Apps, Quiet Engine, Forced Purge, Hunter Mode, Backups

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms

# Global Console Logger for Real-Time CMD Output
function Log-GuiConsole {
    [CmdletBinding()]
    param(
        [string]$Tag = "GUI",
        [string]$Message,
        [System.ConsoleColor]$Color = [System.ConsoleColor]::Cyan
    )
    $ts = [DateTime]::Now.ToString("HH:mm:ss")
    Write-Host "[$ts] " -NoNewline -ForegroundColor DarkGray
    Write-Host "[$Tag] " -NoNewline -ForegroundColor $Color
    Write-Host $Message -ForegroundColor White
}

function Show-HailUninstallerGUI {
    [CmdletBinding()]
    param(
        [string]$ConfigDir = ""
    )

    $scriptDir = if ($PSScriptRoot) { Split-Path $PSScriptRoot -Parent } else { (Get-Location).Path }
    if (-not $ConfigDir) {
        $ConfigDir = Join-Path $scriptDir "Config"
    }

    $modulesDir = Join-Path $scriptDir "Modules"
    $logoPath = Join-Path $scriptDir "logo.png"

    Log-GuiConsole -Tag "INIT" -Message "Initializing HailUninstaller v0.0.1 Fluent GUI..." -Color Green

    # Define XAML for Windows 11 Fluent UI v0.0.1
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="HailUninstaller - Deep Application &amp; Storage Removal" Height="840" Width="1200"
        MinHeight="720" MinWidth="1020"
        WindowStartupLocation="CenterScreen"
        Background="#F3F3F3"
        FontFamily="Segoe UI Variable Text, Segoe UI, sans-serif">
    
    <Window.Resources>
        <!-- Secondary Button Style -->
        <Style x:Key="SecondaryButton" TargetType="Button">
            <Setter Property="Background" Value="#FFFFFF"/>
            <Setter Property="Foreground" Value="#1B1B1B"/>
            <Setter Property="BorderBrush" Value="#E0E0E0"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="RenderTransformOrigin" Value="0.5,0.5"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Border" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="#F8F8F8"/>
                                <Setter TargetName="Border" Property="BorderBrush" Value="#C5C5C5"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="#EFEFEF"/>
                                <Setter Property="RenderTransform">
                                    <Setter.Value>
                                        <ScaleTransform ScaleX="0.97" ScaleY="0.97"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Border" Property="Opacity" Value="0.5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Tab Button Style -->
        <Style x:Key="TabButton" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#5C5C5C"/>
            <Setter Property="BorderThickness" Value="0,0,0,2"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="Padding" Value="16,9"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="TabBorder" Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="TabBorder" Property="Background" Value="#EBEBEB"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Primary Button Style -->
        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="#0067C0"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="18,8"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="RenderTransformOrigin" Value="0.5,0.5"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Border" Background="{TemplateBinding Background}"
                                CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="#1873C4"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="#005A9E"/>
                                <Setter Property="RenderTransform">
                                    <Setter.Value>
                                        <ScaleTransform ScaleX="0.97" ScaleY="0.97"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Border" Property="Background" Value="#CCCCCC"/>
                                <Setter Property="Foreground" Value="#888888"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
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
                        <TextBlock Text="v0.0.1" FontSize="10" FontWeight="Bold" Foreground="#444444"/>
                    </Border>
                </StackPanel>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <TextBlock Name="TxtLiveStatusIndicator" Text="Ready" FontSize="11" Foreground="#107C41" Margin="0,0,16,0" FontWeight="SemiBold"/>
                    <TextBlock Text="Deep Application &amp; Storage Removal Suite" FontSize="11" Foreground="#707070"/>
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
                <Button Name="TabOrphans" Content="Ghost Folders" Style="{StaticResource TabButton}" BorderBrush="#0067C0" Foreground="#0067C0"/>
                <Button Name="TabInstalled" Content="Installed Applications" Style="{StaticResource TabButton}" Margin="8,0,0,0"/>
                <Button Name="TabForced" Content="Forced Uninstall" Style="{StaticResource TabButton}" Margin="8,0,0,0"/>
                <Button Name="TabHunter" Content="Hunter Mode" Style="{StaticResource TabButton}" Margin="8,0,0,0"/>
                <Button Name="TabBackups" Content="Backups &amp; Rollback" Style="{StaticResource TabButton}" Margin="8,0,0,0"/>
            </StackPanel>
        </Border>

        <!-- Action / Filter Bar -->
        <Grid Grid.Row="3" Margin="24,4,24,8">
            <StackPanel Orientation="Horizontal">
                <Button Name="BtnScanAction" Style="{StaticResource PrimaryButton}" Margin="0,0,8,0" Padding="14,6">
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <!-- React Bits LatticeLoader Component -->
                        <Grid Name="LatticeScanAction" Width="17" Height="17" Margin="0,0,8,0" Visibility="Collapsed" VerticalAlignment="Center">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="5"/>
                                <ColumnDefinition Width="5"/>
                                <ColumnDefinition Width="5"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="5"/>
                                <RowDefinition Height="5"/>
                                <RowDefinition Height="5"/>
                            </Grid.RowDefinitions>
                            <Rectangle Name="CellScan_0" Grid.Row="0" Grid.Column="0" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            <Rectangle Name="CellScan_1" Grid.Row="0" Grid.Column="1" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            <Rectangle Name="CellScan_2" Grid.Row="0" Grid.Column="2" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            <Rectangle Name="CellScan_7" Grid.Row="1" Grid.Column="0" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            <Rectangle Name="CellScan_8" Grid.Row="1" Grid.Column="1" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            <Rectangle Name="CellScan_3" Grid.Row="1" Grid.Column="2" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            <Rectangle Name="CellScan_6" Grid.Row="2" Grid.Column="0" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            <Rectangle Name="CellScan_5" Grid.Row="2" Grid.Column="1" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            <Rectangle Name="CellScan_4" Grid.Row="2" Grid.Column="2" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Grid>
                        <TextBlock Name="TxtScanActionIcon" Text="" Margin="0" VerticalAlignment="Center"/>
                        <TextBlock Name="TxtScanActionLabel" Text="Scan Storage Leftovers" VerticalAlignment="Center"/>
                        <TextBlock Name="TxtScanActionTimer" Text="0.0s" Margin="6,0,0,0" FontSize="11" Opacity="0.85" FontFamily="Consolas, monospace" VerticalAlignment="Center" Visibility="Collapsed"/>
                    </StackPanel>
                </Button>
                <Button Name="BtnSelectHigh" Content="Select High Confidence" Style="{StaticResource SecondaryButton}" Margin="0,0,6,0" IsEnabled="False"/>
                <Button Name="BtnSelectAll" Content="Select All" Style="{StaticResource SecondaryButton}" Margin="0,0,6,0" IsEnabled="False"/>
                <Button Name="BtnSelectHeavy" Content="Select &gt; 100 MB" Style="{StaticResource SecondaryButton}" Margin="0,0,6,0" IsEnabled="False"/>
                <Button Name="BtnClearSelection" Content="Clear Selection" Style="{StaticResource SecondaryButton}" Margin="0,0,6,0" IsEnabled="False"/>
            </StackPanel>

            <Border HorizontalAlignment="Right" Background="#FFFFFF" BorderBrush="#E0E0E0" BorderThickness="1" CornerRadius="5" Padding="8,4" Width="260">
                <Grid>
                    <TextBox Name="TxtSearch" BorderThickness="0" Background="Transparent" Margin="4,0,0,0" FontSize="12" VerticalAlignment="Center" ToolTip="Search current items..."/>
                </Grid>
            </Border>
        </Grid>

        <!-- Main Content Area with Fluid Page Transition Containers -->
        <Grid Grid.Row="4" Margin="18,0,18,0">
            
            <!-- VIEW A: Orphaned Storage Folders List -->
            <Grid Name="ViewOrphans" Visibility="Visible">
                <Grid.RenderTransform>
                    <TranslateTransform Y="0"/>
                </Grid.RenderTransform>
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
                                <TextBlock Text="[STORAGE SCAN]" FontSize="13" FontWeight="Bold" Foreground="#0067C0" HorizontalAlignment="Center" Margin="0,0,0,10"/>
                                <TextBlock Text="Ready to Deep-Scan Storage Drives" FontSize="17" FontWeight="Bold" Foreground="#1B1B1B" HorizontalAlignment="Center" Margin="0,0,0,4"/>
                                <TextBlock Text="HailUninstaller will deeply analyze AppData, ProgramData, and secondary fixed drive roots to safely discover folders whose applications have already been uninstalled." FontSize="12" Foreground="#666666" TextWrapping="Wrap" TextAlignment="Center" Margin="0,0,0,18"/>
                                <Button Name="BtnStartScanHero" Style="{StaticResource PrimaryButton}" HorizontalAlignment="Center" Padding="24,8" FontSize="13">
                                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                        <!-- React Bits LatticeLoader Component -->
                                        <Grid Name="LatticeStartScanHero" Width="18" Height="18" Margin="0,0,8,0" Visibility="Collapsed" VerticalAlignment="Center">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="6"/>
                                                <ColumnDefinition Width="6"/>
                                                <ColumnDefinition Width="6"/>
                                            </Grid.ColumnDefinitions>
                                            <Grid.RowDefinitions>
                                                <RowDefinition Height="6"/>
                                                <RowDefinition Height="6"/>
                                                <RowDefinition Height="6"/>
                                            </Grid.RowDefinitions>
                                            <Rectangle Name="CellHero_0" Grid.Row="0" Grid.Column="0" Width="4" Height="4" RadiusX="2" RadiusY="2" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellHero_1" Grid.Row="0" Grid.Column="1" Width="4" Height="4" RadiusX="2" RadiusY="2" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellHero_2" Grid.Row="0" Grid.Column="2" Width="4" Height="4" RadiusX="2" RadiusY="2" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellHero_7" Grid.Row="1" Grid.Column="0" Width="4" Height="4" RadiusX="2" RadiusY="2" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellHero_8" Grid.Row="1" Grid.Column="1" Width="4" Height="4" RadiusX="2" RadiusY="2" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellHero_3" Grid.Row="1" Grid.Column="2" Width="4" Height="4" RadiusX="2" RadiusY="2" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellHero_6" Grid.Row="2" Grid.Column="0" Width="4" Height="4" RadiusX="2" RadiusY="2" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellHero_5" Grid.Row="2" Grid.Column="1" Width="4" Height="4" RadiusX="2" RadiusY="2" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellHero_4" Grid.Row="2" Grid.Column="2" Width="4" Height="4" RadiusX="2" RadiusY="2" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Grid>
                                        <TextBlock Name="TxtHeroScanIcon" Text="" Margin="0" VerticalAlignment="Center"/>
                                        <TextBlock Name="TxtHeroScanLabel" Text="Scan Storage Now" VerticalAlignment="Center"/>
                                        <TextBlock Name="TxtHeroScanTimer" Text="0.0s" Margin="6,0,0,0" FontSize="11" Opacity="0.85" FontFamily="Consolas, monospace" VerticalAlignment="Center" Visibility="Collapsed"/>
                                    </StackPanel>
                                </Button>
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
                <Grid.RenderTransform>
                    <TranslateTransform Y="0"/>
                </Grid.RenderTransform>
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
                                <Button Name="BtnAppDeepScan" Style="{StaticResource PrimaryButton}" Padding="14,4">
                                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                        <!-- React Bits LatticeLoader Component -->
                                        <Grid Name="LatticeAppDeepScan" Width="17" Height="17" Margin="0,0,6,0" Visibility="Collapsed" VerticalAlignment="Center">
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="5"/>
                                                <ColumnDefinition Width="5"/>
                                                <ColumnDefinition Width="5"/>
                                            </Grid.ColumnDefinitions>
                                            <Grid.RowDefinitions>
                                                <RowDefinition Height="5"/>
                                                <RowDefinition Height="5"/>
                                                <RowDefinition Height="5"/>
                                            </Grid.RowDefinitions>
                                            <Rectangle Name="CellAppDeep_0" Grid.Row="0" Grid.Column="0" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellAppDeep_1" Grid.Row="0" Grid.Column="1" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellAppDeep_2" Grid.Row="0" Grid.Column="2" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellAppDeep_7" Grid.Row="1" Grid.Column="0" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellAppDeep_8" Grid.Row="1" Grid.Column="1" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellAppDeep_3" Grid.Row="1" Grid.Column="2" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellAppDeep_6" Grid.Row="2" Grid.Column="0" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellAppDeep_5" Grid.Row="2" Grid.Column="1" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            <Rectangle Name="CellAppDeep_4" Grid.Row="2" Grid.Column="2" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Grid>
                                        <TextBlock Name="TxtAppDeepScanIcon" Text="🔍" Margin="0,0,4,0" VerticalAlignment="Center"/>
                                        <TextBlock Name="TxtAppDeepScanLabel" Text="Deep Scan Leftovers" VerticalAlignment="Center"/>
                                        <TextBlock Name="TxtAppDeepScanTimer" Text="0.0s" Margin="5,0,0,0" FontSize="11" Opacity="0.85" FontFamily="Consolas, monospace" VerticalAlignment="Center" Visibility="Collapsed"/>
                                    </StackPanel>
                                </Button>
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
                                            <CheckBox IsChecked="{Binding Selected, Mode=TwoWay}" VerticalAlignment="Center" Margin="0,0,12,0"/>
                                            <StackPanel Grid.Column="1" VerticalAlignment="Center">
                                                <TextBlock Text="{Binding DisplayName}" FontWeight="Bold" FontSize="13" Foreground="#1B1B1B"/>
                                                <TextBlock Text="{Binding Publisher}" FontSize="11" Foreground="#707070"/>
                                            </StackPanel>
                                            <Border Grid.Column="2" Background="#F3F3F3" CornerRadius="4" Padding="6,2" VerticalAlignment="Center" Margin="12,0">
                                                <TextBlock Text="{Binding Type}" FontSize="11" Foreground="#5C5C5C"/>
                                            </Border>
                                            <TextBlock Grid.Column="3" Text="{Binding DisplayVersion}" FontSize="11" Foreground="#707070" VerticalAlignment="Center"/>
                                        </Grid>
                                    </Border>
                                </DataTemplate>
                            </ListBox.ItemTemplate>
                        </ListBox>
                    </Grid>
                </Border>
            </Grid>

            <!-- VIEW C: Forced Target Purge (Corrupted / Unlisted) -->
            <Grid Name="ViewForced" Visibility="Collapsed">
                <Grid.RenderTransform>
                    <TranslateTransform Y="0"/>
                </Grid.RenderTransform>
                <Border Style="{StaticResource CardBorder}" Margin="6">
                    <StackPanel Margin="12">
                        <TextBlock Text="🎯 Forced Target Residual Purge" FontSize="16" FontWeight="Bold" Foreground="#1B1B1B" Margin="0,0,0,4"/>
                        <TextBlock Text="Purge corrupted, partially uninstalled, or stubborn software directly from its installation folder or main executable." FontSize="12" Foreground="#666666" Margin="0,0,0,20"/>
                        
                        <TextBlock Text="Target Directory or Executable Path:" FontSize="13" FontWeight="SemiBold" Foreground="#1B1B1B" Margin="0,0,0,6"/>
                        <Grid Margin="0,0,0,16">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBox Name="TxtForcedTarget" Padding="8,6" FontSize="13" BorderBrush="#CCCCCC" VerticalAlignment="Center"/>
                            <Button Name="BtnBrowseForcedFolder" Grid.Column="1" Content="📁 Browse Folder" Style="{StaticResource SecondaryButton}" Margin="8,0,0,0"/>
                            <Button Name="BtnBrowseForcedExe" Grid.Column="2" Content="⚙️ Browse .exe" Style="{StaticResource SecondaryButton}" Margin="8,0,0,0"/>
                        </Grid>

                        <Button Name="BtnRunForcedScan" Style="{StaticResource PrimaryButton}" HorizontalAlignment="Left" Padding="20,8">
                            <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                <!-- React Bits LatticeLoader Component -->
                                <Grid Name="LatticeForcedScan" Width="17" Height="17" Margin="0,0,8,0" Visibility="Collapsed" VerticalAlignment="Center">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="5"/>
                                        <ColumnDefinition Width="5"/>
                                        <ColumnDefinition Width="5"/>
                                    </Grid.ColumnDefinitions>
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="5"/>
                                        <RowDefinition Height="5"/>
                                        <RowDefinition Height="5"/>
                                    </Grid.RowDefinitions>
                                    <Rectangle Name="CellForced_0" Grid.Row="0" Grid.Column="0" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    <Rectangle Name="CellForced_1" Grid.Row="0" Grid.Column="1" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    <Rectangle Name="CellForced_2" Grid.Row="0" Grid.Column="2" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    <Rectangle Name="CellForced_7" Grid.Row="1" Grid.Column="0" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    <Rectangle Name="CellForced_8" Grid.Row="1" Grid.Column="1" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    <Rectangle Name="CellForced_3" Grid.Row="1" Grid.Column="2" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    <Rectangle Name="CellForced_6" Grid.Row="2" Grid.Column="0" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    <Rectangle Name="CellForced_5" Grid.Row="2" Grid.Column="1" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    <Rectangle Name="CellForced_4" Grid.Row="2" Grid.Column="2" Width="3.6" Height="3.6" RadiusX="1.8" RadiusY="1.8" Fill="#FFFFFF" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Grid>
                                <TextBlock Name="TxtForcedScanIcon" Text="" Margin="0" VerticalAlignment="Center"/>
                                <TextBlock Name="TxtForcedScanLabel" Text="Start Forced Scan &amp; Remnant Analysis" VerticalAlignment="Center"/>
                                <TextBlock Name="TxtForcedScanTimer" Text="0.0s" Margin="6,0,0,0" FontSize="11" Opacity="0.85" FontFamily="Consolas, monospace" VerticalAlignment="Center" Visibility="Collapsed"/>
                            </StackPanel>
                        </Button>
                    </StackPanel>
                </Border>
            </Grid>

            <!-- VIEW D: Hunter Mode (Target Running Process) -->
            <Grid Name="ViewHunter" Visibility="Collapsed">
                <Grid.RenderTransform>
                    <TranslateTransform Y="0"/>
                </Grid.RenderTransform>
                <Border Style="{StaticResource CardBorder}" Margin="6">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <Grid Margin="4,0,0,8">
                            <TextBlock Text="Hunter Mode: Active User Processes" FontWeight="SemiBold" FontSize="13"/>
                            <Button Name="BtnRefreshHunter" HorizontalAlignment="Right" Style="{StaticResource SecondaryButton}" Padding="12,6">
                                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                                    <!-- React Bits LatticeLoader Component (Ink colored for secondary button) -->
                                    <Grid Name="LatticeHunter" Width="16" Height="16" Margin="0,0,6,0" Visibility="Collapsed" VerticalAlignment="Center">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="5"/>
                                            <ColumnDefinition Width="5"/>
                                            <ColumnDefinition Width="5"/>
                                        </Grid.ColumnDefinitions>
                                        <Grid.RowDefinitions>
                                            <RowDefinition Height="5"/>
                                            <RowDefinition Height="5"/>
                                            <RowDefinition Height="5"/>
                                        </Grid.RowDefinitions>
                                        <Rectangle Name="CellHunter_0" Grid.Row="0" Grid.Column="0" Width="3.5" Height="3.5" RadiusX="1.7" RadiusY="1.7" Fill="#0067C0" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        <Rectangle Name="CellHunter_1" Grid.Row="0" Grid.Column="1" Width="3.5" Height="3.5" RadiusX="1.7" RadiusY="1.7" Fill="#0067C0" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        <Rectangle Name="CellHunter_2" Grid.Row="0" Grid.Column="2" Width="3.5" Height="3.5" RadiusX="1.7" RadiusY="1.7" Fill="#0067C0" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        <Rectangle Name="CellHunter_7" Grid.Row="1" Grid.Column="0" Width="3.5" Height="3.5" RadiusX="1.7" RadiusY="1.7" Fill="#0067C0" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        <Rectangle Name="CellHunter_8" Grid.Row="1" Grid.Column="1" Width="3.5" Height="3.5" RadiusX="1.7" RadiusY="1.7" Fill="#0067C0" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        <Rectangle Name="CellHunter_3" Grid.Row="1" Grid.Column="2" Width="3.5" Height="3.5" RadiusX="1.7" RadiusY="1.7" Fill="#0067C0" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        <Rectangle Name="CellHunter_6" Grid.Row="2" Grid.Column="0" Width="3.5" Height="3.5" RadiusX="1.7" RadiusY="1.7" Fill="#0067C0" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        <Rectangle Name="CellHunter_5" Grid.Row="2" Grid.Column="1" Width="3.5" Height="3.5" RadiusX="1.7" RadiusY="1.7" Fill="#0067C0" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        <Rectangle Name="CellHunter_4" Grid.Row="2" Grid.Column="2" Width="3.5" Height="3.5" RadiusX="1.7" RadiusY="1.7" Fill="#0067C0" Opacity="0.2" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Grid>
                                    <TextBlock Name="TxtHunterIcon" Text="" Margin="0" VerticalAlignment="Center"/>
                                    <TextBlock Name="TxtHunterLabel" Text="Refresh Active Processes" VerticalAlignment="Center"/>
                                    <TextBlock Name="TxtHunterTimer" Text="0.0s" Margin="5,0,0,0" FontSize="11" Opacity="0.85" FontFamily="Consolas, monospace" VerticalAlignment="Center" Visibility="Collapsed"/>
                                </StackPanel>
                            </Button>
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
                                            </Grid.ColumnDefinitions>
                                            <StackPanel VerticalAlignment="Center">
                                                <TextBlock Text="{Binding ProcessName}" FontWeight="Bold" FontSize="13" Foreground="#1B1B1B"/>
                                                <TextBlock Text="{Binding Path}" FontSize="11" Foreground="#707070" ToolTip="{Binding Path}"/>
                                            </StackPanel>
                                            <TextBlock Grid.Column="1" Text="{Binding FormattedMemory}" FontSize="11" Foreground="#707070" VerticalAlignment="Center" Margin="12,0"/>
                                            <Button Grid.Column="2" Name="BtnTargetProcess" Tag="{Binding}" Content="Target &amp; Trace" Style="{StaticResource SecondaryButton}" Padding="10,4"/>
                                        </Grid>
                                    </Border>
                                </DataTemplate>
                            </ListBox.ItemTemplate>
                        </ListBox>
                    </Grid>
                </Border>
            </Grid>

            <!-- VIEW E: Leftover Remnant Cards Grid (Detailed Review) -->
            <Grid Name="ViewLeftoverCards" Visibility="Collapsed">
                <Grid.RenderTransform>
                    <TranslateTransform Y="0"/>
                </Grid.RenderTransform>
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <Grid Margin="6,4,6,8">
                        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                            <Button Name="BtnBackFromCards" Content="&lt; Back" Style="{StaticResource SecondaryButton}" Margin="0,0,12,0" Padding="10,4"/>
                            <TextBlock Name="TxtCardsTargetTitle" Text="Detected Remnants" FontSize="14" FontWeight="Bold" Foreground="#1B1B1B" VerticalAlignment="Center"/>
                        </StackPanel>
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                            <Button Name="BtnSelectAllCards" Content="Select All" Style="{StaticResource SecondaryButton}" Margin="0,0,6,0" Padding="10,4"/>
                            <Button Name="BtnClearAllCards" Content="Clear" Style="{StaticResource SecondaryButton}" Padding="10,4"/>
                        </StackPanel>
                    </Grid>

                    <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <!-- Card 1: Files & Folders -->
                            <Border Grid.Row="0" Grid.Column="0" Style="{StaticResource CardBorder}">
                                <StackPanel>
                                    <TextBlock Text="AppData &amp; Disk Residuals" FontSize="13" FontWeight="Bold" Foreground="#1B1B1B" Margin="0,0,0,8"/>
                                    <StackPanel Name="PnlFilesList"/>
                                </StackPanel>
                            </Border>

                            <!-- Card 2: Registry Keys -->
                            <Border Grid.Row="0" Grid.Column="1" Style="{StaticResource CardBorder}">
                                <StackPanel>
                                    <TextBlock Text="Registry Remnants (HKCU / HKLM)" FontSize="13" FontWeight="Bold" Foreground="#1B1B1B" Margin="0,0,0,8"/>
                                    <StackPanel Name="PnlRegistryList"/>
                                </StackPanel>
                            </Border>

                            <!-- Card 3: Services & Scheduled Tasks -->
                            <Border Grid.Row="1" Grid.Column="0" Style="{StaticResource CardBorder}">
                                <StackPanel>
                                    <TextBlock Text="Background Services &amp; Tasks" FontSize="13" FontWeight="Bold" Foreground="#1B1B1B" Margin="0,0,0,8"/>
                                    <StackPanel Name="PnlServicesList"/>
                                </StackPanel>
                            </Border>

                            <!-- Card 4: Shortcuts -->
                            <Border Grid.Row="1" Grid.Column="1" Style="{StaticResource CardBorder}">
                                <StackPanel>
                                    <TextBlock Text="Shortcuts &amp; Startup Entries" FontSize="13" FontWeight="Bold" Foreground="#1B1B1B" Margin="0,0,0,8"/>
                                    <StackPanel Name="PnlShortcutsList"/>
                                </StackPanel>
                            </Border>
                        </Grid>
                    </ScrollViewer>
                </Grid>
            </Grid>

            <!-- VIEW F: Backups & Rollback History -->
            <Grid Name="ViewBackups" Visibility="Collapsed">
                <Grid.RenderTransform>
                    <TranslateTransform Y="0"/>
                </Grid.RenderTransform>
                <Border Style="{StaticResource CardBorder}" Margin="6">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <Grid Margin="4,0,0,8">
                            <TextBlock Text="Safety Snapshots (All deletions create restorable manifests)" FontWeight="SemiBold" FontSize="13"/>
                            <Button Name="BtnRestoreSelectedBackup" Content="Restore Selected Snapshot" HorizontalAlignment="Right" Style="{StaticResource PrimaryButton}" Padding="14,4"/>
                        </Grid>
                        <ListBox Name="LstBackups" Grid.Row="1" BorderThickness="0" Background="Transparent" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                            <ListBox.ItemTemplate>
                                <DataTemplate>
                                    <Border BorderBrush="#F0F0F0" BorderThickness="0,0,0,1" Padding="8,8" Background="Transparent">
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <StackPanel VerticalAlignment="Center">
                                                <TextBlock Text="{Binding BackupId}" FontWeight="Bold" FontSize="13" Foreground="#1B1B1B"/>
                                                <TextBlock Text="{Binding Application}" FontSize="11" Foreground="#707070"/>
                                            </StackPanel>
                                            <TextBlock Grid.Column="1" Text="{Binding Timestamp}" FontSize="11" Foreground="#707070" VerticalAlignment="Center" Margin="12,0"/>
                                            <Border Grid.Column="2" Background="#EBF3FC" CornerRadius="4" Padding="6,2" VerticalAlignment="Center">
                                                <TextBlock Text="{Binding FormattedSize}" FontSize="11" Foreground="#0067C0" FontWeight="SemiBold"/>
                                            </Border>
                                        </Grid>
                                    </Border>
                                </DataTemplate>
                            </ListBox.ItemTemplate>
                        </ListBox>
                    </Grid>
                </Border>
            </Grid>

            <!-- VIEW G: Operation Complete / Success Screen -->
            <Grid Name="ViewStep3" Visibility="Collapsed">
                <Grid.RenderTransform>
                    <TranslateTransform Y="0"/>
                </Grid.RenderTransform>
                <Border Style="{StaticResource CardBorder}" Margin="6" VerticalAlignment="Center" HorizontalAlignment="Center" Padding="40" MaxWidth="600">
                    <StackPanel HorizontalAlignment="Center">
                        <TextBlock Text="[SUCCESS]" FontSize="16" FontWeight="Bold" Foreground="#107C41" HorizontalAlignment="Center" Margin="0,0,0,12"/>
                        <TextBlock Text="Cleanup Successfully Executed!" FontSize="20" FontWeight="Bold" Foreground="#107C41" HorizontalAlignment="Center" Margin="0,0,0,8"/>
                        <TextBlock Name="TxtResultStats" Text="Freed 0 MB across 0 items" FontSize="14" Foreground="#1B1B1B" HorizontalAlignment="Center" Margin="0,0,0,6"/>
                        <TextBlock Name="TxtBackupId" Text="Backup: N/A" FontSize="11" Foreground="#707070" HorizontalAlignment="Center" Margin="0,0,0,24"/>
                        <Button Name="BtnReturnHome" Content="Return to Storage Cleaner" Style="{StaticResource PrimaryButton}" HorizontalAlignment="Center" Padding="20,8"/>
                    </StackPanel>
                </Border>
            </Grid>
        </Grid>

        <!-- Bottom Navigation & Action Bar -->
        <Border Grid.Row="5" Background="#FFFFFF" BorderBrush="#EAEAEA" BorderThickness="0,1,0,0" Padding="24,10">
            <Grid>
                <TextBlock Name="TxtBottomSummary" Text="Ready to scan. Select an action above." VerticalAlignment="Center" FontSize="12" Foreground="#555555"/>
                <Button Name="BtnNext" Content="Clean Selected Items" Style="{StaticResource PrimaryButton}" HorizontalAlignment="Right" VerticalAlignment="Center"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    # Set Window Icon if present
    if (Test-Path -LiteralPath $logoPath) {
        try {
            $window.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create([System.Uri]::new($logoPath))
            $titleLogo = $window.FindName("TitleLogo")
            if ($titleLogo) {
                $titleLogo.Source = [System.Windows.Media.Imaging.BitmapFrame]::Create([System.Uri]::new($logoPath))
            }
        } catch { }
    }

    # Bind UI Elements
    $tabOrphans = $window.FindName("TabOrphans")
    $tabInstalled = $window.FindName("TabInstalled")
    $tabForced = $window.FindName("TabForced")
    $tabHunter = $window.FindName("TabHunter")
    $tabBackups = $window.FindName("TabBackups")

    $btnScanAction = $window.FindName("BtnScanAction")
    $latticeScanAction = $window.FindName("LatticeScanAction")
    $cellsScanAction = @(0..8 | ForEach-Object { $window.FindName("CellScan_$_") })
    $txtScanActionIcon = $window.FindName("TxtScanActionIcon")
    $txtScanActionLabel = $window.FindName("TxtScanActionLabel")
    $txtScanActionTimer = $window.FindName("TxtScanActionTimer")

    $btnSelectHigh = $window.FindName("BtnSelectHigh")
    $btnSelectAll = $window.FindName("BtnSelectAll")
    $btnSelectHeavy = $window.FindName("BtnSelectHeavy")
    $btnClearSelection = $window.FindName("BtnClearSelection")
    $txtSearch = $window.FindName("TxtSearch")
    $txtLiveStatusIndicator = $window.FindName("TxtLiveStatusIndicator")

    $viewOrphans = $window.FindName("ViewOrphans")
    $viewInstalled = $window.FindName("ViewInstalled")
    $viewForced = $window.FindName("ViewForced")
    $viewHunter = $window.FindName("ViewHunter")
    $viewLeftoverCards = $window.FindName("ViewLeftoverCards")
    $viewBackups = $window.FindName("ViewBackups")
    $viewStep3 = $window.FindName("ViewStep3")

    $pnlScanPrompt = $window.FindName("PnlScanPrompt")
    $btnStartScanHero = $window.FindName("BtnStartScanHero")
    $latticeStartScanHero = $window.FindName("LatticeStartScanHero")
    $cellsHero = @(0..8 | ForEach-Object { $window.FindName("CellHero_$_") })
    $txtHeroScanIcon = $window.FindName("TxtHeroScanIcon")
    $txtHeroScanLabel = $window.FindName("TxtHeroScanLabel")
    $txtHeroScanTimer = $window.FindName("TxtHeroScanTimer")

    $lstOrphans = $window.FindName("LstOrphans")
    $txtOrphanCount = $window.FindName("TxtOrphanCount")

    $lstApps = $window.FindName("LstApps")
    $btnAppNormalUninstall = $window.FindName("BtnAppNormalUninstall")
    $btnAppQuietUninstall = $window.FindName("BtnAppQuietUninstall")
    $btnAppDeepScan = $window.FindName("BtnAppDeepScan")
    $latticeAppDeepScan = $window.FindName("LatticeAppDeepScan")
    $cellsAppDeep = @(0..8 | ForEach-Object { $window.FindName("CellAppDeep_$_") })
    $txtAppDeepScanIcon = $window.FindName("TxtAppDeepScanIcon")
    $txtAppDeepScanLabel = $window.FindName("TxtAppDeepScanLabel")
    $txtAppDeepScanTimer = $window.FindName("TxtAppDeepScanTimer")

    $txtForcedTarget = $window.FindName("TxtForcedTarget")
    $btnBrowseForcedFolder = $window.FindName("BtnBrowseForcedFolder")
    $btnBrowseForcedExe = $window.FindName("BtnBrowseForcedExe")
    $btnRunForcedScan = $window.FindName("BtnRunForcedScan")
    $latticeForcedScan = $window.FindName("LatticeForcedScan")
    $cellsForced = @(0..8 | ForEach-Object { $window.FindName("CellForced_$_") })
    $txtForcedScanIcon = $window.FindName("TxtForcedScanIcon")
    $txtForcedScanLabel = $window.FindName("TxtForcedScanLabel")
    $txtForcedScanTimer = $window.FindName("TxtForcedScanTimer")

    $lstHunter = $window.FindName("LstHunter")
    $btnRefreshHunter = $window.FindName("BtnRefreshHunter")
    $latticeHunter = $window.FindName("LatticeHunter")
    $cellsHunter = @(0..8 | ForEach-Object { $window.FindName("CellHunter_$_") })
    $txtHunterIcon = $window.FindName("TxtHunterIcon")
    $txtHunterLabel = $window.FindName("TxtHunterLabel")
    $txtHunterTimer = $window.FindName("TxtHunterTimer")

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

    # Reactive State Store
    $script:activeTab = "Orphans"
    $script:originTab = "Orphans"
    $script:allOrphans = [System.Collections.ObjectModel.ObservableCollection[PSCustomObject]]::new()
    $script:allInstalledApps = @()
    $script:currentLeftoverItems = @()
    $script:activeTargetApp = $null
    $script:latestBackupId = ""
    $script:isOperationRunning = $false

    # Thread-safe async coordination store (shared reference across event closures)
    $guiAsyncState = [hashtable]::Synchronized(@{
        ActiveJobs   = [System.Collections.Generic.List[psobject]]::new()
        RunningTasks = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    })
    $script:activeAsyncJobs = $guiAsyncState.ActiveJobs

    # Helper: Set Tab Active UI
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

    # Helper: Fluid View Switch with 60 FPS Fade & Slide Transition
    $switchView = {
        param($targetView)
        $views = @($viewOrphans, $viewInstalled, $viewForced, $viewHunter, $viewLeftoverCards, $viewBackups, $viewStep3)
        foreach ($v in $views) {
            if ($v -eq $targetView) {
                $v.Visibility = [System.Windows.Visibility]::Visible
                
                # Fluent entrance animation: Fade-in + Slide-up (14px -> 0px)
                $tt = $v.RenderTransform
                if ($tt -is [System.Windows.Media.TranslateTransform]) {
                    $daSlide = [System.Windows.Media.Animation.DoubleAnimation]::new(14, 0, [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(220)))
                    $daSlide.DecelerationRatio = 0.85
                    $tt.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $daSlide)
                }
                $daFade = [System.Windows.Media.Animation.DoubleAnimation]::new(0.0, 1.0, [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(220)))
                $v.BeginAnimation([System.Windows.Controls.Grid]::OpacityProperty, $daFade)
            } else {
                $v.Visibility = [System.Windows.Visibility]::Collapsed
            }
        }
    }

    # Helper: React Bits LatticeLoader Micro-Interaction Controller (Orbit Wave + Live Stopwatch Timer)
    $activeLatticeTimers = [System.Collections.Generic.Dictionary[object, object]]::new()

    $startLattice = {
        param($latticeGrid, $cells, $icon, $label, $timerText, $scanningText)
        if ($latticeGrid) { $latticeGrid.Visibility = [System.Windows.Visibility]::Visible }
        if ($icon) { $icon.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($timerText) {
            $timerText.Text = "0.0s"
            $timerText.Visibility = [System.Windows.Visibility]::Visible
        }
        if ($label -and $scanningText) { $label.Text = $scanningText }

        # Animate orbit wave on perimeter cells (0, 1, 2, 3, 4, 5, 6, 7)
        if ($cells -and $cells.Count -ge 8) {
            for ($i = 0; $i -lt 8; $i++) {
                $cell = $cells[$i]
                if ($cell) {
                    $da = [System.Windows.Media.Animation.DoubleAnimation]::new()
                    $da.From = 0.2
                    $da.To = 1.0
                    $da.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(180))
                    $da.AutoReverse = $true
                    $da.BeginTime = [TimeSpan]::FromMilliseconds($i * 105)
                    $da.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                    $cell.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $da)
                }
            }
            # Center cell (index 8) soft pulse
            if ($cells.Count -gt 8 -and $cells[8]) {
                $daCenter = [System.Windows.Media.Animation.DoubleAnimation]::new()
                $daCenter.From = 0.2
                $daCenter.To = 0.55
                $daCenter.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(420))
                $daCenter.AutoReverse = $true
                $daCenter.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
                $cells[8].BeginAnimation([System.Windows.UIElement]::OpacityProperty, $daCenter)
            }
        }

        # Live Stopwatch Timer
        if ($timerText) {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $dt = [System.Windows.Threading.DispatcherTimer]::new()
            $dt.Interval = [TimeSpan]::FromMilliseconds(100)
            $dt.Add_Tick({
                if ($timerText -and $sw.IsRunning) {
                    $s = $sw.Elapsed.TotalSeconds
                    $timerText.Text = "$("{0:N1}" -f $s)s"
                }
            }.GetNewClosure())
            $dt.Start()
            $activeLatticeTimers[$latticeGrid] = @{ Stopwatch = $sw; Timer = $dt }
        }
    }

    $stopLattice = {
        param($latticeGrid, $cells, $icon, $label, $timerText, $defaultText)
        if ($latticeGrid -and $activeLatticeTimers.ContainsKey($latticeGrid)) {
            $rec = $activeLatticeTimers[$latticeGrid]
            $rec.Timer.Stop()
            $rec.Stopwatch.Stop()
            $activeLatticeTimers.Remove($latticeGrid) | Out-Null
        }

        # Clear cell animations and reset opacity
        if ($cells) {
            foreach ($c in $cells) {
                if ($c) {
                    $c.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
                    $c.Opacity = 0.2
                }
            }
        }

        if ($latticeGrid) { $latticeGrid.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($timerText) { $timerText.Visibility = [System.Windows.Visibility]::Collapsed }
        if ($icon) { $icon.Visibility = [System.Windows.Visibility]::Visible }
        if ($label -and $defaultText) { $label.Text = $defaultText }
    }

    # Helper: Universal Asynchronous Worker (Task-Isolated, Shared-Reference Safe)
    $invokeAsyncWorker = {
        param(
            [string]$TaskName = "Worker",
            [scriptblock]$WorkerScript,
            [array]$ScriptArgs = @(),
            [scriptblock]$OnProgress = $null,
            [scriptblock]$OnComplete = $null,
            [scriptblock]$OnError = $null
        )

        if ($guiAsyncState.RunningTasks.Contains($TaskName)) {
            Log-GuiConsole -Tag "INFO" -Message "Task '$TaskName' is already in progress." -Color DarkGray
            return
        }
        $guiAsyncState.RunningTasks.Add($TaskName) | Out-Null
        $script:isOperationRunning = $true

        if ($txtLiveStatusIndicator) {
            $txtLiveStatusIndicator.Text = "Scanning..."
            $txtLiveStatusIndicator.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0067C0")
        }

        $queue = [System.Collections.Concurrent.ConcurrentQueue[psobject]]::new()
        $ps = [powershell]::Create()
        $ps.AddScript($WorkerScript) | Out-Null
        foreach ($arg in $ScriptArgs) {
            $ps.AddArgument($arg) | Out-Null
        }
        $ps.AddArgument($queue) | Out-Null

        $asyncHandle = $ps.BeginInvoke()

        $pollTimer = [System.Windows.Threading.DispatcherTimer]::new()
        $pollTimer.Interval = [TimeSpan]::FromMilliseconds(50)

        # Track active job in shared collection
        $jobRecord = [PSCustomObject]@{
            TaskName = $TaskName
            Timer    = $pollTimer
            Runspace = $ps
            Handle   = $asyncHandle
            Queue    = $queue
        }
        $guiAsyncState.ActiveJobs.Add($jobRecord)

        # Reference captures for closure
        $sharedJobs = $guiAsyncState.ActiveJobs
        $sharedTasks = $guiAsyncState.RunningTasks
        $taskKey = $TaskName
        $isFinished = $false

        $tickAction = {
            if ($isFinished) { return }

            try {
                # Drain queue and stream events
                if ($queue) {
                    $item = $null
                    while ($queue.TryDequeue([ref]$item)) {
                        if ($OnProgress -and $item) {
                            try { & $OnProgress $item } catch { }
                        }
                    }
                }

                if ($asyncHandle -and $asyncHandle.IsCompleted) {
                    $isFinished = $true
                    $pollTimer.Stop()

                    try {
                        $res = $ps.EndInvoke($asyncHandle)
                        if ($ps.Streams.Error.Count -gt 0) {
                            foreach ($err in $ps.Streams.Error) {
                                Log-GuiConsole -Tag "WARN" -Message "Worker stream: $err" -Color Yellow
                            }
                        }
                        if ($OnComplete) {
                            & $OnComplete $res
                        }
                    } catch {
                        Log-GuiConsole -Tag "ERROR" -Message "Async background error: $_" -Color Red
                        if ($OnError) {
                            & $OnError $_
                        }
                    } finally {
                        try { $ps.Dispose() } catch { }
                        try { $sharedJobs.Remove($jobRecord) | Out-Null } catch { }
                        try { $sharedTasks.Remove($taskKey) | Out-Null } catch { }

                        if ($sharedTasks.Count -eq 0) {
                            $script:isOperationRunning = $false
                            if ($txtLiveStatusIndicator) {
                                $txtLiveStatusIndicator.Text = "Ready"
                                $txtLiveStatusIndicator.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#107C41")
                            }
                        }
                    }
                }
            } catch {
                $isFinished = $true
                $pollTimer.Stop()
                Log-GuiConsole -Tag "ERROR" -Message "Timer tick exception: $_" -Color Red
                try { $ps.Dispose() } catch { }
                try { $sharedJobs.Remove($jobRecord) | Out-Null } catch { }
                try { $sharedTasks.Remove($taskKey) | Out-Null } catch { }

                if ($sharedTasks.Count -eq 0) {
                    $script:isOperationRunning = $false
                    if ($txtLiveStatusIndicator) {
                        $txtLiveStatusIndicator.Text = "Ready"
                        $txtLiveStatusIndicator.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#107C41")
                    }
                }
                if ($OnError) {
                    & $OnError $_
                }
            }
        }.GetNewClosure()

        $pollTimer.Add_Tick($tickAction)
        $pollTimer.Start()
    }

    # Summary Updater for Orphans
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
        Log-GuiConsole -Tag "SELECT" -Message "Orphan selection updated: $selCount folder(s) selected ($szStr)" -Color DarkYellow
    }

    # Load Orphans Function (Async, Non-blocking)
    $loadOrphansData = {
        if ($guiAsyncState.RunningTasks.Contains("ScanOrphans")) { return }

        Log-GuiConsole -Tag "SCAN" -Message "Storage ghost folder scan initiated across all fixed drives..." -Color Magenta
        & $startLattice $latticeScanAction $cellsScanAction $txtScanActionIcon $txtScanActionLabel $txtScanActionTimer "Scanning..."
        & $startLattice $latticeStartScanHero $cellsHero $txtHeroScanIcon $txtHeroScanLabel $txtHeroScanTimer "Scanning Storage..."
        $btnScanAction.IsEnabled = $false
        $btnStartScanHero.IsEnabled = $false
        $txtOrphanCount.Text = "Analyzing drives in background..."

        $workerBlock = {
            param($mPath, $cPath, $q)
            Get-ChildItem -Path $mPath -Filter *.ps1 | Where-Object { $_.Name -ne "GUI.ps1" } | ForEach-Object { . $_.FullName }
            
            $cb = {
                param($cur, $tot, $task)
                if ($q) {
                    $q.Enqueue([PSCustomObject]@{
                        Type    = "Progress"
                        Current = $cur
                        Total   = $tot
                        Task    = $task
                    })
                }
            }

            $raw = @(Scan-OrphanedStorageFolders -ConfigDir $cPath -ProgressCallback $cb)
            return $raw
        }

        $onProgress = {
            param($info)
            if ($info.Type -eq "Progress") {
                $txtOrphanCount.Text = "[$($info.Current)/$($info.Total)] $($info.Task)"
                Log-GuiConsole -Tag "SCAN" -Message "[$($info.Current)/$($info.Total)] $($info.Task)" -Color DarkCyan
            }
        }

        $onComplete = {
            param($rawOrphans)
            $script:allOrphans.Clear()
            $totalOrphanBytes = 0L

            foreach ($o in @($rawOrphans)) {
                if (-not $o) { continue }
                $totalOrphanBytes += [long]$o.Size
                $script:allOrphans.Add([PSCustomObject]@{
                    Category        = $o.Category
                    SubCategory     = $o.SubCategory
                    Type            = $o.Type
                    Path            = $o.Path
                    Name            = $o.Name
                    Size            = [long]$o.Size
                    ItemCount       = $o.ItemCount
                    FormattedSize   = Format-Bytes $o.Size
                    Score           = $o.Score
                    Selected        = $false
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
            $btnStartScanHero.IsEnabled = $true

            & $stopLattice $latticeScanAction $cellsScanAction $txtScanActionIcon $txtScanActionLabel $txtScanActionTimer "Rescan Storage"
            & $stopLattice $latticeStartScanHero $cellsHero $txtHeroScanIcon $txtHeroScanLabel $txtHeroScanTimer "Scan Storage Now"

            $totalFormatted = Format-Bytes $totalOrphanBytes
            $txtOrphanCount.Text = "$($script:allOrphans.Count) folders found ($totalFormatted total)"
            Log-GuiConsole -Tag "SCAN" -Message "Storage scan complete! Found $($script:allOrphans.Count) orphan folder(s) totaling $totalFormatted." -Color Green
            & $updateOrphanSummary
        }

        $onError = {
            param($err)
            & $stopLattice $latticeScanAction $cellsScanAction $txtScanActionIcon $txtScanActionLabel $txtScanActionTimer "Rescan Storage"
            & $stopLattice $latticeStartScanHero $cellsHero $txtHeroScanIcon $txtHeroScanLabel $txtHeroScanTimer "Scan Storage Now"
            $btnScanAction.IsEnabled = $true
            $btnStartScanHero.IsEnabled = $true
            $txtOrphanCount.Text = "Scan stopped: $err"
            Log-GuiConsole -Tag "ERROR" -Message "Storage scan failed: $err" -Color Red
        }

        & $invokeAsyncWorker "ScanOrphans" $workerBlock @($modulesDir, $ConfigDir) $onProgress $onComplete $onError
    }

    # Load Installed Applications (Async)
    $loadInstalledApps = {
        if ($script:allInstalledApps.Count -gt 0 -or $guiAsyncState.RunningTasks.Contains("LoadInstalledApps")) { return }

        Log-GuiConsole -Tag "APP" -Message "Loading installed applications and AppX/MSIX packages..." -Color Blue
        $txtBottomSummary.Text = "Discovering installed software..."

        $workerBlock = {
            param($mPath, $q)
            Get-ChildItem -Path $mPath -Filter *.ps1 | Where-Object { $_.Name -ne "GUI.ps1" } | ForEach-Object { . $_.FullName }
            return @(Get-InstalledApplications -IncludeAppX)
        }

        $onComplete = {
            param($apps)
            $script:allInstalledApps = @($apps | ForEach-Object {
                if ($_ -and $_.PSObject.Properties['Selected'] -eq $null) {
                    $_ | Add-Member -MemberType NoteProperty -Name "Selected" -Value $false -PassThru
                } else {
                    $_
                }
            })
            $lstApps.ItemsSource = $script:allInstalledApps
            $txtBottomSummary.Text = "$($script:allInstalledApps.Count) applications loaded. Select an app to uninstall or deep scan."
            Log-GuiConsole -Tag "APP" -Message "Successfully loaded $($script:allInstalledApps.Count) installed applications." -Color Green
        }

        $onError = {
            param($err)
            $txtBottomSummary.Text = "Failed to load applications: $err"
            Log-GuiConsole -Tag "ERROR" -Message "Failed to load installed applications: $err" -Color Red
        }

        & $invokeAsyncWorker "LoadInstalledApps" $workerBlock @($modulesDir) $null $onComplete $onError
    }

    # Load Hunter Processes (Async)
    $loadHunterProcesses = {
        if ($guiAsyncState.RunningTasks.Contains("LoadHunterProcesses")) { return }

        Log-GuiConsole -Tag "HUNTER" -Message "Enumerating running user processes..." -Color Magenta
        & $startLattice $latticeHunter $cellsHunter $txtHunterIcon $txtHunterLabel $txtHunterTimer "Refreshing..."
        $btnRefreshHunter.IsEnabled = $false

        $workerBlock = {
            param($mPath, $cPath, $q)
            Get-ChildItem -Path $mPath -Filter *.ps1 | Where-Object { $_.Name -ne "GUI.ps1" } | ForEach-Object { . $_.FullName }
            return @(Get-RunningHunterTargets -ConfigDir $cPath)
        }

        $onComplete = {
            param($targets)
            $lstHunter.ItemsSource = @($targets)
            & $stopLattice $latticeHunter $cellsHunter $txtHunterIcon $txtHunterLabel $txtHunterTimer "Refresh Active Processes"
            $btnRefreshHunter.IsEnabled = $true
            Log-GuiConsole -Tag "HUNTER" -Message "Discovered $(@($targets).Count) active user target processes." -Color Green
        }

        $onError = {
            param($err)
            & $stopLattice $latticeHunter $cellsHunter $txtHunterIcon $txtHunterLabel $txtHunterTimer "Refresh Active Processes"
            $btnRefreshHunter.IsEnabled = $true
            Log-GuiConsole -Tag "ERROR" -Message "Failed to enumerate hunter processes: $err" -Color Red
        }

        & $invokeAsyncWorker "LoadHunterProcesses" $workerBlock @($modulesDir, $ConfigDir) $null $onComplete $onError
    }

    # Load Backups (Async)
    $loadBackupsData = {
        if ($guiAsyncState.RunningTasks.Contains("LoadBackups")) { return }

        Log-GuiConsole -Tag "BACKUP" -Message "Retrieving backup restore manifests..." -Color Cyan
        $workerBlock = {
            param($mPath, $q)
            Get-ChildItem -Path $mPath -Filter *.ps1 | Where-Object { $_.Name -ne "GUI.ps1" } | ForEach-Object { . $_.FullName }
            return @(Get-CleanupBackups)
        }

        $onComplete = {
            param($backups)
            $lstBackups.ItemsSource = @($backups)
            Log-GuiConsole -Tag "BACKUP" -Message "Loaded $(@($backups).Count) backup snapshots." -Color Green
        }

        $onError = {
            param($err)
            Log-GuiConsole -Tag "ERROR" -Message "Failed to load backups: $err" -Color Red
        }

        & $invokeAsyncWorker "LoadBackups" $workerBlock @($modulesDir) $null $onComplete $onError
    }

    # Display Leftover Cards for any Scored Result Set
    $displayLeftoverCards = {
        param($app, $leftovers)
        $script:originTab = $script:activeTab
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
        $btnNext.Content = "Clean Selected Items"
        $btnNext.Visibility = [System.Windows.Visibility]::Visible
        $txtBottomSummary.Text = "Review detected remnants. Uncheck any items you wish to preserve."
        Log-GuiConsole -Tag "CARDS" -Message "Displaying $(@($leftovers).Count) leftover items for '$($app.DisplayName)' across 4 card categories." -Color Cyan
    }

    # Tab 1: Orphans
    $tabOrphans.Add_Click({
        $script:activeTab = "Orphans"
        $script:originTab = "Orphans"
        Log-GuiConsole -Tag "NAV" -Message "Switched to tab: Ghost Folders" -Color Blue
        & $setTabActive $tabOrphans
        & $switchView $viewOrphans
        $btnScanAction.Visibility = [System.Windows.Visibility]::Visible
        $btnSelectHigh.Visibility = [System.Windows.Visibility]::Visible
        $btnSelectAll.Visibility = [System.Windows.Visibility]::Visible
        $btnSelectHeavy.Visibility = [System.Windows.Visibility]::Visible
        $btnClearSelection.Visibility = [System.Windows.Visibility]::Visible
        $btnNext.Content = "Delete Selected Ghost Folders"
        $btnNext.Visibility = [System.Windows.Visibility]::Visible
        & $updateOrphanSummary
    })

    # Tab 2: Installed Apps
    $tabInstalled.Add_Click({
        $script:activeTab = "Installed"
        $script:originTab = "Installed"
        Log-GuiConsole -Tag "NAV" -Message "Switched to tab: Installed Applications" -Color Blue
        & $setTabActive $tabInstalled
        & $switchView $viewInstalled
        $btnScanAction.Visibility = [System.Windows.Visibility]::Collapsed
        $btnSelectHigh.Visibility = [System.Windows.Visibility]::Collapsed
        $btnSelectAll.Visibility = [System.Windows.Visibility]::Visible
        $btnSelectHeavy.Visibility = [System.Windows.Visibility]::Collapsed
        $btnClearSelection.Visibility = [System.Windows.Visibility]::Visible
        $btnNext.Content = "Scan Leftovers For App"
        $btnNext.Visibility = [System.Windows.Visibility]::Visible
        & $loadInstalledApps
    })

    # Tab 3: Forced Uninstall
    $tabForced.Add_Click({
        $script:activeTab = "Forced"
        $script:originTab = "Forced"
        Log-GuiConsole -Tag "NAV" -Message "Switched to tab: Forced Target Purge" -Color Blue
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
        $script:originTab = "Hunter"
        Log-GuiConsole -Tag "NAV" -Message "Switched to tab: Hunter Mode" -Color Blue
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
        $script:originTab = "Backups"
        Log-GuiConsole -Tag "NAV" -Message "Switched to tab: Backups & Rollback" -Color Blue
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
                Log-GuiConsole -Tag "FILTER" -Message "Filtered orphans matching '$filter': $($filtered.Count) matches" -Color DarkGray
            }
        } elseif ($script:activeTab -eq "Installed") {
            if ([string]::IsNullOrWhiteSpace($filter)) {
                $lstApps.ItemsSource = $script:allInstalledApps
            } else {
                $filtered = @($script:allInstalledApps | Where-Object { $_.DisplayName -like "*$filter*" -or $_.Publisher -like "*$filter*" })
                $lstApps.ItemsSource = $filtered
                Log-GuiConsole -Tag "FILTER" -Message "Filtered applications matching '$filter': $($filtered.Count) matches" -Color DarkGray
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
            Log-GuiConsole -Tag "SELECT" -Message "Selected all installed applications" -Color DarkYellow
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
            Log-GuiConsole -Tag "SELECT" -Message "Cleared all selections" -Color DarkYellow
        }
    })

    # Live checkbox sync handlers
    $lstOrphans.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::CheckedEvent, [System.Windows.RoutedEventHandler]{
        & $updateOrphanSummary
    })
    $lstOrphans.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::UncheckedEvent, [System.Windows.RoutedEventHandler]{
        & $updateOrphanSummary
    })
    $lstApps.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::CheckedEvent, [System.Windows.RoutedEventHandler]{
        $selCount = @($script:allInstalledApps | Where-Object { $_.Selected }).Count
        if ($selCount -gt 0) {
            $txtBottomSummary.Text = "$selCount application(s) selected for batch operations."
        }
    })
    $lstApps.AddHandler([System.Windows.Controls.Primitives.ToggleButton]::UncheckedEvent, [System.Windows.RoutedEventHandler]{
        $selCount = @($script:allInstalledApps | Where-Object { $_.Selected }).Count
        if ($selCount -gt 0) {
            $txtBottomSummary.Text = "$selCount application(s) selected for batch operations."
        } else {
            $txtBottomSummary.Text = "$($script:allInstalledApps.Count) applications loaded. Select an app to uninstall or deep scan."
        }
    })

    # Trigger Orphan Scan
    $btnScanAction.Add_Click({ & $loadOrphansData })
    if ($btnStartScanHero) { $btnStartScanHero.Add_Click({ & $loadOrphansData }) }

    # Helper: Resolve target installed application(s)
    $getSelectedInstalledApps = {
        $checked = @($script:allInstalledApps | Where-Object { $_.Selected })
        if ($checked.Count -gt 0) {
            return $checked
        }
        if ($lstApps.SelectedItem) {
            return @($lstApps.SelectedItem)
        }
        return @()
    }

    # App Actions: Standard Uninstall
    $btnAppNormalUninstall.Add_Click({
        $selectedApps = & $getSelectedInstalledApps
        if ($selectedApps.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Please select or check an application to uninstall.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            return
        }
        $appNames = ($selectedApps | ForEach-Object { $_.DisplayName }) -join ", "
        if ($appNames.Length -gt 100) { $appNames = $appNames.Substring(0, 97) + "..." }
        $res = [System.Windows.MessageBox]::Show("Launch official uninstaller for $($selectedApps.Count) application(s)?`n`n$appNames", "Standard Uninstall", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
            foreach ($app in $selectedApps) {
                Log-GuiConsole -Tag "UNINSTALL" -Message "Invoking standard uninstaller for '$($app.DisplayName)'..." -Color Yellow
                $window.Cursor = [System.Windows.Input.Cursors]::Wait
                Invoke-NativeUninstall -Application $app -Quiet:$false
                $window.Cursor = [System.Windows.Input.Cursors]::Arrow
                Log-GuiConsole -Tag "UNINSTALL" -Message "Uninstaller completed for '$($app.DisplayName)'." -Color Green
            }
            $script:allInstalledApps = @()
            & $loadInstalledApps
        }
    })

    # App Actions: Quiet Uninstall
    $btnAppQuietUninstall.Add_Click({
        $selectedApps = & $getSelectedInstalledApps
        if ($selectedApps.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Please select or check an application to quietly uninstall.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            return
        }
        $appNames = ($selectedApps | ForEach-Object { $_.DisplayName }) -join ", "
        if ($appNames.Length -gt 100) { $appNames = $appNames.Substring(0, 97) + "..." }
        $res = [System.Windows.MessageBox]::Show("Run silent / unattended uninstaller for $($selectedApps.Count) application(s)?`n`n$appNames`n`nHailUninstaller will automatically inject quiet parameters.", "Quiet Uninstall", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($res -eq [System.Windows.MessageBoxResult]::Yes) {
            foreach ($app in $selectedApps) {
                Log-GuiConsole -Tag "QUIET" -Message "Executing quiet unattended uninstallation for '$($app.DisplayName)'..." -Color Magenta
                $window.Cursor = [System.Windows.Input.Cursors]::Wait
                Invoke-NativeUninstall -Application $app -Quiet:$true
                $window.Cursor = [System.Windows.Input.Cursors]::Arrow
                Log-GuiConsole -Tag "QUIET" -Message "Quiet uninstallation finished for '$($app.DisplayName)'." -Color Green
            }
            $script:allInstalledApps = @()
            & $loadInstalledApps
        }
    })

    # App Actions: Deep Scan (Async)
    $btnAppDeepScan.Add_Click({
        $selectedApps = & $getSelectedInstalledApps
        if ($selectedApps.Count -eq 0 -or $guiAsyncState.RunningTasks.Contains("AppDeepScan")) {
            if ($selectedApps.Count -eq 0) {
                [System.Windows.MessageBox]::Show("Please select an application to deep-scan.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            }
            return
        }
        $app = $selectedApps[0]
        Log-GuiConsole -Tag "SCAN" -Message "Initiating deep leftover scan for '$($app.DisplayName)'..." -Color Cyan
        & $startLattice $latticeAppDeepScan $cellsAppDeep $txtAppDeepScanIcon $txtAppDeepScanLabel $txtAppDeepScanTimer "Scanning..."
        $btnAppDeepScan.IsEnabled = $false

        $workerBlock = {
            param($mPath, $cPath, $targetApp, $q)
            Get-ChildItem -Path $mPath -Filter *.ps1 | Where-Object { $_.Name -ne "GUI.ps1" } | ForEach-Object { . $_.FullName }
            
            $cb = {
                param($cur, $tot, $task)
                $q.Enqueue([PSCustomObject]@{
                    Type    = "Progress"
                    Current = $cur
                    Total   = $tot
                    Task    = $task
                })
            }

            return @(Start-DeepScan -Application $targetApp -ConfigDir $cPath -ProgressCallback $cb)
        }

        $onProgress = {
            param($info)
            if ($info.Type -eq "Progress") {
                Log-GuiConsole -Tag "SCAN" -Message "[$($info.Current)/$($info.Total)] $($info.Task)" -Color DarkCyan
            }
        }

        $onComplete = {
            param($leftovers)
            & $stopLattice $latticeAppDeepScan $cellsAppDeep $txtAppDeepScanIcon $txtAppDeepScanLabel $txtAppDeepScanTimer "Deep Scan Leftovers"
            $btnAppDeepScan.IsEnabled = $true
            Log-GuiConsole -Tag "SCAN" -Message "Deep scan completed: Discovered $(@($leftovers).Count) remnant item(s) for '$($app.DisplayName)'." -Color Green
            & $displayLeftoverCards $app $leftovers
        }

        $onError = {
            param($err)
            & $stopLattice $latticeAppDeepScan $cellsAppDeep $txtAppDeepScanIcon $txtAppDeepScanLabel $txtAppDeepScanTimer "Deep Scan Leftovers"
            $btnAppDeepScan.IsEnabled = $true
            Log-GuiConsole -Tag "ERROR" -Message "Deep scan failed: $err" -Color Red
        }

        & $invokeAsyncWorker "AppDeepScan" $workerBlock @($modulesDir, $ConfigDir, $app) $onProgress $onComplete $onError
    })

    # Forced Uninstall: Browse Folder
    $btnBrowseForcedFolder.Add_Click({
        $dlg = [System.Windows.Forms.FolderBrowserDialog]::new()
        $dlg.Description = "Select target application folder to purge"
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtForcedTarget.Text = $dlg.SelectedPath
            Log-GuiConsole -Tag "FORCED" -Message "Target folder chosen: $($dlg.SelectedPath)" -Color Cyan
        }
    })

    # Forced Uninstall: Browse Exe
    $btnBrowseForcedExe.Add_Click({
        $dlg = [System.Windows.Forms.OpenFileDialog]::new()
        $dlg.Filter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*"
        $dlg.Title = "Select target application executable"
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtForcedTarget.Text = $dlg.FileName
            Log-GuiConsole -Tag "FORCED" -Message "Target executable chosen: $($dlg.FileName)" -Color Cyan
        }
    })

    # Forced Uninstall: Run Scan (Async)
    $btnRunForcedScan.Add_Click({
        $target = $txtForcedTarget.Text.Trim().Trim('"', "'", ' ')
        if ([string]::IsNullOrWhiteSpace($target)) {
            [System.Windows.MessageBox]::Show("Please enter or browse to a target folder or program name.", "Forced Uninstall", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            return
        }
        if ($guiAsyncState.RunningTasks.Contains("ForcedScan")) { return }

        Log-GuiConsole -Tag "FORCED" -Message "Starting forced remnant analysis on '$target'..." -Color Magenta
        & $startLattice $latticeForcedScan $cellsForced $txtForcedScanIcon $txtForcedScanLabel $txtForcedScanTimer "Analyzing Remnants..."
        $btnRunForcedScan.IsEnabled = $false

        $workerBlock = {
            param($mPath, $cPath, $tgt, $q)
            Get-ChildItem -Path $mPath -Filter *.ps1 | Where-Object { $_.Name -ne "GUI.ps1" } | ForEach-Object { . $_.FullName }
            
            $cb = {
                param($cur, $tot, $task)
                $q.Enqueue([PSCustomObject]@{
                    Type    = "Progress"
                    Current = $cur
                    Total   = $tot
                    Task    = $task
                })
            }

            return (Start-ForcedUninstall -Target $tgt -ConfigDir $cPath -ProgressCallback $cb)
        }

        $onProgress = {
            param($info)
            if ($info.Type -eq "Progress") {
                Log-GuiConsole -Tag "FORCED" -Message "[$($info.Current)/$($info.Total)] $($info.Task)" -Color DarkCyan
            }
        }

        $onComplete = {
            param($res)
            & $stopLattice $latticeForcedScan $cellsForced $txtForcedScanIcon $txtForcedScanLabel $txtForcedScanTimer "Start Forced Scan & Remnant Analysis"
            $btnRunForcedScan.IsEnabled = $true

            $syntheticApp = [PSCustomObject]@{
                DisplayName     = $res.TargetName
                Publisher       = $res.TargetPublisher
                InstallLocation = $res.TargetPath
            }

            Log-GuiConsole -Tag "FORCED" -Message "Forced scan completed: Found $(@($res.Candidates).Count) candidate items." -Color Green
            & $displayLeftoverCards $syntheticApp $res.Candidates
        }

        $onError = {
            param($err)
            & $stopLattice $latticeForcedScan $cellsForced $txtForcedScanIcon $txtForcedScanLabel $txtForcedScanTimer "Start Forced Scan & Remnant Analysis"
            $btnRunForcedScan.IsEnabled = $true
            Log-GuiConsole -Tag "ERROR" -Message "Forced scan failed: $err" -Color Red
        }

        & $invokeAsyncWorker "ForcedScan" $workerBlock @($modulesDir, $ConfigDir, $target) $onProgress $onComplete $onError
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
                    Log-GuiConsole -Tag "HUNTER" -Message "Hunter targeted PID $($procTarget.Id) ($($procTarget.ProcessName)). Terminating process and extracting remnants..." -Color Magenta
                    $window.Cursor = [System.Windows.Input.Cursors]::Wait
                    $res = Invoke-HunterTarget -Target $procTarget -TerminateProcess:$true -ConfigDir $ConfigDir
                    $window.Cursor = [System.Windows.Input.Cursors]::Arrow

                    $syntheticApp = [PSCustomObject]@{
                        DisplayName     = $res.TargetName
                        Publisher       = $res.TargetPublisher
                        InstallLocation = $res.TargetPath
                    }
                    Log-GuiConsole -Tag "HUNTER" -Message "Process terminated. Remnants traced: $(@($res.Candidates).Count) candidate items." -Color Green
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
        Log-GuiConsole -Tag "CARDS" -Message "Selected all leftover card items" -Color DarkYellow
    })

    $btnClearAllCards.Add_Click({
        foreach ($pnl in @($pnlFilesList, $pnlRegistryList, $pnlServicesList, $pnlShortcutsList)) {
            foreach ($child in $pnl.Children) {
                if ($child -is [System.Windows.Controls.CheckBox]) {
                    $child.IsChecked = $false
                }
            }
        }
        Log-GuiConsole -Tag "CARDS" -Message "Cleared all leftover card selections" -Color DarkYellow
    })

    $btnBackFromCards.Add_Click({
        Log-GuiConsole -Tag "NAV" -Message "Returning from leftover cards to $script:originTab view" -Color Blue
        switch ($script:originTab) {
            "Forced" {
                & $switchView $viewForced
                $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
                $txtBottomSummary.Text = "Specify a leftover folder or executable to purge broken software."
            }
            "Hunter" {
                & $switchView $viewHunter
                $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
                $txtBottomSummary.Text = "Inspect active processes to trace their origin and remove."
            }
            Default {
                & $switchView $viewInstalled
                $btnNext.Content = "Scan Leftovers For App"
                $btnNext.Visibility = [System.Windows.Visibility]::Visible
                $txtBottomSummary.Text = "$($script:allInstalledApps.Count) applications loaded. Select an app to uninstall or deep scan."
            }
        }
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
            Log-GuiConsole -Tag "RESTORE" -Message "Executing rollback from snapshot '$($backup.BackupId)'..." -Color Cyan
            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            $rRes = Restore-CleanupBackup -BackupId $backup.BackupId
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
            Log-GuiConsole -Tag "RESTORE" -Message "Rollback complete: $($rRes.RestoredCount) restored, $($rRes.FailedCount) errors." -Color Green
            [System.Windows.MessageBox]::Show("Successfully restored $($rRes.RestoredCount) item(s)! (Failed: $($rRes.FailedCount))", "Restore Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        }
    })

    # Return Home Button from Step 3 (CRITICAL FIX: Zero invalid invocation, origin-aware return)
    $btnReturnHome.Add_Click({
        try {
            switch ($script:originTab) {
                "Installed" {
                    $script:activeTab = "Installed"
                    & $setTabActive $tabInstalled
                    & $switchView $viewInstalled
                    $btnScanAction.Visibility = [System.Windows.Visibility]::Collapsed
                    $btnSelectHigh.Visibility = [System.Windows.Visibility]::Collapsed
                    $btnSelectAll.Visibility = [System.Windows.Visibility]::Visible
                    $btnSelectHeavy.Visibility = [System.Windows.Visibility]::Collapsed
                    $btnClearSelection.Visibility = [System.Windows.Visibility]::Visible
                    $btnNext.Content = "Scan Leftovers For App"
                    $btnNext.Visibility = [System.Windows.Visibility]::Visible
                    & $loadInstalledApps
                }
                "Forced" {
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
                }
                "Hunter" {
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
                }
                Default {
                    $script:activeTab = "Orphans"
                    & $setTabActive $tabOrphans
                    & $switchView $viewOrphans
                    $btnScanAction.Visibility = [System.Windows.Visibility]::Visible
                    $btnSelectHigh.Visibility = [System.Windows.Visibility]::Visible
                    $btnSelectAll.Visibility = [System.Windows.Visibility]::Visible
                    $btnSelectHeavy.Visibility = [System.Windows.Visibility]::Visible
                    $btnClearSelection.Visibility = [System.Windows.Visibility]::Visible
                    $btnNext.Content = "Delete Selected Ghost Folders"
                    $btnNext.Visibility = [System.Windows.Visibility]::Visible
                    & $updateOrphanSummary
                }
            }
        } catch {
            Log-GuiConsole -Tag "ERROR" -Message "Navigation error returning from results: $_" -Color Red
        }
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
            
            if ($res -ne [System.Windows.MessageBoxResult]::Yes) {
                Log-GuiConsole -Tag "SECURITY" -Message "Cleanup cancelled by user: Human approval was declined." -Color Yellow
                return
            }

            Log-GuiConsole -Tag "SECURITY" -Message "Human confirmation verified: Approved deletion of $($selectedItems.Count) orphan folder(s) ($szStr)." -Color Green
            $mockApp = [PSCustomObject]@{
                DisplayName     = "Orphaned_Storage_Cleanup"
                Publisher       = "HailUninstaller"
                InstallLocation = ""
            }

            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            $backupRes = New-CleanupBackup -Application $mockApp -SelectedItems $selectedItems
            $script:latestBackupId = $backupRes.BackupId
            Log-GuiConsole -Tag "BACKUP" -Message "Created restorable safety snapshot: $($backupRes.BackupId)" -Color Cyan

            $cRes = Invoke-CleanupItems -SelectedItems $selectedItems -HumanApproved
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
            Log-GuiConsole -Tag "CLEANUP" -Message "Orphan purge complete! Freed $(Format-Bytes $cRes.RemovedBytes) across $($cRes.RemovedCount) folders." -Color Green

            # In-place purge of deleted orphans from observable collection
            for ($i = $script:allOrphans.Count - 1; $i -ge 0; $i--) {
                if ($script:allOrphans[$i].Selected) {
                    $script:allOrphans.RemoveAt($i)
                }
            }
            $remBytes = 0L
            foreach ($rem in $script:allOrphans) { $remBytes += [long]$rem.Size }
            if ($script:allOrphans.Count -gt 0) {
                $txtOrphanCount.Text = "$($script:allOrphans.Count) folders found ($(Format-Bytes $remBytes) total)"
            } else {
                $txtOrphanCount.Text = "No orphan folders remaining."
                if ($pnlScanPrompt) { $pnlScanPrompt.Visibility = [System.Windows.Visibility]::Visible }
                if ($lstOrphans) { $lstOrphans.Visibility = [System.Windows.Visibility]::Collapsed }
            }

            & $switchView $viewStep3
            $txtResultStats.Text = "Freed: $(Format-Bytes $cRes.RemovedBytes) across $($cRes.RemovedCount) orphaned folder(s)!"
            $txtBackupId.Text = "Backup Snapshot: $($backupRes.BackupId)"
            $btnNext.Visibility = [System.Windows.Visibility]::Collapsed
            $btnReturnHome.Content = "← Return to Ghost Folders"

        # SCENARIO 2: Scanning Selected App from Installed List
        } elseif ($viewInstalled.Visibility -eq [System.Windows.Visibility]::Visible) {
            $selectedApps = & $getSelectedInstalledApps
            if ($selectedApps.Count -eq 0) {
                [System.Windows.MessageBox]::Show("Please select an application to scan.", "HailUninstaller", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                return
            }
            $app = $selectedApps[0]
            Log-GuiConsole -Tag "SCAN" -Message "Deep scanning leftovers for application: $($app.DisplayName)..." -Color Cyan
            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            $leftovers = @(Start-DeepScan -Application $app -ConfigDir $ConfigDir)
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
            Log-GuiConsole -Tag "SCAN" -Message "Deep scan completed: Found $(@($leftovers).Count) remnant item(s)." -Color Green
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
            
            if ($res -ne [System.Windows.MessageBoxResult]::Yes) {
                Log-GuiConsole -Tag "SECURITY" -Message "Cleanup cancelled by user: Human approval was declined." -Color Yellow
                return
            }

            Log-GuiConsole -Tag "SECURITY" -Message "Human confirmation verified: Approved deletion of $($selectedRemnants.Count) remnant(s) for '$targetName' ($szStr)." -Color Green
            $window.Cursor = [System.Windows.Input.Cursors]::Wait
            $backupRes = New-CleanupBackup -Application $script:activeTargetApp -SelectedItems $selectedRemnants
            $script:latestBackupId = $backupRes.BackupId
            Log-GuiConsole -Tag "BACKUP" -Message "Created restorable safety snapshot: $($backupRes.BackupId)" -Color Cyan

            $cRes = Invoke-CleanupItems -SelectedItems $selectedRemnants -HumanApproved
            $window.Cursor = [System.Windows.Input.Cursors]::Arrow
            Log-GuiConsole -Tag "CLEANUP" -Message "Remnant purge complete! Freed $(Format-Bytes $cRes.RemovedBytes) across $($cRes.RemovedCount) item(s)." -Color Green

            & $switchView $viewStep3
            $txtResultStats.Text = "Freed: $(Format-Bytes $cRes.RemovedBytes) across $($cRes.RemovedCount) remnant item(s)!"
            $txtBackupId.Text = "Backup Snapshot: $($backupRes.BackupId)"
            $btnNext.Visibility = [System.Windows.Visibility]::Collapsed

            if ($script:originTab -eq "Installed") {
                $btnReturnHome.Content = "← Return to Installed Applications"
            } elseif ($script:originTab -eq "Forced") {
                $btnReturnHome.Content = "← Return to Forced Purge"
            } elseif ($script:originTab -eq "Hunter") {
                $btnReturnHome.Content = "← Return to Hunter Mode"
            } else {
                $btnReturnHome.Content = "← Return to Ghost Folders"
            }
        }
    })

    # Window Closing: Cleanly dispose background runspaces and stop timers
    $window.Add_Closing({
        try {
            if ($guiAsyncState.ActiveJobs) {
                foreach ($job in @($guiAsyncState.ActiveJobs)) {
                    try {
                        if ($job.Timer) { $job.Timer.Stop() }
                        if ($job.Runspace) { $job.Runspace.Dispose() }
                    } catch { }
                }
                $guiAsyncState.ActiveJobs.Clear()
                $guiAsyncState.RunningTasks.Clear()
            }
            if ($activeLatticeTimers) {
                foreach ($kv in $activeLatticeTimers.GetEnumerator()) {
                    try { $kv.Value.Timer.Stop() } catch { }
                }
                $activeLatticeTimers.Clear()
            }
        } catch { }
    })

    # Window Loaded: Immediate instant launch
    $window.Add_Loaded({
        $txtBottomSummary.Text = "HailUninstaller v0.0.1 ready. Click 'Scan Storage Leftovers' or switch tabs."
        Log-GuiConsole -Tag "READY" -Message "HailUninstaller ready. Console log synchronized with GUI." -Color Green
        # Preload installed software in background for instantaneous responsiveness when switching tabs
        & $loadInstalledApps
    })

    # Launch GUI dialog
    [void]$window.ShowDialog()
}
