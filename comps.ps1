param(
    [Alias('d')]
    [int]$day,                 # необязательный, если не задан — без фильтра по дате

    [Alias('n')]
    [string]$name,             # необязательный, если не задан — без фильтра по имени (Name -like '*строка*')

    [Alias('e')]
    [ValidateSet('enable','disable')]
    [string]$enabled,          # enable / disable, если не задан — все

    [Alias('h')]
    [switch]$help,             # показать справку

    [switch]$disable_yes       # если указан — отключить отобранные компьютеры
)

if ($help) {
    Write-Host @"
Использование:
  .\comps-date.ps1 [-d <дней>] [-n <строка>] [-e <enable|disable>] [-disable_yes] [-h]

Параметры:
  -d            Количество дней без регистрации компьютера в домене (LastLogonDate старше).
                Если не задан, фильтра по дате нет.

  -n            Строка для поиска в Name (Name -like '*строка*').
                Если не задан, выбираются все имена.

  -e            Статус учетной записи компьютера:
                  enable  — только включенные (Enabled = True)
                  disable — только отключенные (Enabled = False)
                Если не задан, выводятся и включенные, и отключенные.

  -disable_yes  Если указан, ВСЕ отобранные компьютеры будут отключены (Disable-ADAccount).

  -h            Показать эту справку.
"@
    return
}

if ($day) {
    $Date = (Get-Date).AddDays(-$day)
}

if ($name) {
    # подстрочный поиск, а не только префикс
    $filter = "Name -like '*$name*'"
} else {
    $filter = '*'
}

$computers = Get-ADComputer -Filter $filter -Properties LastLogonDate,Enabled |
    Where-Object {
        (-not $day     -or $_.LastLogonDate -lt $Date) -and
        (-not $enabled -or
            ($enabled -eq 'enable'  -and $_.Enabled -eq $true)  -or
            ($enabled -eq 'disable' -and $_.Enabled -eq $false)
        )
    } |
    Sort-Object Name

$computers |
    Select-Object Name,LastLogonDate,Enabled |
    Format-Table -AutoSize

if ($disable_yes -and $computers) {
    Write-Host "`nОтключаю отобранные компьютеры..." -ForegroundColor Yellow
    $computers | Disable-ADAccount
    Write-Host "Готово." -ForegroundColor Green
}
