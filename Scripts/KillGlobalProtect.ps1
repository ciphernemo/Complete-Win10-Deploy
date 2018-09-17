$ErrorActionPreference = "SilentlyContinue"

Stop-Process -Name PanGPA -Force -ErrorAction SilentlyContinue | out-null
Wait-Process -Name PanGPA -Timeout 30
Stop-Service -Name PanGPS -NoWait -Force -ErrorAction SilentlyContinue | out-null

exit
