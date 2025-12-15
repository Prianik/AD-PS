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

    [string]$export,           # путь к CSV для экспорта

    [switch]$disable_yes       # если указан — отключить отобранных пользователей
)

if ($help) {
    Write-Host @"
Использование:
  .\users.ps1 [-d <дней>] [-n <строка>] [-e <enable|disable>] [-export <путь_к_csv>] [-disable_yes] [-h]

Параметры:
  -d            Количество дней без входа (LastLogonDate старше).
                Если не задан, фильтра по дате нет.

  -n            Строка для поиска в Name (Name -like '*строка*').
                Если не задан, выбираются все имена.

  -e            Статус учетной записи:
                  enable  — только включенные (Enabled = True)
                  disable — только отключенные (Enabled = False)
                Если не задан, выводятся и включенные, и отключенные.

  -export       Путь к CSV-файлу для экспорта результата выборки.
                Если не задан, экспорт не выполняется.

  -disable_yes  Если указан, ВСЕ отобранные учетные записи пользователей будут отключены (Disable-ADAccount).

  -h            Показать эту справку.
"@
    return
}

if ($day) {
    $Date = (Get-Date).AddDays(-$day)
}

if ($name) {
    # подстрочный поиск по Name
    $filter = "Name -like '*$name*'"
} else {
    $filter = '*'
}

$users = Get-ADUser -Filter $filter -Properties LastLogonDate,Enabled |
    Where-Object {
        (-not $day     -or $_.LastLogonDate -lt $Date) -and
        (-not $enabled -or
            ($enabled -eq 'enable'  -and $_.Enabled -eq $true)  -or
            ($enabled -eq 'disable' -and $_.Enabled -eq $false)
        )
    } |
    Sort-Object Name

# Общий объект вывода
$out = $users |
    Select-Object Name,LastLogonDate,Enabled,DistinguishedName

# Вывод на экран
$out | Format-Table -AutoSize

# Экспорт (если указан -export)
if ($export -and $out) {
    $out | Export-Csv -Path $export -NoTypeInformation -Encoding UTF8
}

# Отключение (если указан -disable_yes)
if ($disable_yes -and $users) {
    Write-Host "`nОтключаю отобранных пользователей..." -ForegroundColor Yellow
    $users | Disable-ADAccount
    Write-Host "Готово." -ForegroundColor Green
}
