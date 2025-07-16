# Requires -RunAsAdministrator

$imageUrl = "https://i.imgur.com/CrpEtxZ.jpeg"
$tempFolder = "$env:TEMP\RestReminder"
$imageOriginalPath = "$tempFolder\rest_reminder.jpeg"

if (-not (Test-Path $tempFolder)) {
    New-Item -ItemType Directory -Path $tempFolder | Out-Null
}

if (-not (Test-Path $imageOriginalPath)) {
    Invoke-WebRequest -Uri $imageUrl -OutFile $imageOriginalPath -UseBasicParsing
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Monitor principal
$primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
$bounds = $primaryScreen.Bounds

# Fondo semitransparente
$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.Bounds = $bounds
$form.BackColor = 'Black'
$form.Opacity = 0.8
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.StartPosition = 'Manual'
$form.KeyPreview = $true

# Formulario de imagen con botón “X”
$formImage = New-Object System.Windows.Forms.Form
$formImage.FormBorderStyle = 'None'
$formImage.Width = 585
$formImage.Height = 800
$formImage.StartPosition = 'Manual'
$formImage.TopMost = $true
$formImage.BackColor = 'Black'
$formImage.ShowInTaskbar = $false
$formImage.Left = $bounds.Left + ($bounds.Width - $formImage.Width) / 2
$formImage.Top = $bounds.Top + ($bounds.Height - $formImage.Height) / 2

# Copia temporal de la imagen
$imagePath = [System.IO.Path]::Combine($tempFolder, "rest_" + [guid]::NewGuid().ToString() + ".jpeg")
Copy-Item -Path $imageOriginalPath -Destination $imagePath -Force

try {
    $image = [System.Drawing.Image]::FromFile($imagePath)
} catch {
    Write-Error "No se pudo cargar la imagen: $imagePath"
    exit
}

# Imagen
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Image = $image
$pictureBox.SizeMode = 'StretchImage'
$pictureBox.Dock = 'Fill'
$formImage.Controls.Add($pictureBox)

# Botón “X” en esquina superior derecha
$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = "X"
$btnClose.Width = 30
$btnClose.Height = 30
$btnClose.Top = 5
$btnClose.Left = $formImage.ClientSize.Width - $btnClose.Width - 5
$btnClose.FlatStyle = 'Flat'
$btnClose.FlatAppearance.BorderSize = 0
$btnClose.BackColor = 'Transparent'
$btnClose.ForeColor = 'White'
$btnClose.Font = 'Segoe UI,12,style=Bold'
$btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnClose.Add_Click({
    if (!$formImage.IsDisposed) { $formImage.Close() }
    if (!$form.IsDisposed) { $form.Close() }
})

# Para que el botón esté encima de la imagen
$formImage.Controls.Add($btnClose)
$formImage.Controls.SetChildIndex($btnClose, 0)

# Cierre con ESC
$form.Add_KeyDown({
    if ($_.KeyCode -eq 'Escape') {
        if (!$formImage.IsDisposed) { $formImage.Close() }
        if (!$form.IsDisposed) { $form.Close() }
    }
})

# Mostrar imagen al cargar fondo
$form.Add_Shown({
    $formImage.Show()
})

# Cierre automático a los 60 segundos
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 60000
$timer.Add_Tick({
    if (!$formImage.IsDisposed) { $formImage.Close() }
    if (!$form.IsDisposed) { $form.Close() }
    $timer.Stop()
})
$timer.Start()

# Ejecutar interfaz
[System.Windows.Forms.Application]::Run($form)

# Limpieza
if ($image -and ($image -is [System.Drawing.Image])) {
    $image.Dispose()
}
if (Test-Path $imagePath) {
    Remove-Item -Path $imagePath -Force -ErrorAction SilentlyContinue
}
if ($timer -and ($timer -is [System.Windows.Forms.Timer])) {
    $timer.Dispose()
}
