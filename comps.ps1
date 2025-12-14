param(
    [Alias('d')]
    [int]$day,                 # необязательный, если не задан — без фильтра по дате

    [Alias('n')]
    [string]$name,             # необязательный, если не задан — без префикса по имени

    [Alias('e')]
    [ValidateSet('enable','disable')]
    [string]$enabled,          # enable / disable, если не задан — все

    [Alias('h')]
    [switch]$help              # показать справку
)

if ($help) {
    Write-Host @"
Использование:
  .\comps-date.ps1 [-d <дней>] [-n <префикс>] [-e <enable|disable>] [-h]

Параметры:
  -d  Количество дней без регистрации компьютера в домене (LastLogonDate старше).
      Если не задан, фильтра по дате нет.

  -n  Префикс поля Name (например, R76-, II-).
      Если не задан, выбираются все имена.

  -e  Статус учетной записи компьютера:
        enable  — только включенные (Enabled = True)
        disable — только отключенные (Enabled = False)
      Если не задан, выводятся и включенные, и отключенные.

  -h  Показать эту справку.
"@
    return
}

# если задан -d, считаем дату-отсечения
if ($day) {
    $Date = (Get-Date).AddDays(-$day)
}

# фильтр для Get-ADComputer: с префиксом или без
if ($name) {
    $filter = "Name -like '*$name*'"
} else {
    $filter = '*'
}

Get-ADComputer -Filter $filter -Properties LastLogonDate,Enabled |
    Where-Object {
        (-not $day     -or $_.LastLogonDate -lt $Date) -and
        (-not $enabled -or
            ($enabled -eq 'enable'  -and $_.Enabled -eq $true)  -or
            ($enabled -eq 'disable' -and $_.Enabled -eq $false)
        )
    } |
    Sort-Object Name |
    Select-Object Name,LastLogonDate,Enabled |
    Format-Table -AutoSize
