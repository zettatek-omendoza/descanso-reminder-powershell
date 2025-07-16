# Recordatorio de Descanso - PowerShell

Este script de PowerShell muestra una imagen centrada en pantalla con un fondo semitransparente como recordatorio para tomar una pausa activa frente al monitor. Ideal para usuarios que trabajan largas horas frente al computador.

## Características

- Imagen centrada con fondo oscuro.
- Botón de cierre tipo "X" en la esquina superior derecha.
- Se puede cerrar también con la tecla `ESC`.
- Se cierra automáticamente después de 60 segundos.
- Funciona solo en el monitor principal.

## Requisitos

- Windows con soporte para .NET Framework y PowerShell 5.1+
- Permisos de administrador para mostrar ventanas flotantes (ideal).

## Ejecución

```powershell
powershell -ExecutionPolicy Bypass -File .\MostrarDescanso.ps1
