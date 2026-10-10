# ==============================================================================
# OtoKapat - Akıllı Otomatik Kapatıcı & Görev Yöneticisi
# Sürüm       : 1.0.0
# Geliştirici : hcorc (OtoKapat Project)
# Lisans      : MIT License
# Platform    : Windows 10 / Windows 11 (PowerShell 5.1+ & .NET Framework 4.5+)
# Tasarım     : Frameless Modern Koyu Tema | WPF XAML | Taşınabilir & Kurulumsuz
# GitHub      : https://github.com/hcorc/OtoKapat
# ==============================================================================

# ------------------------------------------------------------------------------
# Bağımlılıklar (WPF & Form Bileşenleri)
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Konsol Bağlantısını Kopar (Windows Terminal / CMD penceresini anında kapatır)
# ------------------------------------------------------------------------------
try {
    if (-not ("NativeConsole" -as [type])) {
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public static class NativeConsole {
            [DllImport("kernel32.dll", SetLastError = true)]
            public static extern bool FreeConsole();
        }
"@ -ErrorAction SilentlyContinue
    }
    $null = [NativeConsole]::FreeConsole()
} catch {}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing



# ------------------------------------------------------------------------------
# Tekil Çalışma Kontrolü (Single Instance Mutex - İkinci Kez Açılmayı Engeller)
# ------------------------------------------------------------------------------
$script:createdNew = $false
$script:appMutex = New-Object System.Threading.Mutex($true, "OtoKapat_SingleInstance_Mutex", [ref]$script:createdNew)
if (-not $script:createdNew) {
    [System.Windows.Forms.MessageBox]::Show(
        "OtoKapat zaten açık ve çalışıyor!",
        "OtoKapat",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
    exit
}

# ------------------------------------------------------------------------------
# XAML Kullanıcı Arayüzü Tanımı (Modern WPF Koyu Tema)
# ------------------------------------------------------------------------------
[string]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OtoKapat"
        Height="720" Width="1020" MinHeight="680" MinWidth="960"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent" ShowInTaskbar="True"
        FontFamily="Segoe UI" FontSize="13">

    <Window.Resources>
        <!-- Varsayılan TextBlock Rengi -->
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#F8FAFC"/>
        </Style>

        <!-- Koyu Temalı ComboBox ToggleButton -->
        <ControlTemplate x:Key="DarkComboBoxToggleButton" TargetType="ToggleButton">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition />
                    <ColumnDefinition Width="28" />
                </Grid.ColumnDefinitions>
                <Border x:Name="Border" Grid.ColumnSpan="2" CornerRadius="8" Background="#141724" BorderBrush="#282E47" BorderThickness="1" />
                <Border Grid.Column="0" Margin="1" Background="Transparent" />
                <Path x:Name="Arrow" Grid.Column="1" HorizontalAlignment="Center" VerticalAlignment="Center" Fill="#94A3B8" Data="M 0 0 L 4 4 L 8 0 Z"/>
            </Grid>
            <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="Border" Property="BorderBrush" Value="#4F46E5"/>
                    <Setter TargetName="Arrow" Property="Fill" Value="#FFFFFF"/>
                </Trigger>
            </ControlTemplate.Triggers>
        </ControlTemplate>

        <!-- Koyu Temalı ComboBoxItem -->
        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="#161826"/>
            <Setter Property="Foreground" Value="#F8FAFC"/>
            <Setter Property="Padding" Value="12,9"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border x:Name="bdItem" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}" CornerRadius="6" Margin="4,2">
                            <ContentPresenter />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter TargetName="bdItem" Property="Background" Value="#252B42"/>
                                <Setter Property="Foreground" Value="#38BDF8"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="bdItem" Property="Background" Value="#4F46E5"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Koyu Temalı ComboBox -->
        <Style TargetType="ComboBox">
            <Setter Property="Foreground" Value="#F8FAFC"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
            <Setter Property="OverridesDefaultStyle" Value="True"/>
            <Setter Property="ScrollViewer.HorizontalScrollBarVisibility" Value="Auto"/>
            <Setter Property="ScrollViewer.VerticalScrollBarVisibility" Value="Auto"/>
            <Setter Property="ScrollViewer.CanContentScroll" Value="True"/>
            <Setter Property="Height" Value="38"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton x:Name="ToggleButton" Template="{StaticResource DarkComboBoxToggleButton}" Focusable="false" IsChecked="{Binding Path=IsDropDownOpen,Mode=TwoWay,RelativeSource={RelativeSource TemplatedParent}}" ClickMode="Press"/>
                            <ContentPresenter x:Name="ContentSite" IsHitTestVisible="False" Content="{TemplateBinding SelectionBoxItem}" ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}" Margin="12,3,28,3" VerticalAlignment="Center" HorizontalAlignment="Left" />
                            <Popup x:Name="Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}" AllowsTransparency="True" Focusable="False" PopupAnimation="Slide">
                                <Grid x:Name="DropDown" SnapsToDevicePixels="True" MinWidth="{TemplateBinding ActualWidth}" MaxHeight="300">
                                    <Border x:Name="DropDownBorder" Background="#161826" BorderBrush="#2E3552" BorderThickness="1" CornerRadius="8" Margin="0,4,0,4">
                                        <ScrollViewer Margin="2" SnapsToDevicePixels="True">
                                            <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained" />
                                        </ScrollViewer>
                                    </Border>
                                </Grid>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Sol Menü Butonları -->
        <Style x:Key="SidebarBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#94A3B8"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Height" Value="48"/>
            <Setter Property="Margin" Value="0,0,0,6"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="Padding" Value="16,0"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="10" Padding="{TemplateBinding Padding}">
                            <ContentPresenter VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#1C2033"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Hızlı Seçim Chip Butonları -->
        <Style x:Key="PresetChip" TargetType="Button">
            <Setter Property="Background" Value="#171A29"/>
            <Setter Property="Foreground" Value="#93C5FD"/>
            <Setter Property="BorderBrush" Value="#292F47"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="Margin" Value="0,0,8,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="chipBd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#252B42"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Yuvarlatılmış Aksiyon Butonları -->
        <Style x:Key="RoundedBtn" TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="btnBd" Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Opacity" Value="0.9"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Koyu Temalı Metin Girişi -->
        <Style x:Key="DarkInput" TargetType="TextBox">
            <Setter Property="Background" Value="#141724"/>
            <Setter Property="Foreground" Value="#F8FAFC"/>
            <Setter Property="BorderBrush" Value="#2A3048"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>

        <!-- Pencere Kontrol Butonları (Minimize & Kapat) -->
        <Style x:Key="WinCtrlBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#94A3B8"/>
            <Setter Property="Width" Value="38"/>
            <Setter Property="Height" Value="32"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="ctrlBd" Background="{TemplateBinding Background}" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#22283E"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="WinCloseBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#94A3B8"/>
            <Setter Property="Width" Value="38"/>
            <Setter Property="Height" Value="32"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="ctrlCloseBd" Background="{TemplateBinding Background}" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#DC2626"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <!-- Ana Çerçeve (Rounded & Shadowed) -->
    <Border Background="#0C0E16" BorderBrush="#22283E" BorderThickness="1" CornerRadius="14">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="52"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- 1. ÖZEL ÜST BAR (TITLEBAR) -->
            <Border x:Name="pnlTitleBar" Grid.Row="0" Background="#10121C" BorderBrush="#1C2030" BorderThickness="0,0,0,1" CornerRadius="14,14,0,0" Padding="18,0">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>

                    <!-- Sol: Logo ve Başlık -->
                    <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                        <Border Background="#4F46E5" Width="30" Height="30" CornerRadius="8" Margin="0,0,10,0">
                            <TextBlock Text="⚡" FontSize="16" Foreground="#FFFFFF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <TextBlock Text="OtoKapat" FontSize="16" FontWeight="Bold" Foreground="#FFFFFF" VerticalAlignment="Center"/>
                        <TextBlock Text="HK" FontSize="12" Foreground="#64748B" FontWeight="Bold" VerticalAlignment="Center" Margin="8,2,0,0"/>
                    </StackPanel>

                    <!-- Orta: Canlı Sistem Saati -->
                    <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                        <TextBlock Text="🕒 " FontSize="13" Foreground="#38BDF8" VerticalAlignment="Center"/>
                        <TextBlock x:Name="lblSysClock" Text="--:--:--" FontSize="15" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center"/>
                    </StackPanel>

                    <!-- Sağ: Bildirim Test Butonu & Pencere Kontrolleri -->
                    <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                        <!-- Bildirim Testi Butonu -->
                        <Button x:Name="btnTestNotification" Style="{StaticResource PresetChip}" Content="🔔 Bildirim Testi" Margin="0,0,14,0" Padding="10,5" VerticalAlignment="Center"/>

                        <!-- Minimize Butonu -->
                        <Button x:Name="btnWinMinimize" Style="{StaticResource WinCtrlBtn}" Content="—" Margin="0,0,4,0"/>

                        <!-- Kapat Butonu (Düzgün X İkonu) -->
                        <Button x:Name="btnWinClose" Style="{StaticResource WinCloseBtn}" Content="✕"/>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- 2. ANA UYGULAMA İÇERİK IZGARASI -->
            <Grid Grid.Row="1">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="240"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Sol Kenar Çubuğu (Sidebar) -->
                <Border Grid.Column="0" Background="#10121C" BorderBrush="#1C2030" BorderThickness="0,0,1,0" Padding="16,20">
                    <DockPanel LastChildFill="True">
                        <!-- Menü Butonları -->
                        <StackPanel DockPanel.Dock="Top">
                            <Button x:Name="btnNavCountdown" Style="{StaticResource SidebarBtn}" Content="⏱  Geri Sayım"/>
                            <Button x:Name="btnNavTime" Style="{StaticResource SidebarBtn}" Content="🕒  Belirli Saat"/>
                            <Button x:Name="btnNavNetwork" Style="{StaticResource SidebarBtn}" Content="🌐  Ağ &amp; İndirme Takibi"/>
                            <Button x:Name="btnNavFolder" Style="{StaticResource SidebarBtn}" Content="📁  Klasör İzleme"/>
                            <Button x:Name="btnNavProcess" Style="{StaticResource SidebarBtn}" Content="⚡  İşlem İzleme"/>
                        </StackPanel>

                        <!-- Alt Bilgi / İpucu Kutusu -->
                        <Border DockPanel.Dock="Bottom" Background="#151826" BorderBrush="#22283E" BorderThickness="1" CornerRadius="10" Padding="14,12">
                            <StackPanel>
                                <TextBlock Text="DURUM" FontSize="10" FontWeight="Bold" Foreground="#64748B"/>
                                <TextBlock x:Name="lblSidebarStatus" Text="Sistem Boşta" FontSize="13" FontWeight="Bold" Foreground="#38BDF8" Margin="0,4,0,0"/>
                            </StackPanel>
                        </Border>
                    </DockPanel>
                </Border>

                <!-- Sağ İçerik Alanı -->
                <Grid Grid.Column="1" Background="#0C0E16">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <!-- SEKME GÖVDELERİ -->
                    <Grid Grid.Row="0" Margin="24,20,24,14">

                        <!-- 1. Geri Sayım Paneli -->
                        <Border x:Name="pnlCountdown" Visibility="Visible" Background="#131622" BorderBrush="#202538" BorderThickness="1" CornerRadius="12" Padding="24">
                            <DockPanel LastChildFill="True">
                                <StackPanel DockPanel.Dock="Top" Margin="0,0,0,16">
                                    <TextBlock Text="⏱  Geri Sayım Zamanlayıcısı" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF"/>
                                    <TextBlock Text="Belirlediğiniz süre tamamlandığında bilgisayar otomatik olarak kapatılır." FontSize="12" Foreground="#94A3B8" Margin="0,3,0,0"/>
                                </StackPanel>

                                <!-- Hedef Kapanış Saati Kartı -->
                                <Border DockPanel.Dock="Bottom" Background="#1A1D2D" BorderBrush="#2C324E" BorderThickness="1" CornerRadius="10" Padding="16,12" Margin="0,16,0,0">
                                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                                        <TextBlock Text="Hedeflenen Kapanma Vakti: " FontSize="13" Foreground="#94A3B8" VerticalAlignment="Center"/>
                                        <TextBlock x:Name="lblCountdownTargetTime" Text="Süre giriniz" FontSize="15" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center" Margin="6,0,0,0"/>
                                    </StackPanel>
                                </Border>

                                <StackPanel VerticalAlignment="Center">
                                    <!-- Sayaç Girişleri -->
                                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,24">
                                        <StackPanel Margin="0,0,16,0" HorizontalAlignment="Center">
                                            <TextBlock Text="SAAT" FontSize="11" FontWeight="Bold" Foreground="#64748B" HorizontalAlignment="Center" Margin="0,0,0,6"/>
                                            <TextBox x:Name="txtCountHour" Style="{StaticResource DarkInput}" Text="01" Width="70" TextAlignment="Center" FontSize="28" Height="58"/>
                                        </StackPanel>

                                        <TextBlock Text=":" FontSize="36" FontWeight="Bold" Foreground="#475569" VerticalAlignment="Center" Margin="0,14,16,0"/>

                                        <StackPanel Margin="0,0,16,0" HorizontalAlignment="Center">
                                            <TextBlock Text="DAKİKA" FontSize="11" FontWeight="Bold" Foreground="#64748B" HorizontalAlignment="Center" Margin="0,0,0,6"/>
                                            <TextBox x:Name="txtCountMin" Style="{StaticResource DarkInput}" Text="30" Width="70" TextAlignment="Center" FontSize="28" Height="58"/>
                                        </StackPanel>

                                        <TextBlock Text=":" FontSize="36" FontWeight="Bold" Foreground="#475569" VerticalAlignment="Center" Margin="0,14,16,0"/>

                                        <StackPanel HorizontalAlignment="Center">
                                            <TextBlock Text="SANİYE" FontSize="11" FontWeight="Bold" Foreground="#64748B" HorizontalAlignment="Center" Margin="0,0,0,6"/>
                                            <TextBox x:Name="txtCountSec" Style="{StaticResource DarkInput}" Text="00" Width="70" TextAlignment="Center" FontSize="28" Height="58"/>
                                        </StackPanel>
                                    </StackPanel>

                                    <!-- Hızlı Süre Ekleme Butonları -->
                                    <TextBlock Text="Hızlı Süre Seçimi:" FontSize="12" FontWeight="SemiBold" Foreground="#94A3B8" Margin="0,0,0,8" HorizontalAlignment="Center"/>
                                    <WrapPanel HorizontalAlignment="Center">
                                        <Button x:Name="btnChip15m" Style="{StaticResource PresetChip}" Content="+15 Dk"/>
                                        <Button x:Name="btnChip30m" Style="{StaticResource PresetChip}" Content="+30 Dk"/>
                                        <Button x:Name="btnChip45m" Style="{StaticResource PresetChip}" Content="+45 Dk"/>
                                        <Button x:Name="btnChip1h" Style="{StaticResource PresetChip}" Content="+1 Saat"/>
                                        <Button x:Name="btnChip2h" Style="{StaticResource PresetChip}" Content="+2 Saat"/>
                                        <Button x:Name="btnChip3h" Style="{StaticResource PresetChip}" Content="+3 Saat"/>
                                        <Button x:Name="btnChipClear" Style="{StaticResource PresetChip}" Content="Sıfırla" Foreground="#F87171" BorderBrush="#7F1D1D"/>
                                    </WrapPanel>
                                </StackPanel>
                            </DockPanel>
                        </Border>

                        <!-- 2. Belirli Saat Paneli -->
                        <Border x:Name="pnlSpecificTime" Visibility="Collapsed" Background="#131622" BorderBrush="#202538" BorderThickness="1" CornerRadius="12" Padding="24">
                            <DockPanel LastChildFill="True">
                                <StackPanel DockPanel.Dock="Top" Margin="0,0,0,16">
                                    <TextBlock Text="🕒  Belirli Saatte Kapat" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF"/>
                                    <TextBlock Text="Günün seçtiğiniz belirli bir saatinde (Örn: Gece 03:30) bilgisayar otomatik kapatılır." FontSize="12" Foreground="#94A3B8" Margin="0,3,0,0"/>
                                </StackPanel>

                                <!-- Kalan Süre Kartı -->
                                <Border DockPanel.Dock="Bottom" Background="#1A1D2D" BorderBrush="#2C324E" BorderThickness="1" CornerRadius="10" Padding="16,12" Margin="0,16,0,0">
                                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                                        <TextBlock Text="Hesaplanan Kalan Süre: " FontSize="13" Foreground="#94A3B8" VerticalAlignment="Center"/>
                                        <TextBlock x:Name="lblTargetTimeRemaining" Text="Saat seçiniz" FontSize="15" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center" Margin="6,0,0,0"/>
                                    </StackPanel>
                                </Border>

                                <StackPanel VerticalAlignment="Center">
                                    <!-- Saat ve Dakika Seçimi -->
                                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,24">
                                        <StackPanel Margin="0,0,16,0">
                                            <TextBlock Text="HEDEF SAAT" FontSize="11" FontWeight="Bold" Foreground="#64748B" HorizontalAlignment="Center" Margin="0,0,0,6"/>
                                            <ComboBox x:Name="cmbTargetHour" Width="90" Height="50" FontSize="24" FontWeight="Bold"/>
                                        </StackPanel>

                                        <TextBlock Text=":" FontSize="36" FontWeight="Bold" Foreground="#475569" VerticalAlignment="Center" Margin="0,14,16,0"/>

                                        <StackPanel>
                                            <TextBlock Text="HEDEF DAKİKA" FontSize="11" FontWeight="Bold" Foreground="#64748B" HorizontalAlignment="Center" Margin="0,0,0,6"/>
                                            <ComboBox x:Name="cmbTargetMin" Width="90" Height="50" FontSize="24" FontWeight="Bold"/>
                                        </StackPanel>
                                    </StackPanel>

                                    <!-- Hızlı Saat Butonları -->
                                    <TextBlock Text="Örnek Saatler:" FontSize="12" FontWeight="SemiBold" Foreground="#94A3B8" Margin="0,0,0,8" HorizontalAlignment="Center"/>
                                    <WrapPanel HorizontalAlignment="Center">
                                        <Button x:Name="btnTime00" Style="{StaticResource PresetChip}" Content="Gece 00:00"/>
                                        <Button x:Name="btnTime01" Style="{StaticResource PresetChip}" Content="Gece 01:00"/>
                                        <Button x:Name="btnTime02" Style="{StaticResource PresetChip}" Content="Gece 02:00"/>
                                        <Button x:Name="btnTime03" Style="{StaticResource PresetChip}" Content="Gece 03:00"/>
                                        <Button x:Name="btnTime04" Style="{StaticResource PresetChip}" Content="Sabah 04:00"/>
                                        <Button x:Name="btnTimePlus1h" Style="{StaticResource PresetChip}" Content="Şu An + 1 Saat"/>
                                        <Button x:Name="btnTimePlus2h" Style="{StaticResource PresetChip}" Content="Şu An + 2 Saat"/>
                                    </WrapPanel>
                                </StackPanel>
                            </DockPanel>
                        </Border>

                        <!-- 3. Ağ ve İndirme Takibi Paneli -->
                        <Border x:Name="pnlNetwork" Visibility="Collapsed" Background="#131622" BorderBrush="#202538" BorderThickness="1" CornerRadius="12" Padding="24">
                            <DockPanel LastChildFill="True">
                                <StackPanel DockPanel.Dock="Top" Margin="0,0,0,16">
                                    <TextBlock Text="🌐  Ağ &amp; İndirme Takipçisi (Steam, Epic Games, Torrent, vb.)" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF"/>
                                    <TextBlock Text="İndirme hızını gerçek zamanlı izler. İndirme bittiğinde ve hız belirlenen KB/s eşiğinin altına düştüğünde sistemi kapatır." FontSize="12" Foreground="#94A3B8" Margin="0,3,0,0"/>
                                </StackPanel>

                                <!-- Açıklama Kutusu -->
                                <Border DockPanel.Dock="Bottom" Background="#161928" BorderBrush="#242B42" BorderThickness="1" CornerRadius="8" Padding="14,10" Margin="0,14,0,0">
                                    <TextBlock Text="💡 Steam ve Epic Games oyun dosyalarını diske yazarken indirmeyi kısa süreli duraklatabilir. Doğrulama süresi (en az 3 dk) bu aralıklarda bilgisayarın erkenden kapanmasını önler." FontSize="11" Foreground="#94A3B8" TextWrapping="Wrap"/>
                                </Border>

                                <StackPanel VerticalAlignment="Center">
                                    <!-- Anlık Hız Göstergesi Kartı -->
                                    <Border Background="#191C2C" BorderBrush="#2A3048" BorderThickness="1" CornerRadius="12" Padding="20,16" Margin="0,0,0,16">
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>

                                            <StackPanel Grid.Column="0">
                                                <TextBlock Text="ANLIK İNDİRME HIZI" FontSize="11" FontWeight="Bold" Foreground="#64748B"/>
                                                <StackPanel Orientation="Horizontal" Margin="0,4,0,0">
                                                    <TextBlock x:Name="lblNetSpeed" Text="0.0 KB/s" FontSize="36" FontWeight="Bold" Foreground="#38BDF8"/>
                                                </StackPanel>
                                            </StackPanel>

                                            <Border Grid.Column="1" VerticalAlignment="Center" Background="#102A24" BorderBrush="#059669" BorderThickness="1" CornerRadius="20" Padding="14,6">
                                                <TextBlock x:Name="lblNetStatusBadge" Text="AĞ NORMAL 🚀" FontSize="12" FontWeight="Bold" Foreground="#34D399"/>
                                            </Border>
                                        </Grid>
                                    </Border>

                                    <!-- Ayarlar: Kullanıcı Tarafından Düzenlenebilir Eşik ve Doğrulama Süresi -->
                                    <Grid Margin="0,0,0,14">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="1.2*"/>
                                            <ColumnDefinition Width="*"/>
                                        </Grid.ColumnDefinitions>

                                        <!-- Düzenlenebilir Eşik Değeri -->
                                        <StackPanel Grid.Column="0" Margin="0,0,12,0">
                                            <TextBlock Text="Kapanma Eşik Hızı (KB/s):" FontSize="12" FontWeight="SemiBold" Foreground="#94A3B8" Margin="0,0,0,6"/>
                                            <Grid>
                                                <Grid.ColumnDefinitions>
                                                    <ColumnDefinition Width="*"/>
                                                    <ColumnDefinition Width="Auto"/>
                                                </Grid.ColumnDefinitions>
                                                <TextBox x:Name="txtNetThreshold" Style="{StaticResource DarkInput}" Text="100" Height="38" FontSize="16" FontWeight="Bold" Padding="10,0"/>
                                                <TextBlock Grid.Column="1" Text="KB/s" FontSize="13" FontWeight="Bold" Foreground="#94A3B8" VerticalAlignment="Center" Margin="8,0,0,0"/>
                                            </Grid>
                                        </StackPanel>

                                        <!-- Doğrulama & Bekleme Süresi -->
                                        <StackPanel Grid.Column="1" Margin="8,0,0,0">
                                            <TextBlock Text="Doğrulama &amp; Bekleme Süresi:" FontSize="12" FontWeight="SemiBold" Foreground="#94A3B8" Margin="0,0,0,6"/>
                                            <ComboBox x:Name="cmbNetDuration" Height="38"/>
                                        </StackPanel>
                                    </Grid>

                                    <!-- Hızlı Eşik Butonları -->
                                    <TextBlock Text="Hızlı Eşik Değeri Seç:" FontSize="11" FontWeight="SemiBold" Foreground="#64748B" Margin="0,0,0,6"/>
                                    <WrapPanel Margin="0,0,0,14">
                                        <Button x:Name="btnThresh50" Style="{StaticResource PresetChip}" Content="50 KB/s"/>
                                        <Button x:Name="btnThresh100" Style="{StaticResource PresetChip}" Content="100 KB/s (Varsayılan)"/>
                                        <Button x:Name="btnThresh250" Style="{StaticResource PresetChip}" Content="250 KB/s"/>
                                        <Button x:Name="btnThresh500" Style="{StaticResource PresetChip}" Content="500 KB/s"/>
                                        <Button x:Name="btnThresh1M" Style="{StaticResource PresetChip}" Content="1 MB/s (1024 KB/s)"/>
                                        <Button x:Name="btnThresh2M" Style="{StaticResource PresetChip}" Content="2 MB/s"/>
                                    </WrapPanel>

                                    <!-- Geri Sayım Durumu -->
                                    <Border Background="#141724" BorderBrush="#252A40" BorderThickness="1" CornerRadius="8" Padding="14,10">
                                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                                            <TextBlock Text="Eşik Altında Geçen Süre: " FontSize="12" Foreground="#94A3B8"/>
                                            <TextBlock x:Name="lblNetThresholdCountdown" Text="00:00 / 03:00" FontSize="13" FontWeight="Bold" Foreground="#F59E0B" Margin="6,0,0,0"/>
                                        </StackPanel>
                                    </Border>
                                </StackPanel>
                            </DockPanel>
                        </Border>

                        <!-- 4. Klasör İzleme Paneli -->
                        <Border x:Name="pnlFolder" Visibility="Collapsed" Background="#131622" BorderBrush="#202538" BorderThickness="1" CornerRadius="12" Padding="24">
                            <DockPanel LastChildFill="True">
                                <StackPanel DockPanel.Dock="Top" Margin="0,0,0,16">
                                    <TextBlock Text="📁  Klasör İndirme İzleyicisi" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF"/>
                                    <TextBlock Text="İndirme klasörünüzdeki geçici indirme dosyaları (.crdownload, .part vb.) bittiğinde sistemi kapatır." FontSize="12" Foreground="#94A3B8" Margin="0,3,0,0"/>
                                </StackPanel>

                                <StackPanel VerticalAlignment="Center">
                                    <!-- Klasör Seçimi -->
                                    <TextBlock Text="İzlenecek Klasör:" FontSize="12" FontWeight="SemiBold" Foreground="#94A3B8" Margin="0,0,0,6"/>
                                    <Grid Margin="0,0,0,12">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="110"/>
                                        </Grid.ColumnDefinitions>
                                        <TextBox x:Name="txtFolderPath" Grid.Column="0" Style="{StaticResource DarkInput}" Height="38" Margin="0,0,10,0"/>
                                        <Button x:Name="btnBrowseFolder" Grid.Column="1" Style="{StaticResource RoundedBtn}" Content="📂 Gözat..." Background="#1E2338" Foreground="#93C5FD" Height="38" FontWeight="SemiBold"/>
                                    </Grid>

                                    <!-- Hızlı Klasör Seçenekleri -->
                                    <WrapPanel Margin="0,0,0,16">
                                        <Button x:Name="btnFolderDownloads" Style="{StaticResource PresetChip}" Content="📥 İndirilenler Klasörü"/>
                                        <Button x:Name="btnFolderDesktop" Style="{StaticResource PresetChip}" Content="🖥️ Masaüstü"/>
                                    </WrapPanel>

                                    <!-- Yöntem Seçimi -->
                                    <Border Background="#171A29" BorderBrush="#282E47" BorderThickness="1" CornerRadius="10" Padding="16" Margin="0,0,0,16">
                                        <StackPanel>
                                            <RadioButton x:Name="rbFolderTempFiles" IsChecked="True" GroupName="FolderMode" Margin="0,0,0,10">
                                                <StackPanel Margin="6,-2,0,0">
                                                    <TextBlock Text="Geçici indirme dosyalarını bekle (Önerilen)" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                                                    <TextBlock Text=".crdownload, .part, .downloading, .!ut, .tmp dosyaları bittiğinde kapat." FontSize="11" Foreground="#94A3B8"/>
                                                </StackPanel>
                                            </RadioButton>

                                            <RadioButton x:Name="rbFolderInactivity" GroupName="FolderMode">
                                                <StackPanel Margin="6,-2,0,0">
                                                    <TextBlock Text="Dosya yazma hareketsizliğini bekle" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                                                    <TextBlock Text="Klasörde son 3 dakika içinde hiçbir dosya değişmediğinde kapat." FontSize="11" Foreground="#94A3B8"/>
                                                </StackPanel>
                                            </RadioButton>
                                        </StackPanel>
                                    </Border>

                                    <!-- Klasör Durum Bilgisi -->
                                    <Border Background="#141724" BorderBrush="#252A40" BorderThickness="1" CornerRadius="8" Padding="14,12">
                                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                                            <TextBlock Text="Klasör Durumu: " FontSize="12" Foreground="#94A3B8"/>
                                            <TextBlock x:Name="lblFolderStatus" Text="Klasör hazır" FontSize="13" FontWeight="Bold" Foreground="#38BDF8" Margin="6,0,0,0"/>
                                        </StackPanel>
                                    </Border>
                                </StackPanel>
                            </DockPanel>
                        </Border>

                        <!-- 5. İşlem / Process İzleme Paneli -->
                        <Border x:Name="pnlProcess" Visibility="Collapsed" Background="#131622" BorderBrush="#202538" BorderThickness="1" CornerRadius="12" Padding="24">
                            <DockPanel LastChildFill="True">
                                <StackPanel DockPanel.Dock="Top" Margin="0,0,0,16">
                                    <TextBlock Text="⚡  Program / İşlem (Process &amp; PID) İzleyicisi" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF"/>
                                    <TextBlock Text="Seçtiğiniz program veya işlem (PID) kapandığında bilgisayarı otomatik kapatır." FontSize="12" Foreground="#94A3B8" Margin="0,3,0,0"/>
                                </StackPanel>

                                <StackPanel VerticalAlignment="Center">
                                    <!-- Hızlı Seçimler -->
                                    <TextBlock Text="Hızlı Seçim (Popüler Programlar):" FontSize="12" FontWeight="SemiBold" Foreground="#94A3B8" Margin="0,0,0,8"/>
                                    <WrapPanel Margin="0,0,0,14">
                                        <Button x:Name="btnProcSteam" Style="{StaticResource PresetChip}" Content="🎮 Steam"/>
                                        <Button x:Name="btnProcEpic" Style="{StaticResource PresetChip}" Content="⚡ Epic Games"/>
                                        <Button x:Name="btnProcQbit" Style="{StaticResource PresetChip}" Content="📥 qBittorrent"/>
                                        <Button x:Name="btnProcUtorrent" Style="{StaticResource PresetChip}" Content="📦 uTorrent"/>
                                        <Button x:Name="btnProcIdm" Style="{StaticResource PresetChip}" Content="🚀 IDMan"/>
                                        <Button x:Name="btnProcFdm" Style="{StaticResource PresetChip}" Content="📥 FDM"/>
                                    </WrapPanel>

                                    <!-- Kullanıcı Girişi (İsim veya PID) -->
                                    <TextBlock Text="İzlenecek Program Adı veya PID Numarası:" FontSize="12" FontWeight="SemiBold" Foreground="#94A3B8" Margin="0,0,0,6"/>
                                    <TextBox x:Name="txtProcessInput" Style="{StaticResource DarkInput}" Height="38" Margin="0,0,0,14" ToolTip="Örn: steam, EpicGamesLauncher veya 14280"/>

                                    <!-- Çalışan İşlemler Listesi -->
                                    <TextBlock Text="Veya Çalışan Programlar Listesinden Seçin:" FontSize="12" FontWeight="SemiBold" Foreground="#94A3B8" Margin="0,0,0,6"/>
                                    <Grid Margin="0,0,0,16">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="100"/>
                                        </Grid.ColumnDefinitions>
                                        <ComboBox x:Name="cmbProcesses" Grid.Column="0" Height="38" Margin="0,0,10,0"/>
                                        <Button x:Name="btnRefreshProcesses" Grid.Column="1" Style="{StaticResource RoundedBtn}" Content="🔄 Yenile" Background="#1E2338" Foreground="#93C5FD" Height="38" FontWeight="SemiBold"/>
                                    </Grid>

                                    <!-- İşlem Durum Kartı -->
                                    <Border Background="#141724" BorderBrush="#252A40" BorderThickness="1" CornerRadius="8" Padding="14,12">
                                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                                            <TextBlock Text="İzleme Durumu: " FontSize="12" Foreground="#94A3B8"/>
                                            <TextBlock x:Name="lblProcessStatus" Text="Bir program veya PID belirleyin" FontSize="13" FontWeight="Bold" Foreground="#F59E0B" Margin="6,0,0,0"/>
                                        </StackPanel>
                                    </Border>
                                </StackPanel>
                            </DockPanel>
                        </Border>

                    </Grid>

                    <!-- ALT KONTROL VE ÇALIŞTIRMA ALANI -->
                    <Border Grid.Row="1" Background="#10121C" BorderBrush="#1C2030" BorderThickness="0,1,0,0" Padding="24,16" CornerRadius="0,0,14,14">
                        <StackPanel>
                            <!-- Eylem & Güvenlik Seçenekleri -->
                            <Grid Margin="0,0,0,14">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>

                                <!-- Eylem Türü -->
                                <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                                    <TextBlock Text="Eylem:" FontSize="12" FontWeight="Bold" Foreground="#94A3B8" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                    <ComboBox x:Name="cmbAction" Width="210" Height="36"/>
                                </StackPanel>

                                <!-- Checkboxlar -->
                                <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                                    <CheckBox x:Name="chkWarning" Content="60 sn kala sesli geri sayım ve iptal penceresi göster" IsChecked="True" Foreground="#CBD5E1" FontSize="12" VerticalAlignment="Center" Margin="0,0,18,0"/>
                                    <CheckBox x:Name="chkForce" Content="Programları zorla kapat (/f)" IsChecked="True" Foreground="#CBD5E1" FontSize="12" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Grid>

                            <!-- Büyük Başlat/Durdur Butonu ve Durum Çubuğu -->
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="220"/>
                                </Grid.ColumnDefinitions>

                                <!-- Canlı Durum Metni ve İlerleme Çubuğu -->
                                <StackPanel Grid.Column="0" VerticalAlignment="Center" Margin="0,0,18,0">
                                    <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
                                        <Ellipse x:Name="elpStatusDot" Width="10" Height="10" Fill="#64748B" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                        <TextBlock x:Name="lblLiveStatus" Text="Hazır: Bir kapatma yöntemi belirleyin ve Başlat'a tıklayın." FontSize="13" FontWeight="SemiBold" Foreground="#F8FAFC" VerticalAlignment="Center"/>
                                    </StackPanel>
                                    <ProgressBar x:Name="progBar" Height="6" Background="#1B1F30" Foreground="#6366F1" BorderThickness="0" Value="0" Maximum="100"/>
                                </StackPanel>

                                <!-- Büyük Buton -->
                                <Button x:Name="btnStartStop" Style="{StaticResource RoundedBtn}" Grid.Column="1" Content="🚀 GÖREVİ BAŞLAT" Background="#4F46E5" Foreground="#FFFFFF" FontWeight="Bold" FontSize="14" Height="48"/>
                            </Grid>
                        </StackPanel>
                    </Border>
                </Grid>
            </Grid>

            <!-- 3. SON 60 SANİYE UYARI VE İPTAL PENCERESİ (OVERLAY) -->
            <Grid x:Name="pnlAlertOverlay" Grid.RowSpan="2" Panel.ZIndex="100" Visibility="Collapsed" Background="#F0090A11">
                <Border Background="#161826" BorderBrush="#DC2626" BorderThickness="2" CornerRadius="16" Width="600" Height="400" HorizontalAlignment="Center" VerticalAlignment="Center" Padding="32">
                    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                        <TextBlock Text="⚠️" FontSize="42" HorizontalAlignment="Center" Margin="0,0,0,8"/>
                        <TextBlock Text="BİLGİSAYAR KAPATILIYOR!" FontSize="22" FontWeight="Bold" Foreground="#EF4444" HorizontalAlignment="Center"/>
                        <TextBlock Text="Kapatma görevi tamamlandı. Sistem birazdan kapatılacaktır." FontSize="13" Foreground="#94A3B8" HorizontalAlignment="Center" Margin="0,6,0,16"/>

                        <!-- Geri Sayım Kutusu -->
                        <Border Background="#251216" BorderBrush="#EF4444" BorderThickness="1" CornerRadius="12" Padding="20,10" HorizontalAlignment="Center" Margin="0,0,0,24">
                            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                                <TextBlock x:Name="lblAlertCounter" Text="60" FontSize="52" FontWeight="Bold" Foreground="#EF4444" VerticalAlignment="Center"/>
                                <TextBlock Text=" SN" FontSize="20" FontWeight="Bold" Foreground="#F87171" VerticalAlignment="Bottom" Margin="6,0,0,12"/>
                            </StackPanel>
                        </Border>

                        <!-- Butonlar -->
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
                            <Button x:Name="btnCancelShutdown" Style="{StaticResource RoundedBtn}" Content="❌ KAPATMAYI İPTAL ET" Background="#10B981" Foreground="#FFFFFF" FontWeight="Bold" FontSize="14" Height="44" Padding="24,0" Margin="0,0,12,0"/>
                            <Button x:Name="btnImmediateShutdown" Style="{StaticResource RoundedBtn}" Content="⚡ ŞİMDİ KAPAT" Background="#334155" Foreground="#CBD5E1" FontWeight="SemiBold" FontSize="13" Height="44" Padding="18,0"/>
                        </StackPanel>
                    </StackPanel>
                </Border>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

