# How the script works:
#     Add-Type: This part adds the necessary Windows API functions for mouse movement (SetCursorPos) and to get the cursor's position (GetCursorPos).
#     Get-IdleTime: This function calculates the idle time of the system by getting the last input time and comparing it to the current time.
#     Move-MouseLeftRight: This function moves the mouse 10 pixels right, waits for 5 seconds, and if still idle, moves it 10 pixels left.
#     Main Loop: The script continuously checks the idle time, and if the idle time is greater than 5 seconds, it moves the mouse right and left.

# Usage:
#     Save this script as a .ps1 file and run it using PowerShell.
#     The script continuously checks for idle time and moves the mouse right and left after 5 seconds of idle time.

# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

if (-not ([System.Management.Automation.PSTypeName]'MouseMover').Type) {
    $signature = @"
    using System;
    using System.Runtime.InteropServices;

    public class MouseMover {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SetCursorPos(int x, int y);

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern bool GetCursorPos(out POINT lpPoint);

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        public struct POINT {
            public int X;
            public int Y;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct LASTINPUTINFO {
            public uint cbSize;
            public uint dwTime;
        }
    }
"@

    Add-Type -TypeDefinition $signature
}

function Get-IdleTime {
    $lastInputInfo = New-Object "MouseMover+LASTINPUTINFO"
    $lastInputInfo.cbSize = [System.Runtime.InteropServices.Marshal]::SizeOf($lastInputInfo)
    $result = [MouseMover]::GetLastInputInfo([ref]$lastInputInfo)
    if (-not $result) {
        return [TimeSpan]::Zero
    }
    $idleMilliseconds = [Environment]::TickCount - $lastInputInfo.dwTime
    $idleTime = [TimeSpan]::FromMilliseconds($idleMilliseconds)
    return $idleTime
}

function Move-MouseLeftRight {
    param (
        [int]$centerX,
        [int]$centerY,
        [int]$distance = 10,
        [int]$speed = 50
    )

    $xRight = $centerX + $distance
    $xLeft = $centerX - $distance

    [MouseMover]::SetCursorPos($xRight, $centerY)
    Start-Sleep -Seconds 5

    $idleTime = (Get-IdleTime).TotalSeconds
    if ($idleTime -gt 5) {
        [MouseMover]::SetCursorPos($xLeft, $centerY)
        Start-Sleep -Milliseconds $speed
    }
}

while ($true) {
    $idleTime = (Get-IdleTime).TotalSeconds
    if ($idleTime -gt 5) {
        $mousePos = New-Object "MouseMover+POINT"
        [MouseMover]::GetCursorPos([ref]$mousePos)
        Move-MouseLeftRight -centerX $mousePos.X -centerY $mousePos.Y
    }
    Start-Sleep -Milliseconds 500
}
