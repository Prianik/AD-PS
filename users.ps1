param(
    [Alias('d')]
    [int]$day,

    [Alias('n')]
    [string]$name,

    [Alias('e')]
    [ValidateSet('enable','disable')]
    [string]$enabled,

    [Alias('h')]
    [switch]$help
)

if ($help) {
    Write-Host @"
Использование:
  .\users-date.ps1 [-d <дней>] [-n <префикс>] [-e <enable|disable>] [-h]

Параметры:
  -d  Количество дней без входа. Если не задан, фильтра по дате нет.
  -n  Префикс поля Name (например, R76-, II-). Если не задан, все имена.
  -e  Статус учетной записи:
        enable  - только включенные
        disable - только отключенные
      Если не задан, и включенные, и отключенные.
  -h  Показать эту справку.
"@
    return
}

if ($day) {
    $Date = (Get-Date).AddDays(-$day)
}

if ($name) {
    $filter = "Name -like '*$name*'"
} else {
    $filter = '*'
}

Get-ADUser -Filter $filter -Properties LastLogonDate,Enabled |
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