# XAML Okuyucu ve Pencere Oluşturma
$StringReader = New-Object System.IO.StringReader($xaml)
$XmlReader    = [System.Xml.XmlReader]::Create($StringReader)
$window       = [System.Windows.Markup.XamlReader]::Load($XmlReader)

# ==============================================================================
# Kontrollerin Bağlanması (FindName)
# ==============================================================================
# Üst Bar ve Pencere Kontrolleri
$pnlTitleBar            = $window.FindName("pnlTitleBar")
$lblSysClock            = $window.FindName("lblSysClock")
$btnTestNotification    = $window.FindName("btnTestNotification")
$btnWinMinimize         = $window.FindName("btnWinMinimize")
$btnWinClose            = $window.FindName("btnWinClose")

# Navigasyon Butonları
$btnNavCountdown        = $window.FindName("btnNavCountdown")
$btnNavTime             = $window.FindName("btnNavTime")
$btnNavNetwork          = $window.FindName("btnNavNetwork")
$btnNavFolder           = $window.FindName("btnNavFolder")
$btnNavProcess          = $window.FindName("btnNavProcess")
$lblSidebarStatus       = $window.FindName("lblSidebarStatus")

# Paneller
$pnlCountdown           = $window.FindName("pnlCountdown")
$pnlSpecificTime        = $window.FindName("pnlSpecificTime")
$pnlNetwork             = $window.FindName("pnlNetwork")
$pnlFolder              = $window.FindName("pnlFolder")
$pnlProcess             = $window.FindName("pnlProcess")

