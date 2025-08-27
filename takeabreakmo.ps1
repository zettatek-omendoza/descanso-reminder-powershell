$imageUrl = "https://i.imgur.com/jOhzRmH.jpeg"
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

# Fondo semitransparente a pantalla completa
$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = 'None'
$form.Bounds = $bounds
$form.BackColor = 'Black'
$form.Opacity = 0.8
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.StartPosition = 'Manual'
$form.KeyPreview = $true

# Tamaño de la ventana de imagen = 80% de la resolución del monitor
$scale = 0.9
$imgWidth  = [int]($bounds.Width  * $scale)
$imgHeight = [int]($bounds.Height * $scale)

# Formulario de imagen (sin bordes), centrado
$formImage = New-Object System.Windows.Forms.Form
$formImage.FormBorderStyle = 'None'
$formImage.Width = $imgWidth
$formImage.Height = $imgHeight
$formImage.StartPosition = 'Manual'
$formImage.TopMost = $true
$formImage.BackColor = 'Black'
$formImage.ShowInTaskbar = $false
$formImage.Left = $bounds.Left + ([int](($bounds.Width  - $formImage.Width) / 2))
$formImage.Top  = $bounds.Top  + ([int](($bounds.Height - $formImage.Height) / 2))

# Copia temporal de la imagen
$imagePath = [System.IO.Path]::Combine($tempFolder, "rest_" + [guid]::NewGuid().ToString() + ".jpeg")
Copy-Item -Path $imageOriginalPath -Destination $imagePath -Force

try {
    $image = [System.Drawing.Image]::FromFile($imagePath)
} catch {
    Write-Error "No se pudo cargar la imagen: $imagePath"
    exit
}

# Imagen (mantener aspecto)
$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Image = $image
$pictureBox.SizeMode = 'Zoom'    # Antes: StretchImage (deformaba)
$pictureBox.Dock = 'Fill'
$formImage.Controls.Add($pictureBox)

# Botón “X” en esquina superior derecha
$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = "X"
$btnClose.Width = 30
$btnClose.Height = 30
$btnClose.FlatStyle = 'Flat'
$btnClose.FlatAppearance.BorderSize = 0
$btnClose.BackColor = [System.Drawing.Color]::FromArgb(80, 0, 0, 0)
$btnClose.ForeColor = 'White'
$btnClose.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand

# Función para posicionar el botón correctamente en cada cambio de tamaño
$positionCloseBtn = {
    $btnClose.Top = 5
    $btnClose.Left = $formImage.ClientSize.Width - $btnClose.Width - 5
}
$formImage.Add_Resize($positionCloseBtn)
& $positionCloseBtn

$btnClose.Add_Click({
    if (!$formImage.IsDisposed) { $formImage.Close() }
    if (!$form.IsDisposed) { $form.Close() }
})

# Asegurar que el botón esté sobre la imagen
$formImage.Controls.Add($btnClose)
$formImage.Controls.SetChildIndex($btnClose, 0)

# Cierre con ESC y clic en el fondo
$form.Add_KeyDown({
    if ($_.KeyCode -eq 'Escape') {
        if (!$formImage.IsDisposed) { $formImage.Close() }
        if (!$form.IsDisposed) { $form.Close() }
    }
})
$form.Add_Click({
    if (!$formImage.IsDisposed) { $formImage.Close() }
    if (!$form.IsDisposed) { $form.Close() }
})

# Mostrar imagen cuando aparece el fondo
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