# Geri Sayım Kontrolleri
$txtCountHour           = $window.FindName("txtCountHour")
$txtCountMin            = $window.FindName("txtCountMin")
$txtCountSec            = $window.FindName("txtCountSec")
$lblCountdownTargetTime = $window.FindName("lblCountdownTargetTime")
$btnChip15m             = $window.FindName("btnChip15m")
$btnChip30m             = $window.FindName("btnChip30m")
$btnChip45m             = $window.FindName("btnChip45m")
$btnChip1h              = $window.FindName("btnChip1h")
$btnChip2h              = $window.FindName("btnChip2h")
$btnChip3h              = $window.FindName("btnChip3h")
$btnChipClear           = $window.FindName("btnChipClear")

# Belirli Saat Kontrolleri
$cmbTargetHour          = $window.FindName("cmbTargetHour")
$cmbTargetMin           = $window.FindName("cmbTargetMin")
$lblTargetTimeRemaining = $window.FindName("lblTargetTimeRemaining")
$btnTime00              = $window.FindName("btnTime00")
$btnTime01              = $window.FindName("btnTime01")
$btnTime02              = $window.FindName("btnTime02")
$btnTime03              = $window.FindName("btnTime03")
$btnTime04              = $window.FindName("btnTime04")
$btnTimePlus1h          = $window.FindName("btnTimePlus1h")
$btnTimePlus2h          = $window.FindName("btnTimePlus2h")

# Ağ Kontrolleri
$lblNetSpeed            = $window.FindName("lblNetSpeed")
$lblNetStatusBadge      = $window.FindName("lblNetStatusBadge")
$txtNetThreshold        = $window.FindName("txtNetThreshold")
$cmbNetDuration         = $window.FindName("cmbNetDuration")
$lblNetThresholdCountdown = $window.FindName("lblNetThresholdCountdown")
$btnThresh50            = $window.FindName("btnThresh50")
$btnThresh100           = $window.FindName("btnThresh100")
$btnThresh250           = $window.FindName("btnThresh250")
$btnThresh500           = $window.FindName("btnThresh500")
$btnThresh1M            = $window.FindName("btnThresh1M")
$btnThresh2M            = $window.FindName("btnThresh2M")

# Klasör Kontrolleri
$txtFolderPath          = $window.FindName("txtFolderPath")
$btnBrowseFolder        = $window.FindName("btnBrowseFolder")
$btnFolderDownloads     = $window.FindName("btnFolderDownloads")
$btnFolderDesktop       = $window.FindName("btnFolderDesktop")
$rbFolderTempFiles      = $window.FindName("rbFolderTempFiles")
$rbFolderInactivity     = $window.FindName("rbFolderInactivity")
$lblFolderStatus        = $window.FindName("lblFolderStatus")

# İşlem Kontrolleri
$txtProcessInput        = $window.FindName("txtProcessInput")
$cmbProcesses           = $window.FindName("cmbProcesses")
$btnRefreshProcesses    = $window.FindName("btnRefreshProcesses")
$lblProcessStatus       = $window.FindName("lblProcessStatus")
$btnProcSteam           = $window.FindName("btnProcSteam")
$btnProcEpic            = $window.FindName("btnProcEpic")
$btnProcQbit            = $window.FindName("btnProcQbit")
$btnProcUtorrent        = $window.FindName("btnProcUtorrent")
$btnProcIdm             = $window.FindName("btnProcIdm")
$btnProcFdm             = $window.FindName("btnProcFdm")

# Alt Kontroller
$cmbAction              = $window.FindName("cmbAction")
$chkWarning             = $window.FindName("chkWarning")
$chkForce               = $window.FindName("chkForce")
$btnStartStop           = $window.FindName("btnStartStop")
$lblLiveStatus          = $window.FindName("lblLiveStatus")
$progBar                = $window.FindName("progBar")
$elpStatusDot           = $window.FindName("elpStatusDot")

# 60 Saniye Uyarı Paneli (Overlay)
$pnlAlertOverlay        = $window.FindName("pnlAlertOverlay")
$lblAlertCounter        = $window.FindName("lblAlertCounter")
$btnCancelShutdown      = $window.FindName("btnCancelShutdown")
$btnImmediateShutdown   = $window.FindName("btnImmediateShutdown")

# ==============================================================================
# Windows Sistem Kapatma & Bildirim Yöneticisi (shutdown.exe)
# ==============================================================================
$script:isWindowsShutdownScheduled = $false

function Schedule-WindowsShutdown([int]$seconds) {
    if ($seconds -lt 0) { $seconds = 0 }
    $forceParam = if ($chkForce.IsChecked) { "/f" } else { "" }
    $actionIndex = $cmbAction.SelectedIndex

    # Olası eski zamanlanmış görevi temizle
    Start-Process "shutdown.exe" -ArgumentList "/a" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
    $script:isWindowsShutdownScheduled = $false

    if ($actionIndex -eq 0) {
        # Bilgisayarı Kapat: Windows yerel 'Oturumunuz kapatılmak üzere' sistem bildirimini tetikler
        Start-Process "shutdown.exe" -ArgumentList "/s /t $seconds $forceParam" -WindowStyle Hidden
        $script:isWindowsShutdownScheduled = $true
    }
    elseif ($actionIndex -eq 1) {
        # Yeniden Başlat: Windows yerel sistem bildirimini tetikler
        Start-Process "shutdown.exe" -ArgumentList "/r /t $seconds $forceParam" -WindowStyle Hidden
        $script:isWindowsShutdownScheduled = $true
    }
}

function Cancel-WindowsShutdown {
    if ($script:isWindowsShutdownScheduled) {
        Start-Process "shutdown.exe" -ArgumentList "/a" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
        $script:isWindowsShutdownScheduled = $false
    }
}

# ==============================================================================
# Durum Değişkenleri (State)
# ==============================================================================
$script:activeMode               = "Countdown"
$script:isTaskRunning            = $false

# Geri Sayım
$script:totalCountdownSec        = 0
$script:remainingCountdownSec    = 0

# Belirli Saat
$script:targetDateTime           = [DateTime]::MinValue

# Ağ Takibi
$script:lastBytes                = $null
$script:lastNetTime              = $null
$script:lowSpeedSeconds          = 0
$script:targetSustenanceSec      = 180
$script:thresholdBytesPerSec     = 100 * 1024

# Klasör Takibi
$script:folderInactivitySec      = 0
$script:lastFolderWriteTime      = [DateTime]::Now
$script:folderTickCounter        = 0
$script:lastFolderTempCount      = 0

# İşlem Takibi
$script:monitoredProcess         = ""

# 60 Sn Uyarı
$script:alertRemainingSec        = 60
$script:isAlertActive            = $false

# ==============================================================================
# Renk Fırçaları (Brushes)
# ==============================================================================
$brushActiveNavBg   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E2338")
$brushActiveNavText = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
$brushIdleNavBg     = [System.Windows.Media.BrushConverter]::new().ConvertFromString("Transparent")
$brushIdleNavText   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")

$brushDotGreen      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#10B981")
$brushDotAmber      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F59E0B")
$brushDotRed        = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444")
$brushDotIdle       = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#64748B")

$brushBtnStart      = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4F46E5")
$brushBtnStop       = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#DC2626")

# ==============================================================================
# Yardımcı Fonksiyonlar
# ==============================================================================
function Set-ControlsEnabled([bool]$enabled) {
    $cmbAction.IsEnabled            = $enabled
    $chkWarning.IsEnabled           = $enabled
    $chkForce.IsEnabled             = $enabled

    $txtCountHour.IsEnabled         = $enabled
    $txtCountMin.IsEnabled          = $enabled
    $txtCountSec.IsEnabled          = $enabled
    $btnChip15m.IsEnabled           = $enabled
    $btnChip30m.IsEnabled           = $enabled
    $btnChip45m.IsEnabled           = $enabled
    $btnChip1h.IsEnabled            = $enabled
    $btnChip2h.IsEnabled            = $enabled
    $btnChip3h.IsEnabled            = $enabled
    $btnChipClear.IsEnabled         = $enabled

    $cmbTargetHour.IsEnabled        = $enabled
    $cmbTargetMin.IsEnabled         = $enabled
    $btnTime00.IsEnabled            = $enabled
    $btnTime01.IsEnabled            = $enabled
    $btnTime02.IsEnabled            = $enabled
    $btnTime03.IsEnabled            = $enabled
    $btnTime04.IsEnabled            = $enabled
    $btnTimePlus1h.IsEnabled        = $enabled
    $btnTimePlus2h.IsEnabled        = $enabled

    $txtNetThreshold.IsEnabled      = $enabled
    $cmbNetDuration.IsEnabled       = $enabled
    $btnThresh50.IsEnabled          = $enabled
    $btnThresh100.IsEnabled         = $enabled
    $btnThresh250.IsEnabled         = $enabled
    $btnThresh500.IsEnabled         = $enabled
    $btnThresh1M.IsEnabled          = $enabled
    $btnThresh2M.IsEnabled          = $enabled

    $txtFolderPath.IsEnabled        = $enabled
    $btnBrowseFolder.IsEnabled      = $enabled
    $btnFolderDownloads.IsEnabled   = $enabled
    $btnFolderDesktop.IsEnabled     = $enabled
    $rbFolderTempFiles.IsEnabled    = $enabled
    $rbFolderInactivity.IsEnabled   = $enabled

    $txtProcessInput.IsEnabled      = $enabled
    $cmbProcesses.IsEnabled         = $enabled
    $btnRefreshProcesses.IsEnabled  = $enabled
    $btnProcSteam.IsEnabled         = $enabled
    $btnProcEpic.IsEnabled          = $enabled
    $btnProcQbit.IsEnabled          = $enabled
    $btnProcUtorrent.IsEnabled      = $enabled
    $btnProcIdm.IsEnabled           = $enabled
    $btnProcFdm.IsEnabled           = $enabled
}

function Update-CountdownPreview {
    [int]$h = 0; [int]$m = 0; [int]$s = 0
    [int]::TryParse($txtCountHour.Text, [ref]$h) | Out-Null
    [int]::TryParse($txtCountMin.Text,  [ref]$m) | Out-Null
    [int]::TryParse($txtCountSec.Text,  [ref]$s) | Out-Null

    $totalSec = ($h * 3600) + ($m * 60) + $s
    if ($totalSec -gt 0) {
        $target = [DateTime]::Now.AddSeconds($totalSec)
        $dayLabel = if ($target.Date -eq [DateTime]::Today) { "Bugün" } else { "Yarın" }
        $lblCountdownTargetTime.Text = "$dayLabel saat $($target.ToString('HH:mm:ss'))"
    } else {
        $lblCountdownTargetTime.Text = "Süre giriniz"
    }
}

function Add-CountdownMinutes([int]$mins) {
    [int]$h = 0; [int]$m = 0; [int]$s = 0
    [int]::TryParse($txtCountHour.Text, [ref]$h) | Out-Null
    [int]::TryParse($txtCountMin.Text,  [ref]$m) | Out-Null
    [int]::TryParse($txtCountSec.Text,  [ref]$s) | Out-Null

    $totalMins = ($h * 60) + $m + $mins
    $newH = [Math]::Floor($totalMins / 60)
    $newM = $totalMins % 60

    $txtCountHour.Text = $newH.ToString("00")
    $txtCountMin.Text  = $newM.ToString("00")
    Update-CountdownPreview
}

function Update-TargetTimePreview {
    if ($cmbTargetHour.SelectedItem -and $cmbTargetMin.SelectedItem) {
        $targetH = [int]$cmbTargetHour.SelectedItem
        $targetM = [int]$cmbTargetMin.SelectedItem

        $now = [DateTime]::Now
        $target = [DateTime]::new($now.Year, $now.Month, $now.Day, $targetH, $targetM, 0)
        if ($target -le $now) {
            $target = $target.AddDays(1)
        }
        $diff = $target - $now
        $hours = [int]$diff.TotalHours
        $mins  = $diff.Minutes
        $dayStr = if ($target.Date -eq [DateTime]::Today) { "Bugün" } else { "Yarın" }
        $lblTargetTimeRemaining.Text = "$dayStr $($target.ToString('HH:mm')) (Kalan: $hours saat $mins dk)"
    }
}

function Refresh-ProcessList {
    $cmbProcesses.Items.Clear()
    $running = Get-Process | Where-Object { $_.MainWindowTitle -ne '' } | Sort-Object ProcessName
    foreach ($p in $running) {
        $null = $cmbProcesses.Items.Add("$($p.ProcessName) (PID: $($p.Id)) - $($p.MainWindowTitle)")
    }
    if ($cmbProcesses.Items.Count -gt 0) {
        $cmbProcesses.SelectedIndex = 0
    }
}

function Select-Process([string]$name, [string]$display) {
    $txtProcessInput.Text = $name
    $script:monitoredProcess = $name
    $lblProcessStatus.Text = "$display ($name) seçildi."
    $lblProcessStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
}

function Set-ActiveTab([string]$tabName) {
    $script:activeMode = $tabName

    $pnlCountdown.Visibility    = [System.Windows.Visibility]::Collapsed
    $pnlSpecificTime.Visibility = [System.Windows.Visibility]::Collapsed
    $pnlNetwork.Visibility      = [System.Windows.Visibility]::Collapsed
    $pnlFolder.Visibility       = [System.Windows.Visibility]::Collapsed
    $pnlProcess.Visibility      = [System.Windows.Visibility]::Collapsed

    $btnNavCountdown.Background = $brushIdleNavBg; $btnNavCountdown.Foreground = $brushIdleNavText
    $btnNavTime.Background      = $brushIdleNavBg; $btnNavTime.Foreground      = $brushIdleNavText
    $btnNavNetwork.Background   = $brushIdleNavBg; $btnNavNetwork.Foreground   = $brushIdleNavText
    $btnNavFolder.Background    = $brushIdleNavBg; $btnNavFolder.Foreground    = $brushIdleNavText
    $btnNavProcess.Background   = $brushIdleNavBg; $btnNavProcess.Foreground   = $brushIdleNavText

    switch ($tabName) {
        "Countdown" {
            $pnlCountdown.Visibility = [System.Windows.Visibility]::Visible
            $btnNavCountdown.Background = $brushActiveNavBg
            $btnNavCountdown.Foreground = $brushActiveNavText
            Update-CountdownPreview
        }
        "SpecificTime" {
            $pnlSpecificTime.Visibility = [System.Windows.Visibility]::Visible
            $btnNavTime.Background = $brushActiveNavBg
            $btnNavTime.Foreground = $brushActiveNavText
            Update-TargetTimePreview
        }
        "Network" {
            $pnlNetwork.Visibility = [System.Windows.Visibility]::Visible
            $btnNavNetwork.Background = $brushActiveNavBg
            $btnNavNetwork.Foreground = $brushActiveNavText
        }
        "Folder" {
            $pnlFolder.Visibility = [System.Windows.Visibility]::Visible
            $btnNavFolder.Background = $brushActiveNavBg
            $btnNavFolder.Foreground = $brushActiveNavText
        }
        "Process" {
            $pnlProcess.Visibility = [System.Windows.Visibility]::Visible
            $btnNavProcess.Background = $brushActiveNavBg
            $btnNavProcess.Foreground = $brushActiveNavText
            Refresh-ProcessList
        }
    }
}

function Get-CurrentDownloadSpeed {
    try {
        $adapters = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
            Where-Object { $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -ne 'Loopback' }

        $currBytes = 0
        foreach ($a in $adapters) {
            try {
                $currBytes += $a.GetIPv4Statistics().BytesReceived
            } catch {
                # Sanal veya IPv4 desteklemeyen bağdaştırıcıları güvenle atla
            }
        }

        $now = [DateTime]::Now
        if ($null -eq $script:lastBytes -or $null -eq $script:lastNetTime) {
            $script:lastBytes = $currBytes
            $script:lastNetTime = $now
            return @{ BytesPerSec = 0; Display = "0.0 KB/s" }
        }

        $elapsed = ($now - $script:lastNetTime).TotalSeconds
        if ($elapsed -lt 0.5) {
            return @{ BytesPerSec = 0; Display = "Hesaplanıyor..." }
        }

        $bytesDiff = [Math]::Max(0, $currBytes - $script:lastBytes)
        $speedBps = $bytesDiff / $elapsed

        $script:lastBytes = $currBytes
        $script:lastNetTime = $now

        $display = ""
        if ($speedBps -ge 1048576) {
            $display = "{0:N1} MB/s" -f ($speedBps / 1048576)
        } else {
            $display = "{0:N0} KB/s" -f ($speedBps / 1024)
        }

        return @{ BytesPerSec = $speedBps; Display = $display }
    } catch {
        return @{ BytesPerSec = 0; Display = "0.0 KB/s" }
    }
}

function Execute-ShutdownAction {
    $forceParam = if ($chkForce.IsChecked) { "/f" } else { "" }
    $actionIndex = $cmbAction.SelectedIndex

    if ($script:isWindowsShutdownScheduled) {
        Start-Process "shutdown.exe" -ArgumentList "/a" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
        $script:isWindowsShutdownScheduled = $false
    }

    switch ($actionIndex) {
        0 { # Bilgisayarı Kapat
            Start-Process "shutdown.exe" -ArgumentList "/s /t 0 $forceParam" -WindowStyle Hidden
        }
        1 { # Yeniden Başlat
            Start-Process "shutdown.exe" -ArgumentList "/r /t 0 $forceParam" -WindowStyle Hidden
        }
        2 { # Uyku Modu
            Start-Process "rundll32.exe" -ArgumentList "powrprof.dll,SetSuspendState 0,1,0" -WindowStyle Hidden
        }
        3 { # Hazırda Beklet
            Start-Process "shutdown.exe" -ArgumentList "/h" -WindowStyle Hidden
        }
    }
}

function Trigger-ShutdownSequence {
    if ($chkWarning.IsChecked) {
        $script:isAlertActive = $true
        $script:alertRemainingSec = 60
        $lblAlertCounter.Text = "60"
        $pnlAlertOverlay.Visibility = [System.Windows.Visibility]::Visible

        $window.WindowState = [System.Windows.WindowState]::Normal
        $window.Topmost = $true
        $null = $window.Activate()

        # Windows resmi sistem kapatma bildirimini tetikle (1 dakika geri sayım uyarısı)
        Schedule-WindowsShutdown 60

        [System.Media.SystemSounds]::Exclamation.Play()
    } else {
        Execute-ShutdownAction
    }
}

function Start-Task {
    switch ($script:activeMode) {
        "Countdown" {
            [int]$h = 0; [int]$m = 0; [int]$s = 0
            [int]::TryParse($txtCountHour.Text, [ref]$h) | Out-Null
            [int]::TryParse($txtCountMin.Text,  [ref]$m) | Out-Null
            [int]::TryParse($txtCountSec.Text,  [ref]$s) | Out-Null

            $script:totalCountdownSec = ($h * 3600) + ($m * 60) + $s
            if ($script:totalCountdownSec -le 0) {
                [System.Windows.Forms.MessageBox]::Show(
                    "Lütfen 0'dan büyük bir geri sayım süresi belirleyin!",
                    "OtoKapat",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null
                return
            }
            $script:remainingCountdownSec = $script:totalCountdownSec
            $progBar.Maximum = $script:totalCountdownSec
            $progBar.Value = 0

            # Windows yerel sistem bildirimini tetikle ve zamanlamayı başlat
            Schedule-WindowsShutdown $script:totalCountdownSec
        }
        "SpecificTime" {
            $targetH = [int]$cmbTargetHour.SelectedItem
            $targetM = [int]$cmbTargetMin.SelectedItem

            $now = [DateTime]::Now
            $script:targetDateTime = [DateTime]::new($now.Year, $now.Month, $now.Day, $targetH, $targetM, 0)
            if ($script:targetDateTime -le $now) {
                $script:targetDateTime = $script:targetDateTime.AddDays(1)
            }
            $diff = [int]($script:targetDateTime - $now).TotalSeconds
            $progBar.Maximum = $diff
            $progBar.Value = 0

            # Windows yerel sistem bildirimini tetikle ve zamanlamayı başlat
            Schedule-WindowsShutdown $diff
        }
        "Network" {
            [double]$threshKb = 100
            if (-not [double]::TryParse($txtNetThreshold.Text, [ref]$threshKb) -or $threshKb -le 0) {
                $threshKb = 100
                $txtNetThreshold.Text = "100"
            }
            $script:thresholdBytesPerSec = $threshKb * 1024

            $durText = $cmbNetDuration.SelectedItem.ToString()
            if ($durText -like "1 Dakika*")       { $script:targetSustenanceSec = 60 }
            elseif ($durText -like "2 Dakika*")  { $script:targetSustenanceSec = 120 }
            elseif ($durText -like "3 Dakika*")  { $script:targetSustenanceSec = 180 }
            elseif ($durText -like "5 Dakika*")  { $script:targetSustenanceSec = 300 }
            elseif ($durText -like "10 Dakika*") { $script:targetSustenanceSec = 600 }

            $script:lowSpeedSeconds = 0
            $script:lastBytes = $null
            $script:lastNetTime = $null
            $progBar.Maximum = $script:targetSustenanceSec
            $progBar.Value = 0
        }
        "Folder" {
            if (-not (Test-Path $txtFolderPath.Text)) {
                [System.Windows.Forms.MessageBox]::Show(
                    "Belirtilen klasör yolu bulunamadı! Lütfen geçerli bir klasör seçin.",
                    "OtoKapat",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null
                return
            }
            $script:folderInactivitySec = 0
            $script:lastFolderWriteTime = [DateTime]::Now
            $script:folderTickCounter   = 0
            $script:lastFolderTempCount = 0
            $progBar.Maximum = 180
            $progBar.Value = 0
        }
        "Process" {
            $inputVal = $txtProcessInput.Text.Trim()
            if ([string]::IsNullOrWhiteSpace($inputVal)) {
                [System.Windows.Forms.MessageBox]::Show(
                    "Lütfen izlenecek bir program adı veya PID numarası girin!",
                    "OtoKapat",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null
                return
            }

            # GÜVENLİK KONTROLÜ: Program şu an gerçekten çalışıyor mu?
            [int]$chkPid = 0
            $chkProc = $null
            if ([int]::TryParse($inputVal, [ref]$chkPid)) {
                $chkProc = Get-Process -Id $chkPid -ErrorAction SilentlyContinue
            } else {
                $cleanName = $inputVal -replace '\.exe$', ''
                $chkProc = Get-Process -Name $cleanName -ErrorAction SilentlyContinue
            }

            if ($null -eq $chkProc -or @($chkProc).Count -eq 0) {
                [System.Windows.Forms.MessageBox]::Show(
                    "İzlemek istediğiniz '$inputVal' programı şu anda çalışmıyor!`n`nSistemin hemen kapanmasını önlemek için, lütfen önce programı başlatın veya aşağıdaki listeden çalışan bir program seçin.",
                    "OtoKapat - Program Bulunamadı",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null
                return
            }

            $script:monitoredProcess = $inputVal
            $progBar.Maximum = 100
            $progBar.Value = 100
        }
    }

    $script:isTaskRunning = $true
    Set-ControlsEnabled $false
    $btnStartStop.Content = "⏹ GÖREVİ İPTAL ET / DURDUR"
    $btnStartStop.Background = $brushBtnStop
    $elpStatusDot.Fill = $brushDotGreen
    $lblLiveStatus.Text = "Görev Aktif: Sistem izleniyor..."
    $lblSidebarStatus.Text = "Görev Çalışıyor"
    $lblSidebarStatus.Foreground = $brushDotGreen
}

function Stop-Task([string]$reason = "Görev durduruldu.") {
    $script:isTaskRunning = $false
    $script:isAlertActive = $false
    $pnlAlertOverlay.Visibility = [System.Windows.Visibility]::Collapsed
    $window.Topmost = $false

    # Windows resmi zamanlanmış kapatmasını iptal et
    Cancel-WindowsShutdown

    Set-ControlsEnabled $true
    $btnStartStop.Content = "🚀 GÖREVİ BAŞLAT"
    $btnStartStop.Background = $brushBtnStart
    $elpStatusDot.Fill = $brushDotIdle
    $lblLiveStatus.Text = $reason
    $lblSidebarStatus.Text = "Sistem Boşta"
    $lblSidebarStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
    $progBar.Value = 0
    $lblNetThresholdCountdown.Text = "00:00 / 03:00"
}

# ==============================================================================
# Bileşenleri İlk Değerlerle Doldurma
# ==============================================================================
# Eylemler
$null = $cmbAction.Items.Add("🔴 Bilgisayarı Kapat")
$null = $cmbAction.Items.Add("🔄 Yeniden Başlat (Restart)")
$null = $cmbAction.Items.Add("🌙 Uyku Modu (Sleep)")
$null = $cmbAction.Items.Add("❄️ Hazırda Beklet (Hibernate)")
$cmbAction.SelectedIndex = 0

# Belirli Saat: 00 - 23 Saatler
for ($h = 0; $h -le 23; $h++) {
    $null = $cmbTargetHour.Items.Add($h.ToString("00"))
}

# Belirli Saat: 00 - 59 Dakikalar (Tam esneklik)
for ($m = 0; $m -le 59; $m++) {
    $null = $cmbTargetMin.Items.Add($m.ToString("00"))
}

$now = [DateTime]::Now
$cmbTargetHour.SelectedItem = (($now.Hour + 1) % 24).ToString("00")
$cmbTargetMin.SelectedItem  = "00"

# Ağ Bekleme Süresi Seçenekleri
$null = $cmbNetDuration.Items.Add("1 Dakika")
$null = $cmbNetDuration.Items.Add("2 Dakika")
$null = $cmbNetDuration.Items.Add("3 Dakika (Önerilen)")
$null = $cmbNetDuration.Items.Add("5 Dakika")
$null = $cmbNetDuration.Items.Add("10 Dakika")
$cmbNetDuration.SelectedIndex = 2

# Varsayılan İndirilenler Klasörü
$defaultDownloads = [System.IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'), 'Downloads')
$txtFolderPath.Text = $defaultDownloads

# ==============================================================================
# Olay Bağlantıları (Event Handlers)
# ==============================================================================
# Frameless Başlık Çubuğu Taşıma (DragMove)
$pnlTitleBar.Add_MouseLeftButtonDown({
    if ($_.LeftButton -eq [System.Windows.Input.MouseButtonState]::Pressed) {
        $window.DragMove()
    }
})

# Minimize Butonu
$btnWinMinimize.Add_Click({
    $window.WindowState = [System.Windows.WindowState]::Minimized
})

# Kapat Butonu
$btnWinClose.Add_Click({
    $window.Close()
})

# Bildirim Testi Butonu (Gerçek Windows Sistem Kapatma ve İptal Bildirimi Testi)
$btnTestNotification.Add_Click({
    if ($script:isTaskRunning -or $script:isAlertActive) {
        [System.Windows.Forms.MessageBox]::Show(
            "Aktif bir görev çalışırken bildirim testi yapılamaz. Lütfen önce görevi durdurun.",
            "OtoKapat",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $lblLiveStatus.Text = "Windows sistem bildirimi test ediliyor (Kapatma & İptal)..."

    # 1. Olası eski zamanlamayı temizle
    Start-Process "shutdown.exe" -ArgumentList "/a" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue

    # 2. Windows dahili sistem kapatma bildirimini tetikle
    Start-Process "shutdown.exe" -ArgumentList "/s /t 3600" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue

    # 3. 2.5 saniye sonra otomatik iptal et
    $testTimer = New-Object System.Windows.Threading.DispatcherTimer
    $testTimer.Interval = [TimeSpan]::FromMilliseconds(2500)
    $testTimer.Add_Tick({
        param($s, $e)
        $testTimer.Stop()
        Start-Process "shutdown.exe" -ArgumentList "/a" -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
        $lblLiveStatus.Text = "Bildirim testi tamamlandı: Windows sistem bildirimleri ekrana yansıtıldı."
    })
    $testTimer.Start()
})

# Navigasyon Sekmeleri
$btnNavCountdown.Add_Click({ Set-ActiveTab "Countdown" })
$btnNavTime.Add_Click({      Set-ActiveTab "SpecificTime" })
$btnNavNetwork.Add_Click({   Set-ActiveTab "Network" })
$btnNavFolder.Add_Click({    Set-ActiveTab "Folder" })
$btnNavProcess.Add_Click({   Set-ActiveTab "Process" })

# Geri Sayım Hızlı Butonları
$btnChip15m.Add_Click({ Add-CountdownMinutes 15 })
$btnChip30m.Add_Click({ Add-CountdownMinutes 30 })
$btnChip45m.Add_Click({ Add-CountdownMinutes 45 })
$btnChip1h.Add_Click({  Add-CountdownMinutes 60 })
$btnChip2h.Add_Click({  Add-CountdownMinutes 120 })
$btnChip3h.Add_Click({  Add-CountdownMinutes 180 })
$btnChipClear.Add_Click({
    $txtCountHour.Text = "00"
    $txtCountMin.Text  = "00"
    $txtCountSec.Text  = "00"
    Update-CountdownPreview
})

$txtCountHour.Add_TextChanged({ Update-CountdownPreview })
$txtCountMin.Add_TextChanged({  Update-CountdownPreview })
$txtCountSec.Add_TextChanged({  Update-CountdownPreview })

# Belirli Saat Değişimi
$cmbTargetHour.Add_SelectionChanged({ Update-TargetTimePreview })
$cmbTargetMin.Add_SelectionChanged({  Update-TargetTimePreview })

$btnTime00.Add_Click({ $cmbTargetHour.SelectedItem = "00"; $cmbTargetMin.SelectedItem = "00" })
$btnTime01.Add_Click({ $cmbTargetHour.SelectedItem = "01"; $cmbTargetMin.SelectedItem = "00" })
$btnTime02.Add_Click({ $cmbTargetHour.SelectedItem = "02"; $cmbTargetMin.SelectedItem = "00" })
$btnTime03.Add_Click({ $cmbTargetHour.SelectedItem = "03"; $cmbTargetMin.SelectedItem = "00" })
$btnTime04.Add_Click({ $cmbTargetHour.SelectedItem = "04"; $cmbTargetMin.SelectedItem = "00" })
$btnTimePlus1h.Add_Click({
    $newH = ([DateTime]::Now.Hour + 1) % 24
    $cmbTargetHour.SelectedItem = $newH.ToString("00")
})
$btnTimePlus2h.Add_Click({
    $newH = ([DateTime]::Now.Hour + 2) % 24
    $cmbTargetHour.SelectedItem = $newH.ToString("00")
})

# Ağ Hızlı Eşik Butonları
$btnThresh50.Add_Click({  $txtNetThreshold.Text = "50" })
$btnThresh100.Add_Click({ $txtNetThreshold.Text = "100" })
$btnThresh250.Add_Click({ $txtNetThreshold.Text = "250" })
$btnThresh500.Add_Click({ $txtNetThreshold.Text = "500" })
$btnThresh1M.Add_Click({  $txtNetThreshold.Text = "1024" })
$btnThresh2M.Add_Click({  $txtNetThreshold.Text = "2048" })

# Klasör Seçimi (Gözat Dialog)
$btnBrowseFolder.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description = "İzlemek istediğiniz klasörü seçin:"
    $fbd.SelectedPath = $txtFolderPath.Text
    if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtFolderPath.Text = $fbd.SelectedPath
        $lblFolderStatus.Text = "Klasör seçildi: $($fbd.SelectedPath)"
    }
})

$btnFolderDownloads.Add_Click({
    $txtFolderPath.Text = [System.IO.Path]::Combine([Environment]::GetFolderPath('UserProfile'), 'Downloads')
})
$btnFolderDesktop.Add_Click({
    $txtFolderPath.Text = [Environment]::GetFolderPath('Desktop')
})

# İşlem Listesi ve Butonları
$btnRefreshProcesses.Add_Click({ Refresh-ProcessList })

$btnProcSteam.Add_Click({ Select-Process "steam" "Steam" })
$btnProcEpic.Add_Click({  Select-Process "EpicGamesLauncher" "Epic Games" })
$btnProcQbit.Add_Click({  Select-Process "qbittorrent" "qBittorrent" })
$btnProcUtorrent.Add_Click({ Select-Process "uTorrent" "uTorrent" })
$btnProcIdm.Add_Click({   Select-Process "IDMan" "Internet Download Manager" })
$btnProcFdm.Add_Click({   Select-Process "fdm" "Free Download Manager" })

$cmbProcesses.Add_SelectionChanged({
    if ($cmbProcesses.SelectedItem) {
        $procText = $cmbProcesses.SelectedItem.ToString()
        $procName = $procText.Split(' ')[0]
        Select-Process $procName $procName
    }
})

# Başlat / Durdur Butonu
$btnStartStop.Add_Click({
    if ($script:isTaskRunning) {
        Stop-Task "Görev kullanıcı tarafından iptal edildi."
    } else {
        Start-Task
    }
})

# Uyarı Ekranı İptal & Hemen Kapat Butonları
$btnCancelShutdown.Add_Click({
    $script:isAlertActive = $false
    $pnlAlertOverlay.Visibility = [System.Windows.Visibility]::Collapsed
    $window.Topmost = $false
    Stop-Task "Kapatma görevi kullanıcı tarafından iptal edildi."
})

$btnImmediateShutdown.Add_Click({
    $script:isAlertActive = $false
    $pnlAlertOverlay.Visibility = [System.Windows.Visibility]::Collapsed
    $window.Topmost = $false
    Execute-ShutdownAction
})

# Pencere Kapanırken Güvenlik ve Temizlik
$window.Add_Closing({
    param($sender, $e)
    if ($script:isTaskRunning -or $script:isAlertActive) {
        $res = [System.Windows.Forms.MessageBox]::Show(
            "Şu anda aktif bir kapatma görevi çalışıyor.`n`nÇıkmak görevi iptal edecektir. Çıkmak istediğinize emin misiniz?",
            "OtoKapat - Görev Aktif",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($res -ne [System.Windows.Forms.DialogResult]::Yes) {
            $e.Cancel = $true
            return
        }
    }

    Cancel-WindowsShutdown
    try {
        if ($script:appMutex) {
            $script:appMutex.ReleaseMutex()
            $script:appMutex.Dispose()
        }
    } catch {}
})

# ==============================================================================
# İlk Durum Başlangıcı
# ==============================================================================
Set-ActiveTab "Countdown"
Update-CountdownPreview
Update-TargetTimePreview

# ==============================================================================
# Ana Zamanlayıcı (DispatcherTimer - Her Saniye Çalışır)
# ==============================================================================
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)

$timer.Add_Tick({
    $now = [DateTime]::Now
    $lblSysClock.Text = $now.ToString("HH:mm:ss")

    # 1. Ağ Hızı Sürekli Güncellenir
    $speedInfo = Get-CurrentDownloadSpeed
    $lblNetSpeed.Text = $speedInfo.Display

    # 2. Eğer 60 Saniyelik Uyarı Sayacı Çalışıyorsa
    if ($script:isAlertActive) {
        $script:alertRemainingSec--
        $lblAlertCounter.Text = $script:alertRemainingSec.ToString()

        if ($script:alertRemainingSec % 5 -eq 0 -and $script:alertRemainingSec -gt 0) {
            [System.Media.SystemSounds]::Beep.Play()
        }

        if ($script:alertRemainingSec -le 0) {
            $script:isAlertActive = $false
            Execute-ShutdownAction
            return
        }
        return
    }

    # 3. Görev Çalışmıyorsa Devam Etme
    if (-not $script:isTaskRunning) {
        return
    }

    # 4. Aktif Moda Göre İşlemler
    switch ($script:activeMode) {
        "Countdown" {
            $script:remainingCountdownSec--
            $progBar.Value = $script:totalCountdownSec - $script:remainingCountdownSec

            $ts = [TimeSpan]::FromSeconds([Math]::Max(0, $script:remainingCountdownSec))
            $lblLiveStatus.Text = "Geri Sayım: $($ts.ToString('hh\:mm\:ss')) kaldı"

            # 60 Saniye uyarısı (Yarış durumunu önlemek için -le 60 kontrolü)
            if ($script:remainingCountdownSec -le 60 -and $chkWarning.IsChecked -and -not $script:isAlertActive) {
                $script:isAlertActive = $true
                $script:alertRemainingSec = [Math]::Max(1, $script:remainingCountdownSec)
                $lblAlertCounter.Text = $script:alertRemainingSec.ToString()
                $pnlAlertOverlay.Visibility = [System.Windows.Visibility]::Visible
                $window.WindowState = [System.Windows.WindowState]::Normal
                $window.Topmost = $true
                $null = $window.Activate()
                [System.Media.SystemSounds]::Exclamation.Play()
            }
            elseif ($script:remainingCountdownSec -le 0) {
                Stop-Task "Geri sayım tamamlandı."
                Execute-ShutdownAction
            }
        }

        "SpecificTime" {
            $diff = $script:targetDateTime - $now
            $diffSec = [int]$diff.TotalSeconds

            # 60 Saniye uyarısı
            if ($diffSec -le 60 -and $diffSec -gt 0 -and $chkWarning.IsChecked -and -not $script:isAlertActive) {
                $script:isAlertActive = $true
                $script:alertRemainingSec = [Math]::Max(1, $diffSec)
                $lblAlertCounter.Text = $script:alertRemainingSec.ToString()
                $pnlAlertOverlay.Visibility = [System.Windows.Visibility]::Visible
                $window.WindowState = [System.Windows.WindowState]::Normal
                $window.Topmost = $true
                $null = $window.Activate()
                [System.Media.SystemSounds]::Exclamation.Play()
            }
            elseif ($diffSec -le 0) {
                Stop-Task "Hedeflenen saate ulaşıldı."
                Execute-ShutdownAction
            } else {
                $progBar.Value = $progBar.Maximum - $diffSec
                $lblLiveStatus.Text = "Kapanış Saati: $($script:targetDateTime.ToString('HH:mm')) (Kalan: $($diff.ToString('hh\:mm\:ss')))"
            }
        }

        "Network" {
            $bps = $speedInfo.BytesPerSec

            if ($bps -lt $script:thresholdBytesPerSec) {
                # Hız eşiğin altında: Sayaç ilerler
                $script:lowSpeedSeconds++
                $elpStatusDot.Fill = $brushDotAmber
                $lblNetStatusBadge.Text = "HIZ DÜŞÜK ⏳"
                $lblNetStatusBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F59E0B")

                $tsElapsed = [TimeSpan]::FromSeconds($script:lowSpeedSeconds)
                $tsTarget  = [TimeSpan]::FromSeconds($script:targetSustenanceSec)
                $lblNetThresholdCountdown.Text = "$($tsElapsed.ToString('mm\:ss')) / $($tsTarget.ToString('mm\:ss'))"
                $lblLiveStatus.Text = "İndirme Hızı Eşik Altında: $($speedInfo.Display) ($($tsElapsed.ToString('mm\:ss')) / $($tsTarget.ToString('mm\:ss')))"
                $progBar.Value = [Math]::Min($script:targetSustenanceSec, $script:lowSpeedSeconds)

                if ($script:lowSpeedSeconds -ge $script:targetSustenanceSec) {
                    Stop-Task "İndirme tamamlandı (Ağ trafiği kesildi)."
                    Trigger-ShutdownSequence
                }
            } else {
                # Hız eşik üstünde: İndirme sürüyor
                $script:lowSpeedSeconds = 0
                $elpStatusDot.Fill = $brushDotGreen
                $lblNetStatusBadge.Text = "İNDİRME AKTİF 🚀"
                $lblNetStatusBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
                $lblNetThresholdCountdown.Text = "00:00 / $([TimeSpan]::FromSeconds($script:targetSustenanceSec).ToString('mm\:ss'))"
                $lblLiveStatus.Text = "İndirme Devam Ediyor: $($speedInfo.Display)"
                $progBar.Value = 0
            }
        }

        "Folder" {
            $targetPath = $txtFolderPath.Text
            if (-not (Test-Path $targetPath)) {
                Stop-Task "Klasör bulunamadı!"
                return
            }

            $script:folderTickCounter++

            if ($rbFolderTempFiles.IsChecked) {
                # Her 2 saniyede bir veya ilk turda dosya sistemini tara (Disk I/O tasarrufu)
                if ($script:folderTickCounter % 2 -eq 0 -or $script:folderInactivitySec -eq 0) {
                    $found = Get-ChildItem -Path $targetPath -File -Recurse -ErrorAction SilentlyContinue |
                        Where-Object { $_.Name -match '\.(crdownload|part|downloading|!ut|opdownload|aria2|tmp)$' }
                    $script:lastFolderTempCount = if ($found) { @($found).Count } else { 0 }
                }

                $count = $script:lastFolderTempCount
                if ($count -gt 0) {
                    $script:folderInactivitySec = 0
                    $lblFolderStatus.Text = "$count adet geçici indirme dosyası aktif..."
                    $lblFolderStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F59E0B")
                    $lblLiveStatus.Text = "İndirme sürüyor: $count aktif dosya var"
                    $progBar.Value = 0
                } else {
                    $script:folderInactivitySec++
                    $lblFolderStatus.Text = "Geçici dosya kalmadı. Kapanmaya son: $(180 - $script:folderInactivitySec) sn"
                    $lblFolderStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
                    $lblLiveStatus.Text = "İndirme bitti, kapanma bekleniyor ($(180 - $script:folderInactivitySec) sn)"
                    $progBar.Value = $script:folderInactivitySec

                    if ($script:folderInactivitySec -ge 180) {
                        Stop-Task "Klasördeki geçici indirme dosyaları tamamlandı."
                        Trigger-ShutdownSequence
                    }
                }
            } else {
                # Dosya yazma hareketsizliği kontrolü (Son 30 sn içinde yazılan dosya)
                if ($script:folderTickCounter % 2 -eq 0 -or $script:folderInactivitySec -eq 0) {
                    $recentFiles = Get-ChildItem -Path $targetPath -File -Recurse -ErrorAction SilentlyContinue |
                        Where-Object { $_.LastWriteTime -gt [DateTime]::Now.AddSeconds(-30) }
                    $script:lastRecentFilesCount = if ($recentFiles) { @($recentFiles).Count } else { 0 }
                }

                if ($script:lastRecentFilesCount -gt 0) {
                    $script:folderInactivitySec = 0
                    $lblFolderStatus.Text = "Yeni dosya yazılıyor..."
                    $lblFolderStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F59E0B")
                    $lblLiveStatus.Text = "Klasöre veri yazılıyor..."
                    $progBar.Value = 0
                } else {
                    $script:folderInactivitySec++
                    $lblFolderStatus.Text = "Klasörde hareket yok ($(180 - $script:folderInactivitySec) sn kaldı)"
                    $lblFolderStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
                    $lblLiveStatus.Text = "Hareketsizlik süresi: $script:folderInactivitySec / 180 sn"
                    $progBar.Value = $script:folderInactivitySec

                    if ($script:folderInactivitySec -ge 180) {
                        Stop-Task "Klasörde dosya hareketi durdu."
                        Trigger-ShutdownSequence
                    }
                }
            }
        }

        "Process" {
            $targetProc = $txtProcessInput.Text.Trim()
            [int]$pidNum = 0
            $proc = $null

            if ([int]::TryParse($targetProc, [ref]$pidNum)) {
                $proc = Get-Process -Id $pidNum -ErrorAction SilentlyContinue
            } else {
                $cleanName = $targetProc -replace '\.exe$', ''
                $proc = Get-Process -Name $cleanName -ErrorAction SilentlyContinue
            }

            if ($proc) {
                $procFirst = @($proc)[0]
                $lblProcessStatus.Text = "$($procFirst.ProcessName) çalışıyor (PID: $($procFirst.Id))"
                $lblProcessStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
                $lblLiveStatus.Text = "Program izleniyor: $($procFirst.ProcessName) (PID: $($procFirst.Id)) aktif..."
            } else {
                $lblProcessStatus.Text = "$targetProc kapandı! Kapatma başlatılıyor..."
                $lblProcessStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444")
                Stop-Task "$targetProc programı kapandı."
                Trigger-ShutdownSequence
            }
        }
    }
})

$timer.Start()

# ==============================================================================
# Uygulamayı Çalıştır
# ==============================================================================
$null = $window.ShowDialog()
